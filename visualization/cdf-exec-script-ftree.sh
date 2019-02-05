CPU=amg
#METRIC=("3" "6" "3") #Options: 3=switch link traffic or avg packet latency (Depends on file), 6=avg hops
METRIC=("3" "6" "3" "3")
#FILE=("0" "0" "2")
FILE=("0" "0" "1" "2") #Options: 0=model level msg stats, 2=switch link traffic
LOG= #--log
#PLOT_LAYOUT=("cdf" "line-std" "line-sorted" "heatmap")
PLOT_LAYOUT=("heatmap")
LOAD=2.0
TRAFFIC=("1" "3" "4" "5" "6" "7")
TRAFFIC=("1")
FIG_HEIGHT=4     #oldCDF=3, homo=3
FIG_WIDTH=16      #oldCDF=5, homo=4.5
FONT_SIZE=10      #homo=10
STUDY_DIR=/home/noah/Dropbox/RPI/Research/Networks/fit-fly-results/random-runs
STUDY=single

for traf in ${TRAFFIC[@]};do
    for layout in ${PLOT_LAYOUT[@]};do
        OUTPUT_DIR=${STUDY_DIR}/${layout}
        [ -d ${OUTPUT_DIR} ] || mkdir ${OUTPUT_DIR}
        count=-1
        for met in ${METRIC[@]};do
            ((count++))
            f=${FILE[$count]}

            if [ "${f}" == 2 ];then
                LOG=
                level=links
            elif [ "${met}" == 3 ];then
                LOG=--log
                level=links
            else
                LOG=
                level=links
            fi
            LOG=
            if [ "${STUDY}" == "all" ];then
                python cdf-model-msg-stats.py --lp-io-dir \
                    ${STUDY_DIR}/ftree-3240nodes-static-none-15000000end-65536vc-12.5GBps-synthetic-traffic${traf}-load${LOAD}/ \
                    ${STUDY_DIR}/ftree2-3240nodes-static-adaptive-15000000end-65536vc-12.5GBps-synthetic-traffic${traf}-load${LOAD}/ \
                    ${STUDY_DIR}/sfly-3042nodes-minimal-none-15000000end-65536vc-12.5GBps-synthetic-traffic${traf}-load${LOAD}/ \
                    ${STUDY_DIR}/ffly-3042nodes-minimal-path-15000000end-65536vc-12.5GBps-synthetic-traffic${traf}-load${LOAD}/ \
                    ${STUDY_DIR}/dfly-3072nodes-adaptive-none-15000000end-65536vc-12.5GBps-synthetic-traffic${traf}-load${LOAD}/ \
                    --num-bins 1000 --save --model-type 0 0 2 2 1 --num-nodes 3240 3240 3042 3042 3072 --switch-radix 36 36 36 36 42 \
                    --axis-limits --data-file $f --metric $met $LOG --out-file-postfix ftree-ftree2-sfly-ffly-dfly-traffic${traf}-load${LOAD} \
                    --sim-labels ftree ftree2 sfly ffly dfly \
                    --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                    --fig-font-size $FONT_SIZE --collection-level $level
            elif [ "${STUDY}" == "single" ];then
                python cdf-model-msg-stats.py --lp-io-dir \
                    ${STUDY_DIR}/ffly-3042nodes-minimal-congestion-10000end-10240000vc-12.5GBps-synthetic-traffic${traf}-load${LOAD}-payloadsize256/ \
                    --num-bins 1000 --save --model-type 2 --num-nodes 3042 --switch-radix 36 \
                    --axis-limits --data-file $f --metric $met $LOG --out-file-postfix ffly-traffic${traf}-load${LOAD} \
                    --sim-labels ftree ftree2 sfly ffly dfly \
                    --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                    --fig-font-size $FONT_SIZE --collection-level $level
            fi
        done
    done
done
