#!/bin/bash


create_token()
{
result=$(curl --request POST 'https://sso.dynatrace.com/sso/oauth2/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode "client_id=$(DT_CLIENTID)" \
--data-urlencode "client_secret=$(DT_CLIENTSECRET)" \
--data-urlencode 'scope=document:documents:write document:documents:read document:documents:delete document:environment-shares:read document:environment-shares:write document:environment-shares:claim document:environment-shares:delete automation:workflows:read automation:workflows:write automation:workflows:run automation:rules:read automation:rules:write automation:calendars:read automation:calendars:write')
result_dyna=$(echo $result | jq -r '.access_token')
}

get_wf_status()
{
create_token
curl -X 'GET' \
  "$(DT_TENANT_URL)/platform/automation/v1/executions/$(echo $id)" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H "authorization: Bearer $(echo $result_dyna)" | jq -r '.state'
}

start_test_wf()
{


create_token
res=$(curl -X 'POST' \
  "$(DT_TENANT_URL)/platform/automation/v1/workflows/$(DT_EVENT_WF)/run" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H "authorization: Bearer $(echo $result_dyna)" \
  -d '{
         "params": {
            "event_type": "START_TEST",
            "start_time": "$start_timestamp",
            "Release": $(RELEASE_RELEASEID),
            "Pipelineurl": "$(RELEASE_RELEASEWEBURL)",
            "stage": "$(ENVIRONMENT)",
            "Repository": "$(REPOSITORY)",
            "Release_Version": "$(DT_RELEASE_VERSION)",
            "Application": "$(APPLICATION)",
            "Namespace": "$(NAMESPACE)",
            "Build_Version": "$(DT_RELEASE_BUILD_VERSION)"            
         }
         }')
id=$(echo $res | jq -r '.id')
echo $id
while [[ $(get_wf_status) == "RUNNING" ]]; do
sleep 10
done

}

stop_test_wf()
{
create_token
res=$(curl -X 'POST' \
  "$(DT_TENANT_URL)/platform/automation/v1/workflows/$(DT_EVENT_WF)/run" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H "authorization: Bearer $(echo $result_dyna)" \
  -d '{
         "params": {
            "event_type": "END_TEST",
            "stop_time": "$stop_timestamp",
            "Release": $(Release.ReleaseId),
            "Pipelineurl": "$(Release.ReleaseWebURL)",
            "stage": "$(ENVIRONMENT)",
            "Repository": "$(REPOSITORY)",
            "Release Version": "$(DT_RELEASE_VERSION)",
            "Application": "$(APPLICATION)",
            "Namespace": "$(NAMESPACE)",
            "Build_Version": "$(DT_RELEASE_BUILD_VERSION)"            
         }
         }')
id=$(echo $res | jq -r '.id')
echo $id
while [[ $(get_wf_status) == "RUNNING" ]]; do
sleep 10
done

}

JMX_FILE=$AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS/extras/jmeter/Test_Banking_Process.jmx

start_performance_test() {

    echo "Pointing to $SERVER_URL with VirtualUsers $VU and Loops $LOOPS"
    echo "Loading Loadtest $JMX_FILE"
    

    /opt/jmeter/apache-jmeter-5.5/bin/jmeter -n -t $JMX_FILE -JSERVER_URL=$SERVER_URL -JVUCount=$VU -JLoopCount=$LOOPS  -l testreport.jtl
}

start_timestamp=$(date '+%F %H:%M:00')
echo $start_timestamp
echo "##vso[task.setvariable variable=start_timestamp]$start_timestamp"
start_test_wf
start_performance_test
stop_timestamp=$(date '+%F %H:%M:00')
echo $stop_timestamp
echo "##vso[task.setvariable variable=stop_timestamp]$stop_timestamp"
stop_test_wf



# AGENT_RELEASEDIRECTORY=/home/daniel_braaf/myagent/_work/r3/a /RELEASE_PRIMARYARTIFACTSOURCEALIAS/
