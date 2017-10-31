'''
=================
3D wireframe plot
=================
This script parses and visualizes the generated model-net sampling LP-IO
output file
'''
import math
import collections
import numpy as np
import argparse
import matplotlib
#matplotlib.use('MacOSX')
#matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import axes3d
from scipy.interpolate import griddata

# Parse commandline arguments
parser = argparse.ArgumentParser()
parser.add_argument('--lp-io-dir', action='store', dest='lpIoDir',
                    help='path to the directory containing all modelnet sim data')
parser.add_argument('--metric', action='store', default=-1, dest='metric',
                    help='Value of one specific metric to visualize')
parser.add_argument('--disable-sampling', action='store_false', default=True, dest='sampling',
                    help='If selected, disables the visualization of sampling data')
parser.add_argument('--disable-aggregate', action='store_false', default=True, dest='aggregate',
                    help='If selected, disables the visualization of aggregate data')
parser.add_argument('--trace-names', action='store', dest='traceNames',
                    help='if aggregate visualizations are enabled, need names of traces in alloc-file following csv format')
parser.add_argument('--save', action='store_true', default=False, dest='pltSave',
                    help='If selected, saves the plot to --lp-io-dir instead of printing to screen')
parser.add_argument('--individual', action='store_true', default=False, dest='pltIndividually',
                    help='If selected, plots each figure individually')
parser.add_argument('--dimensions', action='store', dest='dimensions',
                    help='Can be either "2" or "3" for either 2d or 3d plots')

results = parser.parse_args()
print 'lp io dir          =', results.lpIoDir
print 'metric             =', results.metric
print 'Visualize sampling =', results.sampling
print 'Visualize aggregate=', results.aggregate
print 'trace names        =', results.traceNames
print 'save plots to file =', results.pltSave
print 'individual plots   =', results.pltIndividually
print 'dimensions         =', results.dimensions
lpIoDir = results.lpIoDir
metric = results.metric
sampling = results.sampling
aggregate = results.aggregate
traceNames = results.traceNames.split(',')
pltSave = results.pltSave
pltIndividually = results.pltIndividually
dimensions = int(results.dimensions)

repetitions = 0
nw_lp = 0
modelnet_fattree = 0
fattree_switch = 0

# Extract config parameters
print 'Extracting config parameters...'
inFile = open(lpIoDir+'/network-model.conf', 'r')
while True:
    line = inFile.readline()
    if not line: break
    line = line.strip()
    temp = line.replace(' ','')
    temp = temp.replace('"','')
    temp = temp.replace(';','')
    temp = temp.split("=")
    if temp[0] == 'repetitions':
        repetitions = float(temp[1])
    if temp[0] == 'nw-lp':
        nw_lp = float(temp[1])
    if temp[0] == 'modelnet_fattree':
        modelnet_fattree = float(temp[1])
    if temp[0] == 'fattree_switch':
        fattree_switch = float(temp[1])
inFile.close()

# Extract allocation data
print 'Extracting allocation data...'
allocations = ['0' for z in range(len(traceNames))]
inFile = open(lpIoDir+'/allocation.conf', 'r')
for i in range(len(traceNames)):
    line = inFile.readline()
    if not line: break
    line = line.strip()
    allocations[i] = line.split(" ")
inFile.close()

# Extract sampling file header
inFile = open(lpIoDir+'/mpi-sampling-stats', 'r')
line = inFile.readline()
line = line.strip()
temp = line.replace('# Format','')
temp = temp.replace(' <','')
temp = temp.replace('>',',')
samplingHeader= temp.split(",")
del samplingHeader[-1]
# Extract sampling interval and end time
line = inFile.readline()
line = line.strip()
temp = line.split(" ")
samplingInterval = float(temp[1])
samplingInterval - int(samplingInterval)
samplingEndTime = float(temp[3])
samplingEndTime = int(samplingEndTime)
# Parse sampling data
print 'Parsing sampling data...'
samplingDataTemp = []
while True:
    line = inFile.readline()
    if not line: break
    line = line.strip()
    temp = line.split(" ")
    temp = [float(i) for i in temp]
    samplingDataTemp.append(temp)
inFile.close()

# Computing and adding additional data
print 'Computing additional data...'
lastCompTime = 0
lastSendTime = 0
tempTime = 0
rankID = samplingDataTemp[0][1]
for i in range(len(samplingDataTemp)):
    if samplingDataTemp[i][3] == 0:
        samplingDataTemp[i].append(float(0))
        samplingDataTemp[i].append(float(0))
    else:
        samplingDataTemp[i].append(float(samplingDataTemp[i][13]/samplingDataTemp[i][3]))
        samplingDataTemp[i].append(float(samplingDataTemp[i][13]*math.pow(1,9)/float(samplingInterval)*math.pow(1024,2)))
    if rankID != samplingDataTemp[i][1]:
        lastCompTime = 0
        lastSendTime = 0
        rankID = samplingDataTemp[i][1]
    if samplingDataTemp[i][12] > 0:
        if lastCompTime == 0:
            lastCompTime = float(samplingDataTemp[i][12])
        else:
            tempTime = float(samplingDataTemp[i][12])
            samplingDataTemp[i][12] = float(samplingDataTemp[i][12]) - lastCompTime
            lastCompTime = tempTime
    if samplingDataTemp[i][9] > 0:
        if lastSendTime == 0:
            lastSendTime = float(samplingDataTemp[i][9])
        else:
            tempTime = float(samplingDataTemp[i][9])
            samplingDataTemp[i][9] = float(samplingDataTemp[i][9]) - lastSendTime
            lastSendTime = tempTime
samplingHeader.append('Avg Bytes')
samplingHeader.append('Injection Bandwidth [MB/s]')

# Compute sampling parameters
numMetrics = len(samplingHeader)
numTimeBins = int(samplingEndTime / samplingInterval)
numRanks = int(len(samplingDataTemp)/numTimeBins)

# Rearrange the sampling data into 3D data structure
print 'Constructing data structure...'
samplingData = [[[0 for z in range(numTimeBins)] for y in range(numMetrics)] for x in range(numRanks)]
for z in range(numTimeBins):
    for y in range(numMetrics):
        for x in range(numRanks):
            samplingData[x][y][z]= samplingDataTemp[x*numTimeBins + z][y]

# Function for grabbing sampling data for given metric
def func_extract_metric_sampling(timeBins,ranks,metric):
    Z = np.zeros(shape=(len(ranks),len(timeBins)))
    for x in range(numTimeBins):
        for y in range(numRanks):
            if samplingData[y][metric][x] > 1e10:
                Z[y][x] = 0
            else:
                Z[y][x] = samplingData[y][metric][x]
    return Z

# Function for grabbing aggregate data for given metric
# traces: number of application traces
def func_extract_metric_aggregate(timeBins,ranks,traces,allocs,metric):
    Z = [0 for i in range(traces)]
    sys = []
    for t in range(traces):
        rowData = []
        for y in range(len(samplingData)):
            if str(int(samplingData[y][1][0])) in allocs[t]:
                agg = 0
                for x in range(numTimeBins):
                    if samplingData[y][metric][x] > 1e10:
                        agg += 0
                    else:
                        agg += samplingData[y][metric][x]
                rowData.append(agg)
                sys.append(agg)
        Z[t] = np.array(rowData)
    # If we are performing multijob, add tracename for System aggregate information
    if traces > 1:
        Z.append(np.array(sys))
    return Z

# Function for formatting 3D figures
def func_set_figure_3d(xlabel,ylabel,zlabel,title,grid):
    ax.set_ylabel(ylabel)
    ax.set_xlabel(xlabel)
    ax.set_zlabel(zlabel)
    plt.title(title)
    plt.grid(grid)

# Function for formatting 2D figures
def func_set_figure_2d(xlabel,ylabel,title,grid):
    plt.ylabel(ylabel)
    plt.xlabel(xlabel)
    plt.title(title)
    plt.grid(grid)

# Generating sampling visualizations
if sampling == True:
    print 'Generating Sampling Visualizations...'
    line = []
    x1 = np.array(range(numTimeBins)) * samplingInterval / 1000000
    y1 = np.array(range(numRanks))
    X, Y = np.meshgrid(x1,y1)
    if metric == -1:
        metricStart = 3
    else:
        metricStart = int(metric)
        numMetrics = int(metric) + 1
    first = True
    for i in range(metricStart,numMetrics):
        if pltIndividually == True:
            fig = plt.figure(figsize=(6,6))
        else:
            if first:
                fig = plt.figure(figsize=(13,7.5))
                first = False
        metric = i
        if pltIndividually == True:
            if dimensions == 3:
                ax = fig.add_subplot(1,1,1,projection='3d')
            else:
                ax = fig.add_subplot(1,1,1)
        else:
            if dimensions == 3:
                ax = fig.add_subplot(math.ceil(math.sqrt(numMetrics-metricStart)),
                                    math.ceil(math.sqrt(numMetrics-metricStart)),
                                    i-metricStart+1, projection='3d')
            else:
                ax = fig.add_subplot(math.ceil(math.sqrt(numMetrics-metricStart)),
                                    math.ceil(math.sqrt(numMetrics-metricStart)),
                                    i-metricStart+1)
            fig.tight_layout()
        Z = func_extract_metric_sampling(x1,y1,metric)
        #ax.plot_surface(X, Y, Z, rstride=10, cstride=10)
        for idx in range(len(Z)):
            if dimensions == 3:
                #ax.plot_surface(X, Y, Z, rstride=10, cstride=10)
                ax.plot(x1,[y1[idx]]*len(x1),Z[idx],color='blue')
                ax.view_init(elev=0, azim=270)
                func_set_figure_3d('Virtual Time', 'MPI Rank ID', samplingHeader[metric],
                    samplingHeader[metric], 'TRUE')
                #break
            else:
                line.append(ax.plot(x1,Z[idx]))
                ax.set_xlabel('Virtual Time (ms)')
                ax.set_ylabel(samplingHeader[metric])
                ax.set_title(samplingHeader[metric])
                #plt.text(60, .025, r'$\mu=100,\ \sigma=15$')
                ax.legend(loc='upper left', ncol=1, borderaxespad=0.1)
                ax.set_axisbelow(True)
                ax.yaxis.grid(color='gray', linestyle='dashed')
                ax.xaxis.grid(color='gray', linestyle='dashed')
                #ax.view_init(elev=-270, azim=270)
                #func_set_figure_3d('Virtual Time', samplingHeader[metric],' ',
                #    samplingHeader[metric], 'TRUE')
        if pltIndividually == True:
            if pltSave == True:
                fig.savefig(lpIoDir+'/sampling'+samplingHeader[metric].replace(' ','')+'.pdf', dpi=320, facecolor='w',
                        edgecolor='w', orientation='portrait', papertype=None,
                        format=None, transparent=False, bbox_inches=None, 
                        pad_inches=0.25, frameon=None)
            else:
                plt.show()
    if pltIndividually == False:
        if pltSave == True:
            fig.savefig(lpIoDir+'/AllMetrics.pdf', dpi=320, facecolor='w',
                    edgecolor='w', orientation='portrait', papertype=None,
                    format=None, transparent=False, bbox_inches=None, 
                    pad_inches=0.25, frameon=None)
        else:
            plt.show()

# Generating Aggregate  visualizations
if aggregate == True:
    print 'Generating Aggregate Visualizations...'
    x1 = np.array(range(numTimeBins)) * samplingInterval
    y1 = np.array(range(numRanks))
    if metric == -1:
        metricStart = 3
    else:
        metricStart = int(metric)
        numMetrics = int(metric) + 1
    first = True
    for i in range(metricStart,numMetrics):
        if pltIndividually == True:
            fig = plt.figure(figsize=(6,6))
        else:
            if first:
                fig = plt.figure(figsize=(10,10))
                first = False
        metric = i
        if pltIndividually == True:
            ax = fig.add_subplot(1,1,1)
        else:
            ax = fig.add_subplot(math.ceil(math.sqrt(numMetrics-metricStart)),
                                math.ceil(math.sqrt(numMetrics-metricStart)),
                                i-metricStart+1)
            fig.tight_layout()

        Z = func_extract_metric_aggregate(x1,y1,len(traceNames),allocations,metric)
        ax.boxplot(Z, whis='range')
        if len(traceNames) > 1:
            traceNames.append('System')
        func_set_figure_2d(traceNames, samplingHeader[metric], samplingHeader[metric], 'on')
        if len(traceNames) > 1:
            traceNames.pop()

        if pltIndividually == True:
            if pltSave == True:
                fig.savefig(lpIoDir+'/aggregate'+samplingHeader[metric].replace(' ','')+'.pdf', dpi=320, facecolor='w',
                        edgecolor='w', orientation='portrait', papertype=None,
                        format=None, transparent=False, bbox_inches=None, 
                        pad_inches=0.25, frameon=None)
            else:
                plt.show()
    if pltIndividually == False:
        if pltSave == True:
            fig.savefig(lpIoDir+'/AllMetrics.pdf', dpi=320, facecolor='w',
                    edgecolor='w', orientation='portrait', papertype=None,
                    format=None, transparent=False, bbox_inches=None, 
                    pad_inches=0.25, frameon=None)
        else:
            plt.show()
