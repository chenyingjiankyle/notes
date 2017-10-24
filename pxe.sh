#!/bin/bash


cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << END
DEVICE=eth1
BOOTPROTO=static
ONBOOT=yes
TYPE=Ethernet
USERCTL=yes
IPV6INIT=no
IPADDR=192.168.0.16
GATEWAY=192.168.0.10
NETMASK=255.255.255.0
END
#关闭eth0
sed -i 's/ONBOOT=yes/ONBOOT=no/' /etc/sysconfig/network-scripts/ifcfg-eth0

#关闭iptables和selinux
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config 
echo "/sbin/setenforce 0" >> /etc/rc.local 
chmod +x /etc/rc.local 
source  /etc/rc.local

mkdir /yum

mount -t nfs 172.25.254.250:/content /mnt/
mount -o loop /mnt/rhel7.1/x86_64/isos/rhel-server-7.1-x86_64-dvd.iso  /yum/

cd /etc/yum.repos.d/
find . -regex '.*\.repo$' -exec mv {} {}.back \;

cat > /etc/yum.repos.d/local.repo << EOT
[local]
baseurl=file:///yum
gpgcheck=0
EOT

yum clean all
yum repolist

yum -y install dhcp
 \cp /usr/share/doc/dhcp-4.2.5/dhcpd.conf.example  /etc/dhcp/dhcpd.conf

cat > /etc/dhcp/dhcpd.conf << END

allow booting;
allow bootp;

option domain-name "pod8.example.com";
option domain-name-servers 172.25.254.254;
default-lease-time 600;
max-lease-time 7200;

log-facility local7;

subnet 192.168.0.0 netmask 255.255.255.0 {
  range 192.168.0.50 192.168.0.60;
  option domain-name-servers 172.25.254.254;
  option domain-name "pod0.example.com";
  option routers 192.168.0.10;
  option broadcast-address 192.168.0.255;
  default-lease-time 600;
  max-lease-time 7200;
  next-server 192.168.0.16;
  filename "pxelinux.0";
}
END

systemctl restart dhcpd

yum -y install tftp-server
service tftp start
yum -y install syslinux
cp /usr/share/syslinux/pxelinux.0  /var/lib/tftpboot/

cd /var/lib/tftpboot/ 
mkdir pxelinux.cfg
cd pxelinux.cfg

cat > default << END

default vesamenu.c32
timeout 60
display boot.msg
menu background splash.jpg
menu title Welcome to Global Learning Services Setup!

label local
        menu label Boot from ^local drive
        menu default
        localhost 0xffff

label install
        menu label Install rhel7
        kernel vmlinuz
        append initrd=initrd.img ks=http://192.168.0.16/myks.cfg
END

cd /mnt/rhel7.1/x86_64/dvd/isolinux
cp splash.png vesamenu.c32 vmlinuz initrd.img /var/lib/tftpboot/

sed -i 's/disable.*/disable\t\t= no/' /etc/xinetd.d/tftp
systemctl start xinetd

yum -y install httpd

cat > /var/www/html/myks.cfg << END

#version=RHEL7
# System authorization information
auth --enableshadow --passalgo=sha512
# Reboot after installation 
reboot
# Use network installation
url --url="http://192.168.0.16/rhel7u1/"
# Use graphical install
#graphical 
text
# Firewall configuration
firewall --enabled --service=ssh
firstboot --disable 
ignoredisk --only-use=vda
# Keyboard layouts
# old format: keyboard us
# new format:
keyboard --vckeymap=us --xlayouts='us'
# System language 
lang en_US.UTF-8
# Network information
network  --bootproto=dhcp
network  --hostname=localhost.localdomain
#repo --name="Server-ResilientStorage" --baseurl=http://download.eng.bos.redhat.com/rel-eng/latest-RHEL-7/compose/Server/x86_64/os//addons/ResilientStorage
# Root password
rootpw --iscrypted nope 
# SELinux configuration
selinux --disabled
# System services
services --disabled="kdump,rhsmcertd" --enabled="network,sshd,rsyslog,ovirt-guest-agent,chronyd"
# System timezone
timezone Asia/Shanghai --isUtc
# System bootloader configuration
bootloader --append="console=tty0 crashkernel=auto" --location=mbr --timeout=1 --boot-drive=vda 
# 设置boot loader安装选项 --append指定内核参数 --location 设定引导记录的位置
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part / --fstype="xfs" --ondisk=vda --size=6144
%post
echo "redhat" | passwd --stdin root
useradd carol
echo "redhat" | passwd --stdin carol
# workaround anaconda requirements
%end

%packages
@core
%end

END
ln -s /yum/ /var/www/html/rhel7u1
service httpd start
systemctl restart xinetd
systemctl enable xinetd
systemctl enable httpd
systemctl enable dhcpd
