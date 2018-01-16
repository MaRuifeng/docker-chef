# This Dockerfile creates a docker image that can be run as a chef server instance
# 
# Note the installation package needs to be constantly updated accordingly (https://downloads.chef.io/chef-server)
# Chef guys say they "super duper don't support Chef Server in Docker" (https://discourse.chef.io/t/installing-and-configuring-chef-into-docker-container/11744/2), 
# but we'll still give a try for it. 
# 
# Author: ruifengm@sg.ibm.com
# Created: 2018-Jan-16
# Last Modified: 2018-Jan-16

FROM sla-dtr.sby.ibm.com/gts-docker-library/centos:6.6
# FROM centos:6.6

MAINTAINER Ruifeng Ma <ruifengm@sg.ibm.com>

RUN yum -y update

# RUN yum -y install tar && \
#     yum -y install python-setuptools && easy_install supervisor && \
#     yum clean all

ADD https://packages.chef.io/files/stable/chef-server/12.17.15/el/6/chef-server-core-12.17.15-1.el6.x86_64.rpm /tmp/chef-server-core-12.17.15-1.el6.x86_64.rpm

RUN rpm -Uvh /tmp/chef-server-core-12.17.15-1.el6.x86_64.rpm && \
    rm /tmp/chef-server-core-12.17.15-1.el6.x86_64.rpm

RUN ln -sf /bin/true /sbin/initctl && mkdir /etc/cron.hourly && mkdir -p /var/www/shared

EXPOSE  443

ADD startup.sh setup.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/*.sh

CMD ["startup.sh"]
