TRACE_DIR1=/Users/Wolfman/Dropbox/RPI/Research/Networks/codes-nemo-results/heterogeneous/aggr-msgs/dfly-trace-amg1k-1ms-n3456-adaptive-1csfbkgnd-30mintvl-1000000tintvl-3456ranks-10000mpt-23Bszmsg
TRACE_DIR2=/Users/Wolfman/Dropbox/RPI/Research/Networks/codes-nemo-results/sfly-trace-amg1k-1ms-n3042-minimal-heterogeneousbkgnd-10mintvl-1000000tintvl-3042ranks-10000mpt
TRACE_DIR3=/Users/Wolfman/Dropbox/RPI/Research/Networks/codes-nemo-results/ftree-trace-amg1k-1ms-n3564-static-heterogeneousbkgnd-10mintvl-1000000tintvl-3564ranks-10000mpt
SIM_LABEL1=dragonfly
SIM_LABEL2=slimfly
SIM_LABEL3=fat-tree
MODEL_TYPE1=1
MODEL_TYPE2=2
MODEL_TYPE3=0
NUM_NODES1=3456
NUM_NODES2=3042
NUM_NODES3=3564
SWITCH_RADIX1=42
SWITCH_RADIX2=36
SWITCH_RADIX3=36
NUM_BINS=100
DATA_FILE=0
METRIC="2 3 4 5 6 7"
#METRIC=3
SAVE=--save

EXE=vis-fattree-msg-stats.py

echo python ${EXE} --lp-io-dir ${TRACE_DIR1} ${TRACE_DIR2} ${TRACE_DIR3} --sim-labels ${SIM_LABEL1} ${SIM_LABEL2} ${SIM_LABEL3} \
    --num-bins ${NUM_BINS} --model-type ${MODEL_TYPE1} ${MODEL_TYPE2} ${MODEL_TYPE3} --num-nodes ${NUM_NODES1} ${NUM_NODES2} ${NUM_NODES3} \
    --switch-radix ${SWITCH_RADIX1} ${SWITCH_RADIX2} ${SWITCH_RADIX3} --data-file ${DATA_FILE} --metric ${METRIC} ${SAVE}
python ${EXE} --lp-io-dir ${TRACE_DIR1} ${TRACE_DIR2} ${TRACE_DIR3} --sim-labels ${SIM_LABEL1} ${SIM_LABEL2} ${SIM_LABEL3} \
    --num-bins ${NUM_BINS} --model-type ${MODEL_TYPE1} ${MODEL_TYPE2} ${MODEL_TYPE3} --num-nodes ${NUM_NODES1} ${NUM_NODES2} ${NUM_NODES3} \
    --switch-radix ${SWITCH_RADIX1} ${SWITCH_RADIX2} ${SWITCH_RADIX3} --data-file ${DATA_FILE} --metric ${METRIC} ${SAVE}
