'''
=================
CDF Plots
=================
This script parses and visualizes the application trace sim data
for the fat-tree model
'''
import math
import collections
import numpy as np
import argparse
import matplotlib
import matplotlib.pyplot as plt
from matplotlib import mlab

# Parse commandline arguments
parser = argparse.ArgumentParser()
parser.add_argument('--lp-io-dir', action='store', dest='lpIoDir', nargs='+', type=str,
                    help='space separated list of paths to the directories containing all modelnet sim data for each execution')
parser.add_argument('--sim-labels', action='store', dest='simLabels', nargs='+', type=str,
                    help='space separated list of labels for each simulation')
parser.add_argument('--num-bins', action='store', default=-1, dest='nbins',
                    help='Number of bins for CDF histogram')
parser.add_argument('--data-file', action='store', default=0, dest='dataFile',
                    help='file with the metric to be visualized. 0:msg-stats, 1:switch-stats, 2:switch-traffic')
parser.add_argument('--metric', action='store', default=5, dest='metric', nargs='+', type=int,
                    help='space separated list of metrics from selected data file to visualize')
parser.add_argument('--save', action='store_true', default=False, dest='pltSave',
                    help='If selected, saves the plot to --lp-io-dir instead of printing to screen')
parser.add_argument('--model-type', action='store', dest='modelType', nargs='+', type=int,
                    help='space separated list of network model types. 0:ftree, 1:dfly, 2:sfly. Ex: --model-type 0 1 2')
parser.add_argument('--num-nodes', action='store', dest='numNodes', nargs='+', type=int,
                    help='space separated list of node counts for each execution to visualize')
parser.add_argument('--switch-radix', action='store', dest='portsPerSwitch', nargs='+', type=int,
                    help='space separated list of switch radix count for each execution to visualize')
parser.add_argument('--annotate-figure', action='store_true', default=False, dest='annoFlag',
                    help='If selected, annotates the generated figure data')
parser.add_argument('--axis-limits', action='store_true', default=True, dest='axisLimits',
                    help='If selected, constrains the limits of the figure axis')

results = parser.parse_args()
print 'lp io dir          =', results.lpIoDir
print 'sim labels         =', results.simLabels
print 'numbins            =', results.nbins
print 'data file          =', results.dataFile
print 'metric             =', results.metric
print 'save plots to file =', results.pltSave
print 'model-type         =', results.modelType
print 'num-noeds          =', results.numNodes
print 'ports per switch   =', results.portsPerSwitch
print 'annotate figure    =', results.annoFlag
print 'axis limits        =', results.axisLimits
lpIoDir = results.lpIoDir
simLabels = results.simLabels
nBins = int(results.nbins)
dataFile = int(results.dataFile)
metric = results.metric
pltSave = results.pltSave
modelType = results.modelType
nodes = results.numNodes
portsPerSwitch = results.portsPerSwitch
annotateFigure = results.annoFlag
axisLimits = results.axisLimits

matplotlib.rcParams.update({'font.size': 12})

#Width of the lines for plotting
lwidth = 2.0

for met in metric:
    #init/clean reused variables
    xlabel = []
    #Create figure for visualization
    fig, ax = plt.subplots(figsize=(5.2, 4))

    for sim in range(len(modelType)):
        if modelType[sim] == 0:
            mType = 'fattree'
            hwName = 'switch'
            portMod = 4
        elif modelType[sim] == 1:
            mType = 'dragonfly'
            hwName = 'router'
            portMod = 3
        elif modelType[sim] == 2:
            mType = 'slimfly'
            hwName = 'router'
            portMod = 3

        #generate path to data for given simulation
        #lpIoDir[sim] = 'fattree-trace-'+trace[sim]+'-1ms-n'+str(nodes[sim])+'-'+routing[sim]
        print 'Working on '+'metric '+str(met)+', simulation '+lpIoDir[sim]

        # Extract mpi-replay-stats file header
        #inFile = open(lpIoDir[sim]+'/mpi-replay-stats', 'r')
        #line = inFile.readline()
        #line = line.strip()
        #temp = line.replace('# Format','')
        #temp = temp.replace(' <','')
        #temp = temp.replace('>',',')
        #temp = temp.replace('# ','')
        #replayHeader= temp.split(",")
        #del replayHeader[-1]

        # Parse mpi-replay-stats data
        #print 'Parsing mpi-replay-stats data...'
        #replayDataTemp = []
        #while True:
        #    line = inFile.readline()
        #    if not line: break
        #    line = line.strip()
        #    temp = line.split(" ")
        #    temp = [float(i) for i in temp]
        #    replayDataTemp.append(temp)
        #inFile.close()

        # Extract fattree-msg-stats file header
        if mType == "dragonfly":
            inFile = open(lpIoDir[sim]+'/'+mType+'-msg-stats.meta', 'r')
        else:
            inFile = open(lpIoDir[sim]+'/'+mType+'-msg-stats', 'r')
        line = inFile.readline()
        line = line.strip()
        temp = line.replace('# Format','')
        temp = temp.replace(' <','')
        temp = temp.replace('>',',')
        temp = temp.replace('Total Data Size','Data Per Terminal [bytes]')
        temp = temp.replace('Total Packet Latency','Avg Packet Latency [ns]')
        temp = temp.replace('# Flits/','')
        temp = temp.replace('hops','Hops')
        temp = temp.replace('Busy Time','Terminal Busy Time [us]')
        temp = temp.replace('End Time','End Time [ms]')
        msgHeader= temp.split(",")
        del msgHeader[-1]
        if mType == "dragonfly":
            inFile.close()
            inFile = open(lpIoDir[sim]+'/dragonfly-msg-stats', 'r')

        # Parse fattree-msg-stats data
        print 'Parsing '+hwName+'-msg-stats data...'
        msgDataTemp = []
        while True:
            line = inFile.readline()
            if not line: break
            line = line.strip()
            temp = line.split(" ")
            #temp = [float(i) for i in temp]
            if temp[met] == '-nan' or temp[met] == 'nan':
                takingUpSpace = 1
            else:
                msgDataTemp.append(temp)
        inFile.close()

        # Extract fattree-switch-stats file header
        inFile = open(lpIoDir[sim]+'/'+mType+'-'+hwName+'-stats', 'r')
        line = inFile.readline()
        line = line.strip()
        temp = line.replace('# Format','')
        temp = temp.replace(' <','')
        temp = temp.replace('>',',')
        switchStatsHeader= temp.split(",")
        del switchStatsHeader[-1]

        # Parse mpi-replay-stats data
        print 'Parsing '+hwName+'-stats data...'
        switchStatsDataTemp = []
        while True:
            line = inFile.readline()
            if not line: break
            line = line.strip()
            temp = line.split(" ")
            if temp != "":
                switchStatsDataTemp.append(temp)
            #temp = [float(i) for i in temp]
        inFile.close()

        # Extract fattree-switch-traffic file header
        inFile = open(lpIoDir[sim]+'/'+mType+'-'+hwName+'-traffic', 'r')
        line = inFile.readline()
        line = line.strip()
        temp = line.replace('# Format','')
        temp = temp.replace(' <','')
        temp = temp.replace('>',',')
        switchTrafficHeader= temp.split(",")
        del switchTrafficHeader[-1]

        # Parse mpi-replay-stats data
        print 'Parsing '+hwName+'-switch-traffic data...'
        switchTrafficDataTemp = []
        while True:
            line = inFile.readline()
            if not line: break
            line = line.strip()
            temp = line.split(" ")
            #temp = [float(i) for i in temp]
            switchTrafficDataTemp.append(temp)
        inFile.close()

        visData = []
        if dataFile == 0:
            visDataTemp = msgDataTemp
        elif dataFile == 1:
            visDataTemp = switchStatsDataTemp
        elif dataFile == 2:
            visDataTemp = switchTrafficDataTemp
        for i in range(len(visDataTemp)):
            if dataFile == 0:
                if met == 6:
                    visData.append(float(visDataTemp[i][met])+1)
                if met == 7:
                    visData.append(float(visDataTemp[i][met])/1000)
                #elif met == 4:
                #    if float(visDataTemp[i][met+1]) > 0:
                #        visData.append(float(visDataTemp[i][met]) / float(visDataTemp[i][met+1]))
                else:
                    visData.append(float(visDataTemp[i][met]))
            elif dataFile == 2:
                for j in range(len(visDataTemp[i])-portMod):
                    visData.append(float(visDataTemp[i][met+j])/1024/1024)
            else:
                for j in range(len(visDataTemp[i])-portMod):
                    visData.append(float(visDataTemp[i][met+j])/1000)

        mean = sum(visData) / len(visData)

        if sim == 0:
            # plot the cumulative histogram
            n, bins, patches = ax.hist(visData, nBins, normed=1, histtype='step',
                cumulative=True, label=simLabels[sim].replace('_','.').replace('-',' '), linewidth=lwidth)
        else:
            # Overlay a reversed cumulative histogram.
            n, bins, patches = ax.hist(visData, nBins, normed=1, histtype='step', cumulative=True,
                label=simLabels[sim].replace('_','.').replace('-',' '), linewidth=lwidth)

        if annotateFigure == 1:
            #Annotate figure
            xText = max(visData)
            yText = sim*.1+.11
            avgMarkerOffsetX = 0
            avgMarkerOffsetY = 0.00
            avgMarkerTextOffsetX = 2
            avgMarkerTextOffsetY = 0
            digits = 3
            if dataFile == 0:
                if met == 7:
                    if simLabels[sim] == 'cr1k':
                        xText = 5.26
                        yText = sim*.1+.11
                    elif simLabels[sim] == 'mg10k':
                        xText = 5.355
                        yText = sim*.1+.13
                        avgMarkerOffsetX = 0.0001
                        avgMarkerOffsetY = -0.017
                    else:
                        xText = 4.55
                        yText = sim*.1+.53
                        avgMarkerOffsetX = -0.01
                        avgMarkerOffsetY = -0.02
                        if sim == 0:
                            avgMarkerTextOffsetX = 0.05
                            avgMarkerTextOffsetY = 0
                        elif sim == 1:
                            avgMarkerTextOffsetX = -0.03
                            avgMarkerTextOffsetY = -0.06
                        else:
                            avgMarkerTextOffsetX = -0.04
                            avgMarkerTextOffsetY = 0.06
                elif met == 5:
                    xText = -1000
                    yText = -1000
                    avgMarkerOffsetX = -0.035
                    avgMarkerOffsetY = -0.024
                    if sim == 0:
                        avgMarkerTextOffsetX = 0.2
                    else:
                        avgMarkerTextOffsetX = -0.4
                elif met == 3:
                    if simLabels[sim] == 'cr1k':
                        avgMarkerOffsetX = -6
                        avgMarkerOffsetY = -0.02
                        if sim == 1:
                            avgMarkerTextOffsetX = -70
                        else:
                            avgMarkerTextOffsetX = 30
                    elif simLabels[sim] == 'mg110k':
                        avgMarkerOffsetX = -150
                        avgMarkerOffsetY = -0.02
                        if sim == 0:
                            avgMarkerTextOffsetX = 2000
                        elif sim == 1:
                            avgMarkerTextOffsetX = 2350
                        else:
                            avgMarkerTextOffsetX = 1700
                    else:
                        avgMarkerOffsetX = -20
                        avgMarkerOffsetY = -0.02
                        if sim == 0:
                            avgMarkerTextOffsetX = -310
                        else:
                            avgMarkerTextOffsetX = 110
                    xText = -30000
                    yText = -1000
                    digits = 0
            elif dataFile == 2:
                xText = 4
                yText = sim*.1+.11
            else:
                if simLabels[sim] == 'mg110k':
                    xText = 5000
                    yText = sim*.02+.91
                elif simLabels[sim] == 'mg10k':
                    xText = 1000
                    yText = sim*.01+.9601
                avgMarkerTextOffsetX = 30
                avgMarkerOffsetX = -60000
                avgMarkerOffsetY = -0.004
                if sim == 2:
                    avgMarkerOffsetY = -0.08

            ax.annotate(simLabels[sim]+' max: '+str(round(max(visData),3)), xy=(max(visData), yText - 0.001),
                xytext=(xText, yText), arrowprops=dict(facecolor='black', shrink=0.01, width=0.1, headwidth=5),)
            ax.annotate('X', xy=(bins[np.searchsorted(bins,mean)], n[np.searchsorted(bins,mean)]),
                xytext=(bins[np.searchsorted(bins,mean)] + avgMarkerOffsetX, n[np.searchsorted(bins,mean)] + avgMarkerOffsetY))
            if digits == 0:
                ax.annotate(''+str(int(round(mean,digits))), xy=(bins[np.searchsorted(bins,mean)], n[np.searchsorted(bins,mean)]),
                    xytext=(bins[np.searchsorted(bins,mean)] + avgMarkerOffsetX + avgMarkerTextOffsetX, n[np.searchsorted(bins,mean)] + avgMarkerOffsetY + avgMarkerTextOffsetY))
            else:
                ax.annotate(''+str(round(mean,digits)), xy=(bins[np.searchsorted(bins,mean)], n[np.searchsorted(bins,mean)]),
                    xytext=(bins[np.searchsorted(bins,mean)] + avgMarkerOffsetX + avgMarkerTextOffsetX, n[np.searchsorted(bins,mean)] + avgMarkerOffsetY + avgMarkerTextOffsetY))

    if axisLimits == 1:
        # tidy up the figure
        ax.set_axisbelow(True)
        ax.yaxis.grid(color='gray', linestyle='dashed')
        ax.xaxis.grid(color='gray', linestyle='dashed')

        # Set axis limits according to metric
        ax.set_ylim([0.0,1.15])
        if dataFile == 0:
            if met == 8:
                if simLabels[sim] == 'mg10k':
                    ax.set_xlim([5.35,5.44])
                elif simLabels[sim] == 'cr1k':
                    ax.set_xlim([250,264])
                else:
                    ax.set_xlim([4.5,5.8])
            elif met == 4:
                print 'something'
                #ax.set_xlim([4.5,6])
            elif met == 3:
                #ax.set_xlim([0.4,4])
                ax.set_ylim([0.0,1.15])
        elif dataFile == 2:
            nothing = 0
        else:
            if simLabels[sim] == 'cr1k':
                ax.set_ylim([0.85,1.05])
            elif simLabels[sim] == 'mg110k':
                ax.set_ylim([0.9,1.02])
            else:
                #ax.set_ylim([0.0,1.01])
                something=1


    #ax.grid(True)
    #ax.legend(loc=0)
    if met == 7:
        ax.legend(loc='upper left', ncol=3, borderaxespad=0.1)
    else:
        ax.legend(loc='upper left', ncol=3, borderaxespad=0.1)
    #ax.set_title('Cumulative step histograms')
    if dataFile == 0:
        xlabel = msgHeader[met]
    elif dataFile == 1:
        xlabel = 'Switch Link Busy Time [us]'
    elif dataFile == 2:
        xlabel = 'Switch Link Traffic [MB]'
    ax.set_xlabel(xlabel)
    ax.set_ylabel('Cumulative Distribution')

    plt.tight_layout()

    if pltSave == True:
        fig.savefig(lpIoDir[sim]+'/'+simLabels[sim]+str(nodes[sim])+xlabel.replace(' ','')+'.pdf', dpi=320, facecolor='w',
                edgecolor='w', orientation='portrait', papertype=None,
                format=None, transparent=False, bbox_inches=None, 
                pad_inches=0.25, frameon=None)
    else:
        plt.show()
