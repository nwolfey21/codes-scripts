'''
===================
Slim Fly Graph Plot
===================
This script parses connection files for the slim fly model to visualize
the simulated slim fly network layout
Connection files are generated and dumped inside the lp-io-dir if you set
'#define SLIMFLY_CONNECTIONS 1' at the top of src/networks/model-net/slimfly.c
Currently only single rail/plane configurations are supported
Saves the generated plot to current working directory
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
parser.add_argument('--lp-io-dir', action='store', dest='lpIoDir',
                    help='path to the directory containing all modelnet sim data.\nIt can be the lp-io directory for one run or a higher level directory with many lp-io dirs within')
parser.add_argument('--visualize-sim', action='store_true', default=False, dest='pltIndividually',
                    help='If selected, plots each figure individually')
results = parser.parse_args()
print 'lp io dir          =', results.lpIoDir
#rootdir = Path(lpIoDir)
#dir_list = [f for f in rootdir.glob('**/*') if f.is_dir()]

numIter = 100    #Number of iterations for force directed and spring layouts

# Visualization Params
sf_type = 1             # Options: 0=singl-rail slim fly, 1=dual-rail slim fly (fit fly)
systemSize = 3042        # Options: 150, 3042
plotType = "grid"    # Options: grid, spring, circular, force, random, shell
exportGEXF = 1          # If true, exports the network in the Graph Exchange XML format (GEXF) for reading into Gephi or other application
exportGRAPHML = 0          # If true, exports the network in the Graph Exchange XML format (GEXF) for reading into Gephi or other application
w = 20                  # Width of figure
h = w/2                 # Height of figure
edgeTerminalWeight = 1    # Weight to apply to terminal connection
edgeLocalWeight = 2    # Weight to apply to local connection
edgeGlobalWeight = 1    # Weight to apply to global connection

# Simulation Params
if systemSize == 150:
    filePath = 'example-layout-input-files/slimfly/'
    reps = 50              # Number of model-net reps (from network config file)
    numRouters = 5         # q value. Number of routers per group and number of groups per subgraph
    numLocal = 2           # Number of levels/layers of switches in the slim fly
    numGlobal = 5           # Number of planes/rails in sumulation (currently only support one)
    numTerminals = 3       # Number of terminals/modelnet_slimfly's per repetition (from network config file)
    k = numLocal + numGlobal + numTerminals     # Switch radix
else:
    filePath = 'example-layout-input-files/slimfly/'
    filePath = '../../fit-fly-results/ffly-3042nodes-minimal-1000000end-65536vc-12.5GBps-CONT-trace-amg1k/'
    filePath = '../../codes-nemo-results/hybrid-bugfix2/ffly-3042nodes-adaptive-congestion-100000000end-65536vc-12.5GBps-CONT-trace-mg1k/'
    filePath = '../../codes-nemo-results/hybrid-bugfix2/sfly-3042nodes-adaptive-none-100000000end-65536vc-12.5GBps-CONT-trace-mg1k/'
    reps = 338              # Number of model-net reps (from network config file)
    numRouters = 13         # q value. Number of routers per group and number of groups per subgraph
    numLocal = 6           # Number of levels/layers of switches in the slim fly
    numGlobal = 13           # Number of planes/rails in sumulation (currently only support one)
    numTerminals = 9       # Number of terminals/modelnet_slimfly's per repetition (from network config file)
    k = numLocal + numGlobal + numTerminals     # Switch radix

#if sf_type == 1:
    #filePath = 'example-layout-input-files/fitfly/'

totalTerminals = numTerminals * reps

# Input Router Connections file
f = open(filePath + 'slimfly-config-router-connections', 'rb')
data = csv.reader(f)
for row in data:
    routers = row

# Input Terminal Connections file
f = open(filePath + 'slimfly-config-terminal-connections', 'rb')
data = csv.reader(f)
for row in data:
    terminals = row

# Extract fattree-switch-traffic file header
inFile = open(filePath+'/slimfly-router-traffic', 'r')
line = inFile.readline()
line = line.strip()
temp = line.replace('# Format','')
temp = temp.replace(' <','')
temp = temp.replace('>',',')
switchTrafficHeader= temp.split(",")
del switchTrafficHeader[-1]

# Parse traffic data
print 'Parsing slimfly-switch-traffic data...'
switchTrafficDataTemp = {}
while True:
    line = inFile.readline()
    if not line: break
    line = line.strip()
    temp = line.split(" ")
    routerID = int(temp[2])
    temp = [float(i) for i in temp[3:]]
    temp = sum(temp)
    switchTrafficDataTemp[routerID+totalTerminals] = temp
inFile.close()

# Extract model-msg-stats file header
inFile = open(filePath+'/slimfly-msg-stats', 'r')
line = inFile.readline()
line = line.strip()
temp = line.replace('# Format','')
temp = temp.replace(' <','')
temp = temp.replace('>',',')
temp = temp.replace('Total Data Size','Data Per Terminal [bytes]')
temp = temp.replace('Total Packet Latency','Aggregate Packet Latency [ns]')
temp = temp.replace('# Flits/','')
temp = temp.replace('hops','Hops')
temp = temp.replace('Busy Time','Terminal Busy Time [us]')
temp = temp.replace('End Time','End Time [ms]')
temp = temp.replace('Packets Generated', 'Packets Generated [1e3]')
temp = temp.replace('Packets finished', 'Packets Finished [1e3]')
msgHeader = temp.split(",")
del msgHeader[-1]
# Parse model-msg-stats data
met = 5
print 'Parsing slimfly-msg-stats data...'
while True:
    line = inFile.readline()
    if not line: break
    line = line.strip()
    temp = line.split(" ")
    terminalID = int(temp[1])
    #temp = [float(i) for i in temp]
    if temp[met] == '-nan' or temp[met] == 'nan':
        takingUpSpace = 1
    else:
        switchTrafficDataTemp[terminalID] = float(temp[met])
inFile.close()

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

# Construct list of unique nodes from connections list
nodes = []
for i in connections:
    if i not in nodes:
        nodes.append(i)
nodes = sorted(nodes, key=int)

# Create Matplotlib figure
fig, ax = plt.subplots(figsize=(w, h))

# Construct graph
G=nx.Graph()
count = 0
for i in nodes:
    G.add_node(i)
    if i < systemSize:
        G.node[i]['viz'] = {'color': {'r': 255, 'g': 0, 'b': 0, 'a': 0.6}}
    elif i >= systemSize and i < systemSize+reps:
        G.node[i]['viz'] = {'color': {'r': 0, 'g': 255, 'b': 0, 'a': 0.6}}
    else:
       G.node[i]['viz'] = {'color': {'r': 0, 'g': 0, 'b': 255, 'a': 0.6}}
for i in range(0,len(connections),2):
    if connections[i]==3380:
        print str(connections[i])+':'+ str(connections[i+1])
        count +=1
    if connections[i+1]==3380:
        print str(connections[i])+':'+ str(connections[i+1])
        count +=1
    # Check if connection is local or global to assign appropriate weight
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
    #if weight == edgeTerminalWeight:
    #    G.edge[connections[i]][connections[i+1]]['viz'] = {'color': {'r': 0, 'g': 0, 'b': 0, 'a': 0.5}}
    #elif weight == edgeGlobalWeight:
    #    G.edge[connections[i]][connections[i+1]]['viz'] = {'color': {'r': 0, 'g': 0, 'b': 0, 'a': 0.5}}
    #else:
    #    G.edge[connections[i]][connections[i+1]]['viz'] = {'color': {'r': 0, 'g': 0, 'b': 0, 'a': 1.0}}
print count

nx.set_node_attributes(G, 'traffic', switchTrafficDataTemp)

# Compute positions in graph
if plotType == "grid":
    pos = {}
    l = w
    n = reps   # We have reps-many routers
    dx = float(float(l)/float(n/2))
    dy = float(float(w)/float(n/2))
    #ds = float(n/4)*dx
    ds = 10
    y = 0
    count = 0
    for s in range(0,2):            # We loop over both subgraphs
        for i in range(0,numRouters):   # We loop over groups in subgraph s
            for j in range(0,numRouters):   # We loop over routers in group i
                x = float(i)*dx + float(s)*ds
                y = float(j)*dy
                pos[totalTerminals + s*(reps/2) + i*numRouters + j] = [x,y]
                count += 1

# Visualize graph
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

# Clean and Save Figure
plt.tight_layout()
fig.savefig('sfly'+str(systemSize)+'-layout-'+plotType+'.pdf', dpi=320, facecolor='w',
    edgecolor='w', orientation='portrait', papertype=None,
    format=None, transparent=False, bbox_inches=None,
    pad_inches=0.25, frameon=None)

# Save graph in GEXF format
if sf_type == 1:
    modelName = 'ffly'
else:
    modelName = 'sfly'
if exportGEXF == 1:
    nx.write_gexf(G,filePath+modelName+str(systemSize)+'.gexf')
if exportGRAPHML == 1:
    nx.write_graphml(G,modelName+str(systemSize)+'.graphml')
