#!/bin/bash

##################
### This workflow automates the execution and analysis of mpi-replay simulations
###
### Generates model.conf files, dumpi allocation files and dumpi workload conf files
### Executes the simulation
### Copies conf files to lp-io directory
### Executes post processing python script in background
##################

# Selection Flags
VIS=0       #Whether or not to perform post-process visualization
SIM=1
COPY_ANALYSIS=1     #Whether or not to copy output directory to an analysis directory
ANALYSIS_DIR=/home/noah/Dropbox/RPI/Research/Networks/codes-nemo-results/   #Only needed if COPY_ANALYSIS=1

# Execution System
EXE_SYS=Titan 	#Options: CCI, Titan

# Network Model
NET_MODEL=dfly     #Options: ftree, sfly, dfly

# Execution Params
NUM_PROCESSES=1
NUM_NODES=16
SYNCH=1
#EXTRAMEM=6500000  #AMG1k
EXTRAMEM=15500000
if [ "$EXE_SYS" == "CCI" ]
then
    TIME_ALLOC=60       #Needed only if running on CCI
fi

# Simulation End Time
SIM_END_TIME=6000000    # Currently over written for each trace

# Synthetic Workload Params
SYNTHETIC=0     #Whether or not to do a synthetic workload
SERVERS=19
LOAD=0.1
TRAFFIC=1       #1:uniform random, 2:worst-case

# Trace Workload Params
TRACE=0         #Whether or not to do a trace workload
NUM_JOBS=1      #Number of workloads to run in parallel
JOBS=("amg1k")
DISABLE_COMPUTE=1

# Background Traffic Params
BACKGROUND=1
MEAN_INTERVAL=10
#MSGS_PER_TICK=10000
#MSGS_PER_TICK_BATCH=("5000" "10000" "20000" "40000" "80000")
MSGS_PER_TICK_BATCH=("10000")
TICK_INTERVAL=1000000
MSG_SIZE=8

# Allocation Protocol (Trace workload only)
ALLOC_POLICY_ALGS=("CONT")       #Options: CONT,cluster,rand,heterogeneous(only supported for running one trace and one background job)

# Network Model Params
echo "Setting Network Model Params"
SYSTEM=3k   #Size of HPC system: 3k, 74k, 1m
if [ "$NET_MODEL" == "ftree" ]
then
    ROUTING_ALGS=("static")     #Options: static,adaptive
    RAIL_ROUTING_ALGS=("random")     #Options: random,adaptive
    LINK_SPEED=("12.5")
    RAILS=("1")
    NUM_LEVELS=3
    #BACKGROUND_RANKS_BATCH=("446" "891" "1782" "3564" "7128")
    #BACKGROUND_RANKS_BATCH=("3564")
    BACKGROUND_RANKS=3456
elif [ "$NET_MODEL" == "sfly" ]
then
    #ROUTING_ALGS=("minimal" "nonminimal" "adaptive")
    ROUTING_ALGS=("minimal")
    #BACKGROUND_RANKS_BATCH=("380" "761" "1521" "3042" "6084")
    #BACKGROUND_RANKS_BATCH=("3042")
    BACKGROUND_RANKS=3042
elif [ "$NET_MODEL" == "dfly" ]
then
    #ROUTING_ALGS=("minimal" "nonminimal" "adaptive")
    ROUTING_ALGS=("adaptive")
    #BACKGROUND_RANKS_BATCH=("432" "864" "1728" "3456" "6912")
    BACKGROUND_RANKS=3456
fi

# Number of Ranks per Router/Switch
TOTAL_RANKS=0
if [ ${TRACE} == 1 ];then
    TOTAL_RANKS=$((${TOTAL_RANKS} + ${RANKS_PER_JOB}))
fi
if [ ${BACKGROUND} == 1 ];then
    TOTAL_RANKS=$((${TOTAL_RANKS} + ${BACKGROUND_RANKS}))
fi
if [ "$NET_MODEL" == "ftree" ]
then
    NW_LP=18   #18 is one rank per node
elif [ "$NET_MODEL" == "sfly" ]
then
    NW_LP=19    #9 is one rank per node
elif [ "$NET_MODEL" == "dfly" ]
then
    NW_LP=4     #4 is one rank per node
fi

# Application Traces
echo "Selecting Application Trace/s"
if [ "$JOBS" == "amg1k" ]
then
    TRACE_PREFIXES=("/scratch/networks/dumpi-traces/df_AMG_n1728_dumpi/dumpi-2014.03.03.14.55.50-")
    RANKS_PER_JOB=("1728")
    SIM_END_TIME=1000000
elif [ "$JOBS" == "amg13k" ]
then
    TRACE_PREFIXES=("/scratch/networks/dumpi-traces/df_AMG_n13824_dumpi/dumpi-2014.03.03.15.09.03-")
    RANKS_PER_JOB=("13824")
elif [ "$JOBS" == "mg1k" ]
then
    TRACE_PREFIXES=("/scratch/networks/dumpi-traces/MultiGrid_C_n1000_dumpi/dumpi-2014.03.07.00.25.12-")
    RANKS_PER_JOB=("1000")
    SIM_END_TIME=6000000
elif [ "$JOBS" == "mg10k" ]
then
    TRACE_PREFIXES=("/scratch/networks/dumpi-traces/MultiGrid_C_n10648_dumpi/dumpi-2014.03.07.00.39.10-")
    RANKS_PER_JOB=("10648")
elif [ "$JOBS" == "mg110k" ]
then
    TRACE_PREFIXES=("/scratch/networks/dumpi-traces/MultiGrid_C_n110592_dumpi/dumpi-2014.03.13.03.09.22-")
    RANKS_PER_JOB=("110592")
elif [ "$JOBS" == "cr1k" ]
then
    TRACE_PREFIXES=("/scratch/networks/dumpi-traces/CrystalRouter_n1000_dumpi/dumpi--2014.04.23.12.17.17-")
    RANKS_PER_JOB=("1000")
    SIM_END_TIME=6000000
elif [ "$JOBS" == "cr10" ]
then
    TRACE_PREFIXES=("/scratch/networks/dumpi-traces/CrystalRouter_n10_dumpi/dumpi--2014.04.23.12.08.27-")
    RANKS_PER_JOB=("10")
elif [ "$JOBS" == "cr10regen" ]
then
    TRACE_PREFIXES=("/scratch/networks/dumpi-traces/CrystalRouter_n10_dumpi_regenerated/dumpi--2014.04.23.12.08.27-")
    RANKS_PER_JOB=("10")
elif [ "$JOBS" == "nemo8" ]
then
    TRACE_PREFIXES=("/scratch/codes-nemo/dumpi-traces/UM/nemo8/dumpi--17.10.04.13.37.57-processed-n2d-")
    RANKS_PER_JOB=("8")
elif [ "$JOBS" == "nemo760" ]
then
    TRACE_PREFIXES=("/scratch/codes-nemo/dumpi-traces/UM/nemo760/dumpi--17.10.09.16.12.50-processed-n2d-")
    RANKS_PER_JOB=("760")
elif [ "$JOBS" == "nemo1521sat" ]
then
    TRACE_PREFIXES=("/scratch/codes-nemo/dumpi-traces/SAT/nemo1521/dumpi--17.10.08.09.31.44-processed-n2d-")
    RANKS_PER_JOB=("1521")
elif [ "$JOBS" == "nemo3042" ]
then
    TRACE_PREFIXES=("/scratch/codes-nemo/dumpi-traces/UM/nemo3042/dumpi--17.10.07.14.43.38-processed-n2d-")
    RANKS_PER_JOB=("3042")
elif [ "$JOBS" == "nemo6084" ]
then
    TRACE_PREFIXES=("/scratch/codes-nemo/dumpi-traces/UM/nemo6084/dumpi--17.10.07.23.16.18-processed-n2d-")
    RANKS_PER_JOB=("6084")
fi

# Sampling Parameters (Only if running trace workload)
ENABLE_SAMPLING=1
SAMPLING_INTERVAL=$(( ${SIM_END_TIME} / 100 ))
SAMPLING_END_TIME=${SIM_END_TIME}

# General Paths
echo "Setting Paths"
if [ "$EXE_SYS" == "CCI" ]
then
    BUILD_DIR=/gpfs/u/home/SPNR/SPNRwlfn/scratch/build-drp-codes-nemo/build-codes-unified
    CODES_DIR=/gpfs/u/home/SPNR/SPNRwlfn/barn/codes-unified/codes
elif [ "$EXE_SYS" == "Titan" ]
then
    CODES_DIR=/home/noah/Dropbox/RPI/Research/Networks/codes-unified/codes
    BUILD_DIR=/scratch/codes-nemo/build/build-codes
fi

TOTAL_SIMS=$(( ${#ROUTING_ALGS} * ${#ALLOC_POLICY_ALGS} ))
COUNT_SIMS=1
for rout_alg in ${ROUTING_ALGS[@]}
do
    for alloc_alg in ${ALLOC_POLICY_ALGS[@]}
    do
        for m in ${MSGS_PER_TICK_BATCH[@]}
        do
            #MSG_SIZE=$(( ${m} * 8 / ${BACKGROUND_RANKS} ))
            #MSGS_PER_TICK=${BACKGROUND_RANKS}
            #TEMP_VAL=$(( ${m} / ${BACKGROUND_RANKS} ))
            #MEAN_INTERVAL=$(( ${TEMP_VAL} * 10 + ${TEMP_VAL} * 5 ))
            MSGS_PER_TICK=${m}
            echo "|||||||||||||||||||||||||||| Running Sim ${COUNT_SIMS}/${TOTAL_SIMS} ||||||||||||||||||||||||||"
            COUNT_SIMS=$(( ${COUNT_SIMS} +1 ))
            # Network model-net group conf params
            echo "Setting model-net conf params"
            if [ "$SYSTEM" == "3k" ]
            then
                echo sys 3k
                if [ "$NET_MODEL" == "ftree" ]
                then
                    REPS=198
                    MODELNET_FATTREE=18
                elif [ "$NET_MODEL" == "sfly" ]
                then
                    REPS=338
                    MODELNET_SLIMFLY=9
                elif [ "$NET_MODEL" == "dfly" ]
                then
                    REPS=864
                    MODELNET_DRAGONFLY_CUSTOM=4
                    MODELNET_DRAGONFLY_CUSTOM_ROUTER=1
                fi
            elif [ "$SYSTEM" == "74k" ]
            then
                echo sys 74k
                REPS=2738
                NUM_ROUTERS=37
                LOCAL_CHANNELS=18
                GENERATOR_SET_X='("1","25","33","11","16","30","10","28","34","36","12","4","26","21","7","27","9","3");'
                GENERATOR_SET_X_PRIME='("32","23","20","19","31","35","24","8","15","5","14","17","18","6","2","13","29","22");'
                MODELNET_SLIMFLY=27
            elif [ "$SYSTEM" == "1m" ]
            then
                echo sys 1m
                REPS=53138
                NUM_ROUTERS=163
                LOCAL_CHANNELS=82
                GENERATOR_SET_X='("1","46","160","25","9","88","136","62","81","140","83","69","77","119","95","132","41","93","40","47","43","22","34","97","61","35","143","58","60","152","146","33","51","64","10","134","133","87","90","65","56","117","3","138","154","75","27","101","82","23","80","94","86","44","68","31","122","70","123","116","120","141","129","66","102","128","20","105","103","11","17","130","112","99","153","29","30","76","73","98","107","162");'
                GENERATOR_SET_X_PRIME='("32","5","67","148","125","45","114","28","147","79","48","89","19","59","106","149","8","42","139","37","72","52","110","7","159","142","12","63","127","137","108","78","2","92","157","50","18","13","109","124","131","158","96","15","38","118","49","135","16","84","115","74","144","104","57","14","155","121","24","126","91","111","53","156","4","21","151","100","36","26","55","85","161","71","6","113","145","150","54","39","1","162");'
                MODELNET_SLIMFLY=19
            fi
            # Common Conf Params
            MESSAGE_SIZE=640
            PACKET_SIZE=4096
            CHUNK_SIZE=${PACKET_SIZE}
            MODELNET_SCHEDULER=fcfs
            ROUTER_DELAY=90
            ROUTING=${rout_alg}
            NUM_INJECTION_QUEUES=1
            NIC_SEQ_DELAY=10
            NODE_COPY_QUEUES=1
            NODE_EAGER_LIMIT=16000
            if [ "$NET_MODEL" == "ftree" ]
            then
                FATTREE_SWITCH=${NUM_LEVELS}
                MODELNET_ORDER=fattree
                SWITCH_COUNT=${REPS}
                SWITCH_RADIX=36
                TERMINAL_RADIX=${RAILS[0]}
                VC_SIZE=65536
                CN_VC_SIZE=${VC_SIZE}
                LINK_BANDWIDTH=${LINK_SPEED[0]}
                CN_BANDWIDTH=${LINK_BANDWIDTH}
                RAIL_ROUTING=${rail_alg}
                if [ "$EXE_SYS" == "CCI" ]
                then
                    ROUTING_FOLDER=/gpfs/u/home/SPNR/SPNRwlfn/barn/Fat-Tree-Topo/summit
                elif [ "$EXE_SYS" == "Titan" ]
                then
                    ROUTING_FOLDER=/home/noah/Dropbox/RPI/Research/Networks/Fat-Tree-Topo/summit
                fi
                DOT_FILE=summit-3564
                DUMP_TOPO=0
            elif [ "$NET_MODEL" == "sfly" ]
            then
                NUM_ROUTERS=13
                LOCAL_CHANNELS=6
                GENERATOR_SET_X='("1","10","9","12","3","4");'        #   : Subgraph 0 generator set
                GENERATOR_SET_X_PRIME='("6","8","2","7","5","11");'   #   : Subgraph 1 generator set
                SLIMFLY_ROUTER=1
                MODELNET_ORDER=slimfly
                NUM_VCS=4
                NUM_TERMINALS=${MODELNET_SLIMFLY}
                GLOBAL_CHANNELS=${NUM_ROUTERS}
                LINK_DELAY=0
                LOCAL_VC_SIZE=65536
                GLOBAL_VC_SIZE=${LOCAL_VC_SIZE}
                CN_VC_SIZE=${LOCAL_VC_SIZE}
                LOCAL_BANDWIDTH=12.5
                CN_BANDWIDTH=${LOCAL_BANDWIDTH}
                GLOBAL_BANDWIDTH=${LOCAL_BANDWIDTH}
                CSF_RATIO=1
            elif [ "$NET_MODEL" == "dfly" ]
            then
                NUM_ROUTER_ROWS=6
                NUM_ROUTER_COLS=16
                NUM_GROUPS=9
                NUM_GLOBAL_CHANNELS=4
                NUM_CNS_PER_ROUTER=${MODELNET_DRAGONFLY_CUSTOM}
                MODELNET_ORDER='("dragonfly_custom","dragonfly_custom_router");'
                LOCAL_VC_SIZE=65536
                GLOBAL_VC_SIZE=65536
                CN_VC_SIZE=65536
                LOCAL_BANDWIDTH=5.25
                CN_BANDWIDTH=16.0
                GLOBAL_BANDWIDTH=4.69
                INTRA_GROUP_CONNECTIONS=/home/noah/Dropbox/RPI/Research/Networks/codes-unified/codes/src/network-workloads/conf/dragonfly-custom/intra-theta
                INTER_GROUP_CONNECTIONS=/home/noah/Dropbox/RPI/Research/Networks/codes-unified/codes/src/network-workloads/conf/dragonfly-custom/inter-theta
            fi

            # Execution Parameters
            echo "Setting up execution parameters"
            WRKLD_TYPE=dumpi

            ALLOC_POLICY=${alloc_alg}   #Options cluster, CONT and rand
            NUM_ALLOCS=1
			if [ "$NET_MODEL" == "ftree" ]
			then
            	NUM_CORES_PER_NODE=$(( ${NW_LP} / ${MODELNET_FATTREE} ))
            elif [ "$NET_MODEL" == "sfly" ]
            then
            	NUM_CORES_PER_NODE=$(( ${NW_LP} / ${MODELNET_SLIMFLY} ))
            elif [ "$NET_MODEL" == "dfly" ]
            then
            	NUM_CORES_PER_NODE=$(( ${NW_LP} / ${MODELNET_DRAGONFLY_CUSTOM} ))
			fi

            # General Paths
            if [ ${TRACE} == 1 ] || [ ${BACKGROUND} == 1 ]
            then
                EXE_PATH=${BUILD_DIR}/src/network-workloads/model-net-mpi-replay
            else
                EXE_PATH=${BUILD_DIR}/src/network-workloads/model-net-synthetic-slimfly
            fi
			if [ "$NET_MODEL" == "ftree" ]
			then
            	TOTAL_NODES=$(( ${MODELNET_FATTREE} * ${REPS} ))
            elif [ "$NET_MODEL" == "sfly" ]
            then
            	TOTAL_NODES=$(( ${MODELNET_SLIMFLY} * ${REPS} ))
            elif [ "$NET_MODEL" == "dfly" ]
            then
            	TOTAL_NODES=$(( ${MODELNET_DRAGONFLY_CUSTOM} * ${REPS} ))
            fi
            TEMP_DIR2=${NET_MODEL}-
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
                if [ "$ROUTING" == "adaptive" ]
                then
                    TEMP_DIR2+=trace-${TEMP_DIR}-1ms-n${TOTAL_NODES}-${ROUTING}-1csf
                else
                    TEMP_DIR2+=trace-${TEMP_DIR}-1ms-n${TOTAL_NODES}-${rout_alg}-${alloc_alg}
                fi
            fi
            if [ ${BACKGROUND} == 1 ]
            then
                TEMP_DIR2+=bkgnd-${MEAN_INTERVAL}mintvl-${TICK_INTERVAL}tintvl-${BACKGROUND_RANKS}ranks-${MSGS_PER_TICK}mpt-${MSG_SIZE}Bszmsg-${SIM_END_TIME}end
            fi
            if [ ${SYNTHETIC} == 1 ]
            then
                TEMP_DIR2+=${NET_MODEL}-synthetic-traffic${TRAFFIC}-load${LOAD}-n${TOTAL_NODES}-${ROUTING}-${rout_alg}-${SIM_END_TIME}end
            fi
            LP_IO_DIR=${BUILD_DIR}/${TEMP_DIR2}
            TEMP_LP_IO_DIR=${BUILD_DIR}/TEMP_${TEMP_DIR2}/
            mkdir ${TEMP_LP_IO_DIR}
            NETWORK_CONF=${TEMP_LP_IO_DIR}/network-model.conf

            # Post Processing Parameters
            PROCESSING_EXE_PATH=/home/noah/Dropbox/RPI/Research/Networks/codes-unified/codes/scripts/modelnet-analysis/parse-sampling.py
            if [ ${SIM} == 1 ]
            then
                echo "Creating network config file"
                mkdir -p ${BUILD_DIR}/${LP_IO_DIR}
    			if [ "$NET_MODEL" == "sfly" ]
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
                	echo "    routing=\"${ROUTING}\";" >> ${NETWORK_CONF}
                	echo "    csf_ratio=\"${CSF_RATIO}\";" >> ${NETWORK_CONF}
                	echo "    num_injection_queues=\"${NUM_INJECTION_QUEUES}\";" >> ${NETWORK_CONF}
                	echo "    nic_seq_delay=\"${NIC_SEQ_DELAY}\";" >> ${NETWORK_CONF}
                	echo "    node_copy_queues=\"${NODE_COPY_QUEUES}\";" >> ${NETWORK_CONF}
                	echo "    node_eager_limit=\"${NODE_EAGER_LIMIT}\";" >> ${NETWORK_CONF}
                	echo "}" >> ${NETWORK_CONF}

    			elif [ "$NET_MODEL" == "dfly" ]
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
                	echo "    routing=\"${ROUTING}\";" >> ${NETWORK_CONF}
                	echo "    num_injection_queues=\"${NUM_INJECTION_QUEUES}\";" >> ${NETWORK_CONF}
                	echo "    nic_seq_delay=\"${NIC_SEQ_DELAY}\";" >> ${NETWORK_CONF}
                	echo "    node_copy_queues=\"${NODE_COPY_QUEUES}\";" >> ${NETWORK_CONF}
                	echo "    node_eager_limit=\"${NODE_EAGER_LIMIT}\";" >> ${NETWORK_CONF}
                	echo "}" >> ${NETWORK_CONF}

                elif [ "$NET_MODEL" == "ftree" ]
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
					echo "    ft_type=\"0\";" >> ${NETWORK_CONF}
					echo "    terminal_radix=\"${TERMINAL_RADIX}\";" >> ${NETWORK_CONF}
					echo "    num_levels=\"${NUM_LEVELS}\";" >> ${NETWORK_CONF}
					echo "    switch_count=\"${SWITCH_COUNT}\";" >> ${NETWORK_CONF}
					echo "    switch_radix=\"${SWITCH_RADIX}\";" >> ${NETWORK_CONF}
                	echo "    router_delay=\"${ROUTER_DELAY}\";" >> ${NETWORK_CONF}
                	echo "    vc_size=\"${VC_SIZE}\";" >> ${NETWORK_CONF}
                	echo "    cn_vc_size=\"${CN_VC_SIZE}\";" >> ${NETWORK_CONF}
                	echo "    link_bandwidth=\"${LINK_BANDWIDTH}\";" >> ${NETWORK_CONF}
                	echo "    cn_bandwidth=\"${CN_BANDWIDTH}\";" >> ${NETWORK_CONF}
                	echo "    routing=\"${ROUTING}\";" >> ${NETWORK_CONF}
                	echo "    routing_folder=\"${ROUTING_FOLDER}\";" >> ${NETWORK_CONF}
                	echo "    dot_file=\"${DOT_FILE}\";" >> ${NETWORK_CONF}
                	echo "    dump_topo=\"${DUMP_TOPO}\";" >> ${NETWORK_CONF}
                	echo "    num_injection_queues=\"${NUM_INJECTION_QUEUES}\";" >> ${NETWORK_CONF}
                	echo "    nic_seq_delay=\"${NIC_SEQ_DELAY}\";" >> ${NETWORK_CONF}
                	echo "    node_copy_queues=\"${NODE_COPY_QUEUES}\";" >> ${NETWORK_CONF}
                	echo "    node_eager_limit=\"${NODE_EAGER_LIMIT}\";" >> ${NETWORK_CONF}
                	echo "}" >> ${NETWORK_CONF}
				fi

                if [ ${TRACE} == 1 ] || [ ${BACKGROUND} == 1 ]
                then
                    # Generate Dumpi Allocation File
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
                            if [ "$NET_MODEL" == "ftree" ]
                            then
                                echo $(( ${MODELNET_FATTREE} * ${REPS} )) >> ${ALLOC_CONFIG_PATH}
                            elif [ "$NET_MODEL" == "sfly" ]
                            then
                                echo $(( ${MODELNET_SLIMFLY} * ${REPS} )) >> ${ALLOC_CONFIG_PATH}
                            elif [ "$NET_MODEL" == "dfly" ]
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
                            if [ "$NET_MODEL" == "ftree" ]
                            then
                                mv allocation-$(( ${MODELNET_FATTREE} * ${REPS} ))-${TEMP_NAME}-$(( ${NUM_ALLOCS} -1 )).conf ${ALLOC_CONF}
                            elif [ "$NET_MODEL" == "sfly" ]
                            then
                                mv allocation-$(( ${MODELNET_SLIMFLY} * ${REPS} ))-${TEMP_NAME}-$(( ${NUM_ALLOCS} -1 )).conf ${ALLOC_CONF}
                            elif [ "$NET_MODEL" == "dfly" ]
                            then
                                mv allocation-$(( ${MODELNET_DRAGONFLY_CUSTOM} * ${REPS} ))-${TEMP_NAME}-$(( ${NUM_ALLOCS} -1 )).conf ${ALLOC_CONF}
                            fi
                        elif [ "${ALLOC_POLICY}" == "heterogeneous" ]   # Currently only supports one trace job
                        then
                            echo Heterogeneous allocation...
                            rm -rf ${ALLOC_CONF}
                            for i in `seq 0 2 $(( ${RANKS_PER_JOB[0]} * 2 -1))`
                            do
                                echo -n "$i " >> ${ALLOC_CONF}
                            done
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
                            for i in `seq 1 2 $(( ${BACKGROUND_RANKS} * 2 -1))`
                            do
                                echo -n "$i " >> ${ALLOC_CONF}
                            done
                        fi
                    fi
                    # Add Background params to workload config file
                    if [ ${BACKGROUND} == 1 ]
                    then
                        echo -n -e "${BACKGROUND_RANKS} synthetic" >> ${WRKLD_CONF_FILE}
                    fi
                fi

                # Execute Simulation
                echo Executing Simultion...
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
						srun -t ${TIME_ALLOC} -N ${NUM_NODES} -n ${NUM_PROCESSES}  -o ${JOBS}-${rout_alg}-${SYSTEM} ${EXE_PATH} --synch=${SYNCH} \
                            --workload_type=${WRKLD_TYPE} --workload_conf_file=${WRKLD_CONF_FILE} \
                            --alloc_file=${ALLOC_CONF} --lp-io-dir=${LP_IO_DIR} \
                            --enable_sampling=${ENABLE_SAMPLING} --sampling_interval=${SAMPLING_INTERVAL} \
                            --sampling_end_time=${SAMPLING_END_TIME} --disable_compute=${DISABLE_COMPUTE} --end=${SIM_END_TIME} \
                            -- ${NETWORK_CONF}
						echo srun -t ${TIME_ALLOC} -N ${NUM_NODES} -n ${NUM_PROCESSES}  -o ${JOBS}-${rout_alg}-${SYSTEM} ${EXE_PATH} --synch=${SYNCH} \
                            --workload_type=${WRKLD_TYPE} --workload_conf_file=${WRKLD_CONF_FILE} \
                            --alloc_file=${ALLOC_CONF} --lp-io-dir=${LP_IO_DIR} \
                            --enable_sampling=${ENABLE_SAMPLING} --sampling_interval=${SAMPLING_INTERVAL} \
                            --sampling_end_time=${SAMPLING_END_TIME} --disable_compute=${DISABLE_COMPUTE} --end=${SIM_END_TIME} \
                            -- ${NETWORK_CONF}
		    		else
						mpirun -n ${NUM_PROCESSES} ${EXE_PATH} --synch=${SYNCH} \
                            --workload_type=${WRKLD_TYPE} --workload_conf_file=${WRKLD_CONF_FILE} \
                            --alloc_file=${ALLOC_CONF} --lp-io-dir=${LP_IO_DIR} \
                            --enable_sampling=${ENABLE_SAMPLING} --sampling_interval=${SAMPLING_INTERVAL} \
                            --sampling_end_time=${SAMPLING_END_TIME} --disable_compute=${DISABLE_COMPUTE} --extramem=${EXTRAMEM} ${ADDL_ARGS} --end=${SIM_END_TIME} \
                            --msgs_per_tick=${MSGS_PER_TICK} --tick_interval=${TICK_INTERVAL} \
                            -- ${NETWORK_CONF}
						echo mpirun -n ${NUM_PROCESSES} ${EXE_PATH} --synch=${SYNCH} \
                            --workload_type=${WRKLD_TYPE} --workload_conf_file=${WRKLD_CONF_FILE} \
                            --alloc_file=${ALLOC_CONF} --lp-io-dir=${LP_IO_DIR} \
                            --enable_sampling=${ENABLE_SAMPLING} --sampling_interval=${SAMPLING_INTERVAL} \
                            --sampling_end_time=${SAMPLING_END_TIME} --disable_compute=${DISABLE_COMPUTE} --extramem=${EXTRAMEM} ${ADDL_ARGS} --end=${SIM_END_TIME} \
                            -- ${NETWORK_CONF}
					fi
                else
                    mpirun -n ${NUM_PROCESSES} ${EXE_PATH} --synch=${SYNCH} \
                        --traffic=${TRAFFIC} --load=${LOAD} --lp-io-dir=${LP_IO_DIR} --end=${SIM_END_TIME}\
                        -- ${NETWORK_CONF}
                    echo mpirun -n ${NUM_PROCESSES} ${EXE_PATH} --synch=${SYNCH} \
                        --traffic=${TRAFFIC} --load=${LOAD} --lp-io-dir=${LP_IO_DIR} \
                        -- ${NETWORK_CONF}
                fi

                # Move Simulation config files to lp-io-dir
                #exit
                echo Copying Files to LP-IO Directory...
                mv ${NETWORK_CONF} ${LP_IO_DIR}
                if [ ${TRACE} == 1 ] || [ ${BACKGROUND} == 1 ]
                then
                    mv ${ALLOC_CONF} ${LP_IO_DIR}
                    mv ${ALLOC_CONFIG_PATH} ${LP_IO_DIR}
                    mv ${WRKLD_CONF_FILE} ${LP_IO_DIR}
                fi
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
                echo Deleting Unused Generated Files
#                rm mpi*
                rm -rf mpi-aggregate*
                rm -rf mpi-workload*
                rm -rf ross.csv
            fi
            # Execute Post Processing and Visualization in Background
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
