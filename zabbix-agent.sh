#!/bin/bash

#下载安装agent端
lftp 172.25.254.250:/notes/project/software/zabbix <<END
mirror zabbix3.2
exit
END

cd zabbix3.2
rpm -ivh zabbix-agent-3.2.7-1.el7.x86_64.rpm
yum -y install net-snmp net-snmp-utils

#配置agent

sed -i 's/^Server=.*/Server=172.25.8.11/' /etc/zabbix/zabbix_agentd.conf
sed -i 's/ServerActive=.*/ServerActive=172.25.8.11/' /etc/zabbix/zabbix_agentd.conf
sed -n '$aHostname=servera.pod1.example.com\nUnsafeUserParameters=1' /etc/zabbix/zabbix_agentd.conf

#启动服务

systemctl start zabbix-agent
systemctl enable zabbix-agent
