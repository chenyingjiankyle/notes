#!bin/bash

#保证我们所有服务器的时区都是Asia/shanghai

timedatectl set-timezone Asia/Shanghai
ntpdate -u 172.25.254.254 ;  setenforce 0

#软件安装，这里server端通过源码编译的方式，将服务主目录放置/usr/local/zabbix目录下：

lftp 172.25.254.250:/notes/project/software/zabbix <<END
mirror zabbix3.2
END

cd zabbix3.2
tar xf zabbix-3.2.7.tar.gz -C /usr/local/src/
yum install gcc gcc-c++ mariadb-devel libxml2-devel net-snmp-devel libcurl-devel -y
# 安装源码编译需要的依赖包
cd /usr/local/src/zabbix-3.2.7/
 ./configure --prefix=/usr/local/zabbix --enable-server --with-mysql --with-net-snmp --with-libcurl --with-libxml2 --enable-agent --enable-ipv6
make && make install

useradd zabbix

sed -i 's/DBHost=.*/DBHost=172.25.8.13/' /usr/local/zabbix/etc/zabbix_server.conf
sed -i '$aDBPassword=uplooking' /usr/local/zabbix/etc/zabbix_server.conf

#将sql语句发送到data端

cd /usr/local/src/zabbix-3.2.7/database/mysql/
scp -r * 172.25.8.13:/root/

