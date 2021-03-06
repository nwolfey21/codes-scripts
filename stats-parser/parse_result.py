"""File Parser.

Usage:
  parse_result.py single <filename> [--plot=<type>] [-s]
  parse_result.py drill [--plot=<type>] [--dstart=<dir>] [-s]
  parse_result.py plot
  parse_result.py (-h | --help)

Options:
  -h --help         Show this screen.
  --plot=<type>			Plot results [default: "all"]
  --save			Save the results as CSV file
  --dstart=<dir>    In drill-down (recursive) mode chooses the root folder to start parsing.

"""

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
#import seaborn as sns
import docopt
from pathlib import Path
from docopt import docopt
import os
import tempfile
from ggplot import *
import pdb


nemolabel = "NeMo"
cpulabel = " Trace"
ts = "Total Sends"
tr = "Total Recvs"
bs = "Bytes Sent"
br = "Bytes Recvd"
et = "End Time"
mets = [ts, tr, bs, br, et]

formatc = ["lpid", "mpid", "Total Sends", "Total Recvs", "Bytes Sent", "Bytes Recvd", "End Time",
          "Send Time", "Comm. Time", "Compute Time", "Job ID", "Run Type", "Run Name"]

def readFilePD(filename):
    with tempfile.TemporaryFile("w+") as outF:
        od = (",".join(formatc) + "\n")
        #od = od.encode()
        outF.write(od)
        with open(filename, 'r') as f:
            fullData = f.readlines()[1:]

        for line in fullData:
            dl = (line.lstrip(" ").rstrip("\n").split(" "))
            #dl = [float(x) for x in dl]
            dinp = dl[2:]
            dinp.append(setNeMoLabel({"MPI Rank ID": int(dl[1])}))
            data = [int(dl[0]), int(dl[1])] + dinp + [filename]
            outdata = ",".join([str(x) for x in data]) + "\n"
            outdata.replace("'","")
           #outdata = outdata.encode()
            outF.write(outdata)
        outF.seek(0)
        parsed = pd.read_csv(outF,sep=",",index_col=1)
    assert isinstance(parsed, pd.DataFrame)
    return parsed


def readFile(filename):
    return readFilePD(filename)
    #keyv = ["MPI Rank ID"]
    data = []
    keys = []
    #runname = ""
    with open(filename, 'r') as f:
        fullData = f.readlines()
    #    runname = f.name
    fullData = fullData[1:]
    for line in fullData:
        dl = (line.lstrip(" ").rstrip("\n").split(" "))
        dl = [float(x) for x in dl]
        dinp = dl[2:]
        dinp.append(setNeMoLabel({"MPI Rank ID": int(dl[1])}))
        data.append([int(dl[0]), int(dl[1])] + dinp + [filename])
        keys.append(int(dl[1]))

    parsedData = pd.DataFrame(data=data, columns=formatc, index=keys)
    # parsedData["Run Type"] = parsedData.apply(lambda x: setNeMoLabel(x), axis=1)
    return parsedData


# Format <LP ID> <MPI Rank ID> <Total sends> <Total Recvs> <Bytes sent>
# <Bytes recvd> <Send time> <Comm. time> <Compute time> <Job ID>

def getMean(metricData, met):
    return metricData[met].mean()


def getMax(metricData, met):
    return metricData[met].max()


def getMin(metricData, met):
    return metricData[met].min()


def getSum(metricData, met):
    return metricData[met].sum()


def getMetric(dd, metric, name, traceType=0):
    metricData = dd
    if traceType != 0:
        metricData = dd[(dd["Run Type"] == traceType)]

    # df[(df.A == 1) & (df.D == 6)]
    if metric == "mean":
        return getMean(metricData, name)
    if metric == "max":
        return getMax(metricData, name)
    if metric == "min":
        return getMin(metricData, name)
    return getSum(metricData, name)


def getMetricNemo(dat, metric, name):
    mets = []
    for i in [nemolabel, cpulabel]:
        mets.append(getMetric(dat[(dat["Run Type"] == i)], metric, name))
        mets.append(i)
    return mets


def getNeMoMPI(df):
    nmp = df.groupby(0).filter(lambda x: x["MPI Rank ID"] % 2 == 0)
    return nmp


def getNonNeMoMPI(df):
    nmp = df.groupby(0).filter(lambda x: x["MPI Rank ID"] % 2 != 0)
    return nmp


def setNeMoLabel(df):
    if df['MPI Rank ID'] % 2 == 0:
        return cpulabel
    return nemolabel


def parseData(df):
    trans = ["mean", "max", "min", "sum"]
    #types = ["N"]
    results = {}
    results_length = {}
    for m in mets:
        for t in trans:
            results_length[m + " " + t] = getMetricNemo(df, t, m)[0]
            results_length[m + " " + t + " " + "RunType"] = getMetricNemo(df, t, m)[1]
            for l in [nemolabel, cpulabel]:
                results[m + " " + t + " " + l] = getMetric(df, t, m, l)

    return (results, results_length)


def parseDataColumnar(df, dirname):
    trans = ["mean", "max", "min", "sum"]

    ncs = ["Metric", "Mean", "Max", "Min", "Sum", "Rank Type", "Run Name", "Topology", "CPU Trace", "NeMo Workload"]
    cleanNames = nameClean(dirname)
    data = []
    dt1 = []
    for m in mets:
        dt1 = []
        for t in trans:
            for l in [nemolabel, cpulabel]:
                data.append([m + " " + t, getMetric(df, t, m, l), l, dirname])
    data = []
    for l in [nemolabel, cpulabel]:
        for m in mets:
            dt1 = []
            for t in trans:
                dt1.append(getMetric(df, t, m, l))
            data.append([m, dt1[0], dt1[1], dt1[2], dt1[3], l, dirname,  cleanNames[0], cleanNames[1], cleanNames[2]])
    return pd.DataFrame(data=data, columns=ncs)


#def parseDataNoFilter(df, dirname):
#    ncs = ["Metric", "Value", "Rank Type", "Run Name"]
#    data = []


def read(args, run_type):
    fn1 = args
    dat = readFile(fn1)

    results = parseData(dat)
    r2 = parseDataColumnar(dat, run_type)

    return results[0], r2, dat


def readRecursive(root="."):
    rootdir = Path(root)
    # Return a list of regular files only, not directories
    file_list = [f for f in rootdir.glob('**/*') if f.is_file()]
    file_list = [f for f in file_list if "mpi-replay-stats" in f.name]
    print("reading in files:")

    resultMat = []
    resultMat2 = []
    resultMat3 = []
    for f in file_list:
        #print(f.name)
        parts = f.parts
        run_type = parts[0]

        if len(parts) > 2:
            run_type = " ".join(parts[0:2])
        else:
            result0, result1, dat = read(f.as_posix(), run_type)

            result0['run_type'] = run_type

            resultMat.append(result0)
            resultMat2.append(result1)
            resultMat3.append(dat)

    return (pd.DataFrame(resultMat), pd.concat(resultMat2), pd.DataFrame(dat))

def plotter(non_col, col):
    p = ggplot(noncol, aes("Run Name", "Mean", color="Rank Type"))
    p + geom_point(color='steelblue') + \
        facet_wrap("Metric")
    return (p)


def plotterPolarBar(non_col):
    #Create figure for visualization
    #fig, ax = plt.subplots(figsize=(5.2, 4))
    # Compute pie slices
    N = 4
    theta = np.linspace((2.0*np.pi/N)/2.0, 2.0 * np.pi, N, endpoint=False)
    radii = np.array(range(1,N+1))
    width = 2.0*np.pi / N

    fig = plt.figure(figsize=(5.2,4))
    ax = fig.add_subplot(111, projection='polar')
    bars = ax.bar(theta, radii, width=width, bottom=0.0)

    # Use custom colors and opacity
    for r, bar in zip(radii, bars):
        bar.set_facecolor(plt.cm.viridis(r / 24.))
        bar.set_alpha(0.5)

    #plt.show()
    fig.savefig('test.pdf', dpi=320, facecolor='w',
                edgecolor='w', orientation='portrait', papertype=None,
                format=None, transparent=False, bbox_inches=None,
                pad_inches=0.25, frameon=None)


# Function gets the values for all runs including the base runs
def getPlotterValues(non_col, cpuTrace, topology, neuro, collector, metric, stat):
    listSize = len(cpuTrace)*len(neuro)*len(collector)
    data = [[0 for j in range(listSize)] for i in range(len(topology))]
    label = [[0 for j in range(listSize)] for i in range(len(topology))]
    for t in range(len(topology)):
        for cpu in range(len(cpuTrace)):
            for n in range(len(neuro)):
                for col in range(len(collector)):
                    j = cpu*len(neuro)*len(collector)+n*len(collector)+col
                    cpuTraceInstance = cpuTrace[cpu]
                    neuroInstance = neuro[n]
                    if collector[col] == "Trace":
                        if neuroInstance == "none":
                            label[t][j] = cpuTrace[cpu]+"\nBase"
                        else:
                            label[t][j] = cpuTrace[cpu]
                    else:
                        if neuroInstance == "none":
                            label[t][j] = neuro[n+1]+"\nBase"
                            neuroInstance = neuro[n+1]
                            cpuTraceInstance = "none"
                        else:
                            label[t][j] = neuroInstance
                    temp = non_col[non_col['Topology'].str.contains(topology[t])]
                    temp = temp[temp['CPU Trace'] == cpuTraceInstance]
                    temp = temp[temp['NeMo Workload'].str.contains(neuroInstance)]
                    temp = temp[temp['Rank Type'].str.contains(collector[col])]
                    temp = temp[temp['Metric'].str.contains(metric)]
                    data[t][j] = float(temp.loc[:,stat])
    return data, label


# Function gets the values for the metrics for only multi-job runs as a percentage of the base run
def getPlotterPercents(non_col, cpuTrace, topology, neuro, collector, metric, stat):
    pdb.set_trace()
    listSize = len(cpuTrace)*len(neuro)*len(collector)
    data = [[0 for j in range(listSize)] for i in range(len(topology))]
    label = [[0 for j in range(listSize)] for i in range(len(topology))]
    for t in range(len(topology)):
        for cpu in range(len(cpuTrace)):
            for n in range(len(neuro)):
                for col in range(len(collector)):
                    j = cpu*len(neuro)*len(collector)+n*len(collector)+col
                    cpuTraceInstance = cpuTrace[cpu]
                    neuroInstance = neuro[n]
                    temp = non_col[non_col['Topology'].str.contains(topology[t])]
                    temp = temp[temp['Rank Type'].str.contains(collector[col])]
                    temp = temp[temp['Metric'].str.contains(metric)]
                    if collector[col] == "Trace":
                        label[t][j] = cpuTrace[cpu]
                        temp = temp[temp['CPU Trace'] == cpuTraceInstance]
                        base = temp[temp['NeMo Workload'].str.contains('none')]
                        numerator = temp[temp['NeMo Workload'] == neuroInstance]
                    else:
                        label[t][j] = neuroInstance
                        temp = temp[temp['NeMo Workload'] == neuroInstance]
                        base = temp[temp['CPU Trace'].str.contains('none')]
                        numerator = temp[temp['CPU Trace'] == cpuTraceInstance]
                    data[t][j] = (float(numerator.loc[:,stat]) - float(base.loc[:,stat]))/float(base.loc[:,stat]) * 100.0
    return data, label


# Attach a text label above each bar displaying its height
def plotterBarAddHeightsLabels(ax, rects):
    for rect in rects:
        height = rect.get_height()
        ax.text(rect.get_x() + rect.get_width()/2., 1.05*height,
                '%d' % int(height), ha='center', va='bottom')

def plotterBar(non_col):
    cpuTrace = ["AMG" "MG"]
    #cpuTrace = ["AMG", "MG", "CR"]
    #cpuTrace = ["AMG"]
    neuro = ["none", "HF"]
    topology = ["Slim Fly", "Dragonfly", "Fat-Tree"]
    collector = ["Trace", "NeMo"]     #Which workload the row is collected for
    metric = "End Time"            #Options: Bytes Sent, Bytes Recvd, Total Sends, Total Recvs, End Time
    stat = "Max"                   #Statistical measure over terminals. Options: Min, Max, Mean, Sum

    #Making call for values
    data, label = getPlotterValues(non_col, cpuTrace, topology, neuro, collector, metric, stat)
    #Making call for Percentages
    data, label = getPlotterPercents(non_col, cpuTrace, topology, [neuro[1]], collector, metric, stat)

    ind = np.arange(0,len(data[0])*1.8,1.8)  # the x locations for the groups
    width = 0.35       # the width of the bars

    fig, ax = plt.subplots(figsize=(7.2, 4))
    rects1 = ax.bar(ind, data[0], width, color='#ffb3ba', edgecolor = ['r' for u in range(len(data[0]))], hatch="////", lw=0.8)

    rects2 = ax.bar(ind + width+0.1, data[1], width, color='#baffc9', edgecolor = ['g' for u in range(len(data[1]))], hatch="\\\\", lw=0.8)

    rects3 = ax.bar(ind +(width+0.1)*2, data[2], width, color='#bae1ff', edgecolor = ['b' for u in range(len(data[2]))], hatch="", lw=0.8)

    # add some text for labels, title and axes ticks
    if metric == "End Time":
        ax.set_ylabel("Slowdown (result-base)/base")
    else:
        ax.set_ylabel(metric)
    #ax.set_title('')
    ax.set_xticks(ind + width / 2)
    ax.set_xticklabels(label[0])
    formatter = FuncFormatter(lambda y, pos: "%d%%" % (y))
    ax.yaxis.set_major_formatter(formatter)

    plotterBarAddHeightsLabels(ax, rects1)
    plotterBarAddHeightsLabels(ax, rects2)
    plotterBarAddHeightsLabels(ax, rects3)

    ax.legend((rects1[0], rects2[0], rects3[0]), (topology))

    #plt.show()
    fig.savefig('test.pdf', dpi=320, facecolor='w',
                edgecolor='w', orientation='portrait', papertype=None,
                format=None, transparent=False, bbox_inches=None,
                pad_inches=0.25, frameon=None)


def nameClean(dat):
    #### Translations ####
    runName = {"ftree":"Fat-Tree","dfly":"Dragonfly", "sfly": "Slim Fly"}
    #routeType={"adaptive":"Adaptive", "static":"Static", "minimal":"Minimal"}
    neuroWorkload = {"hf":"HF", "ff":"Feed Forward"}
    synthWorkload = {"cr1k":"CR", "amg1k": "AMG", "mg1k" : "MG" }
    rtv = dat.split("-")
    rn = []
    rn.append(runName[rtv[0]])
    if len(rtv) == 7:
        rn.append(synthWorkload[rtv[6]])
        rn.append("none")
    elif len(rtv) == 12:
        rn.append("none")
        rn.append(neuroWorkload[rtv[6]])
    elif len(rtv) == 14:
        rn.append(synthWorkload[rtv[6]])
        rn.append(neuroWorkload[rtv[8]])
    return rn
#dfly-trace-amg1k-1ms-n3456-adaptive-1csfbkgnd-10mintvl-1000000tintvl-3456ranks-10000mpt


if __name__ == '__main__':
    arguments = docopt(__doc__)
    if (arguments['single']):
        columnar, noncol = read(arguments["<filename>"])
    # elif (arguments['test']):
    # 	# testit
    # 	fn1 = "dfly-trace-amg1k-1ms-n3456-adaptive-1csfbkgnd-10mintvl-1000000tintvl-3456ranks-10000mpt/mpi-replay-stats"
    # 	dat = readFile(fn1)
    # 	results = parseData(dat)
    # 	print(results)
    elif (arguments['drill']):
        if(arguments['--dstart']):
            os.chdir(os.getcwd() + "/" + arguments["--dstart"])
            #colummar, noncol, opdat = readRecursive(arguments['<dir>'])

        colummar, noncol, opdat = readRecursive()

    # if(arguments['--plot']):
    # 	print("plotting")
    # 	sns.set(style="whitedgrid")

    # colummar['run_type'] = colummar.apply(lambda x: nameClean(x, "run_type"), axis=1)
    # noncol['Run Name'] = noncol.apply(lambda x: nameClean(x), axis=1)
    # opdat['Run Name'] = opdat.apply(lambda x: nameClean(x), axis=1)
    if (arguments['-s']):
        colummar.to_csv("col_data.csv")
        noncol.to_csv("noncol_data.csv")
        opdat.to_csv("op_dat.csv")

    if(arguments['--plot']):
        plotterBar(noncol)
        #p = plotter(noncol, colummar)
        #print(p)


