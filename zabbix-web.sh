#!/bin/bash

#下载安装软件
lftp 172.25.254.250:/notes/project/software/zabbix <<END
mirror zabbix3.2
exit
END

cd zabbix3.2
yum -y install httpd php php-mysql
yum -y localinstall php-mbstring-5.4.16-23.el7_0.3.x86_64.rpm php-bcmath-5.4.16-23.el7_0.3.x86_64.rpm
yum localinstall zabbix-web-3.2.7-1.el7.noarch.rpm zabbix-web-mysql-3.2.7-1.el7.noarch.rpm -y

sed -i 's/#php_value date.timezone.*/php_value date.timezone Asia\/Shanghai/' /etc/httpd/conf.d/zabbix.conf

#启动服务
service httpd start

#启动服务端服务

ssh root@172.25.8.11 "cd /usr/local/zabbix/sbin/;./zabbix_server"


