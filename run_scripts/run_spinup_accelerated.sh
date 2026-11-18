#!/bin/bash

export COMPSET='I2000Clm60FatesCrujraRs'
export RES=f19_g17
export MACH='betzy'
export PROJECT='nn9188k'
export USER='zofias'
export workpath='/cluster/home/zofias'

exprmts="spinup" # space separated list

for exp in $exprmts; do
    

    export TAG="noresm-fates-f19_borealblaze_ppe-$exp"
    export CASEROOT=$workpath/NorESM/cases/borealblaze_PPE_runs
    export CIMEROOT=$workpath/NorESM/SRC/ctsm/cime/scripts

    cd ${CIMEROOT}

    export CIME_HASH=`git log -n 1 --pretty=%h`
    export NorESM_CTSM_HASH=`(cd ../..;git log -n 1 --pretty=%h)`
    export FATES_HASH=`(cd src/fates;git log -n 1 --pretty=%h)`
    export GIT_HASH=N${NorESM_CTSM_HASH}-F${FATES_HASH}	
    export CASE_NAME=${CASEROOT}/${TAG}.`date +"%Y-%m-%d"`


    # REMOVE EXISTING CASE DIRECTORY IF PRESENT 
    rm -rf ${CASE_NAME}

    # CREATE THE CASE
    ./create_newcase --case=${CASE_NAME} --res=${RES} --compset=${COMPSET} --mach=${MACH} --project=${PROJECT} --run-unsupported
    
    echo ./create_newcase --case=${CASE_NAME} --res=${RES} --compset=${COMPSET} --mach=${MACH} --project=${PROJECT} --run-unsupported

    cd ${CASE_NAME}

    ./xmlchange STOP_N=25
    ./xmlchange STOP_OPTION=nyears
    ./xmlchange REST_N=25
    ./xmlchange REST_OPTION=nyears
    #./xmlchange RESUBMIT=11
    ./xmlchange DEBUG=FALSE

    ./xmlchange RUN_STARTDATE=2000-01-01
    ./xmlchange CLM_ACCELERATED_SPINUP=on
    ./xmlchange DATM_YR_START=1990 #start year for forcing data
    ./xmlchange DATM_YR_END=2020 #or 2000?
    ./xmlchange DATM_YR_ALIGN=2000 # repeat year 2000 for timeslice?

    ./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=24:00:00
    ./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME=00:30:00

    ./xmlchange CLM_BLDNML_OPTS="-bgc fates -megan"

    #Ask around whether anyone has optimised these for f19
    #./xmlchange NTASKS_CPL=1536
    #./xmlchange NTASKS_ATM=256
    #./xmlchange NTASKS_LND=1536
    #./xmlchange ROOTPE_CPL=256
    #./xmlchange ROOTPE_ATM=0
    #./xmlchange ROOTPE_LND=256

    ./xmlchange RUNDIR=${CASE_NAME}/run
    #./xmlchange EXEROOT=${CASE_NAME}/bld

    cat >>  user_nl_clm <<EOF

#need these for f19 2000
fluh_timeseries='/cluster/work/users/jessica/wiemip_misc/LUH2_2023_steadystate_0.9x1.25_c260622.nc' # how land use changes
flandusepftdat='/cluster/work/users/jessica/wiemip_misc/fates_landuse_pft_surfdata_0.9x1.25_c260515.nc' # how pfts change by land use
EOF

    ./case.setup
    ./case.build
    #./case.submit

done
