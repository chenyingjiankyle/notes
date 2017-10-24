#!/bin/bash
read -p "请输入dns服务器ip，如（172.25.8.10）：" ip
read -p "请输入你的注册域，如（abc.com）：" zuceyu
read -p "请输入电信用户ip，如（172.25.8.11）：" dxyh
read -p "请输入网通用户ip，如（172.25.8.12）：" wtyh
read -p "请输入电信用户访问的ip，如：（192.168.11.1）" dxip
read -p "请输入网通用户访问的ip，如：（22.21.1.1）" wtip
read -p "请输入其他用户访问的ip，如：（1.1.1.1）" qtip

yum -y install bind

cat > /etc/named.conf << END

options {
	listen-on port 53 { 127.0.0.1; any; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	allow-query     { localhost; any; };
	recursion no;
	dnssec-enable no;
	dnssec-validation no;
	dnssec-lookaside auto;
	bindkeys-file "/etc/named.iscdlv.key";
	managed-keys-directory "/var/named/dynamic";
	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};
logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};
view  dx {
        match-clients { $dxyh; };
	zone "." IN {
		type hint;
		file "named.ca";
	};
	zone "$zuceyu" IN {
		type master;
		file "$zuceyu.dx.zone";	
	};
	include "/etc/named.rfc1912.zones";
};
view  wt {
        match-clients { $wtyh; };
        zone "." IN {
                type hint;
                file "named.ca";
        };
        zone "$zuceyu" IN {
                type master;
                file "$zuceyu.wt.zone";
        };
	include "/etc/named.rfc1912.zones";
};
view  other {
        match-clients { any; };
        zone "." IN {
                type hint;
                file "named.ca";
        };
        zone "$zuceyu" IN {
                type master;
                file "$zuceyu.other.zone";
        };
        include "/etc/named.rfc1912.zones";
};
include "/etc/named.root.key";

END

cat > /var/named/$zuceyu.dx.zone <<END

\$TTL 1D
@	IN SOA	ns1.$zuceyu. rname.invalid. (
					10	; serial
					1D	; refresh
					1H	; retry
					1W	; expire
					3H )	; minimum
@	NS	ns1.$zuceyu.
ns1     A       $ip
www	A	$dxip


END

cat > /var/named/$zuceyu.wt.zone <<END

\$TTL 1D
@       IN SOA  ns1.$zuceyu. rname.invalid. (
                                        10      ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
@       NS      ns1.$zuceyu.
ns1     A       $ip
www     A       $wtip


END

cat > /var/named/$zuceyu.other.zone <<END

\$TTL 1D
@       IN SOA  ns1.$zuceyu. rname.invalid. (
                                        10      ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
@       NS      ns1.$zuceyu.
ns1     A       $ip
www     A       $qtip


END

chgrp named /var/named/$zuceyu.*

service named start
chkconfig named on

