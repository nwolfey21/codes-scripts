'''
=========================
DUMPI Trace Visualization
=========================
This script parses the NeMo generated large-scale chip communication data file
(csv) to extract all inter-chip message transfers and generate a 2D heatmap
showing the number of spike transfers between all chips.
'''
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import time
import sys
import pdb

# Visualization Params
w = 5.5                  # Width of output figure
h = w/2                 # Height of output figure

##CIFAR100 4k chips
#inputDirPath = '/barn/superneuro/totals/cifar100'
#inputFilename = 'sparse_agg.csv'
#outputFilename = 'cifar100-2048chips.csv'
#numTraces = 4096            # Number of chips we have
#postNumTraces = 2048        #Number of chips we want to have

##MNIST 2466 chips
inputDirPath = '/barn/superneuro/totals'
inputFilename = 'out.csv'
outputFilename = 'mnist-1234chips.csv'
numTraces = 2467            # Number of chips we have
postNumTraces = 1234        #Number of chips we want to have

outputDirPath = '/scratch/networks/dumpi-traces/codes-nemo/chip-connection-files/'
commFlag = 1	#Collect metrics following the 2D communication heat map layout

#--Data Sets
commAggrData = [[0 for y in range(postNumTraces)] for z in range(postNumTraces)]

tempTime = time.time()

inFile = open(inputDirPath + '/' + inputFilename,'r')
outFile = open(outputDirPath + '/' + outputFilename, 'w')

lineNum = -1
dataMatrix = [[int(0) for x in range(postNumTraces)] for y in range(postNumTraces)]

while True:
    lineNum += 1
    line = inFile.readline()
    if not line: break
    line = line.strip()
    temp = line.split(",")
    src = temp[0]
    dst = temp[1]
    sends = temp[2]

    nodeID = float(src)
    sys.stdout.write("------>"+str(nodeID)+" out of "+str(numTraces)+"("+str(nodeID/numTraces)+"%) ETA: "+str((time.time()-tempTime)*(numTraces-nodeID))+"\r")
    tempTime = time.time()
    sys.stdout.flush()

    if commFlag and int(dst) != -1:
        #pdb.set_trace()
        newSrc = int(float(src)/(float(numTraces)/float(postNumTraces)))
        newDst = int(float(dst)/(float(numTraces)/float(postNumTraces)))
        dataMatrix[int(newSrc)][int(newDst)] += int(sends)
        commAggrData[newSrc][newDst] = 1
        #commAggrData[newSrc][newDst] += int(sends)

for x in range(postNumTraces):
    for y in range(postNumTraces):
        if dataMatrix[x][y] > 0:
            outFile.write(str(x)+','+str(y)+','+str(dataMatrix[x][y])+'\n')

inFile.close()
outFile.close()

# Create Matplotlib figure
fig, ax = plt.subplots(figsize=(w, h))

#plt.imshow(commAggrData, cmap='tab20', origin='lower',interpolation='nearest', clim=(min(min(commAggrData)),250))
plt.imshow(commAggrData, cmap='binary', origin='lower',interpolation='nearest')
#plt.imshow(commAggrData, cmap='plasma', origin='lower',interpolation='nearest', clim=(min(min(commAggrData)),max(max(commAggrData))))
#clb = plt.colorbar()
#clb.set_label('Msg Transfers')
ax.set_xlabel('Receiving Chip ID')
ax.set_ylabel('Sending Chip ID')
# Clean and Save Heat Map
plt.tight_layout()
fig.savefig('heatmap.pdf', dpi=320, facecolor='w',
    edgecolor='w', orientation='portrait', papertype=None,
    format=None, transparent=False, bbox_inches=None,
    pad_inches=0.25, frameon=None)
pdb.set_trace()
#plt.hist(commAggrData, bins=numTraces)
# Clean and Save Histogram
#plt.tight_layout()
#fig.savefig('histogram.pdf', dpi=320, facecolor='w',
    #edgecolor='w', orientation='portrait', papertype=None,
    #format=None, transparent=False, bbox_inches=None,
    #pad_inches=0.25, frameon=None)
