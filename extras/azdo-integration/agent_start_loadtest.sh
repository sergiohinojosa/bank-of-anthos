#!/bin/bash




JMX_FILE=$AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS/extras/jmeter/Test_Banking_Process.jmx

start_performance_test() {

    echo "Pointing to $SERVER_URL with VirtualUsers $VU and Loops $LOOPS"
    echo "Loading Loadtest $JMX_FILE"
    

    /opt/jmeter/apache-jmeter-5.5/bin/jmeter -n -t $JMX_FILE -JSERVER_URL=$SERVER_URL -JVUCount=$VU -JLoopCount=$LOOPS  -l testreport.jtl
}

start_timestamp=$(date '+%F %H:%M:00')
echo $start_timestamp
echo "##vso[task.setvariable variable=start_timestamp]$start_timestamp"
start_performance_test
stop_timestamp=$(date '+%F %H:%M:00')
echo $stop_timestamp
echo "##vso[task.setvariable variable=stop_timestamp]$stop_timestamp"



# AGENT_RELEASEDIRECTORY=/home/daniel_braaf/myagent/_work/r3/a /RELEASE_PRIMARYARTIFACTSOURCEALIAS/
