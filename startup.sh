#!/bin/bash

# Start up the chef services inside the container, monitor their statues and exit if anyone is down

# Author: ruifengm@sg.ibm.com
# Date: 2018-Jan-16

echo -e "[$(date)]\tSetting kernel parameters and applying required system changes ..."
sysctl -w kernel.shmall=4194304
sysctl -w kernel.shmmax=17179869184 # for postgres
sysctl -w vm.overcommit_memory=1
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo 511 > /proc/sys/net/core/somaxconn
echo "127.0.0.1 $(hostname -f) $(hostname -s)" >> /etc/hosts # Needed for Bookshelf APIs

# Handling issue reported here (https://github.com/chef/chef-server/issues/403)
# If the server.pid file exists but the corresponding process does not, rails will be 
# caught in a restart loop, leading to a high CPU utilization. 

[[ -e /opt/opscode/embedded/service/oc_id/tmp/pids/server.pid ]] && rm -f /opt/opscode/embedded/service/oc_id/tmp/pids/server.pid

echo -e "[$(date)]\tStarting the Chef server and tracing logs ..."
/opt/opscode/embedded/bin/runsvdir-start &
if [[ -f "/root/chef_configured" ]]; then
	echo -e "[$(date)]\tChef Server already configured!\n"
    chef-server-ctl status
else
    echo -e "[$(date)]\tApply required configurations of the Chef server ..."
    /usr/local/bin/setup.sh
fi
chef-server-ctl tail &

stop_chef() {
	echo -e "[$(date)]\tSIGTERM received from docker. Gracefully stopping the Chef server ..."
	chef-server-ctl stop > /dev/null 2>&1
	exit $?
}

trap 'kill ${!}; stop_chef' SIGTERM

while sleep 2; do
  ps aux | grep -q '[r]unsvdir -P /opt/opscode/service' # use regex to avoid grep process itself being grepped
  RUNSVDIR_STATUS=$?
  if [[ $RUNSVDIR_STATUS -ne 0 ]]; then
  	echo -e "[$(date)]\tThe runsvdir program is not running. There is no guarantee that the spawned runsv processes can be properly maintained. Aborting the container ..."
    exit 1
  fi
done