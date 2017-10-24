#!/bin/bash
yum -y install httpd
yum -y install rsync

cat > /etc/rsyncd.conf << END
uid = apache
gid = apache
use chroot = yes
max connections = 4
pid file = /var/run/rsyncd.pid
exclude = lost+found/
transfer logging = yes
timeout = 900
ignore nonreadable = yes
dont compress   = *.gz *.tgz *.zip *.z *.Z *.rpm *.deb *.bz2 *.iso

[webshare]
         path = /var/www/html
         comment = www.abc.com html page
         read only = no
         auth users=user01 user02
         secrets file=/etc/rsyncd_user.db

END

echo "/usr/bin/rsync --daemon" >> /etc/rc.local 
chmod +x /etc/rc.d/rc.local

cat > /etc/rsyncd_user.db << END
user01:123
user02:456
END
chmod 600 /etc/rsyncd_user.db 
pkill -9 rsync ; rm -fr /var/run/rsyncd.pid
source  /etc/rc.local
chown apache.apache /var/www/html/
service httpd start
chkconfig httpd on
