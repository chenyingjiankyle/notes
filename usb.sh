#!/bin/bash

#创建挂载目录
mkdir /mnt/usb
mount /dev/sda1  /mnt/usb/

#yum源

rm -rf /etc/yum.repos.d/*

cat > /etc/yum.repos.d/base.repo <<END
[base]
baseurl=http://172.25.254.254/content/rhel6.5/x86_64/dvd/
gpgcheck=0

END

yum clean all

#安装文件系统 
yum -y install filesystem --installroot=/mnt/usb/

#安装应用程序与bash shell

yum -y install bash coreutils findutils grep vim-enhanced rpm yum passwd net-tools util-linux lvm2 openssh-clients bind-utils --installroot=/mnt/usb/

#安装内核

cp -a /boot/vmlinuz-2.6.32-431.el6.x86_64 /mnt/usb/boot/
cp -a /boot/initramfs-2.6.32-431.el6.x86_64.img /mnt/usb/boot/
cp -arv /lib/modules/2.6.32-431.el6.x86_64/ /mnt/usb/lib/modules/

#安装grub软件

rpm -ivh http://172.25.254.254/content/rhel6.5/x86_64/dvd/Packages/grub-0.97-83.el6.x86_64.rpm --root=/mnt/usb/ --nodeps --force
grub-install  --root-directory=/mnt/usb/ /dev/sda --recheck

cp /boot/grub/grub.conf  /mnt/usb/boot/grub/
#配置 grub.conf
cat >/mnt/usb/boot/grub/grub.conf <<END
default=0
timeout=5
splashimage=/boot/grub/splash.xpm.gz
hiddenmenu
title My usb system from kyle
        root (hd0,0)
        kernel /boot/vmlinuz-2.6.32-431.el6.x86_64 ro root=UUID=2eee2002-aeb4-499c-972c-15d62bf2a509 selinux=0 
        initrd /boot/initramfs-2.6.32-431.el6.x86_64.img

END

cp /boot/grub/splash.xpm.gz /mnt/usb/boot/grub/

#完善配置文件
cp /etc/skel/.bash* /mnt/usb/root/

cat > /mnt/usb/etc/sysconfig/network <<END

NETWORKING=yes
HOSTNAME=myusb.kyle.org
END

cp /etc/sysconfig/network-scripts/ifcfg-eth0 /mnt/usb/etc/sysconfig/network-scripts/

cat > /mnt/usb/etc/sysconfig/network-scripts/ifcfg-eth0 << END
DEVICE="eth0"
BOOTPROTO="static"
ONBOOT="yes"
IPADDR=192.168.0.8
NETMASK=255.255.255.0
GATEWAY=192.168.0.254
DNS1=8.8.8.8

END

cat > /mnt/usb/etc/fstab << END

UUID="" /  ext4 defaults 0 0
proc                    /proc                   proc    defaults        0 0
sysfs                   /sys                    sysfs   defaults        0 0
tmpfs                   /dev/shm                tmpfs   defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0

END

sed -i 's/^root/root:$1$HORgV/$uu5Ipz.4aRdZKCszBDput0:15937:0:99999:7:::/'  /mnt/usb/etc/shadow

umount /mnt/usb/
