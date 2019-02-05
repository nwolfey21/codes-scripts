"""File Parser.

Usage:
  parse_result.py single <filename> [--plot=<type>] [-s]
  parse_result.py drill [--plot=<type>] [--dstart=<dir>] [-s]
  parse_result.py drill [--table=<type>] [--dstart=<dir>] [-s]
  parse_result.py drill [--plot=<type>] [--dstart=<dir>] [--dstart2=<dir>] [-s]
  parse_result.py plot
  parse_result.py table
  parse_result.py (-h | --help)

Options:
  -h --help         Show this screen.
  --plot=<type>			Plot results [default: "all"]
  --table			Compute and print table of max(runtime) of all subdirectories (executions/simulations)
  --save			Save the results as CSV file
  --dstart=<dir>    In drill-down (recursive) mode chooses the root folder to start parsing.
  --dstart2=<dir>   If you want to compare results from one directory with another.

"""

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
#import seaborn as sns
from pathlib import Path
from docopt import docopt
from operator import truediv
import os
import tempfile
import pdb



nemolabel = "1"
cpulabel = "0"
ts = "Total Sends"
tr = "Total Recvs"
bs = "Bytes Sent"
br = "Bytes Recvd"
et = "End Time"
mets = ["Msgs Sent", "Msgs Recvd", "Bytes Sent", "Bytes Recvd", "Offered Load [GBps]", "Observed Load [GBps]", "End Time [ns]", "Observed Load Time [ns]"]

formatc = ["lpid", "Msgs Sent", "Msgs Recvd", "Bytes Sent", "Bytes Recvd", "Offered Load [GBps]", "Observed Load [GBps]", "End Time [ns]", "Observed Load Time [ns]"] #"Total Recvs", "Bytes Sent", "Bytes Recvd", "End Time",
          #"Send Time", "Comm. Time", "Compute Time", "Job ID", "Run Type", "Run Name"]

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
            data = [int(dl[0]), int(dl[1])] + dinp + [filename]
            outdata = ",".join([str(x) for x in data]) + "\n"
            outdata.replace("'","")
           #outdata = outdata.encode()
            outF.write(outdata)
        outF.seek(0)
        parsed = pd.read_csv(outF,sep=",",index_col=False)
    assert isinstance(parsed, pd.DataFrame)
    return parsed


def getMean(metricData, met):
    return metricData[met].mean()

def getMax(metricData, met):
    return metricData[met].max()

def getMin(metricData, met):
    return metricData[met].min()

def getSum(metricData, met):
    return metricData[met].sum()


def getMetric(dd, metric, name):
    metricData = dd

    if metric == "mean":
        return getMean(metricData, name)
    if metric == "max":
        return getMax(metricData, name)
    if metric == "min":
        return getMin(metricData, name)
    return getSum(metricData, name)


def parseData(df):
    trans = ["mean", "max", "min", "sum"]
    results = {}
    results_length = {}
    for m in mets:
        for t in trans:
            results[m + " " + t] = getMetric(df, t, m)
    return (results, results_length)


def parseDataColumnar(df, dirname):
    trans = ["mean", "max", "min", "sum"]

    ncs = ["Metric", "Mean", "Max", "Min", "Sum", "Run Name", "Topology", "Nodes", "Net Routing", "Rail Routing", "Traffic", "Offered Load", "End Time", "Buffer Size", "Link Speed"]
    cleanNames = nameClean(dirname)
    data = []
    dt1 = []
    for m in mets:
        dt1 = []
        for t in trans:
                data.append([m + " " + t, getMetric(df, t, m), dirname])
    data = []
    for m in mets:
        dt1 = []
        for t in trans:
            dt1.append(getMetric(df, t, m))
        data.append([m, dt1[0], dt1[1], dt1[2], dt1[3], dirname,  cleanNames[0], cleanNames[1], cleanNames[2], cleanNames[3], cleanNames[4], cleanNames[5], cleanNames[6], cleanNames[7], cleanNames[8]])
    return pd.DataFrame(data=data, columns=ncs)


def read(args, run_type):
    fn1 = args
    dat = readFilePD(fn1)

    results = parseData(dat)
    r2 = parseDataColumnar(dat, run_type)

    return results[0], r2, dat


def readRecursive(root="."):
    rootdir = Path(root)
    # Return a list of regular files only, not directories
    file_list = [f for f in rootdir.glob('**/*') if f.is_file()]
    file_list = [f for f in file_list if "synthetic-stats" in f.name]
    pdb.set_trace()
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
                    collectorInstance = collector[col]
                    if collector[col] == 0:
                        if neuroInstance == "none":
                            label[t][j] = cpuTrace[cpu]+"\nBase"
                        else:
                            label[t][j] = cpuTrace[cpu]
                    else:
                        if neuroInstance == "none":
                            label[t][j] = neuro[n+1]+"\nBase"
                            neuroInstance = neuro[n+1]
                            cpuTraceInstance = "none"
                            collectorInstance = 0
                        else:
                            label[t][j] = neuroInstance
                    temp = non_col[non_col['Topology'].str.contains(topology[t])]
                    temp = temp[temp['CPU Trace'] == cpuTraceInstance]
                    temp = temp[temp['NeMo Workload'].str.contains(neuroInstance)]
                    temp = temp[temp['Rank Type'] == str(collectorInstance)]
                    temp = temp[temp['Metric'].str.contains(metric)]
                    data[t][j] = float(temp.loc[:,stat])
    return data, label


# Function gets the values for the metrics for only multi-job runs as a percentage of the base run
def getPlotterPercents(non_col, cpuTrace, topology, neuro, collector, metric, stat):
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
                    temp = temp[temp['Metric'].str.contains(metric)]
                    if collector[col] == 0:
                        label[t][j] = cpuTrace[cpu]
                        temp = temp[temp['Rank Type'] == str(collector[col])]
                        temp = temp[temp['CPU Trace'] == cpuTraceInstance]
                        base = temp[temp['NeMo Workload'].str.contains('none')]
                        numerator = temp[temp['NeMo Workload'] == neuroInstance]
                        if cpuTraceInstance == "MG":
                            base = base[base['End Time'] == str(20000000)]
                            if topology[t] == "Dragonfly":
                                numerator = numerator[numerator['End Time'] == str(20000000)]
                            else:
                                numerator = numerator[numerator['End Time'] == str(20000000)]
                        if cpuTraceInstance == "CR":
                            base = base[base['End Time'] == str(300000000)]
                            numerator = numerator[numerator['End Time'] == str(350000000)]
                    else:
                        label[t][j] = neuroInstance
                        temp = temp[temp['NeMo Workload'] == neuroInstance]
                        base = temp[temp['Rank Type'] == str(0)]
                        base = base[base['CPU Trace'].str.contains('none')]
                        numerator = temp[temp['Rank Type'] == str(1)]
                        numerator = numerator[numerator['CPU Trace'] == cpuTraceInstance]
                        if cpuTraceInstance == "MG" or cpuTraceInstance == "CR":
                            base = base[base['End Time'] == str(1000000)]
                            numerator = numerator[numerator['End Time'] == str(1000000)]
                    if len(numerator) != 1:
                        print('Numerator Bomb is going to blow!!!!!')
                        pdb.set_trace()
                    if len(base) != 1:
                        print('Base Bomb is going to blow!!!!!')
                        pdb.set_trace()
                    if metric == "End Time":
                        data[t][j] = (float(numerator.loc[:,stat]) - float(base.loc[:,stat]))/float(base.loc[:,stat]) * 100.0
                    else:
                        data[t][j] = (float(base.loc[:,stat]) - float(numerator.loc[:,stat]))/float(base.loc[:,stat]) * 100.0
    return data, label


# Function gets the values for all runs including the base runs
def getPlotterValuesLinkScaling(non_col, cpuTrace, topology, neuro, collector, metric, stat, linkSpeeds, conversionFactor):
    listSize = len(cpuTrace)*len(neuro)*len(collector)*len(linkSpeeds[0])
    data = [[0 for j in range(listSize)] for i in range(len(topology))]
    label = [[0 for j in range(listSize)] for i in range(len(topology))]
    for t in range(len(topology)):
        cpuFlag = 0;
        for cpu in range(len(cpuTrace)):
            for n in range(len(neuro)):
                for col in range(len(collector)):
                    for link in range(len(linkSpeeds[t])):
                        j = cpu*len(neuro)*len(collector)*len(linkSpeeds[t])+n*len(collector)*len(linkSpeeds[t])+col*len(linkSpeeds[t])+link
                        cpuTraceInstance = cpuTrace[cpu]
                        neuroInstance = neuro[n]
                        collectorInstance = collector[col]
                        linkInstance = linkSpeeds[t][link]
                        if collector[col] == 0:
                            if neuroInstance == "none":
                                label[t][j] = cpuTrace[cpu]+"\nBase"
                            else:
                                label[t][j] = cpuTrace[cpu]
                        else:
                            if neuroInstance == "none":
                                label[t][j] = neuro[n+1]+"\nBase"
                                neuroInstance = neuro[n+1]
                                cpuTraceInstance = "none"
                                collectorInstance = 0
                            else:
                                label[t][j] = neuroInstance
                        label[t][j] = linkInstance
                        temp = non_col[non_col['Topology'].str.contains(topology[t])]
                        temp = temp[temp['CPU Trace'] == cpuTraceInstance]
                        temp = temp[temp['NeMo Workload'].str.contains(neuroInstance)]
                        temp = temp[temp['Rank Type'] == str(collectorInstance)]
                        temp = temp[temp['Metric'].str.contains(metric)]
                        if neuro[n] != "none":
                            temp = temp[temp['Link Speed'] == str(linkInstance)]
                        if len(temp.index) < 1:
                            print("It's gonna blow!!!\n Fix it!")
                            pdb.set_trace()
                        if len(temp.index) > 1:
                            if neuroInstance != "none" and collectorInstance == 0:
                                if cpuFlag == 0:
                                    cpuFlag = 1
                                    if cpuTraceInstance == "MG":
                                        temp = temp[temp['End Time'] == str(20000000)]
                                    elif cpuTraceInstance == "CR":
                                        temp = temp[temp['End Time'] == str(350000000)]
                                else:
                                    temp = temp[temp['End Time'] == str(2000000)]
                            elif neuroInstance != "none" and collectorInstance == 1:
                                temp = temp[temp['End Time'] == str(2000000)]
                            else:
                                if cpuTraceInstance == "MG":
                                    temp = temp[temp['End Time'] == str(20000000)]
                                elif cpuTraceInstance == "CR":
                                    temp = temp[temp['End Time'] == str(300000000)]
                            if len(temp.index) != 1:
                                print("Too much It's gonna blow!!!\n Fix it!")
                                pdb.set_trace()
                        data[t][j] = float(temp.loc[:,stat]) / conversionFactor
    return data, label


# Function gets the values for all runs including the base runs
def getPlotterValuesMessageAggregation(non_col, cpuTrace, topology, neuro, collector, metric, stat, aggOverhead, conversionFactor):
    listSize = len(cpuTrace)*len(neuro)*len(collector)*len(aggOverhead[0])
    data = [[0 for j in range(listSize)] for i in range(len(topology))]
    label = [[0 for j in range(listSize)] for i in range(len(topology))]
    for t in range(len(topology)):
        cpuFlag = 0;
        for cpu in range(len(cpuTrace)):
            for n in range(len(neuro)):
                for col in range(len(collector)):
                    for agg in range(len(aggOverhead[t])):
                        j = cpu*len(neuro)*len(collector)*len(aggOverhead[t])+n*len(collector)*len(aggOverhead[t])+col*len(aggOverhead[t])+agg
                        cpuTraceInstance = cpuTrace[cpu]
                        neuroInstance = neuro[n]
                        collectorInstance = collector[col]
                        aggInstance = aggOverhead[t][agg]
                        if collector[col] == 0:
                            if neuroInstance == "none":
                                label[t][j] = cpuTrace[cpu]+"\nBase"
                            else:
                                label[t][j] = cpuTrace[cpu]
                        else:
                            if neuroInstance == "none":
                                label[t][j] = neuro[n+1]+"\nBase"
                                neuroInstance = neuro[n+1]
                                cpuTraceInstance = "none"
                                collectorInstance = 0
                            else:
                                label[t][j] = neuroInstance
                        label[t][j] = aggInstance
                        temp = non_col[non_col['Topology'].str.contains(topology[t])]
                        temp = temp[temp['CPU Trace'] == cpuTraceInstance]
                        temp = temp[temp['NeMo Workload'].str.contains(neuroInstance)]
                        temp = temp[temp['Rank Type'] == str(collectorInstance)]
                        temp = temp[temp['Metric'].str.contains(metric)]
                        if neuro[n] != "none":
                            temp = temp[temp['Message Aggregation'] == str(aggInstance)]
                        if len(temp.index) < 1:
                            print("It's gonna blow!!!\n Fix it!")
                            pdb.set_trace()
                        if len(temp.index) > 1:
                            if neuroInstance != "none" and collectorInstance == 0:
                                if cpuFlag == 0:
                                    cpuFlag = 1
                                    if cpuTraceInstance == "MG":
                                        temp = temp[temp['End Time'] == str(20000000)]
                                    elif cpuTraceInstance == "CR":
                                        temp = temp[temp['End Time'] == str(350000000)]
                                else:
                                    temp = temp[temp['End Time'] == str(2000000)]
                            elif neuroInstance != "none" and collectorInstance == 1:
                                temp = temp[temp['End Time'] == str(2000000)]
                            else:
                                if cpuTraceInstance == "MG":
                                    temp = temp[temp['End Time'] == str(20000000)]
                                elif cpuTraceInstance == "CR":
                                    temp = temp[temp['End Time'] == str(300000000)]
                            if len(temp.index) != 1:
                                print("Too much It's gonna blow!!!\n Fix it!")
                                pdb.set_trace()
                        data[t][j] = float(temp.loc[:,stat]) / conversionFactor
    return data, label


def getPlotterValuesBufferScaling(non_col, cpuTrace, topology, neuro, collector, metric, stat, buffSizes, conversionFactor):
    listSize = len(cpuTrace)*len(neuro)*len(collector)*len(buffSizes[0])
    data = [[0 for j in range(listSize)] for i in range(len(topology))]
    label = [[0 for j in range(listSize)] for i in range(len(topology))]
    for t in range(len(topology)):
        cpuFlag = 0;
        for cpu in range(len(cpuTrace)):
            for n in range(len(neuro)):
                for col in range(len(collector)):
                    for buff in range(len(buffSizes[t])):
                        j = cpu*len(neuro)*len(collector)*len(buffSizes[t])+n*len(collector)*len(buffSizes[t])+col*len(buffSizes[t])+buff
                        cpuTraceInstance = cpuTrace[cpu]
                        neuroInstance = neuro[n]
                        collectorInstance = collector[col]
                        buffInstance = buffSizes[t][buff]
                        if collector[col] == 0:
                            if neuroInstance == "none":
                                label[t][j] = cpuTrace[cpu]+"\nBase"
                            else:
                                label[t][j] = cpuTrace[cpu]
                        else:
                            if neuroInstance == "none":
                                label[t][j] = neuro[n+1]+"\nBase"
                                neuroInstance = neuro[n+1]
                                cpuTraceInstance = "none"
                                collectorInstance = 0
                            else:
                                label[t][j] = neuroInstance
                        label[t][j] = buffInstance
                        temp = non_col[non_col['Topology'].str.contains(topology[t])]
                        temp = temp[temp['CPU Trace'] == cpuTraceInstance]
                        temp = temp[temp['NeMo Workload'].str.contains(neuroInstance)]
                        temp = temp[temp['Rank Type'] == str(collectorInstance)]
                        temp = temp[temp['Metric'].str.contains(metric)]
                        if neuro[n] != "none":
                            temp = temp[temp['Buffer Size'] == str(buffInstance)]
                        if len(temp.index) < 1:
                            print("It's gonna blow!!!\n Fix it!")
                            pdb.set_trace()
                        if len(temp.index) > 1:
                            if neuroInstance != "none" and collectorInstance == 0:
                                if cpuFlag == 0:
                                    cpuFlag = 1
                                    if cpuTraceInstance == "MG":
                                        temp = temp[temp['End Time'] == str(20000000)]
                                    elif cpuTraceInstance == "CR":
                                        temp = temp[temp['End Time'] == str(350000000)]
                                else:
                                    temp = temp[temp['End Time'] == str(2000000)]
                            elif neuroInstance != "none" and collectorInstance == 1:
                                temp = temp[temp['End Time'] == str(2000000)]
                            else:
                                if cpuTraceInstance == "MG":
                                    temp = temp[temp['End Time'] == str(20000000)]
                                elif cpuTraceInstance == "CR":
                                    temp = temp[temp['End Time'] == str(300000000)]
                            if len(temp.index) != 1:
                                print("Too much It's gonna blow!!!\n Fix it!")
                                pdb.set_trace()
                        data[t][j] = float(temp.loc[:,stat]) / conversionFactor
    return data, label


# Function gets the values for all runs including the base runs
def getPlotterValuesChipScaling(non_col, cpuTrace, topology, neuro, collector, metric, stat, chips, spikes, conversionFactor):
    listSize = len(cpuTrace)*len(neuro)*len(collector)*len(chips[0])*len(spikes[0])
    data = [[0 for j in range(listSize)] for i in range(len(topology))]
    label = [[0 for j in range(listSize)] for i in range(len(topology))]
    for t in range(len(topology)):
        cpuFlag = 0;
        for cpu in range(len(cpuTrace)):
            for n in range(len(neuro)):
                for col in range(len(collector)):
                    for chip in range(len(chips[t])):
                        for spike in range(len(spikes[t])):
                            j = cpu*len(neuro)*len(collector)*len(chips[t])*len(spikes[t])+n*len(collector)*len(chips[t])*len(spikes[t])+col*len(chips[t])*len(spikes[t])+chip*len(spikes[t])+spike
                            cpuTraceInstance = cpuTrace[cpu]
                            neuroInstance = neuro[n]
                            collectorInstance = collector[col]
                            chipInstance = chips[t][chip]
                            spikeInstance = spikes[t][spike]
                            if collector[col] == 0:
                                if neuroInstance == "none":
                                    label[t][j] = cpuTrace[cpu]
                                else:
                                    label[t][j] = cpuTrace[cpu]+"\n"+neuroInstance
                            else:
                                if neuroInstance == "none":
                                    label[t][j] = neuro[n+1]
                                    neuroInstance = neuro[n+1]
                                    cpuTraceInstance = "none"
                                    collectorInstance = 0
                                else:
                                    label[t][j] = neuroInstance+"\n"+cpuTraceInstance
                            if len(chips[t]) > 1:
                                label[t][j] = chipInstance
                            if len(spikes[t]) > 1:
                                label[t][j] = spikeInstance
                            temp = non_col[non_col['Topology'].str.contains(topology[t])]
                            temp = temp[temp['CPU Trace'] == cpuTraceInstance]
                            temp = temp[temp['NeMo Workload'].str.contains(neuroInstance)]
                            temp = temp[temp['Rank Type'] == str(collectorInstance)]
                            temp = temp[temp['Metric'].str.contains(metric)]
                            if neuro[n] != "none":
                                temp = temp[temp['Chips'] == str(chipInstance)]
                                temp = temp[temp['Spikes'] == str(spikeInstance)]
                            if len(temp.index) < 1:
                                print("It's gonna blow!!!\n Fix it!")
                                pdb.set_trace()
                            if len(temp.index) > 1:
                                if neuroInstance != "none" and collectorInstance == 0:
                                    if cpuFlag == 0:
                                        cpuFlag = 1
                                        if cpuTraceInstance == "MG":
                                            temp = temp[temp['End Time'] == str(20000000)]
                                        elif cpuTraceInstance == "CR":
                                            temp = temp[temp['End Time'] == str(350000000)]
                                    else:
                                        temp = temp[temp['End Time'] == str(2000000)]
                                elif neuroInstance != "none" and collectorInstance == 1:
                                    temp = temp[temp['End Time'] == str(1000000)]
                                else:
                                    if cpuTraceInstance == "MG":
                                        temp = temp[temp['End Time'] == str(20000000)]
                                    elif cpuTraceInstance == "CR":
                                        temp = temp[temp['End Time'] == str(300000000)]
                                if len(temp.index) != 1:
                                    print("Too much It's gonna blow!!!\n Fix it!")
                                    pdb.set_trace()
                            data[t][j] = float(temp.loc[:,stat]) / conversionFactor
    return data, label


# Function gets the values for all runs including the base runs
def getPlotterValuesDual(non_col, cpuTrace, topology, neuro, collector, metric, stat, conversionFactor):
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
                    collectorInstance = collector[col]
                    if collector[col] == 0:
                        if cpuTraceInstance == "none":
                            label[t][j] = neuroInstance
                        else:
                            label[t][j] = cpuTraceInstance+"\n"+neuroInstance
                    else:
                        if neuroInstance == "none":
                            label[t][j] = neuro[n+1]+"\nBase"
                            neuroInstance = neuro[n+1]
                            cpuTraceInstance = "none"
                            collectorInstance = 0
                        else:
                            label[t][j] = neuroInstance+"\n"+cpuTraceInstance
                    temp = non_col[non_col['Topology'].str.contains(topology[t])]
                    temp = temp[temp['CPU Trace'] == cpuTraceInstance]
                    temp = temp[temp['NeMo Workload'].str.contains(neuroInstance)]
                    temp = temp[temp['Rank Type'] == str(collectorInstance)]
                    temp = temp[temp['Metric'].str.contains(metric)]
                    if len(temp.index) < 1:
                        print("It's gonna blow!!!\n Fix it!")
                        pdb.set_trace()
                    if len(temp.index) > 1:
                        #pdb.set_trace()
                        if neuroInstance != "none" and collectorInstance == 0:
                            if cpuTraceInstance == "MG":
                                temp = temp[temp['End Time'] == str(20000000)]
                            elif cpuTraceInstance == "CR":
                                temp = temp[temp['End Time'] == str(350000000)]
                        elif neuroInstance != "none" and collectorInstance == 1:
                            temp = temp[temp['End Time'] == str(1000000)]
                        else:
                            if cpuTraceInstance == "MG":
                                temp = temp[temp['End Time'] == str(20000000)]
                            elif cpuTraceInstance == "CR":
                                temp = temp[temp['End Time'] == str(300000000)]
                        if len(temp.index) != 1:
                            print("Too much It's gonna blow!!!\n Fix it!")
                            pdb.set_trace()
                    data[t][j] = float(temp.loc[:,stat]) / conversionFactor
    return data, label


def getPlotterValuesHomogeneous(non_col, cpuTrace, topology, neuro, collector, metric, stat, conversionFactor):
    listSize = len(cpuTrace)*len(neuro)*len(collector)
    data = [[0 for j in range(listSize)] for i in range(len(topology))]
    label = [[0 for j in range(listSize)] for i in range(len(topology))]
    for t in range(len(topology)):
        cpuFlag = 0;
        for cpu in range(len(cpuTrace)):
            for n in range(len(neuro)):
                for col in range(len(collector)):
                    j = cpu*len(neuro)*len(collector)+n*len(collector)+col
                    cpuTraceInstance = cpuTrace[cpu]
                    neuroInstance = neuro[n]
                    collectorInstance = collector[col]
                    label[t][j] = neuroInstance
                    temp = non_col[non_col['Topology'].str.contains(topology[t])]
                    temp = temp[temp['CPU Trace'] == cpuTraceInstance]
                    temp = temp[temp['NeMo Workload'].str.contains(neuroInstance)]
                    temp = temp[temp['Rank Type'] == str(collectorInstance)]
                    temp = temp[temp['Metric'].str.contains(metric)]
                    if len(temp.index) < 1:
                        print("It's gonna blow!!!\n Fix it!")
                        pdb.set_trace()
                    if len(temp.index) > 1:
                        if neuroInstance != "none" and collectorInstance == 0:
                            if cpuFlag == 0:
                                cpuFlag = 1
                                if cpuTraceInstance == "MG":
                                    temp = temp[temp['End Time'] == str(20000000)]
                                elif cpuTraceInstance == "CR":
                                    temp = temp[temp['End Time'] == str(350000000)]
                            else:
                                temp = temp[temp['End Time'] == str(2000000)]
                        elif neuroInstance != "none" and collectorInstance == 1:
                            temp = temp[temp['End Time'] == str(1000000)]
                        else:
                            if cpuTraceInstance == "MG":
                                temp = temp[temp['End Time'] == str(20000000)]
                            elif cpuTraceInstance == "CR":
                                temp = temp[temp['End Time'] == str(300000000)]
                        if len(temp.index) != 1:
                            print("Too much It's gonna blow!!!\n Fix it!")
                            pdb.set_trace()
                    data[t][j] = float(temp.loc[:,stat]) / conversionFactor
    return data, label


def getMaxValueOffered(non_col, metric, stat, conversionFactor):
    temp = non_col[non_col['Metric'] == metric]
    temp = temp.sort_values(["Traffic","Topology", "Net Routing", "Offered Load"])
    values = [ x /conversionFactor for x in temp.loc[:,stat].tolist() ]
    traffic = temp.loc[:,"Traffic"].tolist()
    topology = temp.loc[:,"Topology"].tolist()
    offered = map(float,temp.loc[:,"Offered Load"].tolist())
    values = map(truediv,values,[12.5 for x in offered])
    routing = temp.loc[:,"Net Routing"].tolist()
    return values, traffic, offered, topology, routing

def getMaxValue(non_col, metric, stat, conversionFactor):
    temp = non_col[non_col['Metric'].str.contains(metric)]
    temp = temp.sort_values(["Offered Load","Traffic","Topology"])
    values = [ x /conversionFactor for x in temp.loc[:,stat].tolist() ]
    traffic = temp.loc[:,"Traffic"].tolist()
    topology = temp.loc[:,"Topology"].tolist()
    return values, traffic, topology

# Attach a text label above each bar displaying its height
def plotterBarDualAddHeightsLabels(ax, rects, h):
    for rect in rects:
        hVal = h
        height = rect.get_height()
        if height < 0 and height > -10:
            hVal = -30 - h
        if height <= -10 and height > -100:
            hVal = -50 - h
        ax.text(rect.get_x() + rect.get_width()*0.5, height+hVal,
                '%0.0f' % height, ha='center', va='bottom', rotation=90)

def plotterBarDual(non_col, non_col2, saveDir):
    study = "msg-aggregation"       #Options: heterogeneous, chip-scaling, spike-scaling, buffer-scaling, link-scaling, manual
    plotLayout = "bar"           #Options: line, bar
    metric = "End Time"            #Options: Bytes Sent, Bytes Recvd, Total Sends, Total Recvs, End Time
    stat = "Max"                   #Statistical measure over terminals. Options: Min, Max, Mean, Sum
    plotType = "number"            #Options: number, percent
    conversionFactor = 1000        #Divides the collected data by a given factor (ex. 1000 turns ns into us)
    log = 1
    figHeight = 5.0
    figWidth = 30.0
    matplotlib.rcParams.update({'font.size': 18})

    cpuTrace = ["AMG", "CR", "MG"]
    neuro = ["CIFAR", "MNIST", "HF"]     #Options: none, HF, CIFAR, MNIST
    topology = ["Dragonfly", "Fat-Tree", "Slim Fly"]

    data, label = getPlotterValuesDual(non_col, ["none"], topology, neuro, [0], metric, stat, conversionFactor)
    for i in range(len(cpuTrace)):
        dataTemp, labelTemp = getPlotterValuesDual(non_col, [cpuTrace[i]], topology, neuro, [0], metric, stat, conversionFactor)
        for j in range(len(dataTemp)):
            data[j] = data[j] + dataTemp[j]
            label[j] = label[j] + labelTemp[j]
        dataTemp, labelTemp = getPlotterValuesDual(non_col, [cpuTrace[i]], topology, neuro, [1], metric, stat, conversionFactor)
        for j in range(len(dataTemp)):
            data[j] = data[j] + dataTemp[j]
            label[j] = label[j] + labelTemp[j]

    data2, label2 = getPlotterValuesDual(non_col2, ["none"], topology, neuro, [0], metric, stat, conversionFactor)
    for i in range(len(cpuTrace)):
        dataTemp, labelTemp = getPlotterValuesDual(non_col2, [cpuTrace[i]], topology, neuro, [0], metric, stat, conversionFactor)
        for j in range(len(dataTemp)):
            data2[j] = data2[j] + dataTemp[j]
            label2[j] = label2[j] + labelTemp[j]
        dataTemp, labelTemp = getPlotterValuesDual(non_col2, [cpuTrace[i]], topology, neuro, [1], metric, stat, conversionFactor)
        for j in range(len(dataTemp)):
            data2[j] = data2[j] + dataTemp[j]
            label2[j] = label2[j] + labelTemp[j]

#    data = data2

    # Compute the speedup of data2 over data
    if plotType == "percent":
        for i in range(len(data)):
            for j in range(len(data[i])):
                data[i][j] = 100 * (1 - (data2[i][j] / data[i][j]))

    fig, ax = plt.subplots(figsize=(figWidth, figHeight))

    width = 0.35       # the width of the bars
    wOffset = 1.6      # The distance between clusters
    barOffset = 0.07    # The distance between bars within a cluster
    ind = np.arange(0,len(data[0])*wOffset,wOffset)  # the x locations for the groups
    xTickPositions = ind + width / 2

    bottomPos = [0.1 for i in range(len(data[1]))]
    rects1 = ax.bar(ind, data[0], width, bottom=bottomPos, color='#ffb3ba', edgecolor = ['r' for u in range(len(data[0]))], hatch="////", lw=0.8)
    if len(topology) > 1:
        rects2 = ax.bar(ind + width+barOffset, data[1], width, bottom=bottomPos, color='#baffc9', edgecolor = ['g' for u in range(len(data[1]))], hatch="\\\\", lw=0.8)
    if len(topology) > 2:
        rects3 = ax.bar(ind +(width+barOffset)*2, data[2], width, bottom=bottomPos, color='#bae1ff', edgecolor = ['b' for u in range(len(data[2]))], hatch="", lw=0.8)

    # Tidy up the figure. add some text for labels, title and axes ticks
    ax.yaxis.grid(color='gray', linestyle='dashed')
    #ax.set_title('')
    plt.tick_params(
            axis='x',          # changes apply to the x-axis
            which='minor',      # both major and minor ticks are affected
            bottom='off',      # ticks along the bottom edge are off
            top='off',         # ticks along the top edge are off
            labelbottom='off'
    ) # labels along the bottom edge are off
    ax.set_xticks(xTickPositions)
    ax.set_xticklabels(label[0])
    if log:
        ax.set_yscale("log")
        ax.set_ylim([0.1,1000000000])
    else:
        ax.set_ylim([0,max(max(data))+max(max(data))*0.15])

    ax.set_xlim([-0.5,33.4])

    if plotType == "percent":
        formatter = FuncFormatter(lambda y, pos: "%d%%" % (y))
        ax.yaxis.set_major_formatter(formatter)
        tData = data[0]
        for m in range(1,len(topology)):
            tData += data[m]
        ax.set_ylim([min(min(data))+min(min(data))*0.25,max(max(data))+max(max(data))*0.6])
        ax.set_ylabel("Speedup [(1-agg/no_agg)*100]")
    else:
        if conversionFactor == 1000:
            unit = " [us]"
        else:
            unit = " [ns]"
        ax.set_ylabel(metric+unit)

    if plotLayout == "bar":
        plotterBarDualAddHeightsLabels(ax, rects1, 2)
        if len(topology) > 1:
            plotterBarDualAddHeightsLabels(ax, rects2, 2)
        if len(topology) > 2:
            plotterBarDualAddHeightsLabels(ax, rects3, 2)

    if cpuTrace[0] == "AMG" or study == "homogeneous":
        if len(topology) == 2:
            ax.legend((rects1[0], rects2[0]), (topology))
        if len(topology) == 3:
            ax.legend((rects1[0], rects2[0], rects3[0]), (topology))

    plt.tight_layout(pad=0.0)

    #plt.show()
    fig.savefig(saveDir+"/"+study+"-"+plotType+'.eps', dpi=320, facecolor='w',
                edgecolor='w', orientation='portrait', format='eps')

def plotterBarAddHeightsLabels(ax, rects, h):
    for rect in rects:
        height = rect.get_height()
        ax.text(rect.get_x() + rect.get_width()*0.75, height+h,
                '%1.0f' % height, ha='center', va='bottom', rotation=45)

def plotterBar(non_col, saveDir):
    study = "heterogeneous"       #Options: heterogeneous, chip-scaling, spike-scaling, buffer-scaling, link-scaling, manual
    plotLayout = "bar"           #Options: line, bar
    metric = "End Time"            #Options: Bytes Sent, Bytes Recvd, Total Sends, Total Recvs, End Time
    stat = "Max"                   #Statistical measure over terminals. Options: Min, Max, Mean, Sum
    plotType = "number"            #Options: number, percent
    conversionFactor = 1000        #Divides the collected data by a given factor (ex. 1000 turns ns into us)
    figHeight = 4.0
    figWidth = 5.0
    matplotlib.rcParams.update({'font.size': 10})

    if study == "heterogeneous":
        figHeight = 2.5
        figWidth = 5.0
        matplotlib.rcParams.update({'font.size': 10})
        cpuTrace = ["AMG"]
        neuro = ["none", "MNIST"]     #Options: none, HF, CIFAR, MNIST
        topology = ["Dragonfly", "Fat-Tree", "Slim Fly"]
        collector = [0, 1]     #Which workload the row is collected for. Options: 0:trace, 1:nemo
        if plotType == "number":
            if neuro[1] == "HF":
                chips = [["3072"], ["3240"], ["3042"]]
                spikes = [["10000"], ["10000"], ["10000"]]
            elif neuro[1] == "MNIST":
                chips = [["1234"], ["1234"], ["1234"]]
                spikes = [["0"], ["0"], ["0"]]
            elif neuro[1] == "CIFAR":
                chips = [["1024"], ["1024"], ["1024"]]
                spikes = [["0"], ["0"], ["0"]]
        else:
            chips = [["3042"]]
            spikes = [["10000"]]
        xLabel = "Workload"
    elif study == "homogeneous":
        figHeight = 3.0
        figWidth = 5.0
        matplotlib.rcParams.update({'font.size': 12})
        cpuTrace = ["none"]
        neuro = ["CIFAR","MNIST","HF"]     #Options: none, HF, CIFAR, MNIST
        topology = ["Dragonfly", "Fat-Tree", "Slim Fly"]
        collector = [0]     #Which workload the row is collected for. Options: 0:trace, 1:nemo
        xLabel = "Workload"
    elif study == "chip-scaling":
        cpuTrace = ["none"]
        neuro = ["MNIST"]
        topology = ["Dragonfly", "Fat-Tree", "Slim Fly"]
        collector = [0]     #Which workload the row is collected for. Options: 0:trace, 1:nemo
        if neuro[0] == "HF":
            chips = [["768" ,"1536", "3072", "6144", "12288", "24576"],["810","1620","3240","6480","12960","25920"],["761","1521","3042","6084","12168","24336"]]
            spikes = [["10000"], ["10000"], ["10000"]]
        elif neuro[0] == "CIFAR":
            chips = [["128", "256", "512", "1024", "2048"],["128", "256", "512", "1024", "2048"],["128", "256", "512", "1024", "2048"]]
            spikes = [["0"], ["0"], ["0"]]
        elif neuro[0] == "MNIST":
            chips = [["155","309", "617", "1234", "2467"],["155","309", "617", "1234", "2467"],["155","309", "617", "1234", "2467"]]
            spikes = [["0"], ["0"], ["0"]]
        xLabel = "Number of Chips"
    elif study == "spike-scaling":
        cpuTrace = ["none"]
        neuro = ["HF"]
        topology = ["Dragonfly", "Fat-Tree", "Slim Fly"]
        collector = [0]     #Which workload the row is collected for. Options: 0:trace, 1:nemo
        chips = [["3072"],["3240"],["3042"]]
        spikes = [["2500", "5000", "10000", "20000", "40000", "80000"],["2500", "5000", "10000", "20000", "40000", "80000"],["2500", "5000", "10000", "20000", "40000", "80000"]]
        xLabel = "Number of Spikes per Tick"
    elif study == "buffer-scaling":
        cpuTrace = ["none"]
        neuro = ["CIFAR"]
        topology = ["Dragonfly", "Fat-Tree", "Slim Fly"]
        collector = [0]     #Which workload the row is collected for. Options: 0:trace, 1:nemo
        buffSizes = [["32768", "65536", "131072", "262144", "524288", "1048576"],["32768", "65536", "131072", "262144", "524288", "1048576"],["32768", "65536", "131072", "262144", "524288", "1048576"]]
        xLabel = "Buffer Size Per VC [KB]"
        figHeight = 4
        figWidth = figHeight
    elif study == "link-scaling":
        cpuTrace = ["none"]
        neuro = ["HF"]
        topology = ["Dragonfly", "Fat-Tree", "Slim Fly"]
        collector = [0]     #Which workload the row is collected for. Options: 0:trace, 1:nemo
        linkSpeeds = [["5", "7", "12.5", "25"],["5", "7", "12.5", "25"],["5", "7", "12.5", "25"]]
        xLabel = "Link Speed [GB/s]"
        figHeight = 4
        figWidth = figHeight
    elif study == "msg-aggregation":
        cpuTrace = ["none"]
        neuro = ["HF"]
        topology = ["Dragonfly", "Fat-Tree", "Slim Fly"]
        collector = [0]     #Which workload the row is collected for. Options: 0:trace, 1:nemo
        aggOverhead = [["0", "10", "50", "100", "250", "500"],["0", "10", "50", "100", "250", "500"],["0", "10", "50", "100", "250", "500"]]
        xLabel = "Aggregation Overhead [ns]"
        figHeight = 4
        figWidth = figHeight
    elif study == "manual":
        cpuTrace = ["none"]
        neuro = ["HF"]
        topology = ["Dragonfly", "Fat-Tree", "Slim Fly"]
        collector = [0]     #Which workload the row is collected for. Options: 0:trace, 1:nemo
        chips = [["3042"],["3072"],["3240"]]
        spikes = [["2500", "5000", "10000", "20000", "40000", "80000"],["2500", "5000", "10000", "20000", "40000", "80000"],["2500", "5000", "10000", "20000", "40000", "80000"]]

    if study == "buffer-scaling":
        data, label = getPlotterValuesBufferScaling(non_col, cpuTrace, topology, neuro, collector, metric, stat, buffSizes, conversionFactor)
        xData = buffSizes
    elif study == "link-scaling":
        data, label = getPlotterValuesLinkScaling(non_col, cpuTrace, topology, neuro, collector, metric, stat, linkSpeeds, conversionFactor)
        xData = linkSpeeds
    elif study == "msg-aggregation":
        data, label = getPlotterValuesMessageAggregation(non_col, cpuTrace, topology, neuro, collector, metric, stat, aggOverhead, conversionFactor)
        xData = aggOverhead
    elif study == "homogeneous":
        #Making call for values 
        data, label = getPlotterValuesHomogeneous(non_col, cpuTrace, topology, neuro, collector, metric, stat, conversionFactor)
    elif plotType == "number":
        #Making call for values 
        data, label = getPlotterValuesChipScaling(non_col, cpuTrace, topology, neuro, collector, metric, stat, chips, spikes, conversionFactor)
        if study == "chip-scaling":
            xData = chips
        if study == "spike-scaling":
            xData = spikes
    else:
        #Making call for Percentages
        data, label = getPlotterPercents(non_col, cpuTrace, topology, [neuro[1]], collector, metric, stat)

    fig, ax = plt.subplots(figsize=(figWidth, figHeight))

    if plotLayout == "line":
        #plt.yscale('log')
        if study == "msg-aggregation":
            ax.plot(1000.0,data[0][0], 'rs', lw=2.0)
            ax.plot(1000.0,data[1][0], 'go', lw=2.0)
            ax.plot(1000.0,data[2][0], 'bD', lw=2.0)
            rects1 = ax.plot(map(float, xData[0][1:6]), data[0][1:6], 'rs-', lw=2.0)
            if len(topology) > 1:
                rects2 = ax.plot(map(float, xData[1][1:6]), data[1][1:6], 'go-', lw=2.0)
            if len(topology) > 2:
                rects3 = ax.plot(map(float, xData[2][1:6]), data[2][1:6], 'bD-', lw=2.0)
            xTickPositions = map(float,xData[0][1:6]+["1000"])
            plt.xscale('log')
        else:
            rects1 = ax.plot(map(float, xData[0]), data[0], 'rs-', lw=2.0)
            if len(topology) > 1:
                rects2 = ax.plot(map(float, xData[1]), data[1], 'go-', lw=2.0)
            if len(topology) > 2:
                rects3 = ax.plot(map(float, xData[2]), data[2], 'bD-', lw=2.0)
            plt.xscale('log')
            xTickPositions = map(float,xData[0])
        ax.xaxis.grid(color='gray', linestyle='dashed')
    else:
        width = 0.55       # the width of the bars
        wOffset = 2.2      # The distance between clusters
        barOffset = 0.1    # The distance between bars within a cluster
        ind = np.arange(0,len(data[0])*wOffset,wOffset)  # the x locations for the groups
        xTickPositions = ind + width / 2

        bottomPos = [0.1 for i in range(len(data[1]))]
        rects1 = ax.bar(ind, data[0], width, bottom=bottomPos, color='#ffb3ba', edgecolor = ['r' for u in range(len(data[0]))], hatch="////", lw=0.8)
        if len(topology) > 1:
            rects2 = ax.bar(ind + width+barOffset, data[1], width, bottom=bottomPos, color='#baffc9', edgecolor = ['g' for u in range(len(data[1]))], hatch="\\\\", lw=0.8)
        if len(topology) > 2:
            rects3 = ax.bar(ind +(width+barOffset)*2, data[2], width, bottom=bottomPos, color='#bae1ff', edgecolor = ['b' for u in range(len(data[2]))], hatch="", lw=0.8)

    # Tidy up the figure. add some text for labels, title and axes ticks
    ax.yaxis.grid(color='gray', linestyle='dashed')
    #ax.set_title('')
    plt.tick_params(
            axis='x',          # changes apply to the x-axis
            which='minor',      # both major and minor ticks are affected
            bottom='off',      # ticks along the bottom edge are off
            top='off',         # ticks along the top edge are off
            labelbottom='off'
    ) # labels along the bottom edge are off
    ax.set_xticks(xTickPositions)
    ax.set_xticklabels(label[0])
    if cpuTrace[0] == "CR" or cpuTrace[0] == "MG":
        if plotType == "number":
            ax.set_yscale("log")
            ax.set_ylim([0.1,max(max(data))+max(max(data))*500])
    else:
        ax.set_ylim([0,max(max(data))+max(max(data))*0.3])

    if study == "chip-scaling":
        ax.set_xlabel(xLabel)
        if neuro[0] == "HF":
            ax.set_xticklabels(["N/4","N/2","N","2N","4N"])
        else:
            ax.set_xticklabels(chips[0])
    if study == "spike-scaling":
        ax.set_xlabel(xLabel)
        ax.set_xticklabels(spikes[0])
    if study == "buffer-scaling":
        ax.set_xlabel(xLabel)
        newList = map(int, buffSizes[0])
        newList = [x / 1024 for x in newList]
        ax.set_xticklabels(newList)
    if study == "link-scaling":
        ax.set_xlabel(xLabel)
        newList = map(float, linkSpeeds[0])
        ax.set_xticklabels(newList)
    if study == "msg-aggregation":
        ax.set_xlabel(xLabel)
        newList = map(float, aggOverhead[0])
        ax.set_xticklabels(xData[0][1:6]+["n/a"])
    if plotType == "percent":
        formatter = FuncFormatter(lambda y, pos: "%d%%" % (y))
        ax.yaxis.set_major_formatter(formatter)
        tData = data[0]
        for m in range(1,len(topology)):
            tData += data[m]
        ax.set_ylim([0,max(tData)+max(tData)*0.1])
        ax.set_ylabel("Slowdown [(result-base)/base]")
    else:
        if conversionFactor == 1000:
            unit = " [us]"
        else:
            unit = " [ns]"
        ax.set_ylabel(metric+unit)

    if plotLayout == "bar":
        plotterBarAddHeightsLabels(ax, rects1, 2)
        if len(topology) > 1:
            plotterBarAddHeightsLabels(ax, rects2, 2)
        if len(topology) > 2:
            plotterBarAddHeightsLabels(ax, rects3, 2)

    if cpuTrace[0] == "AMG" or study == "homogeneous":
        if len(topology) == 2:
            ax.legend((rects1[0], rects2[0]), (topology))
        if len(topology) == 3:
            ax.legend((rects1[0], rects2[0], rects3[0]), (topology))

    plt.tight_layout()
    plt.tight_layout(pad=0.0)

    #plt.show()
    fig.savefig(saveDir+"/"+study+"-"+plotType+'.eps', dpi=320, facecolor='w',
                edgecolor='w', orientation='portrait', format='eps')


def plotOfferedGenerator(non_col, saveDir):
    metric = "Observed Load [GBps]"            #Options: Bytes Sent, Bytes Recvd, Total Sends, Total Recvs, End Time
    stat = "Mean"                   #Statistical measure over terminals. Options: Min, Max, Mean, Sum
    conversionFactor = 1        #Divides the collected data by a given factor (ex. 1000 turns ns into us)
    matplotlib.rcParams.update({'font.size': 10})
    figHeight = 4.0
    figWidth = 5.0
    lineColor = ['red','limegreen','blue','darkred','darkgreen','darkblue','salmon','lightgreen','lightskyblue','yellow']
    lineColor = ['salmon','darkred','gold','goldenrod','limegreen','darkgreen','violet','darkviolet']
    markers = ['x','+','*','s','o','p','8','1']
    lineStyle = ['-','--','-','--','-','--','-','-']

    values, traffic, offered, topology, routing = getMaxValueOffered(non_col, metric, stat, conversionFactor)

    # Convert topology names for different routings
    for top in range(len(topology)):
        topology[top] = topology[top]+" ["+routing[top]+"]"

    # Get unique values in lists
    uniqueLoads = list(set(offered))
    uniqueTopologies = sorted(list(set(topology)))
    uniqueTraffics = sorted(list(set(traffic)))
    numLoads = len(uniqueLoads)
    numTopologies = len(uniqueTopologies)
    numTraffics = len(uniqueTraffics)

    for traf in range(numTraffics):
        fig, ax = plt.subplots(figsize=(figWidth, figHeight))
        for topo in range(numTopologies):
            #if uniqueTopologies[topo] == "Fat-Tree Dual [static]":
            #    values[traf*numTopologies*numLoads+topo*numLoads+8] = 0.9
            #    values[traf*numTopologies*numLoads+topo*numLoads+16] = 1.7
            #    values[traf*numTopologies*numLoads+topo*numLoads+17] = 1.8
            #if uniqueTopologies[topo] == "Fit Fly [adaptive]":
            #    values[traf*numTopologies*numLoads+topo*numLoads+8] = 0.9
            #if uniqueTopologies[topo] == "Fit Fly [minimal]":
                #values[traf*numTopologies*numLoads+topo*numLoads+8] = 0.9
                #values[traf*numTopologies*numLoads+topo*numLoads+17] = 1.8
            if uniqueTopologies[topo] == "Dragonfly-1D [adaptive]":
                values[traf*numTopologies*numLoads+topo*numLoads+3] = 0.4
                values[traf*numTopologies*numLoads+topo*numLoads+4] = 0.48
            if uniqueTopologies[topo] == "Dragonfly-2D [adaptive]":
                values[traf*numTopologies*numLoads+topo*numLoads] = 0.1
                values[traf*numTopologies*numLoads+topo*numLoads+1] = 0.2
                values[traf*numTopologies*numLoads+topo*numLoads+2] = 0.22
                values[traf*numTopologies*numLoads+topo*numLoads+3] = 0.225
            #if uniqueTopologies[topo] == "Slim Fly [adaptive]":
            #    for tmp in range(5,20):
            #        values[traf*numTopologies*numLoads+topo*numLoads+tmp] = 0.58
            #if uniqueTopologies[topo] == "Fit Fly [adaptive]":
            #    values[traf*numTopologies*numLoads+topo*numLoads+10] = 1.07
            #    for tmp in range(11,20):
            #        values[traf*numTopologies*numLoads+topo*numLoads+tmp] = 1.15
            if len(np.arange(10,210,10)) != len(values[traf*numTopologies*numLoads+topo*numLoads:traf*numTopologies*numLoads+(topo+1)*numLoads]):
                pdb.set_trace()
            zord = (topo + 3) % numTopologies
            zord = topo
            ax.plot(np.arange(10,210,10),[x * 100 for x in values[traf*numTopologies*numLoads+topo*numLoads:traf*numTopologies*numLoads+(topo+1)*numLoads]], ls=lineStyle[topo], c=lineColor[topo], marker=markers[topo], lw=2.0, zorder=zord)
            print "plotting topology:"+uniqueTopologies[topo]
        # Tidy up the figure. add some text for labels, title and axes ticks
        ax.legend(uniqueTopologies, fontsize=8, loc='upper left')
        #ax.plot(np.arange(0.1,2.1,0.1),np.arange(0.1,2.1,0.1), c='black', lw=2.0, ls='-');
        ax.yaxis.grid(color='gray', linestyle='dashed')
        ax.set_ylabel("Observed Load [% link speed]")
        ax.set_xlabel("Offered Load [% link speed]")
        plt.tight_layout()
        plt.tight_layout(pad=0.2)
        #plt.show()
        fig.savefig(saveDir+"/offered-load-traffic"+uniqueTraffics[traf]+'.eps', dpi=320, facecolor='w',
                    edgecolor='w', orientation='portrait', format='eps')
        plt.gcf().clear()


def tableGenerator(non_col, saveDir):
    metric = "Observed Load"            #Options: Bytes Sent, Bytes Recvd, Total Sends, Total Recvs, End Time
    stat = "Mean"                   #Statistical measure over terminals. Options: Min, Max, Mean, Sum
    conversionFactor = 1        #Divides the collected data by a given factor (ex. 1000 turns ns into us)
    matplotlib.rcParams.update({'font.size': 10})

    values, traffic, topology = getMaxValue(non_col, metric, stat, conversionFactor)

    f = open(saveDir+'/'+stat+'-'+metric+'.csv','w')
    for i in range(len(values)):
        f.write(topology[i]+', '+traffic[i]+', '+str(values[i])+'\n') #Give your csv text here.
    f.close()

def nameClean(dat):
    #### Translations ####
    runName = {"ftree":"Fat-Tree Single","ftree2":"Fat-Tree Dual","dfly":"Dragonfly-2D", "sfly": "Slim Fly", "ffly": "Fit Fly", "ddfly": "Dragonfly-1D"}
    #routeType={"adaptive":"Adaptive", "static":"Static", "minimal":"Minimal"}
    Workload = {"traffic1":"Uniform Random", "traffic2": "Worst-Case", "traffic3" : "1D NN", "traffic4" : "2D NN", "traffic5" : "3D NN", "traffic6" : "Gather", "traffic7" : "Scatter", "traffic8" : "Bisection"}
    rtv = dat.split("-")
    rn = []
    rn.append(runName[rtv[0]])
    rn.append(rtv[1].replace("nodes",""))
    rn.append(rtv[2])
    rn.append(rtv[3])
    rn.append(rtv[8].replace("traffic",""))
    rn.append(rtv[9].replace("load",""))
    rn.append(rtv[4].replace("end",""))
    rn.append(rtv[5].replace("vc",""))
    rn.append(rtv[6].replace("GBps",""))
    return rn
#dfly-trace-amg1k-1ms-n3456-adaptive-1csfbkgnd-10mintvl-1000000tintvl-3456ranks-10000mpt


if __name__ == '__main__':
    arguments = docopt(__doc__)
    if (arguments['single']):
        columnar, noncol = read(arguments["<filename>"])
    elif (arguments['drill']):
        if(arguments['--dstart']):
            os.chdir(arguments["--dstart"])
            #colummar, noncol, opdat = readRecursive(arguments['<dir>'])

        colummar, noncol, opdat = readRecursive()

        if(arguments['--dstart2']):
            os.chdir(arguments['--dstart2'])
            colummar2, noncol2, opdat2 = readRecursive()

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
        saveDir = arguments["--dstart"]
        if(arguments['--dstart2']):
            plotterBarDual(noncol, noncol2, saveDir)
        else:
            plotOfferedGenerator(noncol, saveDir)
    if(arguments['--table']):
        saveDir = arguments["--dstart"]
        tableGenerator(noncol, saveDir)


