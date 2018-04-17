'''
===================
NeMo to Dumpi Ascii
===================
This script parses the NeMo generated list of MPI calls and converts that into the dumpi
approved ascii format
'''
import collections
import argparse
import subprocess
import sys
import time
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import axes3d
import pdb

# Parse commandline arguments
parser = argparse.ArgumentParser()
parser.add_argument('--file-prefix', action='store', default=-1, dest='inputDirPath',
                    help='Path to input files including prefix only')
parser.add_argument('--output-dir', action='store', default=-1, dest='outputDirPath',
                    help='Path to place directory for storing converted files')
parser.add_argument('--num-files', action='store', default=0, dest='numTraces',
                    help='Number of trace files to convert')

results = parser.parse_args()
print 'inputDirPath       =', results.inputDirPath
print 'outputDirPath      =', results.outputDirPath
print 'numTraces          =', results.numTraces
inputDirPath = results.inputDirPath
outputDirPath = results.outputDirPath
numTraces = int(results.numTraces)
endTime = 0.033
numBins = 100
dt = 0.033/numBins
sendsData = np.zeros((numTraces,numBins),dtype=np.int)
recvsData = np.zeros((numTraces,numBins),dtype=np.int)
convertDumpi = 0

ascii2DumpiExe = "~/Dropbox/RPI/Research/Networks/dumpi/install-titan/bin/ascii2dumpi"
tempTime = time.time()
for nodeID in range(0,numTraces):
    sys.stdout.write("------>"+str(nodeID)+" out of "+str(numTraces)+"("+str(nodeID/numTraces)+"%) ETA: "+str((time.time()-tempTime)*(numTraces-nodeID))+"\r")
    tempTime = time.time()
    sys.stdout.flush()
    if convertDumpi:
        outputFile = inputDirPath + 'n2d-' + str(nodeID).zfill(4)
        outFile = open(outputFile+'.dat','w')
    inFile = open(inputDirPath + str(nodeID).zfill(4) + '.dat','r')

    line = inFile.readline()    #Toss out header
    if not line: break
    while True:
        line = inFile.readline()
        if not line: break
        line = line.strip()
        line = line.split(" ")
        #outFile.write(line[0]+" entering at walltime %.9f" % round(float(line[3]) - round(float(line[3]),0)+round(float(line[3]),0)/100.000,9)+", cputime "+str(float(0))+" seconds in thread 0.\n")
        if convertDumpi:
            outFile.write(line[0]+" entering at walltime %.9f" % round(float(line[3]),9)+", cputime "+str(float(0))+" seconds in thread 0.\n")
            outFile.write("int count="+str(line[7])+"\n")
            #outFile.write("MPI_Datatype datatype="+str(line[8])+"\n")
            outFile.write("MPI_Datatype datatype=4 (MPI_LONG)\n")
        t = round(float(line[3]) / dt, 3)   #Compute time bin
        if line[0] == "MPI_Isend":
            if convertDumpi:
                outFile.write("int dest="+str(line[2])+"\n")
                countSends[int(float(line[3])*1000)] += 1
            sendsData[int(line[1])][int(t)] = sendsData[nodeID][int(t)] + 1
        else:
            if convertDumpi:
                outFile.write("int source="+str(line[1])+"\n")
                countRecvs[int(float(line[3])*1000)] += 1
            recvsData[int(line[1])][int(t)] = recvsData[nodeID][int(t)] + 1
        if convertDumpi:
            outFile.write("int tag="+str(line[10])+"\n")
            #outFile.write("MPI_Comm comm="+str(0)+"\n")
            outFile.write("MPI_Comm comm=4 (user-defined-comm)\n")
            #outFile.write("MPI_Request request=[0]"+"\n")
        if line[0] == "MPI_Isend":
            if convertDumpi:
                outFile.write("MPI_Request request=[3]"+"\n")
        else:
            if convertDumpi:
                outFile.write("MPI_Request request=[2]"+"\n")
        if convertDumpi:
            outFile.write(line[0]+" returning at walltime %.9f" % round(float(line[3]),9)+", cputime "+str(float(0))+" seconds in thread 0."+"\n")

    inFile.close()
    if convertDumpi:
        outFile.close()

    #for tick in range(0,numTicks):
    #    print(" s%d" % tick + ":%d" % countSends[tick] + " r%d" % tick + ":%d" % countRecvs[tick])

    if convertDumpi:
        call = ascii2DumpiExe+" -o "+outputFile+".bin "+outputFile+".dat"

        p = subprocess.Popen(call, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        for line in p.stdout.readlines():
            print line,
        retval = p.wait()

X, Y = np.meshgrid(np.array(range(numTraces)),np.array(range(numBins)))
fig = plt.figure(figsize=(6,6))
ax = fig.add_subplot(1,1,1,projection='3d')
ax.plot_surface(X,Y,sendsData.transpose(),rstride=10,cstride=10)
fig.savefig("/home/noah/Dropbox/sends.pdf",dpi=320,facecolor='w',edgecolor='w')
fig2 = plt.figure(figsize=(6,6))
ax = fig2.add_subplot(1,1,1,projection='3d')
ax.plot_surface(X,Y,recvsData.transpose(),rstride=10,cstride=10)
fig.savefig("/home/noah/Dropbox/recvs.pdf",dpi=320,facecolor='w',edgecolor='w')
#plt.show()
