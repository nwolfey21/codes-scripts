#!/bin/bash

##############################################################################
### This workflow automates the execution and analysis of mpi-replay         #
### simulations                                                              #
##############################################################################
### 1. Generates network model conf files, dumpi allocation files and dumpi  #
###    workload conf files in a "TEMP..." directory inside the BUILD_DIR.    #
### 2. Executes the simulation.                                              #
### 3. Copies conf files to lp-io directory                                  #
### 4. Executes post processing python script in background (WIP)            #
##############################################################################

###################
# Selection Flags #
###################
VIS=0               # Whether or not to perform post-process visualization
COMM_MAP=0          # Whether or not to generate the post process communication heat map visualization
SIM=1               # Whether or not to perform a codes model simulation (must be set in addition to TRACE, SYNTHETIC, and/or, BACKGROUND)
TRACE=0             # Whether or not to do a trace workload
SYNTHETIC=0         # Whether or not to do a synthetic workload
BACKGROUND=1        # Whether or not to do a Neuromorphic background workload
DEBUG=0             # Runs sequentially in gdb 
STUDY=vis-sampling # What study (if any) are we running. Options: chip-scaling, spike-scaling, buffer-scaling, link-scaling, spike-aggregation, aggregation-scaling, vis-sampling, msg-size-scaling, offered-load-scaling, verification, routing-comparison, synthetic-comparison, none
                        # single-tick: Runs neuromorphic workloads for only one tick, extending the tick window long enough to allow all generated spikes to reach their destination. Currently does with and then without spike aggregation
                        # hybrid-jobs: Runs neuromorphic workloads in parallel with cpu trace workloads
                        # routing-comparison: Runs the network models under both adaptive and minimal routing protocols
                        # synthetic-comparison: Runs each topology and synthetic workload with 100 messages at 90% injection load
ENABLE_SAMPLING=1   # Sampling Parameters (Only if running TRACE workload or BACKGROUND workload)
COPY_ANALYSIS=0     # Whether or not to copy output directory to an analysis directory
if [ ${SYNTHETIC} == 1 ];then
    if [ "${STUDY}" == "none" ];then
        ANALYSIS_DIR=/home/noah/Dropbox/RPI/Research/Networks/fit-fly-results/random-runs   #Only needed if COPY_ANALYSIS=1
    else
        ANALYSIS_DIR=/home/noah/Dropbox/RPI/Research/Networks/fit-fly-results/${STUDY}
    fi
elif [ ${TRACE} == 1 ];then
    if [ "${STUDY}" == "none" ];then
        ANALYSIS_DIR=/home/noah/Dropbox/RPI/Research/Networks/fit-fly-results/cpu-traces
    else
        ANALYSIS_DIR=/home/noah/Dropbox/RPI/Research/Networks/fit-fly-results/${STUDY}
    fi
elif [ ${BACKGROUND} == 1 ];then
    if [ "${STUDY}" == "none" ];then
        ANALYSIS_DIR=/home/noah/Dropbox/RPI/Research/Networks/fit-fly-results/neuro-traces
    else
        ANALYSIS_DIR=/home/noah/Dropbox/RPI/Research/Networks/fit-fly-results/${STUDY}
    fi
fi
EXE_SYS=server 	    # Execution system. Options: CCI, server

#################
# CODES Paths #
#################
echo "Setting Paths"
if [ "$EXE_SYS" == "CCI" ]; then
    BUILD_DIR=/gpfs/u/home/SPNR/SPNRwlfn/scratch/build-drp-codes-nemo/build-codes-unified
    CODES_DIR=/gpfs/u/home/SPNR/SPNRwlfn/barn/codes-unified/codes
    TRACE_DIR=/gpfs/u/home/SPNR/SPNRwlfn/scratch/dumpi-traces
elif [ "$EXE_SYS" == "server" ]; then
    CODES_DIR=/home/noah/Dropbox/RPI/Research/Networks/codes-unified/codes
    BUILD_DIR=/scratch/codes-nemo/build/build-codes
    TRACE_DIR=/scratch/networks/dumpi-traces/
    SCRIPTS_DIR=/home/noah/Dropbox/RPI/Research/Networks/codes-scripts
    #TRACE_DIR=/scratch/codes-nemo/dumpi-traces/
fi
if [ "$VIS" == 1 ]; then
    PROCESSING_EXE_PATH=/home/noah/Dropbox/RPI/Research/Networks/codes-unified/codes/scripts/modelnet-analysis/parse-sampling.py
fi

##########################
# Sim Parameters/Metrics #
##########################

# Network Model
NET_MODEL=sfly      # Options:
                    #   ftree: fat-tree
                    #   sfly: slim fly
                    #   dfly: Cray style dragonfly. 2D flattened butterfly within groups
                    #   ffly: dual-rail slim fly
                    #   ddfly: Dally style dragonfly fully connected within groups
NET_MODEL_SIZE=3k   # Size of HPC system: 150, 3k, 74k, 1m

# Server Execution Params
NUM_PROCESSES=1       # Physical MPI processes
SYNCH=1                # ROSS event scheduling protocol
EXTRAMEM=10000000        # Extra memory to allocate per MPI process last was 8500000
BATCH=2                # ROSS batch parameter
GVT=128                 # ROSS gvt parameter
MAX_OPT_LOOKAHEAD=100 # ROSS max opt lookahead parameter

# CCI Execution Params (in addition to Server Execution Params)
TIME_ALLOC=350       # Requested job allocation time limit
NUM_NODES=1        # Requested job number of nodes

# Simulation End Time
SIM_END_TIME=1000000    # Currently over written for each trace

# Sampling Points
SAMPLING_POINTS=100     # Number of points in time to sample trace metrics during the simulation (ENABLE_SAMPLING flag must be on)

# Synthetic Workload Params
LOAD=0.5        # Percentage of terminal link bandwidth for servers to inject traffic
NUM_MSGS=1000     # Number of messages to send per synthetic process
NUM_MSGS=4     # Number of messages to send per synthetic process
PAYLOAD_SIZE=256 # Size of messages to send between synthetic processes
WARM_UP_TIME=40000 # Time delay before stats are collected. For accurate verification results
WARM_UP_TIME=0 # Time delay before stats are collected. For accurate verification results
TRAFFIC=2       # Network model dependent
                #    1: Uniform
                #    2: Worst-case (Slim Fly & Fit Fly only)
                #    3: 1D Nearest Neighbor
                #    4: 2D Nearest Neighbor
                #    5: 3D Nearest Neighbor
                #    6: Gather
                #    7: Scatter
                #    8: Bisection
                #    9: All-2-All
                #   10: Ping

# Trace Workload Params
NUM_JOBS=1          # Number of workloads to run in parallel
JOBS=("amg1k")      # Options:
                        # amg1k: 1728 ranks of Algebraic Multigrid Solver
                        # cr1k: 1000 ranks of Crystal Router Mini App
                        # mg1k: 1000 ranks of Multigrid Solver
DISABLE_COMPUTE=1   # Whether or not to incorporate DUMPI trace compute times

# Neuromorphic Background Traffic Params
BACKGROUND_JOB="none"     # Options: hf, cifar, mnist, none
MEAN_INTERVAL=10        # Nanosecond delay between spike message injections
TICK_INTERVAL=1000000   # Nanosecond length of a tick
SPIKE_SIZE=8              # Size in Bytes of spike messages. Used 200 for dfly data collection amg/mnist
SPIKES_PER_TICK=10000     # Number of spike messages to inject per chip per tick. Overwritten in "get_background_wrkld_params()"
BACKGROUND_RANKS=3456   # Number of neuromorphic chips. Currently overwritten for each net model in "Network Model Params" section below
AGGREGATION_OVERHEAD=0  # Nanosecond delay per spike required to aggregate into one message per chip connection
SPIKE_AGGREGATION_FLAG=0 # 0: Don't perform spike aggregation. 1: Do perform spike aggregation

# Allocation Protocol (Trace workload only)
ALLOC_POLICY=("heterogeneous")  # Options: CONT,cluster, and rand (supported for one or more trace/background/combined jobs)
                            # Options Continued: heterogeneous (supported for running one combined trace and background job)
                            # Currently overwritten in execution for loop below

# Common Network Params
MESSAGE_SIZE=656
PACKET_SIZE=4096
CHUNK_SIZE=${PACKET_SIZE}
MODELNET_SCHEDULER=fcfs
ROUTER_DELAY=90
NUM_INJECTION_QUEUES=1
NIC_SEQ_DELAY=10
NODE_COPY_QUEUES=1
NODE_EAGER_LIMIT=16000
VC_SIZE_DEFAULT=65536
LINK_BANDWIDTH_DEFAULT=12.5

# Network Params for Verification Runs
if [ "${STUDY}" == "verification" ];then
    MESSAGE_SIZE=656
    PACKET_SIZE=256
    CHUNK_SIZE=${PACKET_SIZE}
    MODELNET_SCHEDULER=fcfs
    ROUTER_DELAY=90
    NIC_SEQ_DELAY=0
    NODE_EAGER_LIMIT=16000
    VC_SIZE_DEFAULT=102400
    LINK_BANDWIDTH_DEFAULT=12.5
fi

# Network Model Specific Params
get_net_model_params() {
if [ "$NET_MODEL" == "ftree" ] || [ "$NET_MODEL" == "ftree2" ]
then
    if [ "$NET_MODEL" == "ftree2" ];then
        FT_TYPE=2
        NUM_INJECTION_QUEUES=2
        NODE_COPY_QUEUES=2
        RAIL_SELECT=adaptive           # Options:
                                            # adaptive: routes along rail with least congestion
                                            # dedicated: routes along preselected rail
    else
        FT_TYPE=0
        NUM_INJECTION_QUEUES=1
        NODE_COPY_QUEUES=1
        RAIL_SELECT=none
    fi
    FTREE_MODEL=ftree10    #Options: ftree (summit approx w/11 pods), ftree10 (ftree with 10 pods)
    ROUTING_ALG=static     #Options: static,adaptive
    NUM_LEVELS=3
    VC_SIZE=$(( ${VC_SIZE_INSTANCE} > 0 ? ${VC_SIZE_INSTANCE} : ${VC_SIZE_DEFAULT} ))
    CN_VC_SIZE=${VC_SIZE}
    if (( $(echo "${LINK_BANDWIDTH_INSTANCE} > 0" | bc -l)  ));then
        LINK_BANDWIDTH=${LINK_BANDWIDTH_INSTANCE}
    else
        LINK_BANDWIDTH=${LINK_BANDWIDTH_DEFAULT}
    fi
    CN_BANDWIDTH=${LINK_BANDWIDTH}
    if [ "$EXE_SYS" == "CCI" ]
    then
        ROUTING_FOLDER=/gpfs/u/home/SPNR/SPNRwlfn/barn/Fat-Tree-Topo/summit
    elif [ "$EXE_SYS" == "server" ]
    then
        ROUTING_FOLDER=/home/noah/Dropbox/RPI/Research/Networks/Fat-Tree-Topo/summit
    fi
    if [ "${FTREE_MODEL}" == "ftree" ];then
        REPS=198
        ROUTING_FOLDER+=-3564
        DOT_FILE=summit-3564
        DUMP_TOPO=0
        BACKGROUND_RANKS=3564
    elif [ "${FTREE_MODEL}" == "ftree10" ];then
        REPS=180
        ROUTING_FOLDER+=-3240
        DOT_FILE=summit-3240
        DUMP_TOPO=0
        BACKGROUND_RANKS=3240
    fi
    #BACKGROUND_RANKS_BATCH=("446" "891" "1782" "3564" "7128")
    #BACKGROUND_RANKS_BATCH=("3564")
elif [ "$NET_MODEL" == "sfly" ] || [ "$NET_MODEL" == "ffly" ]
then
    if [ "$NET_MODEL" == "ffly" ];then
        SF_TYPE=1   #Options: 0->single rail slim fly, 1->dual-rail slim fly (fit fly)
        NUM_INJECTION_QUEUES=2
        NODE_COPY_QUEUES=2
        RAIL_SELECT=path           # Options:
                                            # path: routes along rail with shortest path
                                            # congestion: routes along rail with least congestion
                                            # dedicated: routes along preselected rail
    else
        SF_TYPE=0
        NUM_INJECTION_QUEUES=1
        NODE_COPY_QUEUES=1
        RAIL_SELECT=none
    fi
    ROUTING_ALG=adaptive     # Options: minimal, nonminimal, adaptive
    LOCAL_VC_SIZE=$(( ${VC_SIZE_INSTANCE} > 0 ? ${VC_SIZE_INSTANCE} : ${VC_SIZE_DEFAULT} ))
    GLOBAL_VC_SIZE=${LOCAL_VC_SIZE}
    CN_VC_SIZE=${LOCAL_VC_SIZE}
    if (( $(echo "${LINK_BANDWIDTH_INSTANCE} > 0" | bc -l)  ));then
        LOCAL_BANDWIDTH=${LINK_BANDWIDTH_INSTANCE}
    else
        LOCAL_BANDWIDTH=${LINK_BANDWIDTH_DEFAULT}
    fi
    CN_BANDWIDTH=${LOCAL_BANDWIDTH}
    GLOBAL_BANDWIDTH=${LOCAL_BANDWIDTH}
    BACKGROUND_RANKS=3042
    #BACKGROUND_RANKS_BATCH=("380" "761" "1521" "3042" "6084")
    #BACKGROUND_RANKS_BATCH=("3042")
elif [ "$NET_MODEL" == "dfly" ]
then
    DFLY_MODEL=theta8       # Options: theta (regular theta), theta8 (8 group theta)
    ROUTING_ALG=adaptive    # Options: minimal, nonminimal, adaptive
    RAIL_SELECT=none
    LOCAL_VC_SIZE=$(( ${VC_SIZE_INSTANCE} > 0 ? ${VC_SIZE_INSTANCE} : ${VC_SIZE_DEFAULT} ))
    GLOBAL_VC_SIZE=${LOCAL_VC_SIZE}
    CN_VC_SIZE=${LOCAL_VC_SIZE}
    if (( $(echo "${LINK_BANDWIDTH_INSTANCE} > 0" | bc -l)  ));then
        LOCAL_BANDWIDTH=${LINK_BANDWIDTH_INSTANCE}
    else
        LOCAL_BANDWIDTH=${LINK_BANDWIDTH_DEFAULT}
    fi
    CN_BANDWIDTH=${LOCAL_BANDWIDTH}
    GLOBAL_BANDWIDTH=${LOCAL_BANDWIDTH}
    #Theta bandwidths
    #LOCAL_BANDWIDTH=5.25
    #CN_BANDWIDTH=16.0
    #GLOBAL_BANDWIDTH=4.69
    if [ "${DFLY_MODEL}" == "theta" ];then
        INTRA_GROUP_CONNECTIONS=${CODES_DIR}/src/network-workloads/conf/dragonfly-custom/intra-theta
        INTER_GROUP_CONNECTIONS=${CODES_DIR}/src/network-workloads/conf/dragonfly-custom/inter-theta
        BACKGROUND_RANKS=3456
        REPS=864
        NUM_GROUPS=9
    elif [ "${DFLY_MODEL}" == "theta8" ];then
        INTRA_GROUP_CONNECTIONS=${CODES_DIR}/src/network-workloads/conf/dragonfly-custom/intra-theta-8group
        INTER_GROUP_CONNECTIONS=${CODES_DIR}/src/network-workloads/conf/dragonfly-custom/inter-theta-8group
        BACKGROUND_RANKS=3072
        REPS=768
        NUM_GROUPS=8
    fi
    #BACKGROUND_RANKS_BATCH=("432" "864" "1728" "3456" "6912")
elif [ "$NET_MODEL" == "ddfly" ]
then
    DFLY_DALLY_MODEL=3k       # Options: 3k
    ROUTING_ALG=adaptive    # Options: minimal, nonminimal, adaptive
    RAIL_SELECT=none
    LOCAL_VC_SIZE=$(( ${VC_SIZE_INSTANCE} > 0 ? ${VC_SIZE_INSTANCE} : ${VC_SIZE_DEFAULT} ))
    GLOBAL_VC_SIZE=${LOCAL_VC_SIZE}
    CN_VC_SIZE=${LOCAL_VC_SIZE}
    if (( $(echo "${LINK_BANDWIDTH_INSTANCE} > 0" | bc -l)  ));then
        LOCAL_BANDWIDTH=${LINK_BANDWIDTH_INSTANCE}
    else
        LOCAL_BANDWIDTH=${LINK_BANDWIDTH_DEFAULT}
    fi
    CN_BANDWIDTH=${LOCAL_BANDWIDTH}
    GLOBAL_BANDWIDTH=${LOCAL_BANDWIDTH}
    if [ "${DFLY_DALLY_MODEL}" == "3k" ];then
        INTRA_GROUP_CONNECTIONS=${CODES_DIR}/src/network-workloads/conf/dragonfly-custom/intra-dfdally-3k
        INTER_GROUP_CONNECTIONS=${CODES_DIR}/src/network-workloads/conf/dragonfly-custom/inter-dfdally-3k
        BACKGROUND_RANKS=3200
        REPS=400
        NUM_GROUPS=25
    fi
fi
}

##################################################################################################
# Execution Loop                                                                                 #
##################################################################################################
# For each metric that you want to vary, assign the values to one of the "LOOP#" variables below #
# Ex: LOOP1=("sfly" "dfly" "ftree") will execute the three different NET_MODELs                  #
# Replace the corresponding "LOOP_METRIC#" variable within the correspondig loop statement       #
# Ex: LOOP_METRIC1=${L1} ---> NET_MODEL=${L1} is done for the LOOP1 which goes over NET_MODELs   #
# Leave unused LOOP# variables set to ("1") so they are unused                                   #
##################################################################################################
exec_loop() {
    #LOOP1=("ftree" "ftree2" "sfly" "ffly" "dfly" "ddfly")
    LOOP1=("ftree" "ftree2" "sfly" "ffly" "dfly" "ddfly")
    #LOOP1=("ffly" "ftree2")
    LOOP1=("sfly")
    if [ ${SYNTHETIC} == 1 ];then
        #LOOP2=("1" "3" "4" "5" "6" "7" "8" "9" "10")
        LOOP2=("3" "4" "5")
        LOOP2=("9")
    elif [ ${BACKGROUND} == 1 ] && [ ${TRACE} == 0 ];then
        LOOP2=("mnist" "cifar" "hf")
        LOOP2=("cifar")
    elif [ ${TRACE} == 1 ] && [ ${BACKGROUND} == 0 ];then
        LOOP2=("amg1k" "mg1k" "cr1k")
        LOOP2=("amg1k")
    elif [ ${TRACE} == 1 ] && [ ${BACKGROUND} == 1 ];then
        LOOP2=("amg1k" "mg1k" "cr1k")
        #LOOP2=("mg1k")
        LOOP2=("amg1k")
    else
        echo "Must select one simulation option (options: synthetic, background, trace)"
        exit
    fi
    TOTAL_SIMS=$(( ${#LOOP1[@]} * ${#LOOP2[@]} * ${#LOOP3[@]} ))
    COUNT_SIMS=1
    for L1 in ${LOOP1[@]};do
        NET_MODEL=${L1}  # Set variable dependent on loop
        for L2 in ${LOOP2[@]};do
            if [ ${SYNTHETIC} == 1 ];then
                TRAFFIC=${L2}
            elif [ ${BACKGROUND} == 1 ] && [ ${TRACE} == 0 ];then
                BACKGROUND_JOB=${L2}
                echo Background Job: $BACKGROUND_JOB
            elif [ ${TRACE} == 1 ] && [ ${BACKGROUND} == 0 ];then
                JOBS=${L2}  # Set variable dependent on loop
                echo Trace Job: ${JOBS[0]}
            elif [ ${TRACE} == 1 ] && [ ${BACKGROUND} == 1 ];then
                JOBS=${L2}  # Set variable dependent on loop
                BACKGROUND_JOB=("mnist")
                echo Trace Job: ${JOBS[0]}
            fi
            echo Network Model: ${NET_MODEL}
            # Check if running a specific study
            if [ "${STUDY}" == "spike-scaling" ];then
                LOOP3=("2500" "5000" "10000" "20000" "40000" "80000")
                #LOOP3=("2500" "5000" "20000" "40000")
            elif [ "${STUDY}" == "hybrid-jobs" ];then
                LOOP3=("mnist" "cifar" "hf")
            elif [ "${STUDY}" == "offered-load-scaling" ];then
                LOOP3=($(seq 0.1 0.1 0.1))
            elif [ "${STUDY}" == "verification" ];then
                LOOP3=($(seq 0.2 0.2 2.0))
            elif [ "${STUDY}" == "routing-comparison" ];then
                LOOP3=("adaptive" "minimal")
            elif [ "${STUDY}" == "msg-size-scaling" ];then
                LOOP3=("8" "16" "32" "64" "128" "256" "512" "1024" "2048" "4096" "8192" "16384" "32768" "65536")
            elif [ "${STUDY}" == "chip-scaling" ];then
                if [ "${L1}" == "sfly" ];then
                    LOOP3=("761" "1521" "3042" "6084" "12168")
                    LOOP3=("3042")
                elif [ "${L1}" == "dfly" ];then
                    LOOP3=("768" "1536" "3072" "6144" "12288")
                elif [ "${L1}" == "ddfly" ];then
                    LOOP3=("800" "1600" "3200" "6400" "12800")
                else
                    LOOP3=("810" "1620" "3240" "6480" "12960")
                    #LOOP3=("12960")
                fi
                if [ "$BACKGROUND_JOB" == "mnist" ];then
                    LOOP3=("155" "309" "617" "1234" "2467")
                elif [ "$BACKGROUND_JOB" == "cifar" ]; then
                    LOOP3=("128" "256" "512" "1024" "2048")
                    LOOP3=("128")
                fi
            elif [ "${STUDY}" == "buffer-scaling" ];then
                #if [ "${L1}" == "sfly" ];then
                #    #LOOP3=("8192" "16384" "32768" "65536" "131072" "262144" "524288" "1048576")
                #    LOOP3=("8192")
                #elif [ "${L1}" == "ftree" ];then
                #    #LOOP3=("8192" "16384" "32768" "65536" "131072" "262144" "524288" "1048576")
                #    LOOP3=("8192")
                #elif [ "${L1}" == "dfly" ];then
                #    LOOP3=("8192" "16384")
                #fi
                LOOP3=("32768" "65536" "131072" "262144" "524288" "1048576")
            elif [ "${STUDY}" == "link-scaling" ];then
                LOOP3=("5" "7" "12.5" "25")
            elif [ "${STUDY}" == "aggregation-scaling" ];then
                LOOP3=("10" "50" "100" "250" "500")
                SPIKE_AGGREGATION_FLAG=1
            elif [ "${STUDY}" == "spike-aggregation" ];then
                LOOP3=("10")
                SPIKE_AGGREGATION_FLAG=1
            elif [ "${STUDY}" == "vis-sampling" ];then
                LOOP3=("1")
            elif [ "${STUDY}" == "single-tick" ];then
                TICK_INTERVAL=20000000   # Nanosecond length of a tick
                LOOP3=("1" "0")
            elif [ "${STUDY}" == "synthetic-comparison" ];then
                LOOP3=("1.5") #Injection Load
                LOOP3=($(seq 0.25 0.25 1.5))
            elif [ "${STUDY}" == "none" ];then
                LOOP3=("1")
            fi
            for L3 in ${LOOP3[@]};do
                VC_SIZE_INSTANCE=${VC_SIZE_DEFAULT}
                LINK_BANDWIDTH_INSTANCE=${LINK_BANDWIDTH_DEFAULT}
                if [ "${STUDY}" == "buffer-scaling" ];then
                    VC_SIZE_INSTANCE=${L3}
                elif [ "${STUDY}" == "link-scaling" ];then
                    LINK_BANDWIDTH_INSTANCE=${L3}
                elif [ "${STUDY}" == "offered-load-scaling" ];then
                    LOAD=${L3}
                    NUM_MSGS=40000
                elif [ "${STUDY}" == "verification" ];then
                    #TRAFFIC=1
                    WARM_UP_TIME=10000
                    SIM_END_TIME=20000
                    NUM_MSGS=2000000
                    LOAD=${L3}
                elif [ "${STUDY}" == "synthetic-comparison" ];then
                    #TRAFFIC=1
                    WARM_UP_TIME=0
                    NUM_MSGS=100
                    LOAD=${L3}
                elif [ "${STUDY}" == "routing-comparison" ];then
                    ROUTING_ALG=${L3}
                elif [ "${STUDY}" == "hybrid-jobs" ];then
                    BACKGROUND_JOB=${L3}
                elif [ "${STUDY}" == "msg-size-scaling" ];then
                    PAYLOAD_SIZE=${L3}
                elif [ "${STUDY}" == "spike-scaling" ];then
                    SPIKES_PER_TICK=${L3}
                elif [ "${STUDY}" == "aggregation-scaling" ];then
                    AGGREGATION_OVERHEAD=${L3}
                elif [ "${STUDY}" == "spike-aggregation" ];then
                    AGGREGATION_OVERHEAD=${L3}
                elif [ "${STUDY}" == "single-tick" ];then
                    SPIKE_AGGREGATION_FLAG=${L3} # 0: Don't perform spike aggregation. 1: Do perform spike aggregation
                else
                    BACKGROUND=${BACKGROUND}
                fi
                # Set network model specific params
                get_net_model_params
                if [ ${BACKGROUND} == 1 ];then
                    get_background_wrkld_params # Overwrites background params specific to each neuro workload. Some are further overwritten if doing a scaling study
                fi
                # Set study specific params
                if [ "${STUDY}" == "chip-scaling" ];then
                    BACKGROUND_RANKS=${L3}  # Set variable dependent on loop
                    if [ "$BACKGROUND_JOB" == "mnist" ];then
                        CHIP_FILE=${TRACE_DIR}/codes-nemo/chip-connection-files/mnist-nonzero-${L3}chips.csv
                    elif [ "$BACKGROUND_JOB" == "cifar" ]; then
                        CHIP_FILE=${TRACE_DIR}/codes-nemo/chip-connection-files/cifar100-nonzero-${L3}chips.csv
                    fi
                fi
                echo LOCAL_VC_SIZE: ${LOCAL_VC_SIZE}

                # Set trace params
                get_trace_params    # Makes call to "get_trace_params" function at bottom of this file
                if [ ${SYNTHETIC} == 1 ];then
                    if [ -z $SIM_END_TIME  ];then
                        SIM_END_TIME=1500000000
                    fi
                fi
                if [ ${BACKGROUND} == 1 ];then
                    SIM_END_TIME=580000
                fi
                if [ ${TRACE} == 1 ];then
                    if [ "${JOBS[0]}" == "amg1k" ];then
                        SIM_END_TIME=580000
                    elif [ "${JOBS[0]}" == "cr1k" ];then
                        SIM_END_TIME=1000000000
                    elif [ "${JOBS[0]}" == "mg1k" ];then
                        SIM_END_TIME=100000000
                    else
                        echo Trace job type ${JOBS[0]} is not supported for sim_end_time
                        exit
                    fi
                fi
                # Set default number of rails to 1
                NUM_RAILS=1
                # Setting Trace Sampling metrics
                echo Simulation End Time: ${SIM_END_TIME} Sampling Points: ${SAMPLING_POINTS}
                SAMPLING_INTERVAL=$(( ${SIM_END_TIME} / ${SAMPLING_POINTS} ))
                SAMPLING_END_TIME=${SIM_END_TIME}

                echo "|||||||||||||||||||||||||||| Running Sim ${COUNT_SIMS}/${TOTAL_SIMS} ||||||||||||||||||||||||||"
                COUNT_SIMS=$(( ${COUNT_SIMS} +1 ))
                # Network model-net group conf params
                echo "Setting model-net conf params"
                if [ "$NET_MODEL_SIZE" == "150" ]
                then
                    echo System Size: 150 nodes
                    if [ "$NET_MODEL" == "sfly" ] || [ "$NET_MODEL" == "ffly" ]
                    then
                        REPS=50
                        NUM_ROUTERS=5
                        LOCAL_CHANNELS=2
                        GENERATOR_SET_X='("1","4");'        #   : Subgraph 0 generator set
                        GENERATOR_SET_X_PRIME='("2","3");'   #   : Subgraph 1 generator set
                        MODELNET_SLIMFLY=3
                        SERVERS=3
                    fi
                fi
                if [ "$NET_MODEL_SIZE" == "3k" ]
                then
                    echo System Size: 3k nodes
                    if [ "$NET_MODEL" == "ftree" ] || [ "$NET_MODEL" == "ftree2" ]
                    then
                        MODELNET_FATTREE=18
                        SERVERS=18      # Number of server LPs to deploy per terminal
                    elif [ "$NET_MODEL" == "sfly" ] || [ "$NET_MODEL" == "ffly" ]
                    then
                        REPS=338
                        NUM_ROUTERS=13
                        LOCAL_CHANNELS=6
                        GENERATOR_SET_X='("1","10","9","12","3","4");'        #   : Subgraph 0 generator set
                        GENERATOR_SET_X_PRIME='("6","8","2","7","5","11");'   #   : Subgraph 1 generator set
                        MODELNET_SLIMFLY=9
                        SERVERS=9      # Number of server LPs to deploy per terminal
                    elif [ "$NET_MODEL" == "dfly" ]
                    then
                        MODELNET_DRAGONFLY_CUSTOM=4
                        MODELNET_DRAGONFLY_CUSTOM_ROUTER=1
                        SERVERS=4      # Number of server LPs to deploy per terminal
                    elif [ "$NET_MODEL" == "ddfly" ]
                    then
                        MODELNET_DRAGONFLY_CUSTOM=8
                        MODELNET_DRAGONFLY_CUSTOM_ROUTER=1
                        SERVERS=8      # Number of server LPs to deploy per terminal
                    fi
                elif [ "$NET_MODEL_SIZE" == "74k" ]
                then
                    echo System Size: 74k nodes
                    REPS=2738
                    NUM_ROUTERS=37
                    LOCAL_CHANNELS=18
                    GENERATOR_SET_X='("1","25","33","11","16","30","10","28","34","36","12","4","26","21","7","27","9","3");'
                    GENERATOR_SET_X_PRIME='("32","23","20","19","31","35","24","8","15","5","14","17","18","6","2","13","29","22");'
                    MODELNET_SLIMFLY=27
                    SERVERS=27
                elif [ "$NET_MODEL_SIZE" == "1m" ]
                then
                    echo System Size: 1m nodes
                    echo sys 1m
                    REPS=53138
                    NUM_ROUTERS=163
                    LOCAL_CHANNELS=82
                    GENERATOR_SET_X='("1","46","160","25","9","88","136","62","81","140","83","69","77","119","95","132","41","93","40","47","43","22","34","97","61","35","143","58","60","152","146","33","51","64","10","134","133","87","90","65","56","117","3","138","154","75","27","101","82","23","80","94","86","44","68","31","122","70","123","116","120","141","129","66","102","128","20","105","103","11","17","130","112","99","153","29","30","76","73","98","107","162");'
                    GENERATOR_SET_X_PRIME='("32","5","67","148","125","45","114","28","147","79","48","89","19","59","106","149","8","42","139","37","72","52","110","7","159","142","12","63","127","137","108","78","2","92","157","50","18","13","109","124","131","158","96","15","38","118","49","135","16","84","115","74","144","104","57","14","155","121","24","126","91","111","53","156","4","21","151","100","36","26","55","85","161","71","6","113","145","150","54","39","1","162");'
                    MODELNET_SLIMFLY=19
                fi
                if [ "$NET_MODEL" == "ftree" ] || [ "$NET_MODEL" == "ftree2" ]
                then
                    FATTREE_SWITCH=${NUM_LEVELS}
                    MODELNET_ORDER=fattree
                    SWITCH_COUNT=${REPS}
                    SWITCH_RADIX=36
                    RAILS=1
                    TERMINAL_RADIX=${RAILS}
                    if [ ${FT_TYPE} == 2 ];then
                        FATTREE_SWITCH=6
                        NUM_RAILS=2
                    fi
                elif [ "$NET_MODEL" == "sfly" ] || [ "$NET_MODEL" == "ffly" ]
                then
                    SLIMFLY_ROUTER=1
                    MODELNET_ORDER=slimfly
                    NUM_TERMINALS=${MODELNET_SLIMFLY}
                    GLOBAL_CHANNELS=${NUM_ROUTERS}
                    NUM_VCS=4
                    LINK_DELAY=0
                    CSF_RATIO=1
                    if [ ${SF_TYPE} == 1 ];then
                        SLIMFLY_ROUTER=2
                        NUM_RAILS=2
                    fi
                elif [ "$NET_MODEL" == "dfly" ]
                then
                    NUM_ROUTER_ROWS=6
                    NUM_ROUTER_COLS=16
                    NUM_GLOBAL_CHANNELS=4
                    NUM_CNS_PER_ROUTER=${MODELNET_DRAGONFLY_CUSTOM}
                    MODELNET_ORDER='("dragonfly_custom","dragonfly_custom_router");'
                    ADAPTIVE_THRESHOLD=0
                    MINIMAL_BIAS=0      # Off or on
                elif [ "$NET_MODEL" == "ddfly" ]
                then
                    NUM_ROUTER_ROWS=1
                    NUM_ROUTER_COLS=16
                    NUM_GLOBAL_CHANNELS=12
                    NUM_CNS_PER_ROUTER=${MODELNET_DRAGONFLY_CUSTOM}
                    MODELNET_ORDER='("dragonfly_custom","dragonfly_custom_router");'
                    ADAPTIVE_THRESHOLD=0
                    MINIMAL_BIAS=0      # Off or on
                fi

                # Compute Total Number of Nodes
                if [ "$NET_MODEL" == "ftree" ] || [ "$NET_MODEL" == "ftree2" ]
                then
                    TOTAL_NODES=$(( ${MODELNET_FATTREE} * ${REPS} ))
                elif [ "$NET_MODEL" == "sfly" ] || [ "$NET_MODEL" == "ffly" ]
                then
                    TOTAL_NODES=$(( ${MODELNET_SLIMFLY} * ${REPS} ))
                elif [ "$NET_MODEL" == "dfly" ] || [ "$NET_MODEL" == "ddfly" ]
                then
                    TOTAL_NODES=$(( ${MODELNET_DRAGONFLY_CUSTOM} * ${REPS} ))
                fi

                # Check if need to change heterogeneous alloc policy for single job run
                if [ "${ALLOC_POLICY}" == "heterogeneous" ];then
                    if [ ${TRACE} == 0 ] || [ ${BACKGROUND} == 0 ];then
                        ALLOC_POLICY=("CONT")
                    fi
                fi

                # Calculate number of nw_lps per repetition based on total number of ranks and total nodes
                TOTAL_RANKS=0
                if [ ${TRACE} == 1 ];then
                    TOTAL_RANKS=$((${TOTAL_RANKS} + ${RANKS_PER_JOB}))
                fi
                if [ ${BACKGROUND} == 1 ];then
                    TOTAL_RANKS=$((${TOTAL_RANKS} + ${BACKGROUND_RANKS}))
                fi
                if [ "$NET_MODEL" == "ftree" ] || [ "$NET_MODEL" == "ftree2" ]
                then
                    if [ "${ALLOC_POLICY}" == "heterogeneous" ];then
                        NW_LP=$(( 2 * ${MODELNET_FATTREE} ))
                    else
                        NW_LP=$(( $(( $(( ${TOTAL_RANKS} + ${TOTAL_NODES} - 1 )) / ${TOTAL_NODES} )) * ${MODELNET_FATTREE} ))
                    fi
                elif [ "$NET_MODEL" == "sfly" ] || [ "$NET_MODEL" == "ffly" ]
                then
                    if [ "${ALLOC_POLICY}" == "heterogeneous" ];then
                        NW_LP=$(( 2 * ${MODELNET_SLIMFLY} ))
                    else
                        NW_LP=$(( $(( $(( ${TOTAL_RANKS} + ${TOTAL_NODES} - 1 )) / ${TOTAL_NODES} )) * ${MODELNET_SLIMFLY} ))
                    fi
                elif [ "$NET_MODEL" == "dfly" ] || [ "$NET_MODEL" == "ddfly" ]
                then
                    if [ "${ALLOC_POLICY}" == "heterogeneous" ];then
                        NW_LP=$(( 2 * ${MODELNET_DRAGONFLY_CUSTOM} ))
                    else
                        NW_LP=$(( $(( $(( ${TOTAL_RANKS} + ${TOTAL_NODES} - 1 )) / ${TOTAL_NODES} )) * ${MODELNET_DRAGONFLY_CUSTOM} ))
                    fi
                fi

                # Calculate number of mpi ranks per node for mapping jobs
                if [ "$NET_MODEL" == "ftree" ] || [ "$NET_MODEL" == "ftree2" ]
                then
                    NUM_CORES_PER_NODE=$(( ${NW_LP} / ${MODELNET_FATTREE} ))
                elif [ "$NET_MODEL" == "sfly" ] || [ "$NET_MODEL" == "ffly" ]
                then
                    NUM_CORES_PER_NODE=$(( ${NW_LP} / ${MODELNET_SLIMFLY} ))
                elif [ "$NET_MODEL" == "dfly" ] || [ "$NET_MODEL" == "ddfly" ]
                then
                    NUM_CORES_PER_NODE=$(( ${NW_LP} / ${MODELNET_DRAGONFLY_CUSTOM} ))
                fi

                # Execution Paths
                if [ ${TRACE} == 1 ] || [ ${BACKGROUND} == 1 ]
                then
                    EXE_PATH=${BUILD_DIR}/src/network-workloads/model-net-mpi-replay
                    if [ ${DEBUG} == 1 ];then
                        EXE_PATH=${BUILD_DIR}/src/network-workloads/.libs/model-net-mpi-replay
                    fi
                elif [ ${SYNTHETIC} == 1 ];then
                    EXE_PATH=${BUILD_DIR}/src/network-workloads/model-net-synthetic-all
                    if [ ${DEBUG} == 1 ];then
                        EXE_PATH=${BUILD_DIR}/src/network-workloads/.libs/model-net-synthetic-all
                    fi
                    #if [ "$NET_MODEL" == "sfly" ] || [ "$NET_MODEL" == "ffly" ];then
                    #    EXE_PATH=${BUILD_DIR}/src/network-workloads/model-net-synthetic-slimfly
                    #    if [ ${DEBUG} == 1 ];then
                    #        EXE_PATH=${BUILD_DIR}/src/network-workloads/.libs/model-net-synthetic-slimfly
                    #    fi
                    #elif [ "$NET_MODEL" == "dfly" ];then
                    #    EXE_PATH=${BUILD_DIR}/src/network-workloads/model-net-synthetic-custom-dfly
                    #    if [ ${DEBUG} == 1 ];then
                    #        EXE_PATH=${BUILD_DIR}/src/network-workloads/.libs/model-net-synthetic-custom-dfly
                    #    fi
                    #elif [ "$NET_MODEL" == "ftree" ];then
                    #    EXE_PATH=${BUILD_DIR}/src/network-workloads/model-net-synthetic-fattree
                    #    if [ ${DEBUG} == 1 ];then
                    #        EXE_PATH=${BUILD_DIR}/src/network-workloads/.libs/model-net-synthetic-fattree
                    #    fi
                    #else
                    #    echo "synthetic workload execution is not supported for the ${NET_MODEL} model"
                    #    exit
                    #fi
                fi

                # Create LP_IO Directory Name
                create_lp_io_dir_name

                if [ ${SIM} == 1 ]
                then
                    # Create Network Config File
                    NETWORK_CONF=${TEMP_LP_IO_DIR}/network-model.conf
                    create_net_conf

                    if [ ${TRACE} == 1 ] || [ ${BACKGROUND} == 1 ]
                    then
                        # Generate Dumpi Allocation File
                        NUM_ALLOCS=1
                        create_alloc_conf
                    fi

                    # Execute Simulation
                    WRKLD_TYPE=dumpi
                    tmp_string=""
                    if [ ${TRACE} == 1 ];then
                        tmp_string+="Trace "
                    fi
                    if [ ${BACKGROUND} == 1 ];then
                        tmp_string+="Background "
                    fi
                    if [ ${SYNTHETIC} == 1 ];then
                        tmp_string+="Synthetic "
                    fi
                    if [ ${DEBUG} == 1 ];then
                        tmp_string+="Debug "
                    fi
                    echo Executing ${tmp_string}Simultion...
                    rm -rf ${LP_IO_DIR}
                    if [ ${TRACE} == 1 ] || [ ${BACKGROUND} == 1 ]
                    then
                        ADDL_ARGS=""
                        if [ ${BACKGROUND} == 1 ]
                        then
                            ADDL_ARGS="--mean_interval=${MEAN_INTERVAL}"
                        fi
                        if [ "$EXE_SYS" == "CCI" ]
                        then
                            SBATCH_SCRIPT=${TEMP_LP_IO_DIR}/sbatch-script.sh
                            echo "#!/bin/bash" > ${SBATCH_SCRIPT}
                            echo -n "srun -t ${TIME_ALLOC} -N ${NUM_NODES} -n ${NUM_PROCESSES}  -o ${TEMP_LP_IO_DIR}/srun-log ${EXE_PATH} --synch=${SYNCH}" >> ${SBATCH_SCRIPT}
                            echo -n " --batch=${BATCH} --gvt-interval=${GVT} --max-opt-lookahead=${MAX_OPT_LOOKAHEAD}" >> ${SBATCH_SCRIPT}
                            echo -n " --workload_type=${WRKLD_TYPE} --workload_conf_file=${WRKLD_CONF_FILE}" >> ${SBATCH_SCRIPT}
                            echo -n " --alloc_file=${ALLOC_CONF} --lp-io-dir=${LP_IO_DIR}" >> ${SBATCH_SCRIPT}
                            echo -n " --enable_sampling=${ENABLE_SAMPLING} --sampling_interval=${SAMPLING_INTERVAL}" >> ${SBATCH_SCRIPT}
                            echo -n " --sampling_end_time=${SAMPLING_END_TIME} --disable_compute=${DISABLE_COMPUTE} --extramem=${EXTRAMEM} ${ADDL_ARGS} --end=${SIM_END_TIME}" >> ${SBATCH_SCRIPT}
                            echo -n " --spikes_per_tick=${SPIKES_PER_TICK} --spike_size=${SPIKE_SIZE} --tick_interval=${TICK_INTERVAL}" >> ${SBATCH_SCRIPT}
                            echo -n " --chip_connections=${CHIP_CONNECTIONS} --chip_file=${CHIP_FILE}" >> ${SBATCH_SCRIPT}
                            echo -n " --spike_aggregation_flag=${SPIKE_AGGREGATION_FLAG} --aggregation_overhead=${AGGREGATION_OVERHEAD}" >> ${SBATCH_SCRIPT}
                            echo " -- ${NETWORK_CONF} | tee ${TEMP_LP_IO_DIR}/stdout-output " >> ${SBATCH_SCRIPT}
                            echo "# Save all variables to file" >> ${SBATCH_SCRIPT}
                            ( set -o posix ; set ) >> ${TEMP_LP_IO_DIR}/execution-variables
                            # Copy config files to the LP-IO-DIR
                            move_config_files
                            chmod +x ${SBATCH_SCRIPT}
                            sbatch --time=${TIME_ALLOC} --nodes=${NUM_NODES} --mail-type=END --mail-user=nwolfey21@gmail.com ${SBATCH_SCRIPT}
                            echo "Submitted Sbatch job ${LP_IO_DIR}" 
                        else
                            if [ ${DEBUG} == 1 ] && [ ${SYNCH} == 1 ];then
                                gdb --args ${EXE_PATH} --synch=1 --batch=${BATCH} --gvt-interval=${GVT} --max-opt-lookahead=${MAX_OPT_LOOKAHEAD} \
                                    --workload_type=${WRKLD_TYPE} --workload_conf_file=${WRKLD_CONF_FILE} \
                                    --alloc_file=${ALLOC_CONF} --lp-io-dir=${LP_IO_DIR} \
                                    --enable_sampling=${ENABLE_SAMPLING} --sampling_interval=${SAMPLING_INTERVAL} \
                                    --sampling_end_time=${SAMPLING_END_TIME} --disable_compute=${DISABLE_COMPUTE} --extramem=${EXTRAMEM} ${ADDL_ARGS} --end=${SIM_END_TIME} \
                                    --spikes_per_tick=${SPIKES_PER_TICK} --spike_size=${SPIKE_SIZE} --tick_interval=${TICK_INTERVAL} --chip_connections=${CHIP_CONNECTIONS} --chip_file=${CHIP_FILE} \
                                    --spike_aggregation_flag=${SPIKE_AGGREGATION_FLAG} --aggregation_overhead=${AGGREGATION_OVERHEAD} \
                                    --analysis-lps=4 --vt-interval=12000 --vt-samp-end=${SIM_END_TIME} \
                                    -- ${NETWORK_CONF} | tee ${TEMP_LP_IO_DIR}/stdout-output
                            elif [ ${DEBUG} == 1 ] && [ ${SYNCH} == 3 ];then
                                mpirun -n ${NUM_PROCESSES} xterm -e gdb --args ${EXE_PATH} --synch=1 --batch=${BATCH} --gvt-interval=${GVT} --max-opt-lookahead=${MAX_OPT_LOOKAHEAD} \
                                    --workload_type=${WRKLD_TYPE} --workload_conf_file=${WRKLD_CONF_FILE} \
                                    --alloc_file=${ALLOC_CONF} --lp-io-dir=${LP_IO_DIR} \
                                    --enable_sampling=${ENABLE_SAMPLING} --sampling_interval=${SAMPLING_INTERVAL} \
                                    --sampling_end_time=${SAMPLING_END_TIME} --disable_compute=${DISABLE_COMPUTE} --extramem=${EXTRAMEM} ${ADDL_ARGS} --end=${SIM_END_TIME} \
                                    --spikes_per_tick=${SPIKES_PER_TICK} --spike_size=${SPIKE_SIZE} --tick_interval=${TICK_INTERVAL} --chip_connections=${CHIP_CONNECTIONS} --chip_file=${CHIP_FILE} \
                                    --spike_aggregation_flag=${SPIKE_AGGREGATION_FLAG} --aggregation_overhead=${AGGREGATION_OVERHEAD} \
                                    -- ${NETWORK_CONF} | tee ${TEMP_LP_IO_DIR}/stdout-output
                            else
                                if [ "${STUDY}" == "vis-sampling" ];then
                                    mpirun -n ${NUM_PROCESSES} ${EXE_PATH} --synch=${SYNCH} --batch=${BATCH} --gvt-interval=${GVT} --max-opt-lookahead=${MAX_OPT_LOOKAHEAD} \
                                        --workload_type=${WRKLD_TYPE} --workload_conf_file=${WRKLD_CONF_FILE} \
                                        --alloc_file=${ALLOC_CONF} --lp-io-dir=${LP_IO_DIR} \
                                        --enable_sampling=${ENABLE_SAMPLING} --sampling_interval=${SAMPLING_INTERVAL} \
                                        --sampling_end_time=${SAMPLING_END_TIME} --disable_compute=${DISABLE_COMPUTE} --extramem=${EXTRAMEM} ${ADDL_ARGS} --end=${SIM_END_TIME} \
                                        --spikes_per_tick=${SPIKES_PER_TICK} --spike_size=${SPIKE_SIZE} --tick_interval=${TICK_INTERVAL} --chip_connections=${CHIP_CONNECTIONS} --chip_file=${CHIP_FILE} \
                                        --spike_aggregation_flag=${SPIKE_AGGREGATION_FLAG} --aggregation_overhead=${AGGREGATION_OVERHEAD} \
                                        --analysis-lps=4 --vt-interval=6000 --vt-samp-end=${SIM_END_TIME} \
                                        -- ${NETWORK_CONF} | tee ${TEMP_LP_IO_DIR}/stdout-output
                                else
                                    mpirun -n ${NUM_PROCESSES} ${EXE_PATH} --synch=${SYNCH} --batch=${BATCH} --gvt-interval=${GVT} --max-opt-lookahead=${MAX_OPT_LOOKAHEAD} \
                                        --workload_type=${WRKLD_TYPE} --workload_conf_file=${WRKLD_CONF_FILE} \
                                        --alloc_file=${ALLOC_CONF} --lp-io-dir=${LP_IO_DIR} \
                                        --enable_sampling=${ENABLE_SAMPLING} --sampling_interval=${SAMPLING_INTERVAL} \
                                        --sampling_end_time=${SAMPLING_END_TIME} --disable_compute=${DISABLE_COMPUTE} --extramem=${EXTRAMEM} ${ADDL_ARGS} --end=${SIM_END_TIME} \
                                        --spikes_per_tick=${SPIKES_PER_TICK} --spike_size=${SPIKE_SIZE} --tick_interval=${TICK_INTERVAL} --chip_connections=${CHIP_CONNECTIONS} --chip_file=${CHIP_FILE} \
                                        --spike_aggregation_flag=${SPIKE_AGGREGATION_FLAG} --aggregation_overhead=${AGGREGATION_OVERHEAD} \
                                        -- ${NETWORK_CONF} | tee ${TEMP_LP_IO_DIR}/stdout-output
                                fi
                            fi
                            echo mpirun -n ${NUM_PROCESSES} ${EXE_PATH} --synch=${SYNCH} \
                                --workload_type=${WRKLD_TYPE} --workload_conf_file=${WRKLD_CONF_FILE} \
                                --alloc_file=${ALLOC_CONF} --lp-io-dir=${LP_IO_DIR} \
                                --enable_sampling=${ENABLE_SAMPLING} --sampling_interval=${SAMPLING_INTERVAL} \
                                --sampling_end_time=${SAMPLING_END_TIME} --disable_compute=${DISABLE_COMPUTE} --extramem=${EXTRAMEM} ${ADDL_ARGS} --end=${SIM_END_TIME} \
                                --spikes_per_tick=${SPIKES_PER_TICK} --spike_size=${SPIKE_SIZE} --tick_interval=${TICK_INTERVAL} --chip_connections=${CHIP_CONNECTIONS} --chip_file=${CHIP_FILE} \
                                -- ${NETWORK_CONF}
                            # Copy config files to the LP-IO-DIR
                            move_config_files
                        fi
                    elif [ ${SYNTHETIC} == 1 ];then
                        if [ ${DEBUG} == 1 ] && [ ${SYNCH} == 1 ];then
                            gdb --args ${EXE_PATH} --synch=${SYNCH} --extramem=${EXTRAMEM} \
                                --traffic=${TRAFFIC} --load=${LOAD} --num_messages=${NUM_MSGS} --payload_size=${PAYLOAD_SIZE} --lp-io-dir=${LP_IO_DIR} --end=${SIM_END_TIME} --warm_up_time=${WARM_UP_TIME} \
                                -- ${NETWORK_CONF} | tee ${TEMP_LP_IO_DIR}/stdout-output
                            echo gdb --args ${EXE_PATH} --synch=${SYNCH} \
                                --traffic=${TRAFFIC} --load=${LOAD} --num_messages=${NUM_MSGS} --payload_size=${PAYLOAD_SIZE} --lp-io-dir=${LP_IO_DIR} --end=${SIM_END_TIME} --warm_up_time=${WARM_UP_TIME} \
                                -- ${NETWORK_CONF} | tee ${TEMP_LP_IO_DIR}/stdout-output
                        elif [ ${DEBUG} == 1 ] && [ ${SYNCH} != 1 ];then
                            echo "Running in Debug with SYNCH other than 1 is not supported at the moment. Try again later?"
                        else
                            mpirun -n ${NUM_PROCESSES} ${EXE_PATH} --synch=${SYNCH} --extramem=${EXTRAMEM} \
                                --traffic=${TRAFFIC} --load=${LOAD} --num_messages=${NUM_MSGS} --payload_size=${PAYLOAD_SIZE} --lp-io-dir=${LP_IO_DIR} --end=${SIM_END_TIME} --warm_up_time=${WARM_UP_TIME} \
                                -- ${NETWORK_CONF} | tee ${TEMP_LP_IO_DIR}/stdout-output
                            echo mpirun -n ${NUM_PROCESSES} ${EXE_PATH} --synch=${SYNCH} \
                                --traffic=${TRAFFIC} --load=${LOAD} --num_messages=${NUM_MSGS} --payload_size=${PAYLOAD_SIZE} --lp-io-dir=${LP_IO_DIR} --end=${SIM_END_TIME} --warm_up_time=${WARM_UP_TIME} \
                                -- ${NETWORK_CONF} | tee ${TEMP_LP_IO_DIR}/stdout-output
                        fi
                        # Copy config files to the LP-IO-DIR
                        move_config_files
                    fi
                fi
                # Execute Post Processing and Visualization in Background
                if [ ${COMM_MAP} == 1 ];then
                    echo Executing Post Process Generation of the Communication Heat Map
                    python ${SCRIPTS_DIR}/workloads/heatmap.py --input-file-path ${ANALYSIS_DIR}/${TEMP_DIR2}/communication-map --output-file-path ${ANALYSIS_DIR}/${TEMP_DIR2}/communication-heatmap.pdf --num-procs ${TOTAL_NODES}
                fi
                if [ ${VIS} == 1 ]
                then
                    TEMP_DIR=${JOBS[0]}
                    if (( $NUM_JOBS > 1 ))
                    then
                        for i in `seq 1 1 $(( ${NUM_JOBS} -1))`
                        do
                            TEMP_DIR=${TEMP_DIR},${JOBS[$i]}
                        done
                    fi
                    echo Executing Post Process Analysis and Visualization in Background...
                    python -i ${PROCESSING_EXE_PATH} --lp-io-dir ${LP_IO_DIR}/ --disable-aggregate  --individual --trace-names ${TEMP_DIR}
                fi
            done
        done
    done
}

get_trace_params() {
    # Application Traces
    echo "Selecting Application Trace/s"
    if [ "$JOBS" == "amg1k" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/df_AMG_n1728_dumpi/dumpi-2014.03.03.14.55.50-")
        RANKS_PER_JOB=("1728")
    elif [ "$JOBS" == "amg13k" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/df_AMG_n13824_dumpi/dumpi-2014.03.03.15.09.03-")
        RANKS_PER_JOB=("13824")
    elif [ "$JOBS" == "mg1k" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/MultiGrid_C_n1000_dumpi/dumpi-2014.03.07.00.25.12-")
        RANKS_PER_JOB=("1000")
    elif [ "$JOBS" == "mg10k" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/MultiGrid_C_n10648_dumpi/dumpi-2014.03.07.00.39.10-")
        RANKS_PER_JOB=("10648")
    elif [ "$JOBS" == "mg110k" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/MultiGrid_C_n110592_dumpi/dumpi-2014.03.13.03.09.22-")
        RANKS_PER_JOB=("110592")
    elif [ "$JOBS" == "cr1k" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/CrystalRouter_n1000_dumpi/dumpi--2014.04.23.12.17.17-")
        RANKS_PER_JOB=("1000")
    elif [ "$JOBS" == "cr10" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/CrystalRouter_n10_dumpi/dumpi--2014.04.23.12.08.27-")
        RANKS_PER_JOB=("10")
    elif [ "$JOBS" == "cr10regen" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/CrystalRouter_n10_dumpi_regenerated/dumpi--2014.04.23.12.08.27-")
        RANKS_PER_JOB=("10")
    elif [ "$JOBS" == "nemo8" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/UM/nemo8/dumpi--17.10.04.13.37.57-processed-n2d-")
        RANKS_PER_JOB=("8")
    elif [ "$JOBS" == "nemo760" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/UM/nemo760/dumpi--17.10.09.16.12.50-processed-n2d-")
        RANKS_PER_JOB=("760")
    elif [ "$JOBS" == "nemo1521sat" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/SAT/nemo1521/dumpi--17.10.08.09.31.44-processed-n2d-")
        RANKS_PER_JOB=("1521")
    elif [ "$JOBS" == "nemo3042" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/UM/nemo3042/dumpi--17.10.07.14.43.38-processed-n2d-")
        RANKS_PER_JOB=("3042")
    elif [ "$JOBS" == "nemo6084" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/UM/nemo6084/dumpi--17.10.07.23.16.18-processed-n2d-")
        RANKS_PER_JOB=("6084")
    elif [ "$JOBS" == "conv32" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/CONV/complete32/dumpi--17.11.19.20.17.45-processed-n2d-")
        RANKS_PER_JOB=("32")
    elif [ "$JOBS" == "conv4096" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/CONV/complete4096/dumpi--17.11.19.20.17.45-processed-n2d-")
        RANKS_PER_JOB=("4096")
    elif [ "$JOBS" == "mnist_2" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/CONV/mnist/2chip/dumpi--17.12.02.19.19.12-processed-n2d-")
        RANKS_PER_JOB=("2")
    elif [ "$JOBS" == "mnist_256" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/CONV/mnist/2chip/dumpi--17.12.02.-processed-n2d-")
        RANKS_PER_JOB=("144")
    elif [ "$JOBS" == "cifar_100_2" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/CONV/CIFAR_100/2chip/dumpi--17.12.04.13.29.15-processed-n2d-")
        RANKS_PER_JOB=("2")
    elif [ "$JOBS" == "cifar_100_16" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/CONV/CIFAR_100/16_core/dumpi--17.12.01.08.30.36-processed-n2d-")
        RANKS_PER_JOB=("16")
    elif [ "$JOBS" == "cifar_100_4096" ]
    then
        TRACE_PREFIXES=("${TRACE_DIR}/CONV/CIFAR_100/4096_core/dumpi--17.12.01.08.44.46-processed-n2d-")
        RANKS_PER_JOB=("4042")
    fi
}

get_background_wrkld_params(){
    echo "Selecting Background Workload/s"
    if [ "${BACKGROUND_JOB}" == "hf" ];then
        SPIKES_PER_TICK=10000
        CHIP_CONNECTIONS=0
    elif [ "$BACKGROUND_JOB" == "cifar" ];then
        SPIKES_PER_TICK=0
        CHIP_CONNECTIONS=1
        BACKGROUND_RANKS=1024
        CHIP_FILE=${TRACE_DIR}/codes-nemo/chip-connection-files/cifar100-nonzero-1024chips.csv
    elif [ "$BACKGROUND_JOB" == "mnist" ];then
        SPIKES_PER_TICK=0
        CHIP_CONNECTIONS=1
        BACKGROUND_RANKS=1234
        CHIP_FILE=${TRACE_DIR}/codes-nemo/chip-connection-files/mnist-nonzero-1234chips.csv
    elif [ "$BACKGROUND_JOB" == "none" ];then
        SPIKES_PER_TICK=0
        CHIP_CONNECTIONS=0
    fi

}

create_lp_io_dir_name() {
    if [ ${TRACE} == 1 ] || [ ${BACKGROUND} == 1 ]; then
        TEMP_DIR2=${NET_MODEL}-${TOTAL_NODES}nodes-${ROUTING_ALG}-${RAIL_SELECT}-${SIM_END_TIME}end-${VC_SIZE_INSTANCE}vc-${LINK_BANDWIDTH_INSTANCE}GBps-${ALLOC_POLICY}-
    else
        TEMP_DIR2=${NET_MODEL}-${TOTAL_NODES}nodes-${ROUTING_ALG}-${RAIL_SELECT}-${SIM_END_TIME}end-${VC_SIZE_INSTANCE}vc-${LINK_BANDWIDTH_INSTANCE}GBps-
    fi
    if [ ${TRACE} == 1 ]
    then
        TEMP_DIR=${JOBS[0]}
        if (( $NUM_JOBS > 1 ))
        then
            for i in `seq 1 1 $(( ${NUM_JOBS} -1))`
            do
                TEMP_DIR=${TEMP_DIR}-${JOBS[$i]}
            done
        fi
        TOTAL_NW_LP=$(( ${NW_LP} * ${REPS} ))
        NW_LP_PER_NODE=$(( ${TOTAL_NW_LP} / ${TOTAL_NODES} ))
        TEMP_DIR2+=trace-${TEMP_DIR}
    fi
    if [ ${BACKGROUND} == 1 ]
    then
        if [ ${TRACE} == 1 ];then
            TEMP_DIR2+=-
        fi
        TEMP_DIR2+=bkgnd-${BACKGROUND_JOB}-${MEAN_INTERVAL}mintvl-${TICK_INTERVAL}tintvl-${BACKGROUND_RANKS}ranks-${SPIKES_PER_TICK}mpt-${SPIKE_SIZE}Bszmsg-${AGGREGATION_OVERHEAD}agg
    fi
    if [ ${SYNTHETIC} == 1 ]
    then
        TEMP_DIR2+=synthetic-traffic${TRAFFIC}-load${LOAD}-payloadsize${PAYLOAD_SIZE}
    fi
    LP_IO_DIR=${BUILD_DIR}/${TEMP_DIR2}
    TEMP_LP_IO_DIR=${BUILD_DIR}/TEMP_${TEMP_DIR2}/
    mkdir ${TEMP_LP_IO_DIR}
}

create_net_conf() {
    echo "Creating network config file"
    if [ "$NET_MODEL" == "sfly" ] || [ "$NET_MODEL" == "ffly" ]
    then
        # Generate slim fly network model conf file
        echo Generating network model conf file...
        echo "LPGROUPS" > ${NETWORK_CONF}
        echo "{" >> ${NETWORK_CONF}
        echo "    MODELNET_GRP" >> ${NETWORK_CONF}
        echo "    {" >> ${NETWORK_CONF}
        echo "        repetitions=\"${REPS}\";" >> ${NETWORK_CONF}
        if [ ${TRACE} == 1 ] || [ ${BACKGROUND} == 1 ]
        then
            echo "        nw-lp=\"${NW_LP}\";" >> ${NETWORK_CONF}
        else
            echo "        server=\"${SERVERS}\";" >> ${NETWORK_CONF}
        fi
        echo "        modelnet_slimfly=\"${MODELNET_SLIMFLY}\";" >> ${NETWORK_CONF}
        echo "        slimfly_router=\"${SLIMFLY_ROUTER}\";" >> ${NETWORK_CONF}
        echo "    }" >> ${NETWORK_CONF}
        echo "}" >> ${NETWORK_CONF}
        echo "PARAMS" >> ${NETWORK_CONF}
        echo "{" >> ${NETWORK_CONF}
        echo "    sf_type=\"${SF_TYPE}\";" >> ${NETWORK_CONF}
        echo "    num_rails=\"${NUM_RAILS}\";" >> ${NETWORK_CONF}
        echo "    rail_select=\"${RAIL_SELECT}\";" >> ${NETWORK_CONF}
        echo "    packet_size=\"${PACKET_SIZE}\";" >> ${NETWORK_CONF}
        echo "    message_size=\"${MESSAGE_SIZE}\";" >> ${NETWORK_CONF}
        echo "    chunk_size=\"${CHUNK_SIZE}\";" >> ${NETWORK_CONF}
        echo "    modelnet_scheduler=\"${MODELNET_SCHEDULER}\";" >> ${NETWORK_CONF}
        echo "    modelnet_order=( \"${MODELNET_ORDER}\" );" >> ${NETWORK_CONF}
        echo "    num_vcs=\"${NUM_VCS}\";" >> ${NETWORK_CONF}
        echo "    num_routers=\"${NUM_ROUTERS}\";" >> ${NETWORK_CONF}
        echo "    num_terminals=\"${NUM_TERMINALS}\";" >> ${NETWORK_CONF}
        echo "    local_channels=\"${LOCAL_CHANNELS}\";" >> ${NETWORK_CONF}
        echo "    global_channels=\"${GLOBAL_CHANNELS}\";" >> ${NETWORK_CONF}
        echo "    router_delay=\"${ROUTER_DELAY}\";" >> ${NETWORK_CONF}
        echo "    link_delay=\"${LINK_DELAY}\";" >> ${NETWORK_CONF}
        echo "    generator_set_X=${GENERATOR_SET_X}" >> ${NETWORK_CONF}
        echo "    generator_set_X_prime=${GENERATOR_SET_X_PRIME}" >> ${NETWORK_CONF}
        echo "    local_vc_size=\"${LOCAL_VC_SIZE}\";" >> ${NETWORK_CONF}
        echo "    global_vc_size=\"${GLOBAL_VC_SIZE}\";" >> ${NETWORK_CONF}
        echo "    cn_vc_size=\"${CN_VC_SIZE}\";" >> ${NETWORK_CONF}
        echo "    local_bandwidth=\"${LOCAL_BANDWIDTH}\";" >> ${NETWORK_CONF}
        echo "    global_bandwidth=\"${GLOBAL_BANDWIDTH}\";" >> ${NETWORK_CONF}
        echo "    cn_bandwidth=\"${CN_BANDWIDTH}\";" >> ${NETWORK_CONF}
        echo "    routing=\"${ROUTING_ALG}\";" >> ${NETWORK_CONF}
        echo "    csf_ratio=\"${CSF_RATIO}\";" >> ${NETWORK_CONF}
        echo "    num_injection_queues=\"${NUM_INJECTION_QUEUES}\";" >> ${NETWORK_CONF}
        echo "    nic_seq_delay=\"${NIC_SEQ_DELAY}\";" >> ${NETWORK_CONF}
        echo "    node_copy_queues=\"${NODE_COPY_QUEUES}\";" >> ${NETWORK_CONF}
        echo "    node_eager_limit=\"${NODE_EAGER_LIMIT}\";" >> ${NETWORK_CONF}
        echo "}" >> ${NETWORK_CONF}

    elif [ "$NET_MODEL" == "dfly" ] || [ "$NET_MODEL" == "ddfly" ]
    then
        # Generate dragonfly network model conf file
        echo Generating network model conf file...
        echo "LPGROUPS" > ${NETWORK_CONF}
        echo "{" >> ${NETWORK_CONF}
        echo "    MODELNET_GRP" >> ${NETWORK_CONF}
        echo "    {" >> ${NETWORK_CONF}
        echo "        repetitions=\"${REPS}\";" >> ${NETWORK_CONF}
        if [ ${TRACE} == 1 ] || [ ${BACKGROUND} == 1 ]
        then
            echo "        nw-lp=\"${NW_LP}\";" >> ${NETWORK_CONF}
        else
            echo "        server=\"${SERVERS}\";" >> ${NETWORK_CONF}
        fi
        echo "        modelnet_dragonfly_custom=\"${MODELNET_DRAGONFLY_CUSTOM}\";" >> ${NETWORK_CONF}
        echo "        modelnet_dragonfly_custom_router=\"${MODELNET_DRAGONFLY_CUSTOM_ROUTER}\";" >> ${NETWORK_CONF}
        echo "    }" >> ${NETWORK_CONF}
        echo "}" >> ${NETWORK_CONF}
        echo "PARAMS" >> ${NETWORK_CONF}
        echo "{" >> ${NETWORK_CONF}
        echo "    packet_size=\"${PACKET_SIZE}\";" >> ${NETWORK_CONF}
        echo "    message_size=\"${MESSAGE_SIZE}\";" >> ${NETWORK_CONF}
        echo "    chunk_size=\"${CHUNK_SIZE}\";" >> ${NETWORK_CONF}
        echo "    modelnet_scheduler=\"${MODELNET_SCHEDULER}\";" >> ${NETWORK_CONF}
        echo "    modelnet_order=${MODELNET_ORDER}" >> ${NETWORK_CONF}
        echo "    num_router_rows=\"${NUM_ROUTER_ROWS}\";" >> ${NETWORK_CONF}
        echo "    num_router_cols=\"${NUM_ROUTER_COLS}\";" >> ${NETWORK_CONF}
        echo "    num_groups=\"${NUM_GROUPS}\";" >> ${NETWORK_CONF}
        echo "    router_delay=\"${ROUTER_DELAY}\";" >> ${NETWORK_CONF}
        echo "    local_vc_size=\"${LOCAL_VC_SIZE}\";" >> ${NETWORK_CONF}
        echo "    global_vc_size=\"${GLOBAL_VC_SIZE}\";" >> ${NETWORK_CONF}
        echo "    cn_vc_size=\"${CN_VC_SIZE}\";" >> ${NETWORK_CONF}
        echo "    local_bandwidth=\"${LOCAL_BANDWIDTH}\";" >> ${NETWORK_CONF}
        echo "    global_bandwidth=\"${GLOBAL_BANDWIDTH}\";" >> ${NETWORK_CONF}
        echo "    cn_bandwidth=\"${CN_BANDWIDTH}\";" >> ${NETWORK_CONF}
        echo "    num_cns_per_router=\"${NUM_CNS_PER_ROUTER}\";" >> ${NETWORK_CONF}
        echo "    num_global_channels=\"${NUM_GLOBAL_CHANNELS}\";" >> ${NETWORK_CONF}
        echo "    intra-group-connections=\"${INTRA_GROUP_CONNECTIONS}\";" >> ${NETWORK_CONF}
        echo "    inter-group-connections=\"${INTER_GROUP_CONNECTIONS}\";" >> ${NETWORK_CONF}
        echo "    routing=\"${ROUTING_ALG}\";" >> ${NETWORK_CONF}
        echo "    adaptive_threshold=\"${ADAPTIVE_THRESHOLD}\";" >> ${NETWORK_CONF}
        echo "    minimal-bias=\"${MINIMAL_BIAS}\";" >> ${NETWORK_CONF}
        echo "    num_injection_queues=\"${NUM_INJECTION_QUEUES}\";" >> ${NETWORK_CONF}
        echo "    nic_seq_delay=\"${NIC_SEQ_DELAY}\";" >> ${NETWORK_CONF}
        echo "    node_copy_queues=\"${NODE_COPY_QUEUES}\";" >> ${NETWORK_CONF}
        echo "    node_eager_limit=\"${NODE_EAGER_LIMIT}\";" >> ${NETWORK_CONF}
        if [ "$NET_MODEL" == "ddfly" ];then
            echo "    df-dally-vc=\"1\";" >> ${NETWORK_CONF}
            echo "    num_row_chans=\"1\";" >> ${NETWORK_CONF}
            echo "    num_col_chans=\"1\";" >> ${NETWORK_CONF}
        fi
        echo "}" >> ${NETWORK_CONF}

    elif [ "$NET_MODEL" == "ftree" ] || [ "$NET_MODEL" == "ftree2" ]
    then
        # Generate fat-tree network model conf file
        echo Generating network model conf file...
        echo "LPGROUPS" > ${NETWORK_CONF}
        echo "{" >> ${NETWORK_CONF}
        echo "    MODELNET_GRP" >> ${NETWORK_CONF}
        echo "    {" >> ${NETWORK_CONF}
        echo "        repetitions=\"${REPS}\";" >> ${NETWORK_CONF}
        if [ ${TRACE} == 1 ] || [ ${BACKGROUND} == 1 ]
        then
            echo "        nw-lp=\"${NW_LP}\";" >> ${NETWORK_CONF}
        else
            echo "        server=\"${SERVERS}\";" >> ${NETWORK_CONF}
        fi
        echo "        modelnet_fattree=\"${MODELNET_FATTREE}\";" >> ${NETWORK_CONF}
        echo "        fattree_switch=\"${FATTREE_SWITCH}\";" >> ${NETWORK_CONF}
        echo "    }" >> ${NETWORK_CONF}
        echo "}" >> ${NETWORK_CONF}
        echo "PARAMS" >> ${NETWORK_CONF}
        echo "{" >> ${NETWORK_CONF}
        echo "    packet_size=\"${PACKET_SIZE}\";" >> ${NETWORK_CONF}
        echo "    message_size=\"${MESSAGE_SIZE}\";" >> ${NETWORK_CONF}
        echo "    chunk_size=\"${CHUNK_SIZE}\";" >> ${NETWORK_CONF}
        echo "    modelnet_scheduler=\"${MODELNET_SCHEDULER}\";" >> ${NETWORK_CONF}
        echo "    modelnet_order=( \"${MODELNET_ORDER}\" );" >> ${NETWORK_CONF}
        echo "    ft_type=\"${FT_TYPE}\";" >> ${NETWORK_CONF}
        echo "    num_rails=\"${NUM_RAILS}\";" >> ${NETWORK_CONF}
        echo "    rail_select=\"${RAIL_SELECT}\";" >> ${NETWORK_CONF}
        echo "    terminal_radix=\"${TERMINAL_RADIX}\";" >> ${NETWORK_CONF}
        echo "    num_levels=\"${NUM_LEVELS}\";" >> ${NETWORK_CONF}
        echo "    switch_count=\"${SWITCH_COUNT}\";" >> ${NETWORK_CONF}
        echo "    switch_radix=\"${SWITCH_RADIX}\";" >> ${NETWORK_CONF}
        echo "    router_delay=\"${ROUTER_DELAY}\";" >> ${NETWORK_CONF}
        echo "    vc_size=\"${VC_SIZE}\";" >> ${NETWORK_CONF}
        echo "    cn_vc_size=\"${CN_VC_SIZE}\";" >> ${NETWORK_CONF}
        echo "    link_bandwidth=\"${LINK_BANDWIDTH}\";" >> ${NETWORK_CONF}
        echo "    cn_bandwidth=\"${CN_BANDWIDTH}\";" >> ${NETWORK_CONF}
        echo "    routing=\"${ROUTING_ALG}\";" >> ${NETWORK_CONF}
        echo "    routing_folder=\"${ROUTING_FOLDER}\";" >> ${NETWORK_CONF}
        echo "    dot_file=\"${DOT_FILE}\";" >> ${NETWORK_CONF}
        echo "    dump_topo=\"${DUMP_TOPO}\";" >> ${NETWORK_CONF}
        echo "    num_injection_queues=\"${NUM_INJECTION_QUEUES}\";" >> ${NETWORK_CONF}
        echo "    nic_seq_delay=\"${NIC_SEQ_DELAY}\";" >> ${NETWORK_CONF}
        echo "    node_copy_queues=\"${NODE_COPY_QUEUES}\";" >> ${NETWORK_CONF}
        echo "    node_eager_limit=\"${NODE_EAGER_LIMIT}\";" >> ${NETWORK_CONF}
        echo "}" >> ${NETWORK_CONF}
    fi
}

create_alloc_conf() {
    echo Generating Dumpi Allocation File...
    ALLOC_EXE_PATH=${CODES_DIR}/scripts/allocation_gen/listgen-upd.py
    ALLOC_CLUSTER_EXE_PATH=${CODES_DIR}/scripts/job_placement/cluster/get_hostlists.py
    ALLOC_CONFIG_PATH=${TEMP_LP_IO_DIR}/alloc_config.conf
    ALLOC_CONF=${TEMP_LP_IO_DIR}/allocation.conf
    ID_CONVERSION_EXE_PATH=${CODES_DIR}/scripts/job_placement/nodeids-to-rankids.py
    WRKLD_CONF_FILE=${TEMP_LP_IO_DIR}/workload_conf_file.conf
    rm -rf ${ALLOC_CONF}
    rm -rf ${WRKLD_CONF_FILE}
    if [ ${TRACE} == 1 ]
    then
        if [ "$ALLOC_POLICY" == "CONT" ] || [ "$ALLOC_POLICY" == "rand" ]
        then
            echo Continuous or Rand allocation...
            echo ${ALLOC_CONFIG_PATH}
            echo ${ALLOC_POLICY} > ${ALLOC_CONFIG_PATH}
            if [ "$NET_MODEL" == "ftree" ] || [ "$NET_MODEL" == "ftree2" ]
            then
                echo $(( ${MODELNET_FATTREE} * ${REPS} )) >> ${ALLOC_CONFIG_PATH}
            elif [ "$NET_MODEL" == "sfly" ] || [ "$NET_MODEL" == "ffly" ]
            then
                echo $(( ${MODELNET_SLIMFLY} * ${REPS} )) >> ${ALLOC_CONFIG_PATH}
            elif [ "$NET_MODEL" == "dfly" ] || [ "$NET_MODEL" == "ddfly" ]
            then
                echo $(( ${MODELNET_DRAGONFLY_CUSTOM} * ${REPS} )) >> ${ALLOC_CONFIG_PATH}
            fi
            echo ${NUM_ALLOCS} >> ${ALLOC_CONFIG_PATH}
            echo ${NUM_CORES_PER_NODE} >> ${ALLOC_CONFIG_PATH}
            for i in `seq 0 1 $(( ${NUM_JOBS} -1))`
            do
                echo -n "${RANKS_PER_JOB[$i]} " >> ${ALLOC_CONFIG_PATH}
            done
            echo "" >> ${ALLOC_CONFIG_PATH}
            echo "python ${ALLOC_EXE_PATH} ${ALLOC_CONFIG_PATH}"
            python ${ALLOC_EXE_PATH} ${ALLOC_CONFIG_PATH}
            unset TEMP_NAME
            for i in `seq 0 1 $(( ${NUM_JOBS} -1))`
            do
                if (( $i == 0 ))
                then
                    TEMP_NAME=${RANKS_PER_JOB[$i]}
                else
                    TEMP_NAME=${TEMP_NAME}_${RANKS_PER_JOB[$i]}
                fi
            done
        elif [ "${ALLOC_POLICY}" == "cluster" ]
        then
            echo Cluster allocation...
            for i in `seq 0 1 $(( ${NUM_JOBS} -1))`
            do
                if (( $i == 0 ))
                then
                    TEMP_NAME_NODES=$(( ${RANKS_PER_JOB[$i]} / ${NW_LP_PER_NODE} ))
                    TEMP_NAME_RANKS=${RANKS_PER_JOB[$i]}
                else
                    TEMP_NAME_NODES=${TEMP_NAME_NODES},$(( ${RANKS_PER_JOB[$i]} / ${NW_LP_PER_NODE} ))
                    TEMP_NAME_RANKS=${TEMP_NAME_RANKS},${RANKS_PER_JOB[$i]}
                fi
            done
            python ${ALLOC_CLUSTER_EXE_PATH} -d Geometric -p 0.5 -j ${TEMP_NAME_NODES} -o ${ALLOC_CONF} -s 1 -u [0-$(( ${TOTAL_NODES} - 1 ))]
            echo Converting node IDs to rank IDs
            python ${ID_CONVERSION_EXE_PATH} --alloc-file ${ALLOC_CONF} --num-jobs ${NUM_JOBS} --num-nodes ${TOTAL_NODES} --num-traces-per-job ${TEMP_NAME_RANKS}  --num-ranks-per-node ${NW_LP_PER_NODE}
        fi
        if [ "$ALLOC_POLICY" == "CONT" ]
        then
            mv testrest.conf ${ALLOC_CONF}
        elif [ "$ALLOC_POLICY" == "rand" ]
        then
            if [ "$NET_MODEL" == "ftree" ] || [ "$NET_MODEL" == "ftree2" ]
            then
                mv rand_node1-alloc-$(( ${MODELNET_FATTREE} * ${REPS} ))-${TEMP_NAME}-$(( ${NUM_ALLOCS} -1 )).conf ${ALLOC_CONF}
            elif [ "$NET_MODEL" == "sfly" ] || [ "$NET_MODEL" == "ffly" ]
            then
                mv rand_node1-alloc-$(( ${MODELNET_SLIMFLY} * ${REPS} ))-${TEMP_NAME}-$(( ${NUM_ALLOCS} -1 )).conf ${ALLOC_CONF}
            elif [ "$NET_MODEL" == "dfly" ] || [ "$NET_MODEL" == "ddfly" ]
            then
                mv rand_node1-alloc-$(( ${MODELNET_DRAGONFLY_CUSTOM} * ${REPS} ))-${TEMP_NAME}-$(( ${NUM_ALLOCS} -1 )).conf ${ALLOC_CONF}
            fi
        elif [ "${ALLOC_POLICY}" == "heterogeneous" ]   # Currently only supports one trace job
        then
            echo Heterogeneous allocation...
            echo ${NW_LP}
            rm -rf ${ALLOC_CONF}
            for i in `seq 0 1 $(( ${REPS} -1))`
            do
                for j in `seq 0 1 $(( ${NW_LP} / 2 - 1 ))`
                do
                    result=$(( $i*${NW_LP}/2 + $j ))
                    if [ "${result}" -lt "$((${RANKS_PER_JOB[0]}))" ];then
                        temp=$(( $j + $i * ${NW_LP} ))
                        echo -n "${temp} " >> ${ALLOC_CONF}
                    fi
                done
            done
            #for i in `seq 0 2 $(( ${RANKS_PER_JOB[0]}*2 -1))`
            #do
            #    echo -n "${i} " >> ${ALLOC_CONF}
            #done
        fi
        # Generate Dumpi Workload Config File
        echo Generating Dumpi Workload Config File...
        for i in `seq 0 1 $(( ${NUM_JOBS} -1))`
        do
            if (( $i == 0 ))
            then
                echo "${RANKS_PER_JOB[$i]} ${TRACE_PREFIXES[$i]}" > ${WRKLD_CONF_FILE}
            else
                echo "${RANKS_PER_JOB[$i]} ${TRACE_PREFIXES[$i]}" >> ${WRKLD_CONF_FILE}
            fi
        done
    fi
    # Add Background ranks to allocation file
    if [ ${BACKGROUND} == 1 ]
    then
        if [ "${ALLOC_POLICY}" == "CONT" ]   # Currently only supports one trace job
        then
            if [ -e ${ALLOC_CONF} ]
            then
                echo -n -e "\n" >> ${ALLOC_CONF}
            fi
            for i in `seq 0 1 $(( ${BACKGROUND_RANKS} -1))`
            do
                echo -n "$i " >> ${ALLOC_CONF}
            done
        elif [ "${ALLOC_POLICY}" == "heterogeneous" ]   # Currently only supports one trace job
        then
            if [ -e ${ALLOC_CONF} ]
            then
                echo -n -e "\n" >> ${ALLOC_CONF}
            fi
            for i in `seq 0 1 $(( ${REPS} -1))`
            do
                for j in `seq 0 1 $(( ${NW_LP} / 2 - 1 ))`
                do
                    result=$(( $i*${NW_LP}/2 + $j ))
                    if [ "${result}" -lt "$((${BACKGROUND_RANKS}))" ];then
                        temp=$(( ${NW_LP}/2 + $j + $i * ${NW_LP} ))
                        echo -n "${temp} " >> ${ALLOC_CONF}
                    fi
                done
            done
            #for i in `seq 1 2 $(( ${BACKGROUND_RANKS}*2 -1))`
            #do
            #    echo -n "${i} " >> ${ALLOC_CONF}
            #done
        fi
    fi
    # Add Background params to workload config file
    if [ ${BACKGROUND} == 1 ]
    then
        echo -n -e "${BACKGROUND_RANKS} synthetic" >> ${WRKLD_CONF_FILE}
    fi
}

move_config_files() {
    # Move Simulation config files to lp-io-dir
    echo "Moving Simulation config files to lp-io-dir"
    if [ "${EXE_SYS}" == "CCI" ];then
        echo "" >> ${SBATCH_SCRIPT}
        echo "cp -r ${TEMP_LP_IO_DIR}/* ${LP_IO_DIR}" >> ${SBATCH_SCRIPT}
        #echo "cp ${SBATCH_SCRIPT} ${LP_IO_DIR}" >> ${SBATCH_SCRIPT}
        #echo "mv ${NETWORK_CONF} ${LP_IO_DIR}" >> ${SBATCH_SCRIPT}
        #echo "if [ ${TRACE} == 1 ] || [ ${BACKGROUND} == 1 ]" >> ${SBATCH_SCRIPT}
        #echo "then" >> ${SBATCH_SCRIPT}
	#    echo "    mv ${ALLOC_CONF} ${LP_IO_DIR}" >> ${SBATCH_SCRIPT}
	#    echo "    mv ${ALLOC_CONFIG_PATH} ${LP_IO_DIR}" >> ${SBATCH_SCRIPT}
	#    echo "    mv ${WRKLD_CONF_FILE} ${LP_IO_DIR}" >> ${SBATCH_SCRIPT}
        #echo "fi" >> ${SBATCH_SCRIPT}
        #echo "mv ${TEMP_LP_IO_DIR}/stdout-output ${LP_IO_DIR}" >> ${SBATCH_SCRIPT}
        echo "if [ "$NET_MODEL" == "dfly" ]" >> ${SBATCH_SCRIPT}
        echo "then" >> ${SBATCH_SCRIPT}
	    echo "    mv dragonfly* ${LP_IO_DIR}" >> ${SBATCH_SCRIPT}
        echo "fi" >> ${SBATCH_SCRIPT}
        #echo "mv ${TEMP_LP_IO_DIR}/execution-variables ${LP_IO_DIR}" >> ${SBATCH_SCRIPT}
        echo "# Copy output folder to analysis directory" >> ${SBATCH_SCRIPT}
        echo "if [ ${COPY_ANALYSIS} == 1 ]" >> ${SBATCH_SCRIPT}
        echo "then" >> ${SBATCH_SCRIPT}
	    echo "    cp -rf ${LP_IO_DIR} ${ANALYSIS_DIR}" >> ${SBATCH_SCRIPT}
	    echo "    rm -rf ${LP_IO_DIR}" >> ${SBATCH_SCRIPT}
        echo "fi" >> ${SBATCH_SCRIPT}
        echo "# Delete unused genereated files" >> ${SBATCH_SCRIPT}
        echo "rm -rf mpi-aggregate*" >> ${SBATCH_SCRIPT}
        echo "rm -rf mpi-workload*" >> ${SBATCH_SCRIPT}
        echo "rm -rf ross.csv" >> ${SBATCH_SCRIPT}
        echo "# Remove temp lp io dir" >> ${SBATCH_SCRIPT}
        echo "rm -rf ${TEMP_LP_IO_DIR}" >> ${SBATCH_SCRIPT}
    else
        mv ${NETWORK_CONF} ${LP_IO_DIR}
        if [ ${TRACE} == 1 ] || [ ${BACKGROUND} == 1 ]
        then
        mv ${ALLOC_CONF} ${LP_IO_DIR}
        mv ${ALLOC_CONFIG_PATH} ${LP_IO_DIR}
        mv ${WRKLD_CONF_FILE} ${LP_IO_DIR}
        fi
        mv ${TEMP_LP_IO_DIR}/stdout-output ${LP_IO_DIR}
        if [ "$NET_MODEL" == "dfly" ]
        then
        mv dragonfly* ${LP_IO_DIR}
        fi
        # Remove temp lp io dir
        rm -rf ${TEMP_LP_IO_DIR}
        # Save all variables to file
        ( set -o posix ; set ) >> ${LP_IO_DIR}/execution-variables
        # Copy output folder to analysis directory
        if [ ${COPY_ANALYSIS} == 1 ]
        then
        cp -rf ${LP_IO_DIR} ${ANALYSIS_DIR}
        rm -rf ${LP_IO_DIR}
        fi
        # Delete unused genereated files
        rm -rf mpi-aggregate*
        rm -rf mpi-workload*
        rm -rf ross.csv
    fi
}

# Call Execution loop
exec_loop "$@"
