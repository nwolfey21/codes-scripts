'''
====================
node IDs to rank IDs
====================
This script parses the output allocation file from the cluster policy, which
is based on node IDs and converts it to an allocation file based on rank 
IDs which is the format used for CODES mpi-replay
'''
import numpy as np
import argparse

# Parse commandline arguments
parser = argparse.ArgumentParser()
parser.add_argument('--alloc-file', action='store', dest='allocFile',
                                        help='Ex: --alloc-file /path/to/cluster-alloc-file.conf')
parser.add_argument('--num-jobs', action='store', dest='numJobs',
                                        help='Ex: number of jobs/applications')
parser.add_argument('--num-nodes', action='store', dest='numNodes',
                                        help='Ex: number of nodes in system')
parser.add_argument('--num-traces-per-job', action='store', dest='numTracesPerJob',
                                        help='Ex: number of trace ranks per job in csv format')
parser.add_argument('--num-ranks-per-node', action='store', dest='numRanksPerNode',
                                        help='Ex: number of ranks available per node in system')

results = parser.parse_args()
print 'alloc file         =', results.allocFile
print 'num jobs           =', results.numJobs
print 'num nodes          =', results.numNodes
print 'num traces per job =', results.numTracesPerJob
print 'num ranks per node =', results.numRanksPerNode
allocFile = results.allocFile
numJobs = int(results.numJobs)
numNodes = results.numNodes
numTracesPerJob = results.numTracesPerJob
numRanksPerNode = int(results.numRanksPerNode)

data = ['0' for z in range(numJobs)]
numTracesPerJob = numTracesPerJob.split(",")

# Convert alloc file
inFile = open(allocFile, 'r')
for l in range(numJobs):
    line = inFile.readline()
    if not line: break
    line = line.strip()
    temp= line.split(" ")
    for i in range(numJobs):
        print('i',str(i),'numTraces[i]:',str(int(numTracesPerJob[i])/numRanksPerNode),'length',str(len(temp)))
        if int(numTracesPerJob[i])/numRanksPerNode == len(temp):
            data[i] = temp
inFile.close()
inFile = open(allocFile, 'w')
for i in range(len(data)):
    for j in range(len(data[i])):
        for k in range(numRanksPerNode):
            #if int(data[i][j]) != int(numNodes):
                value = int(data[i][j]) * numRanksPerNode + k
                inFile.write(str(value))
                inFile.write(' ')
    inFile.write('\n')
inFile.close()
