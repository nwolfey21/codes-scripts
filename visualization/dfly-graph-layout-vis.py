'''
===================
Dragonfly Graph Plot
===================
This script parses connection files for the dragonfly model to visualize
the simulated dragonfly network layout
Connection files are generated and dumped inside the lp-io-dir if you set
'#define DRAGONFLY_CONNECTIONS 1' at the top of src/networks/model-net/dragonfly-custom.C
Currently only single rail/plane configurations are supported
Saves the generated plot to current working directory
'''
import networkx as nx
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import csv
import pdb

numIter = 1    #Number of iterations for force directed and spring layouts

# Visualization Params
systemSize = 3072        # Options: 150, 3042
plotType = "spring"    # Options: grid, spring, circular, force, random, shell
exportGEXF = 1          # If true, exports the network in the Graph Exchange XML format (GEXF) for reading into Gephi or other application
w = 20                  # Width of figure
h = w/2                 # Height of figure


# Simulation Params
filePath = 'example-layout-input-files/dragonfly/dfly3072-connections.csv'
reps = 338              # Number of model-net reps (from network config file)
numRouters = 13         # q value. Number of routers per group and number of groups per subgraph
numLocal = 6           # Number of levels/layers of switches in the dragonfly
numGlobal = 13           # Number of planes/rails in sumulation (currently only support one)
numTerminals = 9       # Number of terminals/modelnet_dragonfly's per repetition (from network config file)
k = numLocal + numGlobal + numTerminals     # Switch radix

totalTerminals = numTerminals * reps

# Input Up Connections file
f = open(filePath, 'rb')
data = csv.reader(f)
up = []
for row in data:
    up.append(int(row[0]))
    up.append(int(row[1]))

# Concatenate all connections lists
connections = up

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
    if connections[i] == 9423:
        print connections[i+1]

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
    nx.draw_networkx_nodes(G,pos,node_size=100)
    nx.draw_networkx_edges(G,pos)
    #nx.draw(G,pos)
    nx.draw_networkx_labels(G,pos)
# Spring Layout
if plotType == "spring":
    pos=nx.spring_layout(G,iterations=numIter,scale=1)
    nx.draw(G,pos)
    nx.draw_networkx_labels(G,pos)
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
fig.savefig('dfly'+str(systemSize)+'-layout-'+plotType+'.pdf', dpi=320, facecolor='w',
    edgecolor='w', orientation='portrait', papertype=None,
    format=None, transparent=False, bbox_inches=None, 
    pad_inches=0.25, frameon=None)

# Save graph in GEXF format
if exportGEXF == 1:
    nx.write_gexf(G,'dfly'+str(systemSize)+'.gexf')
