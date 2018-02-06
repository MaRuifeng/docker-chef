#!/bin/bash -e

# Set up the chef server with required configurations

# Author: ruifengm@sg.ibm.com
# Date: 2018-Jan-16

# When customized SSL port is used, beware of below open bug and its workaround
# https://github.com/chef/chef-server/issues/50
# In file /opt/opscode/embedded/cookbooks/private-chef/templates/default/oc_erchef.config.erb, below change need to be made
# {s3_url, "<%= node['private_chef']['nginx']['x_forwarded_proto'] %>://<%= @helper.vip_for_uri('bookshelf') %>"},
# TO
# {s3_url, "<%= node['private_chef']['nginx']['x_forwarded_proto'] %>://<%= @helper.vip_for_uri('bookshelf') %>:<%= node['private_chef']['nginx']['ssl_port'] %>"},
export S3_URL_CONFIG_PATH=/opt/opscode/embedded/cookbooks/private-chef/templates/default/oc_erchef.config.erb
# export S3_URL_CHECK_PATH=/var/opt/opscode/opscode-erchef/etc/app.config
export S3_URL_CHECK_PATH=/var/opt/opscode/opscode-erchef/etc/sys.config  # Renamed in newer versions of Chef

export API_FQDN=$(hostname -f)

rm -f /root/chef_configured

echo -e "[$(date)]\tAdding api_fqdn to map localhost ..."

grep -qE "127\.0\.0\.1.+${API_FQDN}" /etc/hosts || echo "127.0.0.1 ${API_FQDN}" >> /etc/hosts

echo -e "[$(date)]\tReconfiguring the Chef server if not done before ..."

[[ -z $(chef-server-ctl status) ]] && chef-server-ctl reconfigure 2>&1

if [[ ${NON_STD_SSL} == true ]]; then
	echo -e "[$(date)]\tAdding api_fqdn: ${API_FQDN} to /etc/opscode/chef-server.rb"
	echo api_fqdn \"${API_FQDN}\" > /etc/opscode/chef-server.rb
	echo -e "[$(date)]\tAdding customized SSL port ${SSL_PORT} for Nginx to /etc/opscode/chef-server.rb"
	echo "nginx['ssl_port'] = ${SSL_PORT}" >> /etc/opscode/chef-server.rb
	cat /etc/opscode/chef-server.rb

	echo "[$(date)]\tHacking s3_url of Bookshelf to ensure successful cookbook upload ..."
	sed -i "s/{s3_url, .*/{s3_url, \"https:\/\/${API_FQDN}:${SSL_PORT}\"},/g" ${S3_URL_CONFIG_PATH}
	echo -e "Reconfiguring chef server..."
	chef-server-ctl reconfigure 2>&1
	echo -e "[$(date)]\tChecking s3_url setting in ${S3_URL_CHECK_PATH} ..."
	cat ${S3_URL_CHECK_PATH} | grep s3_url
fi

echo -e "[$(date)]\tCreating user and organization..."
chef-server-ctl user-create ${USER} ${FIRST_NAME} ${LAST_NAME} ${EMAIL} ${PASSWORD} -f /etc/chef/${USER_PEM}
chef-server-ctl org-create ${ORG} ${ORG_FULL_NAME} --association_user ${USER} -f /etc/chef/${ORG_PEM}
chef-server-ctl user-show ${USER}
chef-server-ctl org-show ${ORG}

touch /root/chef_configured
echo -e "[$(date)]\tChef server configuration completed."
