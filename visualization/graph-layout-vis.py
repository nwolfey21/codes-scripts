'''
===================
Topology Graph Plot
===================
This script parses connection files for all network models to visualize
the simulated network layout
'''

import networkx as nx
import argparse
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import csv
import pdb

# Parse commandline arguments
parser = argparse.ArgumentParser()
parser.add_argument('--root-dir', action='store', dest='rootDir',
                    help='absolute path to the parent directory containing all lp-io directories which have modelnet sim data.\nIt can be the lp-io directory for one run or a higher level directory with many lp-io dirs within')
parser.add_argument('--sim-metric', action='store', default='none', dest='metric', nargs='+', type=str,
                    help='space separated list of metrics from simulation data file to be included as node attributes for visualization\nOptions: none, traffic, busy-time, latency, hops')
parser.add_argument('--plot-type', action='store', default='single', dest='graphType', type=str,
                    help='Whether or not to print all simulations separately or combine workloads as attributes for the same network models\nOptions: single (default), combined')
results = parser.parse_args()
print 'root dir          =', results.rootDir
print 'sim metric        =', results.metric
print 'plot type         =', results.graphType
metricStringList = results.metric
graphType = results.graphType
rootDir = Path(results.rootDir)
dir_list = [f for f in rootDir.glob('**/*') if f.is_dir()]

# Global variables
netModel = ""
systemSize = 0
numIter = 1    #Number of iterations for force directed and spring layouts
plotType = "spring"    # Options: grid, spring, circular, force, random, shell
exportGEXF = 1          # If true, exports the network in the Graph Exchange XML format (GEXF) for reading into Gephi or other application
exportGRAPHML = 0          # If true, exports the network in the Graph Exchange XML format (GEXF) for reading into Gephi or other application
w = 20                  # Width of figure
h = w/2                 # Height of figure
edgeTerminalWeight = 1    # Weight to apply to terminal connection
edgeLocalWeight = 2    # Weight to apply to local connection
edgeGlobalWeight = 1    # Weight to apply to global connection
reps = 0
numRouters = 0
numLocal = 0
numGlobal = 0
numTerminals = 0
totalTerminals = 0
numLevels = 0
numPlanes = 0

# Function for constructing the NetworkX graph
def funcConstructGraph(G, nodes, netModel, systemSize, connections):
    if netModel == "sfly" or netModel == "ffly":
        for i in nodes:
            G.add_node(i)
            if i < systemSize:
                G.node[i]['viz'] = {'color': {'r': 255, 'g': 0, 'b': 0, 'a': 0.6}}
            elif i >= systemSize and i < systemSize+reps:
                G.node[i]['viz'] = {'color': {'r': 0, 'g': 255, 'b': 0, 'a': 0.6}}
            else:
                G.node[i]['viz'] = {'color': {'r': 0, 'g': 0, 'b': 255, 'a': 0.6}}
        for i in range(0,len(connections),2):
            if connections[i] < systemSize or connections[i+1] < systemSize:
                weight = edgeTerminalWeight
            else:
                if connections[i] >= systemSize+reps:
                    srcConnection = connections[i] - systemSize - reps
                    dstConnection = connections[i+1] - systemSize - reps
                else:
                    srcConnection = connections[i] - systemSize
                    dstConnection = connections[i+1] - systemSize
                difference = (dstConnection) - (srcConnection)
                if difference < 0:
                    difference = difference * (-1)
                weight = edgeLocalWeight
                if difference > numRouters:
                    weight = edgeGlobalWeight
                # Check for specific case when global connections are close across subgraphs
                # When in different subgraphs, the values will be positive and negative
                subgraph1 = (srcConnection) - (reps/2)
                subgraph2 = (dstConnection) - (reps/2)
                if subgraph1*subgraph2 < 0:
                    weight = edgeGlobalWeight
                elif subgraph1*subgraph2 == 0 and subgraph1+subgraph2 < 0:
                    weight = edgeGlobalWeight
            G.add_edge(connections[i],connections[i+1],weight=weight)
    elif netModel == "dfly":
        for i in nodes:
            G.add_node(i)
            #Color routers
            if i % 13 == 12:
                G.node[i]['viz'] = {'color': {'r': 0, 'g': 255, 'b': 0, 'a': 0.6}}
            #Color terminals
            else:
                G.node[i]['viz'] = {'color': {'r': 255, 'g': 0, 'b': 0, 'a': 0.6}}
        for i in range(0,len(connections),2):
            if connections[i] % 13 == 12 and connections[i+1] % 13 == 12:
                if int(connections[i] / 1248) == int(connections[i+1] / 1248):
                    G.add_edge(connections[i],connections[i+1],weight=3)
                else:
                    G.add_edge(connections[i],connections[i+1],weight=2)
            else:
                G.add_edge(connections[i],connections[i+1],weight=1)
    elif netModel == "ddfly":
        for i in nodes:
            G.add_node(i)
            #Color routers
            if i % 17 == 16:
                G.node[i]['viz'] = {'color': {'r': 0, 'g': 255, 'b': 0, 'a': 0.6}}
            #Color terminals
            else:
                G.node[i]['viz'] = {'color': {'r': 255, 'g': 0, 'b': 0, 'a': 0.6}}
        for i in range(0,len(connections),2):
            if connections[i] % 17 == 16 and connections[i+1] % 17 == 16:
                if int(int(connections[i] / 17) / 16) == int(int(connections[i+1] / 17) / 16):
                    G.add_edge(connections[i],connections[i+1],weight=3)
                else:
                    G.add_edge(connections[i],connections[i+1],weight=1)
            else:
                G.add_edge(connections[i],connections[i+1],weight=2)
    else:
        for i in nodes:
            G.add_node(i)
            if i < totalTerminals:
                G.node[i]['viz'] = {'color': {'r': 255, 'g': 0, 'b': 0, 'a': 0.6}}
            else:
                G.node[i]['viz'] = {'color': {'r': 0, 'g': 255, 'b': 0, 'a': 0.6}}
        for i in range(0,len(connections),2):
            if connections[i] < totalTerminals or connections[i+1] < totalTerminals:
                G.add_edge(connections[i],connections[i+1],weight=1)
            else:
                G.add_edge(connections[i],connections[i+1],weight=2)


# Function for generating various spatial layouts of the topologies
def funcConstructLayout(plotType, G):
    # Spring Layout
    if plotType == "grid":
        #nx.draw_networkx_nodes(G,pos,node_size=100)
        #nx.draw_networkx_edges(G,pos)
        #nx.draw(G,pos)
        #nx.draw_networkx_labels(G,pos)
        for node,(x,y) in pos.items():
            G.node[node]['x'] = float(x)
            G.node[node]['y'] = float(y)
    # Spring Layout
    if plotType == "spring":
        pos=nx.spring_layout(G,iterations=numIter,scale=1,dim=3)
        #nx.draw(G,pos)
        #nx.draw_networkx_labels(G,pos)
        for node,(x,y,z) in pos.items():
            G.node[node]['x'] = float(x)
            G.node[node]['y'] = float(y)
            G.node[node]['z'] = float(z)
    # Force Directed Layout
    if plotType == "force":
        pos = nx.fruchterman_reingold_layout(G,iterations=numIter,scale=10)
        nx.draw(G,pos)
        nx.draw_networkx_labels(G,pos)
    # Random Layout
    if plotType == "random":
        nx.draw_random(G)
    # Circular Layout
    if plotType == "circular":
        nx.draw_circular(G)
    # Shell Layout (Concentric circles)
    if plotType == "shell":
        nx.draw_shell(G)


# Function for cleaning and saving the generated figure
def funcSaveFigure(systemSize, plotType, netModel):
    plt.tight_layout()
    fig.savefig('sfly'+str(systemSize)+'-layout-'+plotType+'.pdf', dpi=320, facecolor='w',
        edgecolor='w', orientation='portrait', papertype=None,
        format=None, transparent=False, bbox_inches=None,
        pad_inches=0.25, frameon=None)


# Function for saving the graph in various formats
def funcSaveGraph(G, filePath, netModel, systemSize):
    if exportGEXF == 1:
        nx.write_gexf(G,filePath+'/'+netModel+str(systemSize)+'.gexf')
    if exportGRAPHML == 1:
        nx.write_graphml(G,netModel+str(systemSize)+'.graphml')


# Function for importing simulation traffic results
def funcImportTrafficData(filePath, netModel, switchTrafficDataTemp, metricString):
    # Extract traffic file header
    if metricString == "traffic":
        postfix = "traffic"
    elif metricString == "busy-time":
        postfix = "stats"
    if "tree" in netModel:
        inFile = open(filePath+'/fattree-switch-'+postfix, 'r')
    elif "dfly" in netModel:
        inFile = open(filePath+'/dragonfly-router-'+postfix, 'r')
    else:
        inFile = open(filePath+'/slimfly-router-'+postfix, 'r')
    line = inFile.readline()
    line = line.strip()
    temp = line.replace('# Format','')
    temp = temp.replace(' <','')
    temp = temp.replace('>',',')
    switchTrafficHeader= temp.split(",")
    # Remove extra line of whitespace for dragonfly and ftree models
    if metricString == "busy-time":
        if "tree" in netModel or "dfly" in netModel:
            line = inFile.readline()
    del switchTrafficHeader[-1]

    # Parse traffic data
    print 'Parsing '+netModel+'-switch-'+postfix+' data...'
    while True:
        line = inFile.readline()
        if not line: break
        line = line.strip()
        temp = line.split(" ")
        if netModel == "dfly":
            routerID = (int(temp[2]) + int(temp[1])*96 + 1) * 13 - 1
            temp = [float(i) for i in temp[3:]]
        elif netModel == "ddfly":
            routerID = (int(temp[2]) + int(temp[1])*16 + 1) * 17 - 1
            temp = [float(i) for i in temp[3:]]
        elif "ftree" in netModel:
            routerID = int(temp[3]) + int(temp[1])*numSwitches
            temp = [float(i) for i in temp[4:]]
        else:
            routerID = int(temp[2])
            temp = [float(i) for i in temp[3:]]
        temp = sum(temp)
        if netModel == "sfly" or netModel == "ffly" or "tree" in netModel:
            switchTrafficDataTemp[routerID+totalTerminals] = temp
        else:
            switchTrafficDataTemp[routerID] = temp
            if switchTrafficDataTemp[routerID] > 1407246034530:
                pdb.set_trace()
    inFile.close()
    return switchTrafficDataTemp


# Function for importing simulation msg stats results
def funcImportMsgStatsData(filePath, netModel, switchTrafficDataTemp, metric):
    if "tree" in netModel:
        inFile = open(filePath+'/fattree-msg-stats', 'r')
    elif "dfly" in netModel:
        inFile = open(filePath+'/dragonfly-msg-stats', 'r')
    else:
        inFile = open(filePath+'/slimfly-msg-stats', 'r')
    if "dfly" not in netModel:
        # Extract model-msg-stats file header
        line = inFile.readline()
    # Parse model-msg-stats data
    print 'Parsing '+netModel+'-msg-stats data...'
    while True:
        line = inFile.readline()
        if not line: break
        line = line.strip()
        temp = line.split(" ")
        if netModel == "dfly":
            #terminalID = int(temp[1]) + 8 + int(int(temp[1])/4) * 9
            terminalID = int(int(temp[1])/4) * 13 + 8 + int(temp[1]) % 4
        elif netModel == "ddfly":
            terminalID = int(int(temp[1])/8) * 17 + 8 + int(temp[1]) % 8
            if terminalID == 8193:
                pdb.set_trace()
        else:
            terminalID = int(temp[1])
        #temp = [float(i) for i in temp]
        if temp[metric] == '-nan' or temp[metric] == 'nan':
            temp[metric] = 0
        if float(temp[metric]) > 2e9:
            temp[metric] = 0
        switchTrafficDataTemp[terminalID] = float(temp[metric])
    inFile.close()
    return switchTrafficDataTemp


# Function for importing mpi replay stats results
def funcImportMpiStatsData(filePath, netModel, switchTrafficDataTemp, metric):
    # Open file
    inFile = open(filePath+'/mpi-replay-stats', 'r')
    # Extract file header
    line = inFile.readline()
    # Parse mpi stats data
    print 'Parsing '+netModel+'/msg-replay-stats data...'
    mpiID = [0]
    while True:
        line = inFile.readline()
        if not line: break
        line = line.strip()
        temp = line.split(" ")
        if len(temp) == 11:
            jobIndx = -1
        elif len(temp) == 12:
            jobIndx = -2
        else:
            exit()
        if len(mpiID)-1 < temp[jobIndx]:
            mpiID.append(0)
        if netModel == "dfly":
            terminalID = int(mpiID[int(temp[jobIndx])]/4) * 13 + 8 + mpiID[int(temp[jobIndx])] % 4
        elif netModel == "ddfly":
            terminalID = int(mpiID[int(temp[jobIndx])]/8) * 17 + 8 + mpiID[int(temp[jobIndx])] % 8
            if terminalID == 8193:
                pdb.set_trace()
        else:
            terminalID = mpiID[int(temp[jobIndx])]
        mpiID[int(temp[jobIndx])] += 1
        #temp = [float(i) for i in temp]
        if temp[metric] == '-nan' or temp[metric] == 'nan':
            temp[metric] = 0
        if float(temp[metric]) > 2e9:
            temp[metric] = 0
        if terminalID in switchTrafficDataTemp:
            if switchTrafficDataTemp[terminalID] > float(temp[metric]):
                switchTrafficDataTemp[terminalID] = float(temp[metric])
        else:
            switchTrafficDataTemp[terminalID] = float(temp[metric])
    inFile.close()
    return switchTrafficDataTemp


# Function for importing topology connections
def funcImportTopologyConnections(filePath, netModel):
    nodes = []
    connections = []
    if netModel == "sfly" or netModel == "ffly":
        # Input Router Connections file
        f = open(filePath + '/slimfly-config-router-connections', 'rb')
        data = csv.reader(f)
        for row in data:
            routers = row

        # Input Terminal Connections file
        f = open(filePath + '/slimfly-config-terminal-connections', 'rb')
        data = csv.reader(f)
        for row in data:
            terminals = row

        # Delete extra space generated by extra comma at end of file
        if routers[-1] == ' ':
            del routers[-1]
        if terminals[-1] == ' ':
            del terminals[-1]

        # Convert string list to integer list
        routers = map(int, routers)
        terminals = map(int, terminals)

        # Concatenate all connections lists
        connections = routers+terminals
    elif "dfly" in netModel:
        if netModel == "ddfly":
            f = open('example-layout-input-files/dragonfly/dfdally3200-connections.csv', 'rb')
        else:
            f = open('example-layout-input-files/dragonfly/dfly3072-connections.csv', 'rb')
        data = csv.reader(f)
        up = []
        for row in data:
            up.append(int(row[0]))
            up.append(int(row[1]))

        # Concatenate all connections lists
        connections = up
    else:
        # Input Down Connections file
        f = open(filePath + '/fattree-config-down-connections', 'rb')
        data = csv.reader(f)
        for row in data:
            down = row

        # Delete extra space generated by extra comma at end of file
        if down[-1] == ' ':
            del down[-1]
        # Convert string list to integer list
        down = map(int, down)

        # Input Up Connections file
        f = open(filePath + '/fattree-config-up-connections', 'rb')
        data = csv.reader(f)
        for row in data:
            up = row

        # Delete extra space generated by extra comma at end of file
        if up[-1] == ' ':
            del up[-1]

        # Convert string list to integer list
        up = map(int, up)

        # Concatenate all connections lists
        connections = up+down

    # Construct list of unique nodes from connections list
    for i in connections:
        if i not in nodes:
            nodes.append(i)
    nodes = sorted(nodes, key=int)
    return nodes, connections


# Function for determining the simulation workload
def funcGetWorkload(filePath):
    workload = ''
    if 'trace-cr' in filePath:
        workload = workload+'cr'
    if 'trace-mg' in filePath:
        workload = workload+'mg'
    if 'trace-amg' in filePath:
        workload = workload+'amg'
    if 'bkgnd-mnist' in filePath:
        workload = workload+'mnist'
    if 'bkgnd-cifar' in filePath:
        workload = workload+'cifar'
    if 'bkgnd-hf' in filePath:
        workload = workload+'hf'
    return workload


# Function for determining the Net Model
def funcGetNetModel(filePath):
    global reps
    global numRouters
    global numLocal
    global numGlobal
    global numTerminals
    global k
    global totalTerminals
    global numSwitches
    if "sfly" in filePath:
        netModel = "sfly"
        systemSize = 3042
        reps = 338              # Number of model-net reps (from network config file)
        numRouters = 13         # q value. Number of routers per group and number of groups per subgraph
        numLocal = 6           # Number of levels/layers of switches in the slim fly
        numGlobal = 13           # Number of planes/rails in sumulation (currently only support one)
        numTerminals = 9       # Number of terminals/modelnet_slimfly's per repetition (from network config file)
        k = numLocal + numGlobal + numTerminals     # Switch radix
        totalTerminals = numTerminals * reps
    elif "ffly" in filePath:
        netModel = "ffly"
        systemSize = 3042
        reps = 338              # Number of model-net reps (from network config file)
        numRouters = 13         # q value. Number of routers per group and number of groups per subgraph
        numLocal = 6           # Number of levels/layers of switches in the slim fly
        numGlobal = 13           # Number of planes/rails in sumulation (currently only support one)
        numTerminals = 9       # Number of terminals/modelnet_slimfly's per repetition (from network config file)
        k = numLocal + numGlobal + numTerminals     # Switch radix
        totalTerminals = numTerminals * reps
    elif "dfly" in filePath:
        if "ddfly" in filePath:
            netModel = "ddfly"
            systemSize = 3200
        else:
            netModel = "dfly"
            systemSize = 3072
    elif "ftree":
        k = 36                  # Switch radix
        reps = 180              # Number of model-net reps (from network config file)
        numLevels = 3           # Number of levels/layers of switches in the fat-tree
        numPlanes = 1           # Number of planes/rails in sumulation (currently only support one)
        numTerminals = 18       # Number of terminals/modelnet_fattree's per repetition (from network config file)
        totalTerminals = 180*numTerminals
        numSwitches = reps*numLevels
        if "ftree2" in filePath:
            netModel = "ftree2"
            systemSize = 3240
        else:
            netModel = "ftree"
            systemSize = 3240
    return netModel, systemSize


if graphType == 'combined':
    dirStringList = [ str(directory) for directory in dir_list ]

    uniqueNetModels = []
    netModelsList = []
    for filePath in dirStringList:
        netModel, systemSize = funcGetNetModel(filePath)
        if netModel not in uniqueNetModels:
            uniqueNetModels.append(netModel)
            netModelsList.append([ filePathInstance for filePathInstance in dirStringList if '/'+netModel+'-' in filePathInstance])

    G = [nx.Graph() for x in range(len(netModelsList))]

    # Loop over all network topologies
    for netModelNum in range(len(netModelsList)):
        # Loop over all simulations of the given type of network topology
        for filePath in netModelsList[netModelNum]:
            print "filePath: "+filePath
            netModel, systemSize = funcGetNetModel(filePath)

            # Get a label for the given simulation's workloads to add to the attribute name
            workload = funcGetWorkload(filePath)

            TrafficData = [dict() for x in range(len(metricStringList))]

            # Perform graph initialization only for the first sim in the given network topology
            if filePath == netModelsList[netModelNum][0]:
                # Generate list of nodes and connections for given topology
                connections = []
                nodes = []
                nodes, connections = funcImportTopologyConnections(filePath, netModel)

                # Create Matplotlib figure
                fig, ax = plt.subplots(figsize=(w, h))

                # Create graph
                funcConstructGraph(G[netModelNum], nodes, netModel, systemSize, connections)

            # Collect all simulation metrics in data structure
            for metIter in range(len(metricStringList)):
                metricString = metricStringList[metIter]
                if metricString == "traffic":
                    metric = 5
                if metricString == "end-time":
                    metric = 6
                if metricString == "latency":
                    metric = 3
                if metricString == "hops":
                    metric = 6
                if metricString == "busy-time":
                    metric = 7
                # Both terminals and switches have busy time so we need to make calls for the switches here
                if metricString == "busy-time" or metricString == "traffic":
                    TrafficData[metIter] = funcImportTrafficData(filePath, netModel, TrafficData[metIter], metricString)
                # Make calls to collect terminal data
                if metricString == "end-time":
                    TrafficData[metIter] = funcImportMpiStatsData(filePath, netModel, TrafficData[metIter], metric)
                else:
                    TrafficData[metIter] = funcImportMsgStatsData(filePath, netModel, TrafficData[metIter], metric)
                # Apply the traffic attribute to each node
                nx.set_node_attributes(G[netModelNum], workload+metricStringList[metIter], TrafficData[metIter])


elif graphType == 'single':
    G = [nx.Graph() for x in range(len(dir_list))]

    # Loop over all directories in provided input directory
    for fileNum in range(len(dir_list)):
        filePath = str(dir_list[fileNum])

        print "filePath: "+filePath
        netModel, systemSize = funcGetNetModel(filePath)
        TrafficData = [dict() for x in range(len(metricStringList))]

        # Generate list of nodes and connections for given topology
        connections = []
        nodes = []
        nodes, connections = funcImportTopologyConnections(filePath, netModel)

        # Create Matplotlib figure
        fig, ax = plt.subplots(figsize=(w, h))

        # Create graph
        funcConstructGraph(G[fileNum], nodes, netModel, systemSize, connections)

        # Collect all simulation metrics in data structure
        for metIter in range(len(metricStringList)):
            metricString = metricStringList[metIter]
            if metricString == "traffic":
                metric = 5
            if metricString == "end-time":
                metric = 6
            if metricString == "latency":
                metric = 3
            if metricString == "hops":
                metric = 6
            if metricString == "busy-time":
                metric = 7
            if metricString == "busy-time" or metricString == "traffic":
                TrafficData[metIter] = funcImportTrafficData(filePath, netModel, TrafficData[metIter], metricString)
            elif metricString == "end-time":
                TrafficData[metIter] = funcImportMpiStatsData(filePath, netModel, TrafficData[metIter], metric)
            else:
                TrafficData[metIter] = funcImportMsgStatsData(filePath, netModel, TrafficData[metIter], metric)
            # Apply the traffic attribute to each node
            nx.set_node_attributes(G[fileNum], metricStringList[metIter], TrafficData[metIter])

        funcConstructLayout(plotType, G[fileNum])
        funcSaveFigure(systemSize, plotType, netModel)
        funcSaveGraph(G[fileNum], filePath, netModel, systemSize)

# Merge the graphs into one
G = nx.disjoint_union_all(G)
funcConstructLayout(plotType, G)
funcSaveFigure(systemSize, plotType, netModel)
funcSaveGraph(G, str(rootDir), "all-combined", "3k")
