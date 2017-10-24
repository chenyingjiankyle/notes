#!/bin/bash

read -p "请输入你要创建的用户名：" user
read -p -s "请输入你的密码：" password
read -p "请输入你的虚拟主机域名如（www.abc.com）:" yuming

#修改虚拟主机配置文件

cat > /etc/nginx/conf.d/$yuming.conf << END


server {
    listen       80;
    server_name  $yuming;
    charset utf-8;
    access_log  /var/log/nginx/$yuming.access.log  main;

    location / {
        root   /usr/share/nginx/$yuming;
        index  index.html index.htm;
        auth_basic "info";
        auth_basic_user_file /usr/share/nginx/passwd.db;
    }
 }

END

#创建用户

yum -y install httpd-tools

expect <<EOF &> /dev/null
spawn htpasswd -cm /usr/share/nginx/passwd.db $user
expect "password:"
send "$password\n"
expect "Re-type new password:"
send "$password\n"
expect eof
exit
EOF

#创建测试页面
mkdir -p /usr/share/nginx/$yuming

echo "welcome to $yuming test page"  > /usr/share/nginx/$yuming/index.html

nginx  -t && echo "$虚拟主机创建成功！"

pkill -HUP nginx

service nginx restart

#添加到hosts文件

ip=`ifconfig eth0|sed -n '2p'|sed -n 's/.*inet \(.*\) netmask.*/\1/gp'`
echo "$ip $yuming" >> /etc/hosts
