import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import argparse
import pdb

# Parse commandline arguments
parser = argparse.ArgumentParser()
parser.add_argument('--input-file-path', action='store', dest='inFilePath', nargs='+', type=str,
                    help='space separated list of files containing score data')
parser.add_argument('--output-file-path', action='store', dest='outFilePath', nargs='+', type=str,
                    help='space separated list of files containing score data')
results = parser.parse_args()
print 'input file path        =', results.inFilePath[0]
print 'output file path        =', results.outFilePath[0]

inFilePath = results.inFilePath[0]
outFilePath = results.outFilePath[0]
matplotlib.rcParams.update({'font.size': 10})
figHeight = 4.0
figWidth = 5.0
markerSize = 6
lineWidth= 1.2
lineColor = ['red','limegreen','blue','darkred','darkgreen','darkblue','salmon','lightgreen','lightskyblue','yellow']
#scoresIndvFTFF.csv
#lineColor = ['salmon','orangered','darkred','lightskyblue','dodgerblue','darkblue','yellow']
#markers = ['s','p','*','s','p','*','v','x','+','o']
lineColor = ['salmon','darkred','limegreen','darkgreen','lightskyblue','blue','darkblue','yellow']
#lineColor = ['red','blue','limegreen','darkgreen','lightskyblue','blue','darkblue','yellow']
markers = ['x','+','o','s','*','p','v','x','+','o']
lineStyle = ['-','-','-','-','--','-','-','-','--','-']

inFile = open(inFilePath,'r')
xAxis = inFile.readline()
xAxis = xAxis.strip()
xAxis = xAxis.split(",")
if type(xAxis[1]) == int:
    xAxis = map(float,xAxis[-len(xAxis):])
    xAxisLabels = xAxis
else:
    xAxisLabels = xAxis[-len(xAxis)+1:]
    xAxis = [(x+1) * 0.25 for x in range(len(xAxis)-1)]
    #xAxis = range(0.1,1.0,len(xAxis)-1)
data = []
while True:
    line = inFile.readline()
    if not line: break
    line = line.strip()
    data.append(line.split(","))
inFile.close()

xAxis = [int(t*100) for t in xAxis]
fig, ax = plt.subplots(figsize=(figWidth, figHeight))
for i in range(len(data)):
    ax.plot(xAxis, data[i][-len(data[i])+1:], ls=lineStyle[i], c=lineColor[i], markerfacecolor="None", markeredgecolor=lineColor[i], markeredgewidth=1, marker=markers[i], lw=lineWidth, markersize=markerSize)

ymin, ymax = ax.get_ylim()
#xmin, xmax = ax.get_xlim()
#dx = (xmax-xmin) / len(data)
dy = (ymax-ymin) / len(data)
#ax.annotate(data[2][0]+', '+data[4][0], xy=(xAxis[-2],data[4][-2]),xytext=(xAxis[-4],float(data[4][-2]) - dy/2), arrowprops=dict(facecolor='black', shrink=0.01, width=0.1, headwidth=0.1))
#ax.annotate(data[0][0]+', '+data[1][0]+', '+data[3][0]+', '+data[5][0], xy=(xAxis[-2],data[5][-2]),xytext=(xAxis[-5],float(data[5][-2]) + dy/2), ha="left", arrowprops=dict(arrowstyle='-', facecolor='black'))
#ax.annotate(data[0][0]+', '+data[3][0]+', '+data[5][0], xy=(xAxis[-2],data[5][-2]),xytext=(xAxis[-5],float(data[5][-2]) + dy/2), ha="left", arrowprops=dict(arrowstyle='-', facecolor='black'))

ax.legend([row[0] for row in data], ncol=1, fontsize=8, loc='lower left')
#ax.legend([row[0] for row in data], fontsize=8, loc='lower left', bbox_to_anchor=(0.05,0.5))
#ax.annotate([row[0] for row in data], )
ax.yaxis.grid(color='gray', linestyle='dashed')
#ax.set_yscale("log")
#ax.set_xscale("log")
ax.set_xticks(xAxis)
ax.set_xticklabels(xAxis,rotation=75)
ax.set_xticklabels(xAxisLabels,rotation=75)
#plt.gca().set_ylim(top=105)
plt.gca().set_xlim(right=205)
ax.set_ylabel('Average Score')
ax.set_ylabel('End Time [ns]')
#ax.set_ylabel('Normalized End Time')
ax.set_xlabel('Offered Load [% link speed]')
#ax.set_xlabel('Workload Set')
#ax.set_xlabel('Workload')
#ax.set_xlabel('Network Topology')
plt.tight_layout()
plt.tight_layout(pad=0.3)
#plt.show()
fig.savefig(outFilePath+'.eps', dpi=320, facecolor='w',
            edgecolor='w', orientation='portrait', format='eps')

