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
import matplotlib.pyplot as plt
import seaborn as sns
import docopt
from pathlib import Path
from docopt import docopt
import os
import tempfile
from ggplot import *


nemolabel = "NeMo Trace"
cpulabel = "CPU Trace"
ts = "Total Sends"
tr = "Total Recvs"
bs = "Bytes Sent"
br = "Bytes Recvd"
mets = [ts, tr, bs, br]

formatc = ["lpid", "mpid", "Total Sends", "Total Recvs", "Bytes Sent", "Bytes Recvd",
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
    keyv = ["MPI Rank ID"]
    data = []
    keys = []
    runname = ""
    with open(filename, 'r') as f:
        fullData = f.readlines()
        runname = f.name
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
    types = ["N"]
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

    ncs = ["Metric", "Mean", "Max", "Min", "Sum", "Rank Type", "Run Name"]
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
            data.append([m, dt1[0], dt1[1], dt1[2], dt1[3], l, dirname])
    return pd.DataFrame(data=data, columns=ncs)


def parseDataNoFilter(df, dirname):
    ncs = ["Metric", "Value", "Rank Type", "Run Name"]
    data = []


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


def nameClean(dat,rn = "Run Name"):
    #### Translations ####
    runName = {"ftree":"Fat-Tree","dfly":"DragonFly", "sfly": "SlimFly"}
    routeType={"adaptive":"Adaptive", "static":"Static", "minimal":"Minimal"}
    synthWorkload = {"cr1k":"Crystal Router", "amg1k": "AMG", "mg1k" : "MG" }
    run_name = dat[rn]
    rtv = run_name.split("-")
    rn = ""
    rn += runName[rtv[0]] + " " + routeType[rtv[5]] + " " + synthWorkload[rtv[2]]
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
        p = plotter(noncol, colummar)
        #print(p)


