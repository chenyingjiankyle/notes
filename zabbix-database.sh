#!/bin/bash

#安装mysql
yum -y install mariadb-server mariadb
systemctl start mariadb

#新建数据库导入数据表

mysql <<END
create database zabbix;
grant all on zabbix.* to zabbix@'%' identified by 'uplooking';
flush privileges;
exit
END

mysql zabbix < /root/schema.sql
mysql zabbix < /root/images.sql
mysql zabbix < /root/data.sql


