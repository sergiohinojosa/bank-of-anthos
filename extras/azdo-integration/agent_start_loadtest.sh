#!/bin/bash

JMX_FILE=$AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS/extras/jmeter/Test_Banking_Process.jmx

start_performance_test() {

    echo "Pointing to $SERVER_URL with VirtualUsers $VU and Loops $LOOPS"
    echo "Loading Loadtest $JMX_FILE"
    
    # using default for now
    jmeter -SERVER_URL=$SERVER_URL -JVUCount=$VU -JLoopCount=$LOOPS -n -t $JMX_FILE -l testreport.jtl
}

echo "ENVIRONMENT VARIABLES"
env
echo "WHERE AM I"
pwd
echo "WHO AM I"
whoami

echo "STARTING LOADTEST"


start_timestamp=$(date '+%F %H:%M:00')
echo $start_timestamp
echo "##vso[task.setvariable variable=start_timestamp]$start_timestamp"
start_performance_test
stop_timestamp=$(date '+%F %H:%M:00')
echo $stop_timestamp
echo "##vso[task.setvariable variable=stop_timestamp]$stop_timestamp"
