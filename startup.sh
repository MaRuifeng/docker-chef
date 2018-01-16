#!/bin/sh -e

# Start up the chef services inside the container, monitor their statues and exit if anyone is down

# Author: ruifengm@sg.ibm.com
# Date: 2018-Jan-16

echo -e "[$(date)]\tSetting kernel parameters and applying required system changes ..."
sysctl -w kernel.shmall=4194304
sysctl -w kernel.shmmax=17179869184
sysctl -w vm.overcommit_memory=1
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo 511 > /proc/sys/net/core/somaxconn
echo "127.0.0.1 $(hostname -f) $(hostname -s)" >> /etc/hosts # Needed for Bookshelf APIs

# Handling issue reported here (https://github.com/chef/chef-server/issues/403)
# If the server.pid file exists but the corresponding process does not, rails will be 
# caught in a restart loop, leading to a high CPU utilization. 
# Fixed since Chef Server 12.6.0.

# [[ -e /opt/opscode/embedded/service/oc_id/tmp/pids/server.pid ]] && rm -f /opt/opscode/embedded/service/oc_id/tmp/pids/server.pid

# /opt/opscode/embedded/bin/runsvdir-start &
echo -e "[$(date)]\tStarting the Chef server and tracing logs ..."
/usr/bin/chef-server-ctl start
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

if [[ -z $(chef-server-ctl status) ]]
then
	echo "##### Chef server is not configured #####"
	echo "##### Reconfiguring chef server...  #####"
	chef-server-ctl reconfigure
	echo "Chef server is up"
fi
echo "tracing chef server logs..."
