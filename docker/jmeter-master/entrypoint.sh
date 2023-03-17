#!/bin/bash

echo "********************************************************"
echo "*              Installing JMeter Plugins               *"
echo "********************************************************"
echo

if [ -d $JMETER_CUSTOM_PLUGINS_FOLDER ]
then
  echo "Installing custom plugins from ${JMETER_CUSTOM_PLUGINS_FOLDER}"
  for plugin in ${JMETER_CUSTOM_PLUGINS_FOLDER}/*.jar; do
      echo "Copying plugin $plugin to ${JMETER_HOME}/lib/ext/${plugin}"
      cp $plugin ${JMETER_HOME}/lib/ext
  done;
else
  echo "No custom plugins found in ${JMETER_CUSTOM_PLUGINS_FOLDER}"
fi
echo

echo "********************************************************"
echo "*            Initializing JMeter Master                *"
echo "********************************************************"
echo

freeMem=$(awk '/MemAvailable/ { print int($2/1024) }' /proc/meminfo)

[[ -z ${JVM_XMN} ]] && JVM_XMN=$(($freeMem*2/10))
[[ -z ${JVM_XMS} ]] && JVM_XMS=$(($freeMem*8/10))
[[ -z ${JVM_XMX} ]] && JVM_XMX=$(($freeMem*8/10))

echo "Setting default JVM_ARGS=-Xmn${JVM_XMN}m -Xms${JVM_XMS}m -Xmx${JVM_XMX}m"
export JVM_ARGS="-Xmn${JVM_XMN}m -Xms${JVM_XMS}m -Xmx${JVM_XMX}m"

if [ -n "$OVERRIDE_JVM_ARGS" ]; then
  echo "Overriding JVM_ARGS=${OVERRIDE_JVM_ARGS}"
  export JVM_ARGS="${OVERRIDE_JVM_ARGS}"
fi

if [ -n "$ADDITIONAL_JVM_ARGS" ]; then
  echo "Appending additional JVM args: ${ADDITIONAL_JVM_ARGS}"
  export JVM_ARGS="${JVM_ARGS} ${ADDITIONAL_JVM_ARGS}"
fi

echo "Available memory: ${freeMem} MB"
echo "Configured JVM_ARGS=${JVM_ARGS}"
echo

echo "********************************************************"
echo "*           Preparing JMeter Test Execution            *"
echo "********************************************************"
echo

# Keep entrypoint simple: we must pass the standard JMeter arguments
EXTRA_ARGS=-Dlog4j2.formatMsgNoLookups=true

until [ $(find ${TESTS_DIR}/ -type f | wc -l) -ne 0 ]; do
    echo "No tests found in ${TESTS_DIR}/ directory. Sleeping for 20 seconds..."
    sleep 20
done

echo
echo "Found tests in ${TESTS_DIR}/ directory."
echo

if [ -z ${SLAVE_IP_STRING} ]; then
  SLAVE_IP_STRING=$(getent ahostsv4 ${SLAVE_SVC_NAME} | awk '!($1 in a){a[$1];printf "%s%s",t,$1; t=","}')
  SLAVE_IP_COUNT=$(echo ${SLAVE_IP_COUNT} | awk -F',' '{print NF}')
  until [ $SLAVE_IP_COUNT -eq $SLAVE_REPLICA_COUNT ]; do
    echo "Waiting for $SLAVE_REPLICA_COUNT slave IPs to get resolved, currently resolved: ${SLAVE_IP_COUNT}"
    echo "Currently resolved slave IPs: ${SLAVE_IP_STRING}"
    echo "Checking again in 5 seconds..."
    sleep 5
    SLAVE_IP_STRING=$(getent ahostsv4 ${SLAVE_SVC_NAME} | awk '!($1 in a){a[$1];printf "%s%s",t,$1; t=","}')
    SLAVE_IP_COUNT=$(echo ${SLAVE_IP_STRING} | awk -F',' '{print NF}')
  done
fi

echo
echo "Tests will be distributed among the following Slave IPs: ${SLAVE_IP_STRING}"
echo

echo "********************************************************"
echo "*                Executing JMeter tests                *"
echo "********************************************************"
echo

for file in ${TESTS_DIR}/*.jmx ; do
  echo "START Running JMeter on $(date) for test ${file}"
  echo

  TEST_ARGS="-n -t ${file}"
  CONN_ARGS="-Jserver.rmi.ssl.disable=${SSL_DISABLED} -R ${SLAVE_IP_STRING}"
  EXTRA_ARGS="-l /tmp/report.jtl -e -o /tmp/report -j /tmp/jmeter.log"
  echo "Executing command: jmeter ${TEST_ARGS} ${CONN_ARGS} ${EXTRA_ARGS} ${ADDITIONAL_JMETER_ARGS} ${JMETER_PROPERTIES}"
  echo
  jmeter ${TEST_ARGS} ${CONN_ARGS} ${EXTRA_ARGS} ${ADDITIONAL_JMETER_ARGS} ${JMETER_PROPERTIES}

  echo "END Finished JMeter test on $(date) for test ${file}"
  echo
done

echo "********************************************************"
echo "*           JMeter test executions finished            *"
echo "********************************************************"
echo

echo "Sleeping for 900 seconds so report can be examined"
sleep 900