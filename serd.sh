#!/bin/bash

#推密钥
ssh-keygen
ssh-copy-id root@172.25.1.10
ssh-copy-id root@172.25.1.11
ssh-copy-id root@172.25.1.12

mkdir /uplooking/
chown 48.48 /uplooking/
echo test > test.html

echo "123" > /root/.rsync_pass
chmod 600 /root/.rsync_pass 

for i in {10..12}; do rsync -avz --delete --password-file=/root/.rsync_pass /root/test.html user01@172.25.1.$i::webshare; done

for i in {10..12};do ssh root@172.25.1.$i "cat /var/www/html/test.html";done

#安装sersync
yum -y install rsync
wget ftp://172.25.254.250/notes/project/software/sersync2.5.4_64bit_binary_stable_final.tar.gz
tar xf sersync2.5.4_64bit_binary_stable_final.tar.gz -C /opt/
mv /opt/GNU-Linux-x86 /opt/sersync

#修改配置文件

cat > /opt/sersync/confxml.xml <<END

 <sersync>
        <localpath watch="/uplooking">
            <remote ip="172.25.1.10" name="webshare"/>
            <remote ip="172.25.1.11" name="webshare"/>
            <remote ip="172.25.1.12" name="webshare"/>
        </localpath>
        <rsync>
            <commonParams params="-az"/>
            <auth start="true" users="user02" passwordfile="/etc/rsync.pas"/>
            <userDefinedPort start="false" port="874"/><!-- port=874 -->
            <timeout start="false" time="100"/><!-- timeout=100 -->
            <ssh start="false"/>
        </rsync>
END

echo 456 > /etc/rsync.pas
chmod 600 /etc/rsync.pas
 ./sersync2 -d -r -n 12 -o ./confxml.xml 

