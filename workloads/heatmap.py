'''
==================================
Generalized Heat Map Visualization
==================================
This script parses any communication map following a 2D array of
'space-separated' data with each row adhering to the following format:
    <src ID> <num sends to dst0> <num sends to dst1> <num sends to dstN>
The script then generates a 2D heatmap showing the number of transfers between
all procsses.
'''
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import argparse
import time
import sys
import pdb

# Visualization Params
w = 5.5                  # Width of output figure
h = w/2                 # Height of output figure

# Parse commandline arguments
parser = argparse.ArgumentParser()
parser.add_argument('--input-file-path', action='store', dest='inputFile', nargs=1, type=str,
                    help='Absolute path to the input file containing the space separated comm data')
parser.add_argument('--output-file-path', action='store', dest='outputFile', nargs=1, type=str,
                    help='Absolute path to save the generated heatmap figure')
parser.add_argument('--num-procs', action='store', default=0, dest='numProcs', nargs=1, type=int,
                    help='Total number of processes communicating')
results = parser.parse_args()
inputFile = results.inputFile[0]
outputFile = results.outputFile[0]
numProcs = int(results.numProcs[0])

#--Data Sets
commData = [[int(0) for y in range(numProcs)] for z in range(numProcs)]
tempTime = time.time()

inFile = open(inputFile,'r')
outFile = open(outputFile, 'w')

lineNum = -1
dataMatrix = [[int(0) for x in range(numProcs)] for y in range(numProcs)]

# Parse Data into 2D list
line = inFile.readline()    #Get rid of header file
while True:
    lineNum += 1
    line = inFile.readline()
    if not line: break
    line = line.strip()
    temp = line.split(" ")
    src = int(temp[0])
    sys.stdout.write("------>"+str(src)+" out of "+str(numProcs)+"("+str(src/numProcs)+"%) ETA: "+str((time.time()-tempTime)*(numProcs-src))+"\r")
    tempTime = time.time()
    sys.stdout.flush()
    for i in range(1,len(temp)):
        commData[src][i-1] += int(temp[i])

# Create Matplotlib figure
matplotlib.rcParams.update({'font.size': 8})
fig, ax = plt.subplots(figsize=(w, h))
# Generate heat map of 2D list data
plt.imshow(commData, cmap='binary', origin='lower',interpolation='none')
clb = plt.colorbar()
clb.set_label('Msg Transfers')
ax.set_xlabel('Receiver IDs')
ax.set_ylabel('Sender IDs')
plt.tight_layout()
fig.savefig(outputFile, dpi=320, facecolor='w',
    edgecolor='w', orientation='portrait', papertype=None,
    format=None, transparent=False, bbox_inches=None,
    pad_inches=0.25, frameon=None)
