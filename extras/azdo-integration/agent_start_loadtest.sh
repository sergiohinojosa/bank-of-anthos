#!/bin/bash


create_token()
{
result=$(curl --request POST 'https://sso.dynatrace.com/sso/oauth2/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode "client_id=$(dt_clientid)" \
--data-urlencode "client_secret=$(dt_clientsecret)" \
--data-urlencode 'scope=document:documents:write document:documents:read document:documents:delete document:environment-shares:read document:environment-shares:write document:environment-shares:claim document:environment-shares:delete automation:workflows:read automation:workflows:write automation:workflows:run automation:rules:read automation:rules:write automation:calendars:read automation:calendars:write')
result_dyna=$(echo $result | jq -r '.access_token')
}

get_wf_status()
{
create_token
curl -X 'GET' \
  "$(dt_tenant_url)/platform/automation/v1/executions/$(echo $id)" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H "authorization: Bearer $(echo $result_dyna)" | jq -r '.state'
}

start_test_wf()
{
export dt_event_wf=$DT_EVENT_WF
export dt_clientsecret=$DT_CLIENTSECRET
export dt_tenant_url=$DT_TENANT_URL
export dt_clientid=$DT_CLIENTID

create_token
res=$(curl -X 'POST' \
  "$(dt_tenant_url)/platform/automation/v1/workflows/$(dt_event_wf)/run" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H "authorization: Bearer $(echo $result_dyna)" \
  -d '{
         "params": {
            "event_type": "START_TEST",
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

JMX_FILE=$AGENT_RELEASEDIRECTORY/$RELEASE_PRIMARYARTIFACTSOURCEALIAS/extras/jmeter/Test_Banking_Process.jmx

start_performance_test() {

    echo "Pointing to $SERVER_URL with VirtualUsers $VU and Loops $LOOPS"
    echo "Loading Loadtest $JMX_FILE"
    start_test_wf

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
