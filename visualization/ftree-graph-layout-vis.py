'''
===================
Fat-Tree Graph Plot
===================
This script parses connection files for the fat-tree model to visualize
the simulated fat-tree network layout
Connection files are generated and dumped inside the lp-io-dir if you set
'#define FATTREE_CONNECTIONS 1' at the top of src/networks/model-net/fattree.c
Currently only single rail/plane configurations are supported
Saves the generated plot to current working directory
'''
import networkx as nx
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import csv
import pdb

filePath = '/home/noah/Dropbox/RPI/Research/Networks/codes-nemo-results/heterogeneous/hetero-nonaggr-updated2-endtime-opt-newmodels/ftree-3240nodes-static-1000000end-CONT-bkgnd-hf-10mintvl-1000000tintvl-3240ranks-10000mpt-8Bszmsg/'
numIter = 500    #Number of iterations for force directed and spring layouts

# Simulation Params
k = 36                  # Switch radix
reps = 180              # Number of model-net reps (from network config file)
numLevels = 3           # Number of levels/layers of switches in the fat-tree
numPlanes = 1           # Number of planes/rails in sumulation (currently only support one)
numTerminals = 18       # Number of terminals/modelnet_fattree's per repetition (from network config file)
# Plot Params
plotType = "layered"    # Options: layered, spring, circular, force, random, shell, graphviz
w = 80                  # Width of figure
h = w/2                 # Height of figure

# Input Down Connections file
f = open(filePath + 'fattree-config-down-connections', 'rb')
data = csv.reader(f)
for row in data:
    down = row

# Delete extra space generated by extra comma at end of file
if down[-1] == ' ':
    del down[-1]
# Convert string list to integer list
down = map(int, down)

# Input Up Connections file
f = open(filePath + 'fattree-config-up-connections', 'rb')
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
for i in range(0,len(connections),2):
    G.add_edge(connections[i],connections[i+1])

# Compute LP_type IDs
terminalIds = []
switchIds = []
terminalIds =  range(0,numTerminals*reps)
for i in range(numLevels*numPlanes):
    switchIds.append(range(numTerminals*reps + i*reps,numTerminals*reps + (i+1)*reps))
terminalIds = sorted(terminalIds, key=int)

# Compute positions in graph
pos = {}
l = w
n = len(terminalIds)
dx = float(float(l)/float(n))
y = 0
count = 0
for i in range(0,len(terminalIds)):
    x = float(i)*dx
    pos[terminalIds[i]] = [x,y]
    count += 1
for j in range(0,numLevels*numPlanes):
    n = len(switchIds[j])
    dx = float(float(l)/float(n))
    if j == 5 or j == 2:
        dx = dx * 1.5
    if j<3:
        y = j + 1
    else:
        y = numLevels - j - 1
    for i in range(0,len(switchIds[j])):
        x = float(i)*dx
        pos[switchIds[j][i]] = [x,y]
    count += 1

# Visualize graph
# Standard multi-level tree layout
if plotType == "layered":
    nx.draw(G,pos)
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
# Graphviz Layout
if plotType == "graphviz":
    nx.draw_graphviz(G)

# Clean and Save Figure
plt.tight_layout()
fig.savefig('fat-tree-layout-'+plotType+'.pdf', dpi=320, facecolor='w',
    edgecolor='w', orientation='portrait', papertype=None,
    format=None, transparent=False, bbox_inches=None, 
    pad_inches=0.25, frameon=None)