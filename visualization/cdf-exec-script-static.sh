NEURO=("cifar")
CPU=amg
#SIMS=("cpu" "neuro" "hetero")
SIMS=("all-workload") #Options: all-topo, all-workload, neuro, cpu, hybrid
METRIC=("3" "6" "3") #Options: 3=switch link traffic or avg packet latency (Depends on file), 6=avg hops
#METRIC=("3")
FILE=("0" "0" "2")
#FILE=("2") #Options: 0=model level msg stats, 2=switch link traffic
LOG= #--log
#PLOT_LAYOUT=("cdf" "line-std" "line-sorted" "heatmap")
PLOT_LAYOUT=("heatmap")
FIG_HEIGHT=4     #oldCDF=3, homo=3
FIG_WIDTH=8      #oldCDF=5, homo=4.5
FONT_SIZE=10      #homo=10

for neu in ${NEURO[@]};do
    OUTPUT_DIR=/home/noah/Dropbox/RPI/Research/Papers/Noah/codes-nemo-pmbs/FigureTypes/$neu
    for layout in ${PLOT_LAYOUT[@]};do
        for sim in ${SIMS[@]};do
            count=-1
            for met in ${METRIC[@]};do
                ((count++))
                f=${FILE[$count]}

                if [ "${met}" == 3 ];then
                    LOG=--log
                else
                    LOG=
                fi

                if [ "$neu" == "homo" ];then
                    FIG_HEIGHT=3     #oldCDF=3, homo=3
                    FIG_WIDTH=4.5      #oldCDF=5, homo=4.5
                    if [ "$sim" == "all-topo" ];then
                        python cdf-model-msg-stats.py --lp-io-dir \
                            ../../codes-nemo-results/homo2/dfly-3072nodes-adaptive-2000000end-CONT-bkgnd-cifar-10mintvl-2000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/dfly-3072nodes-adaptive-2000000end-CONT-bkgnd-mnist-10mintvl-2000000tintvl-1234ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/dfly-3072nodes-adaptive-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3072ranks-10000mpt-8Bszmsg-0agg/ \
                            ../../codes-nemo-results/homo2/ftree-3240nodes-static-2000000end-CONT-bkgnd-cifar-10mintvl-2000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/ftree-3240nodes-static-2000000end-CONT-bkgnd-mnist-10mintvl-2000000tintvl-1234ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/ftree-3240nodes-static-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3240ranks-10000mpt-8Bszmsg-0agg/ \
                            ../../codes-nemo-results/homo2/sfly-3042nodes-minimal-2000000end-CONT-bkgnd-cifar-10mintvl-2000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/sfly-3042nodes-minimal-2000000end-CONT-bkgnd-mnist-10mintvl-2000000tintvl-1234ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/sfly-3042nodes-minimal-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3042ranks-10000mpt-8Bszmsg-0agg/ \
                            --num-bins 1000 --save --model-type 1 1 1 0 0 0 2 2 2 --num-nodes 3072 3072 \
                            3072 3240 3240 3240 3042 3042 3042 --switch-radix 48 48 48 36 36 36 36 36 36 \
                            --axis-limits --data-file $f --metric $met $LOG --out-file-postfix $sim \
                            --sim-labels CIFAR-D MNIST-D HF-D CIFAR-F MNIST-F HF-F CIFAR-S MNIST-S HF-S \
                            --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                            --fig-font-size $FONT_SIZE
                    fi
                    if [ "$sim" == "all-workload" ];then
                        python cdf-model-msg-stats.py --lp-io-dir \
                            ../../codes-nemo-results/homo2/dfly-3072nodes-adaptive-2000000end-CONT-bkgnd-cifar-10mintvl-2000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/ftree-3240nodes-static-2000000end-CONT-bkgnd-cifar-10mintvl-2000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/sfly-3042nodes-minimal-2000000end-CONT-bkgnd-cifar-10mintvl-2000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/dfly-3072nodes-adaptive-2000000end-CONT-bkgnd-mnist-10mintvl-2000000tintvl-1234ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/ftree-3240nodes-static-2000000end-CONT-bkgnd-mnist-10mintvl-2000000tintvl-1234ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/sfly-3042nodes-minimal-2000000end-CONT-bkgnd-mnist-10mintvl-2000000tintvl-1234ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/dfly-3072nodes-adaptive-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3072ranks-10000mpt-8Bszmsg-0agg/ \
                            ../../codes-nemo-results/homo2/ftree-3240nodes-static-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3240ranks-10000mpt-8Bszmsg-0agg/ \
                            ../../codes-nemo-results/homo2/sfly-3042nodes-minimal-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3042ranks-10000mpt-8Bszmsg-0agg/ \
                            --num-bins 1000 --save --model-type 1 0 2 1 0 2 1 0 2 --num-nodes 3072 3240 3042 3072 3240 3042 3072 3240 3042 \
                            --switch-radix 48 36 36 48 36 36 48 36 36 \
                            --axis-limits --data-file $f --metric $met $LOG --out-file-postfix $sim \
                            --sim-labels CIFAR-D CIFAR-F CIFAR-S MNIST-D MNIST-F MNIST-S HF-D HF-F HF-S \
                            --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                            --fig-font-size $FONT_SIZE
                    fi
                fi
                if [ "$neu" == "mnist" ];then
                    if [ "$sim" == "all-workload" ];then
                        python cdf-model-msg-stats.py --lp-io-dir \
                            ../../codes-nemo-results/homo2/dfly-3072nodes-adaptive-2000000end-CONT-bkgnd-mnist-10mintvl-2000000tintvl-1234ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/ftree-3240nodes-static-2000000end-CONT-bkgnd-mnist-10mintvl-2000000tintvl-1234ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/sfly-3042nodes-minimal-2000000end-CONT-bkgnd-mnist-10mintvl-2000000tintvl-1234ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/msg-agg/no/dfly-3072nodes-adaptive-1000000end-CONT-trace-amg1k/ \
                            ../../codes-nemo-results/msg-agg/no/ftree-3240nodes-static-1000000end-CONT-trace-amg1k/ \
                            ../../codes-nemo-results/msg-agg/no/sfly-3042nodes-minimal-1000000end-CONT-trace-amg1k/ \
                            ../../codes-nemo-results/msg-agg/no/dfly-3072nodes-adaptive-1000000end-heterogeneous-trace-amg1k-bkgnd-mnist-10mintvl-5000000tintvl-1234ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/msg-agg/no/ftree-3240nodes-static-1000000end-heterogeneous-trace-amg1k-bkgnd-mnist-10mintvl-1000000tintvl-1234ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/msg-agg/no/sfly-3042nodes-minimal-1000000end-heterogeneous-trace-amg1k-bkgnd-mnist-10mintvl-1000000tintvl-1234ranks-0mpt-8Bszmsg/ \
                            --num-bins 1000 --save --model-type 1 0 2 1 0 2 1 0 2 --num-nodes 3072 3240 3042 3072 3240 3042 3072 3240 3042 \
                            --switch-radix 48 36 36 48 36 36 48 36 36 \
                            --axis-limits --data-file $f --metric $met $LOG --out-file-postfix $sim \
                            --sim-labels mnist-D mnist-F mnist-S AMG-D AMG-F AMG-S Hybrid-D Hybrid-F Hybrid-S \
                            --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                            --fig-font-size $FONT_SIZE
                    fi
                fi

                if [ "$neu" == "cifar" ];then
                    if [ "$sim" == "all-topo" ];then
                        python cdf-model-msg-stats.py --lp-io-dir \
                            ../../codes-nemo-results/homo2/dfly-3072nodes-adaptive-2000000end-CONT-bkgnd-cifar-10mintvl-2000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/msg-agg/no/dfly-3072nodes-adaptive-1000000end-CONT-trace-amg1k/ \
                            ../../codes-nemo-results/heterogeneous/cifar/dfly-3072nodes-adaptive-1000000end-65536vc-12.5GBps-heterogeneous-trace-amg1k-bkgnd-cifar-10mintvl-1000000tintvl-1024ranks-0mpt-8Bszmsg-0agg/ \
                            ../../codes-nemo-results/homo2/ftree-3240nodes-static-2000000end-CONT-bkgnd-cifar-10mintvl-2000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/msg-agg/no/ftree-3240nodes-static-1000000end-CONT-trace-amg1k/ \
                            ../../codes-nemo-results/heterogeneous/cifar/ftree-3240nodes-static-1000000end-65536vc-12.5GBps-heterogeneous-trace-amg1k-bkgnd-cifar-10mintvl-1000000tintvl-1024ranks-0mpt-8Bszmsg-0agg/ \
                            ../../codes-nemo-results/homo2/sfly-3042nodes-minimal-2000000end-CONT-bkgnd-cifar-10mintvl-2000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/msg-agg/no/sfly-3042nodes-minimal-1000000end-CONT-trace-amg1k/ \
                            ../../codes-nemo-results/heterogeneous/cifar/sfly-3042nodes-minimal-1000000end-65536vc-12.5GBps-heterogeneous-trace-amg1k-bkgnd-cifar-10mintvl-1000000tintvl-1024ranks-0mpt-8Bszmsg-0agg/ \
                            --num-bins 1000 --save --model-type 1 1 1 0 0 0 2 2 2 --num-nodes 3072 3072 \
                            3072 3240 3240 3240 3042 3042 3042 --switch-radix 48 48 48 36 36 36 36 36 36 \
                            --axis-limits --data-file $f --metric $met $LOG --out-file-postfix $sim \
                            --sim-labels CIFAR-D AMG-D Hybrid-D CIFAR-F AMG-F Hybrid-F CIFAR-S AMG-S Hybrid-S \
                            --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                            --fig-font-size $FONT_SIZE
                    fi
                    if [ "$sim" == "all-workload" ];then
                        python cdf-model-msg-stats.py --lp-io-dir \
                            ../../codes-nemo-results/homo2/dfly-3072nodes-adaptive-2000000end-CONT-bkgnd-cifar-10mintvl-2000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/ftree-3240nodes-static-2000000end-CONT-bkgnd-cifar-10mintvl-2000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/sfly-3042nodes-minimal-2000000end-CONT-bkgnd-cifar-10mintvl-2000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/msg-agg/no/dfly-3072nodes-adaptive-1000000end-CONT-trace-amg1k/ \
                            ../../codes-nemo-results/msg-agg/no/ftree-3240nodes-static-1000000end-CONT-trace-amg1k/ \
                            ../../codes-nemo-results/msg-agg/no/sfly-3042nodes-minimal-1000000end-CONT-trace-amg1k/ \
                            ../../codes-nemo-results/heterogeneous/cifar/dfly-3072nodes-adaptive-1000000end-65536vc-12.5GBps-heterogeneous-trace-amg1k-bkgnd-cifar-10mintvl-1000000tintvl-1024ranks-0mpt-8Bszmsg-0agg/ \
                            ../../codes-nemo-results/heterogeneous/cifar/ftree-3240nodes-static-1000000end-65536vc-12.5GBps-heterogeneous-trace-amg1k-bkgnd-cifar-10mintvl-1000000tintvl-1024ranks-0mpt-8Bszmsg-0agg/ \
                            ../../codes-nemo-results/heterogeneous/cifar/sfly-3042nodes-minimal-1000000end-65536vc-12.5GBps-heterogeneous-trace-amg1k-bkgnd-cifar-10mintvl-1000000tintvl-1024ranks-0mpt-8Bszmsg-0agg/ \
                            --num-bins 1000 --save --model-type 1 0 2 1 0 2 1 0 2 --num-nodes 3072 3240 3042 3072 3240 3042 3072 3240 3042 \
                            --switch-radix 48 36 36 48 36 36 48 36 36 \
                            --axis-limits --data-file $f --metric $met $LOG --out-file-postfix $sim \
                            --sim-labels MNIST-DFLY MNIST-FTREE MNIST-SFLY AMG-DFLY AMG-FTREE AMG-SFLY Hybrid-DFLY Hybrid-FTREE Hybrid-SFLY \
                            --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                            --fig-font-size $FONT_SIZE
                    fi
                    if [ "$sim" == "neuro" ];then
                        python cdf-model-msg-stats.py --lp-io-dir \
                            ../../codes-nemo-results/homo2/dfly-3072nodes-adaptive-2000000end-CONT-bkgnd-cifar-10mintvl-2000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/ftree-3240nodes-static-2000000end-CONT-bkgnd-cifar-10mintvl-2000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/homo2/sfly-3042nodes-minimal-2000000end-CONT-bkgnd-cifar-10mintvl-2000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            --num-bins 1000 --save --model-type 1 0 2 --num-nodes 3072 3240 3042 \
                            --switch-radix 48 36 36 \
                            --axis-limits --data-file $f --metric $met $LOG --out-file-postfix $sim \
                            --sim-labels CIFAR-D CIFAR-F CIFAR-S \
                            --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                            --fig-font-size $FONT_SIZE
                    fi
                    if [ "$sim" == "cpu" ];then
                        python cdf-model-msg-stats.py --lp-io-dir \
                            ../../codes-nemo-results/msg-agg/no/dfly-3072nodes-adaptive-1000000end-CONT-trace-amg1k/ \
                            ../../codes-nemo-results/msg-agg/no/ftree-3240nodes-static-1000000end-CONT-trace-amg1k/ \
                            ../../codes-nemo-results/msg-agg/no/sfly-3042nodes-minimal-1000000end-CONT-trace-amg1k/ \
                            --num-bins 1000 --save --model-type 1 0 2 --num-nodes 3072 3240 3042 \
                            --switch-radix 48 36 36 \
                            --axis-limits --data-file $f --metric $met $LOG --out-file-postfix $sim \
                            --sim-labels AMG-D AMG-F AMG-S \
                            --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                            --fig-font-size $FONT_SIZE
                    fi
                    if [ "$sim" == "hetero" ];then
                        python cdf-model-msg-stats.py --lp-io-dir \
                            ../../codes-nemo-results/msg-agg/no/dfly-3072nodes-adaptive-1000000end-heterogeneous-trace-amg1k-bkgnd-cifar-10mintvl-1000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/msg-agg/no/ftree-3240nodes-static-1000000end-heterogeneous-trace-amg1k-bkgnd-cifar-10mintvl-1000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            ../../codes-nemo-results/msg-agg/no/sfly-3042nodes-minimal-1000000end-heterogeneous-trace-amg1k-bkgnd-cifar-10mintvl-1000000tintvl-1024ranks-0mpt-8Bszmsg/ \
                            --num-bins 1000 --save --model-type 1 0 2 --num-nodes 3072 3240 3042 \
                            --switch-radix 48 36 36 \
                            --axis-limits --data-file $f --metric $met $LOG --out-file-postfix $sim \
                            --sim-labels Hybrid-D Hybrid-F Hybrid-S \
                            --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                            --fig-font-size $FONT_SIZE
                    fi

                elif [ "$neu" == "hopfield" ];then
                    if [ "$sim" == "all-topo" ];then
                        if [ "$CPU" == "amg" ];then
                            python cdf-model-msg-stats.py --lp-io-dir \
                                ../../codes-nemo-results/homo2/dfly-3072nodes-adaptive-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3072ranks-10000mpt-8Bszmsg-0agg/ \
                                ../../codes-nemo-results/msg-agg/no/dfly-3072nodes-adaptive-1000000end-CONT-trace-amg1k/ \
                                ../../codes-nemo-results/msg-agg/no/dfly-3072nodes-adaptive-1000000end-heterogeneous-trace-amg1k-bkgnd-hf-10mintvl-1000000tintvl-3072ranks-10000mpt-8Bszmsg/ \
                                ../../codes-nemo-results/homo2/ftree-3240nodes-static-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3240ranks-10000mpt-8Bszmsg-0agg/ \
                                ../../codes-nemo-results/msg-agg/no/ftree-3240nodes-static-1000000end-CONT-trace-amg1k/ \
                                ../../codes-nemo-results/msg-agg/no/ftree-3240nodes-static-1000000end-heterogeneous-trace-amg1k-bkgnd-hf-10mintvl-1000000tintvl-3240ranks-10000mpt-8Bszmsg/ \
                                ../../codes-nemo-results/homo2/sfly-3042nodes-minimal-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3042ranks-10000mpt-8Bszmsg-0agg/ \
                                ../../codes-nemo-results/msg-agg/no/sfly-3042nodes-minimal-1000000end-CONT-trace-amg1k/ \
                                ../../codes-nemo-results/msg-agg/no/sfly-3042nodes-minimal-1000000end-heterogeneous-trace-amg1k-bkgnd-hf-10mintvl-1000000tintvl-3042ranks-10000mpt-8Bszmsg/ \
                                --num-bins 1000 --save --model-type 1 1 1 0 0 0 2 2 2 --num-nodes 3072 3072 \
                                3072 3240 3240 3240 3042 3042 3042 --switch-radix 48 48 48 36 36 36 36 36 36 \
                                --axis-limits --data-file $f --metric $met $LOG --out-file-postfix $sim \
                                --sim-labels HF-D AMG-D Hybrid-D HF-F AMG-F Hybrid-F HF-S AMG-S Hybrid-S \
                                --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                                --fig-font-size $FONT_SIZE
                        elif [ "$CPU" == "cr" ];then
                            python cdf-model-msg-stats.py --lp-io-dir \
                                ../../codes-nemo-results/homo2/dfly-3072nodes-adaptive-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3072ranks-10000mpt-8Bszmsg-0agg/ \
                                ../../codes-nemo-results/msg-agg/no/dfly-3072nodes-adaptive-300000000end-CONT-trace-cr1k/ \
                                ../../codes-nemo-results/msg-agg/no/dfly-3072nodes-adaptive-350000000end-heterogeneous-trace-cr1k-bkgnd-hf-10mintvl-1000000tintvl-3072ranks-10000mpt-8Bszmsg/ \
                                ../../codes-nemo-results/homo2/ftree-3240nodes-static-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3240ranks-10000mpt-8Bszmsg-0agg/ \
                                ../../codes-nemo-results/msg-agg/no/ftree-3240nodes-static-300000000end-CONT-trace-cr1k/ \
                                ../../codes-nemo-results/msg-agg/no/ftree-3240nodes-static-350000000end-heterogeneous-trace-cr1k-bkgnd-hf-10mintvl-1000000tintvl-3240ranks-10000mpt-8Bszmsg/ \
                                ../../codes-nemo-results/homo2/sfly-3042nodes-minimal-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3042ranks-10000mpt-8Bszmsg-0agg/ \
                                ../../codes-nemo-results/msg-agg/no/sfly-3042nodes-minimal-300000000end-CONT-trace-cr1k/ \
                                ../../codes-nemo-results/msg-agg/no/sfly-3042nodes-minimal-350000000end-heterogeneous-trace-cr1k-bkgnd-hf-10mintvl-1000000tintvl-3042ranks-10000mpt-8Bszmsg/ \
                                --num-bins 1000 --save --model-type 1 1 1 0 0 0 2 2 2 --num-nodes 3072 3072 \
                                3072 3240 3240 3240 3042 3042 3042 --switch-radix 48 48 48 36 36 36 36 36 36 \
                                --axis-limits --data-file $f --metric $met $LOG --out-file-postfix $sim \
                                --sim-labels HF-D CR-D Hybrid-D HF-F CR-F Hybrid-F HF-S CR-S Hybrid-S \
                                --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                                --fig-font-size $FONT_SIZE
                        fi
                    fi
                    if [ "$sim" == "all-workload" ];then
                        python cdf-model-msg-stats.py --lp-io-dir \
                            ../../codes-nemo-results/homo2/dfly-3072nodes-adaptive-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3072ranks-10000mpt-8Bszmsg-0agg/ \
                            ../../codes-nemo-results/homo2/ftree-3240nodes-static-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3240ranks-10000mpt-8Bszmsg-0agg/ \
                            ../../codes-nemo-results/homo2/sfly-3042nodes-minimal-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3042ranks-10000mpt-8Bszmsg-0agg/ \
                            ../../codes-nemo-results/msg-agg/no/dfly-3072nodes-adaptive-1000000end-CONT-trace-amg1k/ \
                            ../../codes-nemo-results/msg-agg/no/ftree-3240nodes-static-1000000end-CONT-trace-amg1k/ \
                            ../../codes-nemo-results/msg-agg/no/sfly-3042nodes-minimal-1000000end-CONT-trace-amg1k/ \
                            ../../codes-nemo-results/msg-agg/no/dfly-3072nodes-adaptive-1000000end-heterogeneous-trace-amg1k-bkgnd-hf-10mintvl-1000000tintvl-3072ranks-10000mpt-8Bszmsg/ \
                            ../../codes-nemo-results/msg-agg/no/ftree-3240nodes-static-1000000end-heterogeneous-trace-amg1k-bkgnd-hf-10mintvl-1000000tintvl-3240ranks-10000mpt-8Bszmsg/ \
                            ../../codes-nemo-results/msg-agg/no/sfly-3042nodes-minimal-1000000end-heterogeneous-trace-amg1k-bkgnd-hf-10mintvl-1000000tintvl-3042ranks-10000mpt-8Bszmsg/ \
                            --num-bins 1000 --save --model-type 1 0 2 1 0 2 1 0 2 --num-nodes 3072 3240 3042 3072 3240 3042 3072 3240 3042 \
                            --switch-radix 48 36 36 48 36 36 48 36 36 \
                            --axis-limits --data-file $f --metric $met $LOG --out-file-postfix $sim \
                            --sim-labels HF-D HF-F HF-S AMG-D AMG-F AMG-S Hybrid-D Hybrid-F Hybrid-S \
                            --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                            --fig-font-size $FONT_SIZE
                    fi
                    if [ "$sim" == "neuro" ];then
                        python cdf-model-msg-stats.py --lp-io-dir \
                            ../../codes-nemo-results/homo2/dfly-3072nodes-adaptive-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3072ranks-10000mpt-8Bszmsg-0agg/ \
                            ../../codes-nemo-results/homo2/ftree-3240nodes-static-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3240ranks-10000mpt-8Bszmsg-0agg/ \
                            ../../codes-nemo-results/homo2/sfly-3042nodes-minimal-1000000end-65536vc-12.5GBps-CONT-bkgnd-hf-10mintvl-1000000tintvl-3042ranks-10000mpt-8Bszmsg-0agg/ \
                            --num-bins 1000 --save --model-type 1 0 2 --num-nodes 3072 3240 3042 \
                            --switch-radix 48 36 36 \
                            --axis-limits --data-file $f --metric $met $LOG --out-file-postfix $sim \
                            --sim-labels HF-D HF-F HF-S
                            --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                            --fig-font-size $FONT_SIZE
                    fi
                    if [ "$sim" == "cpu" ];then
                        python cdf-model-msg-stats.py --lp-io-dir \
                            ../../codes-nemo-results/msg-agg/no/dfly-3072nodes-adaptive-1000000end-CONT-trace-amg1k/ \
                            ../../codes-nemo-results/msg-agg/no/ftree-3240nodes-static-1000000end-CONT-trace-amg1k/ \
                            ../../codes-nemo-results/msg-agg/no/sfly-3042nodes-minimal-1000000end-CONT-trace-amg1k/ \
                            --num-bins 1000 --save --model-type 1 0 2 --num-nodes 3072 3240 3042 \
                            --switch-radix 48 36 36 \
                            --axis-limits --data-file $f --metric $met $LOG --out-file-postfix $sim \
                            --sim-labels AMG-D AMG-F AMG-S
                            --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                            --fig-font-size $FONT_SIZE
                    fi
                    if [ "$sim" == "hetero" ];then
                        python cdf-model-msg-stats.py --lp-io-dir \
                            ../../codes-nemo-results/msg-agg/no/dfly-3072nodes-adaptive-1000000end-heterogeneous-trace-amg1k-bkgnd-hf-10mintvl-1000000tintvl-3072ranks-10000mpt-8Bszmsg/ \
                            ../../codes-nemo-results/msg-agg/no/ftree-3240nodes-static-1000000end-heterogeneous-trace-amg1k-bkgnd-hf-10mintvl-1000000tintvl-3240ranks-10000mpt-8Bszmsg/ \
                            ../../codes-nemo-results/msg-agg/no/sfly-3042nodes-minimal-1000000end-heterogeneous-trace-amg1k-bkgnd-hf-10mintvl-1000000tintvl-3042ranks-10000mpt-8Bszmsg/ \
                            --num-bins 1000 --save --model-type 1 0 2 --num-nodes 3072 3240 3042 \
                            --switch-radix 48 36 36 \
                            --axis-limits --data-file $f --metric $met $LOG --out-file-postfix $sim \
                            --sim-labels Hybrid-D Hybrid-F Hybrid-S
                            --plot-type $layout --output-dir $OUTPUT_DIR --fig-height $FIG_HEIGHT --fig-width $FIG_WIDTH \
                            --fig-font-size $FONT_SIZE
                    fi
                fi
            done
        done
    done
done
