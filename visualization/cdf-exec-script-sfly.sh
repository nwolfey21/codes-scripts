CPU=amg
#METRIC=("3" "6" "3") #Options: 2=terminal bytes transferred, 3=switch link traffic or avg packet latency (Depends on file), 6=avg hops, 7=terminal busy time
METRIC=("3")
#FILE=("0" "0" "2")
FILE=("2") #Options: 0=model level msg stats, 2=switch link traffic, 1=switch busy time
LOG= #--log
#PLOT_LAYOUT=("cdf" "line-std" "line-sorted" "heatmap")
PLOT_LAYOUT=("line-sorted")
FIG_HEIGHT=2.5     #oldCDF=3, homo=3
FIG_WIDTH=5      #oldCDF=5, homo=4.5
FONT_SIZE=8      #homo=10
TEST=all-amg-none

for cpu in ${CPU[@]};do
    for layout in ${PLOT_LAYOUT[@]};do
        OUTPUT_DIR=/home/noah/Dropbox/RPI/Research/Networks/codes-nemo-results/vis-staging/$layout
        count=-1
        for met in ${METRIC[@]};do
            ((count++))
            f=${FILE[$count]}

            if [ "${f}" == 2 ];then
                LOG=
                level=links
            elif [ "${met}" == 3 ];then
                LOG=
                level=links
            else
                LOG=
                level=links
            fi

            if [ ${TEST} == 1 ];then
                python cdf-model-msg-stats.py --test-dir \
                    ../../fit-fly-results/synthetic-comparison-100msgs-allLoads-4kPacketSize-100kbBuffSize/ftree-3240nodes-static-none-1500000000end-102400vc-12.5GBps-synthetic-traffic3-load1.50-payloadsize256 \
                    ../../fit-fly-results/synthetic-comparison-100msgs-allLoads-4kPacketSize-100kbBuffSize/ftree2-3240nodes-static-adaptive-1500000000end-102400vc-12.5GBps-synthetic-traffic3-load1.50-payloadsize256 \
                    ../../fit-fly-results/synthetic-comparison-100msgs-allLoads-4kPacketSize-100kbBuffSize/ftree-3240nodes-static-none-1500000000end-102400vc-12.5GBps-synthetic-traffic3-load1.75-payloadsize256 \
                    ../../fit-fly-results/synthetic-comparison-100msgs-allLoads-4kPacketSize-100kbBuffSize/ftree2-3240nodes-static-adaptive-1500000000end-102400vc-12.5GBps-synthetic-traffic3-load1.75-payloadsize256 \
                    ../../fit-fly-results/synthetic-comparison-100msgs-allLoads-4kPacketSize-100kbBuffSize/ftree-3240nodes-static-none-1500000000end-102400vc-12.5GBps-synthetic-traffic3-load2.00-payloadsize256 \
                    ../../fit-fly-results/synthetic-comparison-100msgs-allLoads-4kPacketSize-100kbBuffSize/ftree2-3240nodes-static-adaptive-1500000000end-102400vc-12.5GBps-synthetic-traffic3-load2.00-payloadsize256 \
                    --num-bins 1000 --save --model-type 0 0 0 0 0 0 --num-nodes 3240 3240 3240 3240 3240 3240 --switch-radix 36 36 36 36 36 36 \
                    --axis-limits --data-file $f --metric $met $LOG --out-file-postfix fitfly-test \
                    --sim-labels 1.5 1.5 1.75 1.75 2.0 2.0 \
                    --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                    --fig-font-size $FONT_SIZE --collection-level $level
            elif [ ${TEST} == 2 ];then
                OUTPUT_DIR=${OUTPUT_DIR}/mnist
                python cdf-model-msg-stats.py --test-dir \
                    ../../codes-nemo-results/vis-staging/mnist/dfly-3072nodes-adaptive-1000000end-CONT-bkgnd-mnist-10mintvl-1000000tintvl-1234ranks-0mpt-8Bszmsg \
                    ../../codes-nemo-results/vis-staging/mnist/ddfly-3200nodes-adaptive-none-20000000end-65536vc-12.5GBps-CONT-bkgnd-mnist-10mintvl-20000000tintvl-1234ranks-0mpt-8Bszmsg-0agg \
                    ../../codes-nemo-results/vis-staging/mnist/ftree-3240nodes-static-1000000end-CONT-bkgnd-mnist-10mintvl-1000000tintvl-1234ranks-0mpt-8Bszmsg \
                    ../../codes-nemo-results/vis-staging/mnist/sfly-3042nodes-adaptive-none-20000000end-65536vc-12.5GBps-CONT-bkgnd-mnist-10mintvl-20000000tintvl-1234ranks-0mpt-8Bszmsg-0agg \
                    --num-bins 1000 --save --model-type 1 1 0 2 --num-nodes 3072 3200 3240 3042 --switch-radix 48 36 36 36 \
                    --axis-limits --data-file $f --metric $met $LOG --out-file-postfix fitfly-test \
                    --sim-labels dfly-2D dfly-1D ftree sfly \
                    --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                    --fig-font-size $FONT_SIZE --collection-level $level
            elif [ ${TEST} == 3 ];then
                INPUT_DIR=/home/noah/Dropbox/RPI/Research/Networks/codes-nemo-results/vis-staging/amg
                OUTPUT_DIR=${INPUT_DIR}
                python cdf-model-msg-stats.py --test-dir ${INPUT_DIR} \
                    --num-bins 1000 --save --model-type 1 1 2 0 0 2 --num-nodes 3072 3200 3042 3240 3240 3042 --switch-radix 48 36 36 36 36 36 \
                    --axis-limits --data-file $f --metric $met $LOG --out-file-postfix fitfly-test \
                    --sim-labels dfly-1D dfly-2D ffly ftree1 ftree2 sfly \
                    --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                    --fig-font-size $FONT_SIZE --collection-level $level
            elif [ ${TEST} == 4 ];then
                OUTPUT_DIR=${OUTPUT_DIR}/amg-mnist
                python cdf-model-msg-stats.py --test-dir \
                    ../../codes-nemo-results/vis-staging/amg-mnist/dfly-3072nodes-adaptive-1000000end-heterogeneous-trace-amg1k-bkgnd-mnist-10mintvl-5000000tintvl-1234ranks-0mpt-8Bszmsg \
                    ../../codes-nemo-results/vis-staging/amg-mnist/ddfly-3200nodes-adaptive-none-1000000end-65536vc-12.5GBps-heterogeneous-trace-amg1k-bkgnd-mnist-10mintvl-3000000tintvl-1234ranks-0mpt-8Bszmsg-0agg \
                    ../../codes-nemo-results/vis-staging/amg-mnist/ftree-3240nodes-static-1000000end-heterogeneous-trace-amg1k-bkgnd-mnist-10mintvl-1000000tintvl-1234ranks-0mpt-8Bszmsg \
                    ../../codes-nemo-results/vis-staging/amg-mnist/sfly-3042nodes-adaptive-none-1000000end-65536vc-12.5GBps-heterogeneous-trace-amg1k-bkgnd-mnist-10mintvl-3000000tintvl-1234ranks-0mpt-8Bszmsg-0agg \
                    --num-bins 1000 --save --model-type 1 1 0 2 --num-nodes 3072 3200 3240 3042 --switch-radix 48 36 36 36 \
                    --axis-limits --data-file $f --metric $met $LOG --out-file-postfix fitfly-test \
                    --sim-labels dfly-2D dfly-1D ftree sfly \
                    --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                    --fig-font-size $FONT_SIZE --collection-level $level
            elif [ "${TEST}" == "all-amg-none" ];then
                #LOG=--log
                INPUT_DIR=../../codes-nemo-results/sampling-gen/all-amg-none
                OUTPUT_DIR=${INPUT_DIR}
                python cdf-model-msg-stats.py --test-dir ${INPUT_DIR} \
                    --num-bins 1000 --save --model-type 1 3 0 0 2 --num-nodes 3200 3072 3240 3240 3042 --switch-radix 36 48 36 36 36 \
                    --axis-limits --data-file $f --metric $met $LOG --out-file-postfix fitfly-test \
                    --sim-labels dfly-1D dfly-2D ftree1 ftree2 sfly \
                    --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                    --fig-font-size $FONT_SIZE --collection-level $level
            elif [ "${TEST}" == "dfly-traffic1" ];then
                #LOG=--log
                INPUT_DIR=../../fit-fly-results/synthetic-comparison-post-fix-dfly-traffic1-vis/
                #INPUT_DIR=../../fit-fly-results/verification/traffic1-visual-analysis/dfly-40-60/
                OUTPUT_DIR=${INPUT_DIR}
                python cdf-model-msg-stats.py --test-dir ${INPUT_DIR} \
                    --num-bins 1000 --save --model-type 3 3 3 3 --num-nodes 3072 3072 3072 3072 --switch-radix 48 48 48 48 \
                    --axis-limits --data-file $f --metric $met $LOG --out-file-postfix fitfly-test \
                    --sim-labels 25 50 75 100 \
                    --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                    --fig-font-size $FONT_SIZE --collection-level $level
            elif [ "${TEST}" == "ddfly-traffic1" ];then
                #LOG=--log
                INPUT_DIR=../../fit-fly-results/synthetic-comparison-post-fix-ddfly-traffic1-vis/
                OUTPUT_DIR=${INPUT_DIR}
                python cdf-model-msg-stats.py --test-dir ${INPUT_DIR} \
                    --num-bins 1000 --save --model-type 1 1 1 1 --num-nodes 3200 3200 3200 3200 --switch-radix 36 36 36 36 \
                    --axis-limits --data-file $f --metric $met $LOG --out-file-postfix fitfly-test \
                    --sim-labels 0.25 0.5 0.75 1.0 \
                    --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                    --fig-font-size $FONT_SIZE --collection-level $level
            elif [ "${TEST}" == "ddfly-dfly-traffic1" ];then
                #LOG=--log
                INPUT_DIR=../../fit-fly-results/synthetic-comparison-post-fix-ddfly-dfly-traffic1-vis/
                OUTPUT_DIR=${INPUT_DIR}
                python cdf-model-msg-stats.py --test-dir ${INPUT_DIR} \
                    --num-bins 1000 --save --model-type 1 1 1 1 3 3 3 3 --num-nodes 3200 3200 3200 3200 3072 3072 3072 3072 --switch-radix 36 36 36 36 48 48 48 48\
                    --axis-limits --data-file $f --metric $met $LOG --out-file-postfix fitfly-test \
                    --sim-labels ddfly-1D-25 ddfly-1D-50 ddfly-1D-75 ddfly-1D-100 dfly-2D-25 dfly-2D-50 dfly-2D-75 dfly-2D-100 \
                    --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                    --fig-font-size $FONT_SIZE --collection-level $level
            elif [ "${TEST}" == "ddfly-dfly-sfly-traffic1" ];then
                #LOG=--log
                INPUT_DIR=../../fit-fly-results/verification/traffic1-visual-analysis/
                OUTPUT_DIR=${INPUT_DIR}
                python cdf-model-msg-stats.py --test-dir ${INPUT_DIR} \
                    --num-bins 1000 --save --model-type 1 3 2 --num-nodes 3200 3072 3042 --switch-radix 36 48 36 \
                    --axis-limits --data-file $f --metric $met $LOG --out-file-postfix fitfly-test \
                    --sim-labels ddfly dfly sfly \
                    --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                    --fig-font-size $FONT_SIZE --collection-level $level
            elif [ "${TEST}" == "all-traffic5" ];then
                #LOG=--log
                INPUT_DIR=../../fit-fly-results/synthetic-comparison-post-fix-all-traffic5-vis/
                OUTPUT_DIR=${INPUT_DIR}
                python cdf-model-msg-stats.py --test-dir ${INPUT_DIR} \
                    --num-bins 1000 --save --model-type 1 3 2 0 0 2 --num-nodes 3200 3072 3042 3240 3240 3042 --switch-radix 36 48 36 36 36 36 \
                    --axis-limits --data-file $f --metric $met $LOG --out-file-postfix fitfly-test \
                    --sim-labels ddfly dfly ffly ftree ftree2 sfly \
                    --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                    --fig-font-size $FONT_SIZE --collection-level $level
            else
                python cdf-model-msg-stats.py --test-dir \
                    ../../fit-fly-results/sfly-3042nodes-minimal-none-2000000end-102400vc-12.5GBps-synthetic-traffic1-load0.50/ \
                    ../../fit-fly-results/ffly-3042nodes-minimal-congestion-2000000end-102400vc-12.5GBps-synthetic-traffic1-load0.50/ \
                    ../../fit-fly-results/ffly-3042nodes-minimal-path-2000000end-102400vc-12.5GBps-synthetic-traffic1-load0.50/ \
                    ../../fit-fly-results/sfly-3042nodes-minimal-none-2000000end-102400vc-12.5GBps-synthetic-traffic2-load0.50/ \
                    ../../fit-fly-results/ffly-3042nodes-minimal-congestion-2000000end-102400vc-12.5GBps-synthetic-traffic2-load0.50/ \
                    ../../fit-fly-results/ffly-3042nodes-minimal-path-2000000end-102400vc-12.5GBps-synthetic-traffic2-load0.50/ \
                    --num-bins 1000 --save --model-type 2 2 2 2 2 2 --num-nodes 3042 3042 3042 3042 3042 3042 --switch-radix 36 36 36 36 36 36 \
                    --axis-limits --data-file $f --metric $met $LOG --out-file-postfix fitfly-slimfly-congestion-path-ur-wc \
                    --sim-labels sfly-ur ffly-cong-ur ffly-path-ur sfly-wc ffly-cong-wc ffly-path-wc \
                    --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                    --fig-font-size $FONT_SIZE --collection-level $level
            fi
        done
    done
done
