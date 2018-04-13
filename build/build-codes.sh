#!/bin/bash
#
# This bash script automates the installation of ROSS/CODES/DUMPI.
# It assumes all three source repos have already been downloaded
#   and reside in their corresponding NAME_DIR path.
# Section 1 includes configurable parameters for your system and
#   build requirements.
# Section 2 performs the selected build processes

#ANSI color escape codes
RED='\033[0;31m'
NC='\033[0m' # No Color
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'
LIGHTGREEN='\033[1;32m'
BLUE='\033[0;34m'
LIGHTBLUE='\033[1;34m'


######## Section 1 ########
#Build Process Selection Flags
CLEAN=1         # Purges all build directories
PREPARE=1       # Executes CODES prepare.sh script
MPI_MODULE=0    # If running on CCI, need to load module for MPI. Fill in module below
ROSS=1          # Builds and installs ROSS
DUMPI=1         # Builds and installs DUMPI. See "DUMPI_ARGS" for passing in args for dumpi vs undumpi
CODES=1         # Builds and installs CODES
CODES_TESTS=1   # Builds and runs the CODES tests

#System
SYS=server      #Options: cci, server

#Array of modules to load (if running on CCI system)
#MODULES=("mpi/mvapich2-2.0a-gcc44")
MODULES=("mpi/openmpi-1.6-gcc44")

#Number of processes for parallel build (1=sequential)
BUILD_PROCS=1

#Important Directory Paths
CODES_DIR=/home/noah/Dropbox/RPI/Research/Networks/codes-unified/codes
CODES_BUILD_DIR=/scratch/codes-nemo/build/build-codes
CODES_INSTALL_DIR=${CODES_BUILD_DIR}/install
DUMPI_DIR=/home/noah/Dropbox/RPI/Research/Networks/sst-dumpi/
DUMPI_BUILD_DIR=/scratch/codes-nemo/build/build-dumpi
DUMPI_INSTALL_DIR=${DUMPI_BUILD_DIR}/install
ROSS_DIR=/home/noah/Dropbox/RPI/Research/Networks/ROSS
ROSS_BUILD_DIR=/scratch/codes-nemo/build/build-ross
ROSS_INSTALL_DIR=${ROSS_BUILD_DIR}/install

#Dumpi Build Arguments
DUMPI_ARGS="--enable-libundumpi --disable-libdumpi"
ROSS_ARGS="-DCMAKE_INSTALL_PREFIX=${ROSS_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Debug"

#If you are on the CCI system then you need path to acceptable autoconf version
if [ "${SYS}" == "cci" ];then
    AUTOCONF_PATH=/gpfs/u/home/SPNR/SPNRwlfn/barn/autoconf-2.69/bin
fi

######## Section 2 ########
#Clean Build Directories
if [ ${CLEAN} == 1 ];then
    echo -e ${BLUE}PROGRESS: ${LIGHTBLUE}cleaning build directories ${MODULES[$i]}${NC}
    rm -r ${CODES_BUILD_DIR}
    rm -r ${ROSS_BUILD_DIR}
    rm -r ${DUMPI_BUILD_DIR}
fi

CUR_DIR=$PWD
OUTPUT_TEXT=("${BLUE}SUMMARY:")
#Export Autoconf Path
if [ "${SYS}" == "cci" ];then
    export PATH=${AUTOCONF_PATH}:$PATH
fi

#Load Modules one by one
if [ ${MPI_MODULE} == 1 ];then
    for i in `seq 0 1 $(( ${#MODULES[@]} -1 ))`;do
        echo -e ${BLUE}PROGRESS: ${LIGHTBLUE}loading module ${MODULES[$i]}${NC}
    module purge
        module load ${MODULES[$i]}
        if [ $? -ne 0 ];then
            echo -e ${RED}ERROR: ${LIGHTRED}failed to load module ${MODULES[$i]}${NC}
        OUTPUT_TEXT+=("${RED}ERROR: ${LIGHTRED}failed to load module ${MODULES[$i]}${NC}")
        else
            echo -e ${GREEN}Success: ${LIGHTGREEN}loaded module ${MODULES[$i]}${NC}
        OUTPUT_TEXT+=("${GREEN}Success: ${LIGHTGREEN}loaded module ${MODULES[$i]}${NC}")
        fi
    done
fi

#Execute Prepare.sh script
if [ ${PREPARE} == 1 ];then
    cd ${CODES_DIR}
    echo -e ${BLUE}PROGRESS: ${LIGHTBLUE}executing CODES prepare.sh script${NC}
    ./prepare.sh
    if [ $? -ne 0 ];then
        echo -e ${RED}ERROR: ${LIGHTRED}failed executing codes prepare.sh script${NC}
    OUTPUT_TEXT+=("${RED}ERROR: ${LIGHTRED}failed executing codes prepare.sh script${NC}")
    else
        echo -e ${GREEN}Success: ${LIGHTGREEN}executed prepare.sh script${NC}
    OUTPUT_TEXT+=("${GREEN}Success: ${LIGHTGREEN}executed prepare.sh script${NC}")
    fi
fi

#Build Dumpi
if [ ${DUMPI} == 1 ];then
    if [ ! -d "$DUMPI_BUILD_DIR" ]; then
    mkdir -p ${DUMPI_BUILD_DIR}
    fi
    echo -e ${BLUE}PROGRESS: ${LIGHTBLUE}running dumpi bootstrap.sh${NC}
    cd ${DUMPI_DIR}
    echo "directory"
    echo $PWD
    ./bootstrap.sh
    cd ${DUMPI_BUILD_DIR}
    echo -e ${BLUE}PROGRESS: ${LIGHTBLUE}configuring dumpi${NC}
    ${DUMPI_DIR}/configure ${DUMPI_ARGS} CC=mpicc CXX=mpicxx --prefix=${DUMPI_INSTALL_DIR} CFLAGS="-DMPICH_SUPPRESS_PROTOTYPES=1 -DHAVE_PRAGMA_HP_SEC_DEF=1"
    if [ $? -ne 0 ];then
        echo -e ${RED}ERROR: ${LIGHTRED}failed configuring dumpi${NC}
    OUTPUT_TEXT+=("${RED}ERROR: ${LIGHTRED}failed configuring dumpi${NC}")
    else
        echo -e ${GREEN}Success: ${LIGHTGREEN}configured dumpi${NC}
    OUTPUT_TEXT+=("${GREEN}Success: ${LIGHTGREEN}configured dumpi${NC}")
    fi
    echo -e ${BLUE}PROGRESS: ${LIGHTBLUE}building dumpi${NC}
    make clean
    make -j ${BUILD_PROCS}
    if [ $? -ne 0 ];then
        echo -e ${RED}ERROR: ${LIGHTRED}failed building dumpi${NC}
    OUTPUT_TEXT+=("${RED}ERROR: ${LIGHTRED}failed building dumpi${NC}")
    else
        echo -e ${GREEN}Success: ${LIGHTGREEN}built dumpi${NC}
    OUTPUT_TEXT+=("${GREEN}Success: ${LIGHTGREEN}built dumpi${NC}")
    fi
    echo -e ${BLUE}PROGRESS: ${LIGHTBLUE}installing dumpi${NC}
    make install
    if [ $? -ne 0 ];then
        echo -e ${RED}ERROR: ${LIGHTRED}failed installing dumpi${NC}
    OUTPUT_TEXT+=("${RED}ERROR: ${LIGHTRED}failed installing dumpi${NC}")
    else
        echo -e ${GREEN}Success: ${LIGHTGREEN}installed dumpi${NC}
    OUTPUT_TEXT+=("${GREEN}Success: ${LIGHTGREEN}installed dumpi${NC}")
    fi
fi

#Build ROSS
if [ ${ROSS} == 1 ];then
    if [ ! -d "${ROSS_BUILD_DIR}" ]; then
    mkdir -p ${ROSS_BUILD_DIR}
    fi
    if [ -e "${ROSS_BUILD_DIR}/CMakeCache.txt" ]; then
    rm ${ROSS_BUILD_DIR}/CMakeCache.txt
    fi
    cd ${ROSS_BUILD_DIR}
    export ARCH=x86_64
    export CC=mpicc
    echo -e ${BLUE}PROGRESS: ${LIGHTBLUE}configuring ROSS${NC}
    cmake ${ROSS_DIR} ${ROSS_ARGS}
    if [ $? -ne 0 ];then
        echo -e ${RED}ERROR: ${LIGHTRED}failed to cmake ROSS${NC}
    OUTPUT_TEXT+=("${RED}ERROR: ${LIGHTRED}failed to cmake ROSS${NC}")
    else
        echo -e ${GREEN}Success: ${LIGHTGREEN}cmake ROSS${NC}
    OUTPUT_TEXT+=("${GREEN}Success: ${LIGHTGREEN}cmake ROSS${NC}")
    fi
    echo -e ${BLUE}PROGRESS: ${LIGHTBLUE}making ROSS${NC}
    make clean
    make -j ${BUILD_PROCS}
    if [ $? -ne 0 ];then
        echo -e ${RED}ERROR: ${LIGHTRED}failed building ROSS${NC}
    OUTPUT_TEXT+=("${RED}ERROR: ${LIGHTRED}failed building ROSS${NC}")
    else
        echo -e ${GREEN}Success: ${LIGHTGREEN}built ROSS${NC}
    OUTPUT_TEXT+=("${GREEN}Success: ${LIGHTGREEN}built ROSS${NC}")
    fi
    echo -e ${BLUE}PROGRESS: ${LIGHTBLUE}installing ROSS${NC}
    make install
    if [ $? -ne 0 ];then
        echo -e ${RED}ERROR: ${LIGHTRED}failed installing ROSS${NC}
    OUTPUT_TEXT+=("${RED}ERROR: ${LIGHTRED}failed installing ROSS${NC}")
    else
        echo -e ${GREEN}Success: ${LIGHTGREEN}installed ROSS${NC}
    OUTPUT_TEXT+=("${GREEN}Success: ${LIGHTGREEN}installed ROSS${NC}")
    fi
fi
#Build CODES
if [ ${CODES} == 1 ];then
    if [ ! -d "${CODES_BUILD_DIR}" ]; then
    mkdir -p ${CODES_BUILD_DIR}
    fi
    cd ${CODES_BUILD_DIR}
    if [ ${DUMPI} == 1 ];then
        CODES_ARGS+="--with-dumpi=${DUMPI_INSTALL_DIR}"
    else
        CODES_ARGS=
    fi
    echo -e ${BLUE}PROGRESS: ${LIGHTBLUE}configuring CODES${NC}
    ${CODES_DIR}/configure ${CODES_ARGS} CC=mpicc CXX=mpicxx CFLAGS="-g" CXXFLAGS="-g" PKG_CONFIG_PATH=${ROSS_INSTALL_DIR}/lib/pkgconfig --prefix=${CODES_INSTALL_DIR}
    if [ $? -ne 0 ];then
        echo -e ${RED}ERROR: ${LIGHTRED}failed configuring CODES${NC}
    OUTPUT_TEXT+=("${RED}ERROR: ${LIGHTRED}failed configuring CODES${NC}")
    else
        echo -e ${GREEN}Success: ${LIGHTGREEN}configuring CODES${NC}
    OUTPUT_TEXT+=("${GREEN}Success: ${LIGHTGREEN}configuring CODES${NC}")
    fi
    echo -e ${BLUE}PROGRESS: ${LIGHTBLUE}building CODES${NC}
    make clean
    make -j ${BUILD_PROCS}
    if [ $? -ne 0 ];then
        echo -e ${RED}ERROR: ${LIGHTRED}failed building CODES${NC}
    OUTPUT_TEXT+=("${RED}ERROR: ${LIGHTRED}failed building CODES${NC}")
    else
        echo -e ${GREEN}Success: ${LIGHTGREEN}building CODES${NC}
    OUTPUT_TEXT+=("${GREEN}Success: ${LIGHTGREEN}building CODES${NC}")
    fi
    echo -e ${BLUE}PROGRESS: ${LIGHTBLUE}installing CODES${NC}
    make install
    if [ $? -ne 0 ];then
        echo -e ${RED}ERROR: ${LIGHTRED}failed installing CODES${NC}
    OUTPUT_TEXT+=("${RED}ERROR: ${LIGHTRED}failed installing CODES${NC}")
    else
        echo -e ${GREEN}Success: ${LIGHTGREEN}installed CODES${NC}
    OUTPUT_TEXT+=("${GREEN}Success: ${LIGHTGREEN}installed CODES${NC}")
    fi
fi

#Build and perform CODES tests
if [ ${CODES_TESTS} == 1 ];then
    cd ${CODES_BUILD_DIR}
    echo -e ${BLUE}PROGRESS: ${LIGHTBLUE}building Codes Tests${NC}
    make tests
    if [ $? -ne 0 ];then
        echo -e ${RED}ERROR: ${LIGHTRED}failed building CODES Tests${NC}
    OUTPUT_TEXT+=("${RED}ERROR: ${LIGHTRED}failed building CODES Tests${NC}")
    else
        echo -e ${GREEN}Success: ${LIGHTGREEN}building CODES Tests${NC}
    OUTPUT_TEXT+=("${GREEN}Success: ${LIGHTGREEN}building CODES Tests${NC}")
    fi
    echo -e ${BLUE}PROGRESS: ${LIGHTBLUE}running Codes Tests${NC}
    make check
    if [ $? -ne 0 ];then
        echo -e ${RED}ERROR: ${LIGHTRED}failed running CODES Tests${NC}
    OUTPUT_TEXT+=("${RED}ERROR: ${LIGHTRED}failed running CODES Tests${NC}")
    else
        echo -e ${GREEN}Success: ${LIGHTGREEN}running CODES Tests${NC}
    OUTPUT_TEXT+=("${GREEN}Success: ${LIGHTGREEN}running CODES Tests${NC}")
    fi
fi

cd ${CUR_DIR}

#Print Summary
echo " "
echo " "
for i in `seq 0 1 $(( ${#OUTPUT_TEXT[@]} -1 ))`;do
    echo -e ${OUTPUT_TEXT[i]}
done
