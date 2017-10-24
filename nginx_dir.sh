#!/bin/bash

read -p "请输入你的虚拟主机域名如（abc）:" yuming

#修改虚拟主机配置文件

cat > /etc/nginx/conf.d/$yuming.conf << END


server {
    listen       80;
    server_name  www.$yuming.com;
    charset utf-8;
    access_log  /var/log/nginx/www.$yuming.com.access.log  main;

    if ( $http_host ~* ^www\.$yuming\.com$ ) {    
 		break;
 		}
 	if ( $http_host ~* ^(.*)\.$yuming\.com$ ) {    
 		set $domain $1;	
 		rewrite /.* /$domain/index.html break;
 	
    }
 }

END

#创建测试页面
mkdir -p /usr/share/nginx/$yuming

echo "welcome to $yuming test page"  > /usr/share/nginx/$yuming/index.html

nginx  -t && echo "$虚拟主机创建成功！"

pkill -HUP nginx

service nginx restart

#添加到hosts文件

ip=`ifconfig eth0|sed -n '2p'|sed -n 's/.*inet \(.*\) netmask.*/\1/gp'`
echo "$ip $yuming" >> /etc/hosts
