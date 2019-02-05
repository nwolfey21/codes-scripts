#TRACE_DIR1=/Users/Wolfman/Dropbox/RPI/Research/Networks/codes-nemo-results/heterogeneous/aggr-msgs/dfly-trace-amg1k-1ms-n3456-adaptive-1csfbkgnd-30mintvl-1000000tintvl-3456ranks-10000mpt-23Bszmsg
#TRACE_DIR2=/Users/Wolfman/Dropbox/RPI/Research/Networks/codes-nemo-results/sfly-trace-amg1k-1ms-n3042-minimal-heterogeneousbkgnd-10mintvl-1000000tintvl-3042ranks-10000mpt
#TRACE_DIR3=/Users/Wolfman/Dropbox/RPI/Research/Networks/codes-nemo-results/ftree-trace-amg1k-1ms-n3564-static-heterogeneousbkgnd-10mintvl-1000000tintvl-3564ranks-10000mpt
#TRACE_DIR1=/home/noah/Dropbox/RPI/Research/Networks/codes-nemo-results/vis-staging/sfly-3042nodes-minimal-1000000end-CONT-trace-conv4096
#TRACE_DIR1=/home/noah/Dropbox/RPI/Research/Networks/codes-nemo-results/vis-staging/sfly-3042nodes-minimal-1000000end-CONT-trace-conv4096
#EXE=cdf-model-msg-stats.py
#GROUP_DIR=/home/noah/Dropbox/RPI/Research/Networks/codes-nemo-results/chip-scaling/1ms
#STUDY=chip-scaling
#NUM_RUNS=4
#MODEL_LIST=("sfly")
#NODES=("3042")
#TIME=2000000
#EXE_STRING="python "${EXE}" --lp-io-dir"
EXE=cdf-model-msg-stats.py
GROUP_DIR=/home/noah/Dropbox/RPI/Research/Networks/codes-nemo-results/chip-scaling/1ms
STUDY=heterogeneous
NUM_RUNS=2
MODEL_LIST=("dfly" "dfly")
NODES=("3072" "3072")
TIME=2000000
EXE_STRING="python "${EXE}" --lp-io-dir"
for n in $( seq 1 ${NUM_RUNS} );  do
    if (( ${#MODEL_LIST[@]} == 1 ));then
        MODEL=${MODEL_LIST[0]}
    else
        MODEL=${MODEL_LIST[n]}
    fi
    if [ "${MODEL}" == "sfly" ];then
        if [ ${STUDY} == "chip-scaling" ];then
            CHIPS=("761" "1521" "3042" "6084" "12168")
            SPIKES=("10000")
        elif [ ${STUDY} == "spike-scaling" ];then
            CHIPS=("3042")
            SPIKES=("2500" "5000" "10000" "20000" "40000" "80000")
        else
            CHIPS=("3042")
            SPIKES=("10000")
        fi
    elif [ "${MODEL}" == "dfly" ];then
        if [ ${STUDY} == "chip-scaling" ];then
	        CHIPS=("768" "1536" "3072" "6144" "12288")
            SPIKES=("10000")
        elif [ ${STUDY} == "spike-scaling" ];then
            CHIPS=("3072")
            SPIKES=("2500" "5000" "10000" "20000" "40000" "80000")
        else
            CHIPS=("3072")
            SPIKES=("10000")
        fi
    elif [ "${MODEL}" == "ftree" ];then
        if [ ${STUDY} == "chip-scaling" ];then
            CHIPS=("810" "1620" "3240" "6480" "12960")
            SPIKES=("10000")
        elif [ ${STUDY} == "spike-scaling" ];then
            CHIPS=("3240")
            SPIKES=("2500" "5000" "10000" "20000" "40000" "80000")
        else
            CHIPS=("3240")
            SPIKES=("10000")
        fi
    fi
    EXE_STRING+=" "${MODEL}
    if (( ${#NODES[@]} == 1 ));then
        EXE_STRING+="-"${NODES[0]}
    else
        EXE_STRING+="-"${NODES[n]}
    fi
    if [ "${MODEL}" == "sfly" ];then
        EXE_STRING+="-minimal-"${TIME}
    elif [ "${MODEL}" == "dfly" ];then
        EXE_STRING+="-adaptive-"${TIME}
    elif [ "${MODEL}" == "ftree" ];then
        EXE_STRING+="-static-"${TIME}
    fi
    EXE_STRING+="-CONT-bkgnd-hf-10mintvl-2000000tintvl"
    if (( ${#CHIPS[@]} == 1 ));then
        EXE_STRING+="-"${CHIPS[0]}"ranks"
    else
        EXE_STRING+="-"${CHIPS[n]}"ranks"
    fi
    if (( ${#SPIKES[@]} == 1 ));then
        EXE_STRING+="-"${SPIKES[0]}"mpt"
    else
        EXE_STRING+="-"${SPIKES[n]}"mpt"
    fi
    EXE_STRING+="-8Bszmsg"
done
echo $EXE_STRING
exit
SIM_LABEL1=761ranks
SIM_LABEL2=1521ranks
SIM_LABEL3=3042ranks
SIM_LABEL4=6084ranks
MODEL_TYPE1=2
MODEL_TYPE2=2
MODEL_TYPE3=2
MODEL_TYPE4=2
NUM_NODES1=3042
NUM_NODES2=3042
NUM_NODES3=3042
NUM_NODES4=3042
SWITCH_RADIX1=36
SWITCH_RADIX2=36
SWITCH_RADIX3=36
SWITCH_RADIX4=36
NUM_BINS=100
DATA_FILE=3
if [ ${DATA_FILE} == 0 ];then
    METRIC="2 3 4 5 6 7"
elif [ ${DATA_FILE} == 3 ];then
    METRIC="2 3 4 5 6"
else
    METRIC="3"
fi
SAVE=--save
AXIS_FLAG=0
ANNO_FLAG=0

EXE=cdf-model-msg-stats.py

echo python ${EXE} --lp-io-dir ${TRACE_DIR1} ${TRACE_DIR2} ${TRACE_DIR3} --sim-labels ${SIM_LABEL1} ${SIM_LABEL2} ${SIM_LABEL3} \
    --num-bins ${NUM_BINS} --model-type ${MODEL_TYPE1} ${MODEL_TYPE2} ${MODEL_TYPE3} --num-nodes ${NUM_NODES1} ${NUM_NODES2} ${NUM_NODES3} \
    --switch-radix ${SWITCH_RADIX1} ${SWITCH_RADIX2} ${SWITCH_RADIX3} --data-file ${DATA_FILE} --metric ${METRIC} ${SAVE}
python ${EXE} --lp-io-dir ${TRACE_DIR1} ${TRACE_DIR2} ${TRACE_DIR3} ${TRACE_DIR4} --sim-labels ${SIM_LABEL1} ${SIM_LABEL2} ${SIM_LABEL3} ${SIM_LABEL4} \
    --num-bins ${NUM_BINS} --model-type ${MODEL_TYPE1} ${MODEL_TYPE2} ${MODEL_TYPE3} ${MODEL_TYPE4} --num-nodes ${NUM_NODES1} ${NUM_NODES2} ${NUM_NODES3} ${NUM_NODES4} \
    --switch-radix ${SWITCH_RADIX1} ${SWITCH_RADIX2} ${SWITCH_RADIX3} ${SWITCH_RADIX4} --data-file ${DATA_FILE} --metric ${METRIC} ${SAVE}
