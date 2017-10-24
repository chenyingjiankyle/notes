#!/bin/bash

#更改主机名，关闭seliunx，关闭eth0网卡，设置网关
hostnamectl set-hostname cobbler
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
setenforce 0

sed -i 's/ONBOOT=yes/ONBOOT=no/' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i '$a GATEWAY=192.168.0.10' /etc/sysconfig/network-scripts/ifcfg-eth1
service network restart

#第二步: 下载软件，并安装
wget -r ftp://172.25.254.250/notes/project/software/cobbler_rhel7/
mv 172.25.254.250/notes/project/software/cobbler_rhel7/ cobbler

cd cobbler/
rpm -ivh python2-simplejson-3.10.0-1.el7.x86_64.rpm
rpm -ivh python-django-1.6.11.6-1.el7.noarch.rpm python-django-bash-completion-1.6.11.6-1.el7.noarch.rpm
yum -y localinstall cobbler-2.8.1-2.el7.x86_64.rpm cobbler-web-2.8.1-2.el7.noarch.rpm 

#第三步: 启动服务
systemctl start cobblerd
systemctl start httpd
systemctl enable httpd
systemctl enable cobblerd

#第四步：cobbler check 检测环境
sed -i 's/^server:.*/server: 192.168.0.11/' /etc/cobbler/settings
sed -i 's/^next_server:.*/next_server: 192.168.0.11/' /etc/cobbler/settings
setenforce=0
sed -i 's/disable.*/disable                 = no/' /etc/xinetd.d/tftp

yum -y install syslinux

systemctl restart rsyncd
systemctl enable rsyncd

netstat -tnlp |grep :888 &> /dev/null && echo "rsync OK"

yum -y install pykickstart

ed -i 's/^default_password.*/default_password_crypted: "$1$random-p$MvGDzDfse5HkTwXB2OLNb."/'  /etc/cobbler/settings

yum -y install fence-agents

#第五步:导入镜像
mkdir /yum
mount -t nfs 172.25.254.250:/content /mnt/
mount -o loop /mnt/rhel7.2/x86_64/isos/rhel-server-7.2-x86_64-dvd.iso /yum/
cobbler import --path=/yum --name=rhel-server-7.2-base --arch=x86_64
#修改dhcp，让cobbler来管理dhcp，并进行cobbler配置同步

yum -y install dhcp

#cat > /etc/cobbler/dhcp.template <<END
sed -i 's/192.168.1/192.168.0/g' /etc/cobbler/dhcp.template
sed -i 's/option routers.*/option routers             192.168.0.10;/' /etc/cobbler/dhcp.template
sed -i 's/option domain-name-servers 192.168.0.1;/option domain-name-servers 172.25.254.254;/' /etc/cobbler/dhcp.template

END

sed -i 's/manage_dhcp:.*/manage_dhcp: 1/' /etc/cobbler/settings 

systemctl restart cobblerd && echo "cobbler重启成功,进入数据通步cobbler sync"

ssh root@localhost "cobbler sync"
#/usr/bin/cobbler sync
#cobbler sync

systemctl restart xinetd
