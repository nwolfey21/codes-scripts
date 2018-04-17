'''
=========================
DUMPI Trace Visualization
=========================
This script parses the ascii dumpi trace to extract all MPI operations and
corresponding information for post processing trace analysis.
Currently this script generates a 2D heatmap showing the number of message
transfers between all ranks.
'''
import collections
import matplotlib
import subprocess
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.colors as colors
import argparse
import time
import sys
import pdb

# Visualization Params
w = 5.5                  # Width of figure
h = w/2                 # Height of figure

#inputDirPath = '/scratch/codes-nemo/dumpi-traces/CONV/CIFAR_100/16_core/'
#inputDirPath = '/scratch/codes-nemo/dumpi-traces/CONV/CIFAR_100/4096_core/'
#inputFilenamePrefix = 'dumpi--17.12.01.08.44.46-processed-n2d-'
#AMG 1728
#inputFilenamePrefix = 'dumpi-2014.03.03.14.55.50-'
#inputDirPath = '/scratch/networks/dumpi-traces/df_AMG_n1728_dumpi/'
#numTraces = 1728
#CR 1000
inputDirPath = '/scratch/networks/dumpi-traces/CrystalRouter_n1000_dumpi/'
inputFilenamePrefix = 'dumpi--2014.04.23.12.17.17-'
numTraces = 1000
#MG 1000
#inputDirPath = '/scratch/networks/dumpi-traces/MultiGrid_C_n1000_dumpi/'
#inputFilenamePrefix = 'dumpi-2014.03.07.00.25.12-'
#numTraces = 1000

outputDirPath = 'CrystalRouter_n1000_dumpi'
outputFilenamePrefix = 'dumpi--17.10.04.13.37.57-processed-n2d-'

#--Useful Dictionaries
mpiTypeToIndx = {'MPI_Isend':0, 'MPI_Irecv':1, 'MPI_Waitall':2}
indxToMpiType = ['MPI_Isend', 'MPI_Irecv', 'MPI_Waitall']

#--Misc Variables
numMetrics = 17
numMpiTypes = 3
numMsgSizes = 64    #Number of different message sizes to allow collection for.
numTimeBins = 100   #Number of bins to distribute time data collection into
percentEndTime = 290000.0 / 44798942    #CrystalRouter Percent of endTime used in Codes replay simulation
endTimeDumpi = 3.3115
endTime = endTimeDumpi * percentEndTime
endTime = 9000000000000000

#--File IO
outputToFile = 0

#--Collection Interval Flags
aggrFlag = 1
timeSampleFlag = 1

#--Convert Dumpi Binary Traces to ascii
convertFlag = 1
dumpi2AsciiExe = '/scratch/codes-nemo/build/build-dumpi/dumpi/bin/dumpi2ascii'

#--Independent Metrics Flags
rankFlag = 0	#Collect metrics with respect to mpi rank IDs
typeFlag = 0	#Collect metrics with respect to mpi operation type
commFlag = 1	#Collect metrics following the 2D communication heat map layout
msgFlag  = 0	#Collect metrics with respect to buffer/msg size

#--Data Sets
typeAggrData = [[0 for x in range(numMetrics)] for y in range(numMpiTypes)]
rankAggrData = [[0 for x in range(numMetrics)] for y in range(numTraces)]
commAggrData = [[0 for y in range(numTraces)] for z in range(numTraces)]
msgAggrData = collections.defaultdict(list)

numIrecvs = 0
numIsends = 0
numSends = 0
numWaits = 0
numWaitalls = 0
numWaitsomes = 0
numBarriers = 0
tempTime = time.time()
for nodeID in range(0,numTraces):
    sys.stdout.write("------>"+str(nodeID)+" out of "+str(numTraces)+"("+str(nodeID/numTraces)+"%) ETA: "+str((time.time()-tempTime)*(numTraces-nodeID))+"\r")
    tempTime = time.time()
    sys.stdout.flush()

    if convertFlag:
        call=dumpi2AsciiExe+" -f "+inputDirPath+"/"+inputFilenamePrefix+str(nodeID).zfill(4)+".bin > "+inputDirPath+"/"+inputFilenamePrefix+str(nodeID).zfill(4)+".dat"
        p = subprocess.Popen(call, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        #for line in p.stdout.readlines():
        #    print line,
        retval = p.wait()

    if outputToFile:
        outFile = open(outputDirPath + '/' + outputFilenamePrefix + str(nodeID).zfill(4) + '.dat','w')
        outFile.write("<mpiType> <src> <dst> <wallStart> <wallStop> <cpuStart> <cpuStop> <count> <dataType> <comm> <tag>\n")

    inFile = open(inputDirPath + '/' + inputFilenamePrefix + str(nodeID).zfill(4) + '.dat','r')
    #inFile = open(inputDirPath + '/' + inputFilenamePrefix + str(nodeID).zfill(4) + '-ascii.dat','r')

    #Data Arrays
    #pndSrc = np.ndarray(shape=(1,), dtype=int, order='C')
    pndSrc = []
    pndDst = []
    pndMpiType = []
    pndWallStart = []
    pndWallStop = []
    pndCpuStart = []
    pndCpuStop = []
    pndCount = []
    pndDataType = []
    pndComm = []
    pndTag = []

    startTimeTrace = 0
    startTimeTraceWall = 0
    stopTimeTrace = 0.154623976

    lineNum = -1

    while True:
        lineNum += 1
        line = inFile.readline()
        if not line: break
        line = line.strip()
        temp = line.replace(',','')
        temp = temp.split(" ")
        mpiType = temp[0]
        state = temp[1]
        wallStart = temp[4]
        cpuStart = temp[6]

        if startTimeTrace == 0:
            startTimeTrace = float(cpuStart)
            startTimeTraceWall = float(wallStart)

        if mpiType == 'MPI_Irecv':
            numIrecvs += 1
            dst = nodeID
            line = inFile.readline()    #Read count line
            line = line.strip()
            temp = line.replace('=',' ')
            #temp = temp.split(" ")
            #count = temp[2]
            line = inFile.readline()    #Read datatype line
            #temp = line.replace('=',' ')
            #temp = temp.split(" ")
            #dataType = temp[2]
            line = inFile.readline()    #Read source line
            line = line.strip()
            temp = line.replace('=',' ')
            temp = temp.split(" ")
            src = temp[2]
            line = inFile.readline()    #Read tag line
            #line = line.strip()
            #temp = line.replace('=',' ')
            #temp = temp.split(" ")
            #tag = temp[2]
            line = inFile.readline()    #Read comm line
            #line = line.strip()
            #temp = line.replace('=',' ')
            #temp = temp.split(" ")
            #comm = temp[2]
            line = inFile.readline()    #Read request line
        elif mpiType == 'MPI_Send':
            numSends += 1
            src = nodeID
            line = inFile.readline()    #Read count line
            #line = line.strip()
            #temp = line.replace('=',' ')
            #temp = temp.split(" ")
            #count = temp[2]
            line = inFile.readline()    #Read datatype line
            #temp = line.replace('=',' ')
            #temp = temp.split(" ")
            dataType = temp[2]
            line = inFile.readline()    #Read dest line
            line = line.strip()
            temp = line.replace('=',' ')
            temp = temp.split(" ")
            dst = temp[2]
            line = inFile.readline()    #Read tag line
            #line = line.strip()
            #temp = line.replace('=',' ')
            #temp = temp.split(" ")
            #tag = temp[2]
            line = inFile.readline()    #Read comm line
            #line = line.strip()
            #temp = line.replace('=',' ')
            #temp = temp.split(" ")
            #comm = temp[2]
        elif mpiType == 'MPI_Isend':
            numIsends += 1
            src = nodeID
            line = inFile.readline()    #Read count line
            #line = line.strip()
            #temp = line.replace('=',' ')
            #temp = temp.split(" ")
            #count = temp[2]
            line = inFile.readline()    #Read datatype line
            #temp = line.replace('=',' ')
            #temp = temp.split(" ")
            dataType = temp[2]
            line = inFile.readline()    #Read dest line
            line = line.strip()
            temp = line.replace('=',' ')
            temp = temp.split(" ")
            dst = temp[2]
            line = inFile.readline()    #Read tag line
            #line = line.strip()
            #temp = line.replace('=',' ')
            #temp = temp.split(" ")
            #tag = temp[2]
            line = inFile.readline()    #Read comm line
            #line = line.strip()
            #temp = line.replace('=',' ')
            #temp = temp.split(" ")
            #comm = temp[2]
            line = inFile.readline()    #Read request line
        elif mpiType == 'MPI_Waitsome':
            numWaitsomes += 1
            line = inFile.readline()    #Read count line
            line = inFile.readline()    #Read count line
            line = inFile.readline()    #Read count line
            line = inFile.readline()    #Read count line
            line = inFile.readline()    #Read count line
            line = inFile.readline()    #Read count line
            continue
        elif mpiType == 'MPI_Waitall':
            numWaitalls += 1
            src = nodeID
            line = inFile.readline()    #Read count line
            #line = line.strip()
            #temp = line.replace('=',' ')
            #temp = temp.split(" ")
            #count = temp[2]
            #dataType = -1
            #dst = -1
            #tag = -1
            #comm = -1
            line = inFile.readline()    #Read request line
            line = inFile.readline()    #Read statuses line
        elif mpiType == 'MPI_Barrier':
            numBarriers += 1
            line = inFile.readline()
            line = inFile.readline()
            continue
        elif mpiType == 'MPI_Allgather':
            line = inFile.readline()
            line = inFile.readline()
            line = inFile.readline()
            line = inFile.readline()
            line = inFile.readline()
            line = inFile.readline()
            continue
        elif mpiType == 'MPI_Allreduce':
            line = inFile.readline()
            line = inFile.readline()
            line = inFile.readline()
            line = inFile.readline()
            line = inFile.readline()
            continue
        elif mpiType == 'MPI_Reduce':
            line = inFile.readline()
            line = inFile.readline()
            line = inFile.readline()
            line = inFile.readline()
            line = inFile.readline()
            line = inFile.readline()
            continue
        elif mpiType == 'MPI_Wtime':
            line = inFile.readline()
            continue
        elif mpiType == 'MPI_Init':
            line = inFile.readline()
            line = inFile.readline()
            line = inFile.readline()
            continue
        elif mpiType == 'MPI_Initialized':
            line = inFile.readline()
            line = inFile.readline()
            continue
        elif mpiType == 'MPI_Comm_rank':
            line = inFile.readline()
            line = inFile.readline()
            line = inFile.readline()
            continue
        elif mpiType == 'MPI_Comm_size':
            line = inFile.readline()
            line = inFile.readline()
            line = inFile.readline()
            continue
        else:
            pdb.set_trace

        line = inFile.readline()    #Read 'returning' line
        temp = line.replace(',','')
        temp = temp.split(" ")
        wallStop = temp[4]
        cpuStop = temp[6]

        if commFlag and int(dst) != -1:
            commAggrData[int(src)][int(dst)] = 1		#Number of calls

        #if cpuStop <= endTime:
        #Data collection
        if aggrFlag:
            #Time bin calculation
            bin = int((float(cpuStop) / float(stopTimeTrace)) * numTimeBins)
            if typeFlag:
                typeAggrData[mpiTypeToIndx[mpiType]][0] += 1                #Number of calls
                typeAggrData[mpiTypeToIndx[mpiType]][1] += int(count)       #Total Message Size
                if int(count) < typeAggrData[mpiTypeToIndx[mpiType]][2]:
                    typeAggrData[mpiTypeToIndx[mpiType]][2] = int(count)    #Min Message Size
                if int(count) > typeAggrData[mpiTypeToIndx[mpiType]][3]:
                    typeAggrData[mpiTypeToIndx[mpiType]][3] = int(count)    #Max message Size
                typeAggrData[mpiTypeToIndx[mpiType]][4] = typeAggrData[mpiTypeToIndx[mpiType]][1] / typeAggrData[mpiTypeToIndx[mpiType]][0]	#Avg Message Size
                typeAggrData[mpiTypeToIndx[mpiType]][5] += float(cpuStop) - float(cpuStart)       #Total Time
                if typeAggrData[mpiTypeToIndx[mpiType]][6] < float(cpuStop) - float(cpuStart):
                    typeAggrData[mpiTypeToIndx[mpiType]][6] = float(cpuStop) - float(cpuStart)    #Min Time
                if typeAggrData[mpiTypeToIndx[mpiType]][7] > float(cpuStop) - float(cpuStart):
                    typeAggrData[mpiTypeToIndx[mpiType]][7] = float(cpuStop) - float(cpuStart)    #Max Time
                typeAggrData[mpiTypeToIndx[mpiType]][8] = typeAggrData[mpiTypeToIndx[mpiType]][5] / typeAggrData[mpiTypeToIndx[mpiType]][0]    #Average Time
                typeAggrData[mpiTypeToIndx[mpiType]][9] = typeAggrData[mpiTypeToIndx[mpiType]][5] / ((float(cpuStop) - float(startTimeTrace)) * numTraces)    #Percent MPI
                typeAggrData[mpiTypeToIndx[mpiType]][10] = (float(cpuStop) - float(startTimeTrace) - typeAggrData[mpiTypeToIndx[mpiType]][5] / numTraces) / (float(cpuStop) - float(startTimeTrace))    #Percent CPU
                typeAggrData[mpiTypeToIndx[mpiType]][11] += float(wallStop) - float(wallStart)       #Total Time
                if typeAggrData[mpiTypeToIndx[mpiType]][12] < float(wallStop) - float(wallStart):
                    typeAggrData[mpiTypeToIndx[mpiType]][12] = float(wallStop) - float(wallStart)    #Min Time
                if typeAggrData[mpiTypeToIndx[mpiType]][13] > float(wallStop) - float(wallStart):
                    typeAggrData[mpiTypeToIndx[mpiType]][13] = float(wallStop) - float(wallStart)    #Max Time
                typeAggrData[mpiTypeToIndx[mpiType]][14] = typeAggrData[mpiTypeToIndx[mpiType]][11] / typeAggrData[mpiTypeToIndx[mpiType]][0] 	#Average Time
                typeAggrData[mpiTypeToIndx[mpiType]][15] = typeAggrData[mpiTypeToIndx[mpiType]][11] / ((float(wallStop) - float(startTimeTraceWall)) * numTraces)		#Percent MPI
                typeAggrData[mpiTypeToIndx[mpiType]][16] = (float(wallStop) - float(startTimeTraceWall) - typeAggrData[mpiTypeToIndx[mpiType]][11] / numTraces) / (float(wallStop) - float(startTimeTraceWall))	#Percent CPU
            if rankFlag:
                rankAggrData[nodeID][0] += 1		#Number of calls
                rankAggrData[nodeID][1] += int(count)	#Total Message Size
                if int(count) < rankAggrData[nodeID][2]:
                    rankAggrData[nodeID][2] = int(count)	#Min Message Size
                if int(count) > rankAggrData[nodeID][3]:
                    rankAggrData[nodeID][3] = int(count)	#Max message Size
                rankAggrData[nodeID][4] = rankAggrData[nodeID][1] / rankAggrData[nodeID][0]	#Avg Message Size
                rankAggrData[nodeID][5] += float(cpuStop) - float(cpuStart)		#Total Time
                if rankAggrData[nodeID][6] < float(cpuStop) - float(cpuStart):
                    rankAggrData[nodeID][6] = float(cpuStop) - float(cpuStart)	#Min Time
                if rankAggrData[nodeID][7] > float(cpuStop) - float(cpuStart):
                    rankAggrData[nodeID][7] = float(cpuStop) - float(cpuStart) 	#Max Time
                rankAggrData[nodeID][8] = rankAggrData[nodeID][5] / rankAggrData[nodeID][0] 	#Average Time
                rankAggrData[nodeID][9] = rankAggrData[nodeID][5] / (float(cpuStop) - float(startTimeTrace))		#Percent MPI
                rankAggrData[nodeID][10] = (float(cpuStop) - float(startTimeTrace) - rankAggrData[nodeID][5]) / (float(cpuStop) - float(startTimeTrace))	#Percent CPU
                rankAggrData[nodeID][11] += float(wallStop) - float(wallStart)		#Total Time
                if rankAggrData[nodeID][12] < float(wallStop) - float(wallStart):
                    rankAggrData[nodeID][12] = float(wallStop) - float(wallStart)	#Min Time
                if rankAggrData[nodeID][13] > float(wallStop) - float(wallStart):
                    rankAggrData[nodeID][13] = float(wallStop) - float(wallStart) 	#Max Time
                rankAggrData[nodeID][14] = rankAggrData[nodeID][11] / rankAggrData[nodeID][0] 	#Average Time
                rankAggrData[nodeID][15] = rankAggrData[nodeID][11] / (float(wallStop) - float(startTimeTraceWall))		#Percent MPI
                rankAggrData[nodeID][16] = (float(wallStop) - float(startTimeTraceWall) - rankAggrData[nodeID][11]) / (float(wallStop) - float(startTimeTraceWall))	#Percent CPU
            if msgFlag:
                if int(count) in msgAggrData:
                    msgAggrData[int(count)][0] += 1		#Number of calls
                    msgAggrData[int(count)][1] += float(cpuStop) - float(cpuStart)		#Total Time
                    if msgAggrData[int(count)][2] < float(cpuStop) - float(cpuStart):
                        msgAggrData[int(count)][2] = float(cpuStop) - float(cpuStart)	#Min Time
                    if msgAggrData[int(count)][3] > float(cpuStop) - float(cpuStart):
                        msgAggrData[int(count)][3] = float(cpuStop) - float(cpuStart) 	#Max Time
                    msgAggrData[int(count)][4] = msgAggrData[int(count)][1] / msgAggrData[int(count)][0] 	#Average Time
                    msgAggrData[int(count)][4] = msgAggrData[int(count)][1] / (float(cpuStop) - float(startTimeTrace) * numTraces)		#Percent MPI
                    msgAggrData[int(count)][5] = (float(cpuStop) - float(startTimeTrace) - msgAggrData[int(count)][1] / numTraces) / (float(cpuStop) - float(startTimeTrace))	#Percent CPU
                    msgAggrData[int(count)][6] += float(wallStop) - float(wallStart)	#Total Time
                    if msgAggrData[int(count)][7] < float(wallStop) - float(wallStart):
                        msgAggrData[int(count)][7] = float(wallStop) - float(wallStart) #Min Time
                    if msgAggrData[int(count)][8] > float(wallStop) - float(wallStart):
                        msgAggrData[int(count)][8] = float(wallStop) - float(wallStart) #Max Time
                    msgAggrData[int(count)][9] = msgAggrData[int(count)][6] / msgAggrData[int(count)][0] 	#Average Time
                    msgAggrData[int(count)][10] = msgAggrData[int(count)][6] / (float(wallStop) - float(startTimeTraceWall) * numTraces)		#Percent MPI
                    msgAggrData[int(count)][11] = (float(wallStop) - float(startTimeTraceWall) - msgAggrData[int(count)][6] / numTraces) / (float(wallStop) - float(startTimeTraceWall))	#Percent CPU
                else:
                    msgAggrData[int(count)].append(1)		#Number of calls
                    msgAggrData[int(count)].append(float(cpuStop) - float(cpuStart))    #Total Time
                    msgAggrData[int(count)].append(float(cpuStop) - float(cpuStart))	#Min Time
                    msgAggrData[int(count)].append(float(cpuStop) - float(cpuStart))	#Max Time
                    msgAggrData[int(count)].append(msgAggrData[int(count)][1] / msgAggrData[int(count)][0]) 	#Average Time
                    msgAggrData[int(count)].append(msgAggrData[int(count)][1] / (float(cpuStop) - float(startTimeTrace) * numTraces))		#Percent MPI
                    msgAggrData[int(count)].append((float(cpuStop) - float(startTimeTrace) - msgAggrData[int(count)][1] / numTraces) / (float(cpuStop) - float(startTimeTrace)))	#Percent CPU
                    msgAggrData[int(count)].append(float(wallStop) - float(wallStart))  #Total Time
                    msgAggrData[int(count)].append(float(wallStop) - float(wallStart))	#Min Time
                    msgAggrData[int(count)].append(float(wallStop) - float(wallStart)) 	#Max Time
                    msgAggrData[int(count)].append(msgAggrData[int(count)][6] / msgAggrData[int(count)][0]) 	#Average Time
                    msgAggrData[int(count)].append(msgAggrData[int(count)][6] / (float(wallStop) - float(startTimeTraceWall) * numTraces))		#Percent MPI
                    msgAggrData[int(count)].append((float(wallStop) - float(startTimeTraceWall) - msgAggrData[int(count)][6] / numTraces) / (float(wallStop) - float(startTimeTraceWall)))	#Percent CPU
            if commFlag and int(dst) != -1:
                continue
                #if mpiType != 'MPI_Irecv':
                #    commAggrData[int(src)][int(dst)] = 1		#Number of calls
                #commAggrData[int(src)][int(dst)][1] += int(count)	#Total Message Size
                #if int(count) < commAggrData[int(src)][int(dst)][2]:
                #    commAggrData[int(src)][int(dst)][2] = int(count)	#Min Message Size
                #if int(count) > commAggrData[int(src)][int(dst)][3]:
                #    commAggrData[int(src)][int(dst)][3] = int(count)	#Max message Size
                #commAggrData[int(src)][int(dst)][4] = commAggrData[int(src)][int(dst)][1] / commAggrData[int(src)][int(dst)][0]	#Avg Message Size
                #commAggrData[int(src)][int(dst)][5] += float(cpuStop) - float(cpuStart)		#Total Time
                #if commAggrData[int(src)][int(dst)][6] < float(cpuStop) - float(cpuStart):
                #    commAggrData[int(src)][int(dst)][6] = float(cpuStop) - float(cpuStart)	#Min Time
                #if commAggrData[int(src)][int(dst)][7] > float(cpuStop) - float(cpuStart):
                #    commAggrData[int(src)][int(dst)][7] = float(cpuStop) - float(cpuStart) 	#Max Time
                #commAggrData[int(src)][int(dst)][8] = commAggrData[int(src)][int(dst)][5] / commAggrData[int(src)][int(dst)][0] 	#Average Time
                #commAggrData[int(src)][int(dst)][9] = commAggrData[int(src)][int(dst)][5] / (float(cpuStop) - float(startTimeTrace))		#Percent MPI
                #commAggrData[int(src)][int(dst)][10] = (float(cpuStop) - float(startTimeTrace) - commAggrData[int(src)][int(dst)][5]) / (float(cpuStop) - float(startTimeTrace))	#Percent CPU
                #commAggrData[int(src)][int(dst)][11] += float(wallStop) - float(wallStart)		#Total Time
                #if commAggrData[int(src)][int(dst)][12] < float(wallStop) - float(wallStart):
                #    commAggrData[int(src)][int(dst)][12] = float(wallStop) - float(wallStart)	#Min Time
                #if commAggrData[int(src)][int(dst)][13] > float(wallStop) - float(wallStart):
                #    commAggrData[int(src)][int(dst)][13] = float(wallStop) - float(wallStart) 	#Max Time
                #commAggrData[int(src)][int(dst)][14] = commAggrData[int(src)][int(dst)][11] / commAggrData[int(src)][int(dst)][0] 	#Average Time
                #commAggrData[int(src)][int(dst)][15] = commAggrData[int(src)][int(dst)][11] / (float(wallStop) - float(startTimeTraceWall))		#Percent MPI
                #commAggrData[int(src)][int(dst)][16] = (float(wallStop) - float(startTimeTraceWall) - commAggrData[int(src)][int(dst)][11]) / (float(wallStop) - float(startTimeTraceWall))	#Percent CPU

        if outputToFile:
            outFile.write(mpiType+" "+str(src)+" "+str(dst)+" "+str(wallStart)+" "+str(wallStop)+" "+str(cpuStart)+" "+str(cpuStop)+" "+str(count)+" "+str(dataType)+" "+str(comm)+" "+str(tag)+"\n")

    if outputToFile:
        inFile.close()
        outFile.close()

print "Irecvs: "+str(numIrecvs)
print "Isends: "+str(numIsends)
print "Sends: "+str(numSends)
print "Waits: "+str(numWaits)
print "Waitalls: "+str(numWaitalls)
print "Waitsomes: "+str(numWaitsomes)
print "Barriers: "+str(numBarriers)

# Create Matplotlib figure
fig, ax = plt.subplots(figsize=(w, h))

#plt.imshow(commAggrData, cmap='tab20', origin='lower',interpolation='nearest', clim=(min(min(commAggrData)),250))
plt.imshow(commAggrData, cmap='binary', origin='lower',interpolation='nearest')
#plt.imshow(commAggrData, cmap='plasma', origin='lower',interpolation='nearest', clim=(min(min(commAggrData)),max(max(commAggrData))))
#clb = plt.colorbar()
#clb.set_label('Msg Transfers')
ax.set_xlabel('Receiving Process ID')
ax.set_ylabel('Sending Process ID')
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
