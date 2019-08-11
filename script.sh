#!/bin/bash
#sspanel 一键搭建脚本 商业版
#测试脚本 请勿破解
#2019-8-11 11:51:42
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
ulimit -c 0
cd /data && rm -rf script*
cd /root
source /etc/os-release &>/dev/null
#IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
#resources=`echo aHR0cHM6Ly9jZG4ucWluZ3NlLmdh | base64 -d`;
update_time='2019-1-15 17:19:45'
config_adr='/data/wwwroot/default/config/.config.php'
#check root
[ $(id -u) != "0" ] && { echo "错误: 您必须以root用户运行此脚本"; exit 1; }
Get_Ip() {
	ip=$(curl -s http://members.3322.org/dyndns/getip)
	[[ -z $ip ]] && ip=$(curl -s https://api.ip.sb/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.ipify.org)
	[[ -z $ip ]] && ip=$(curl -s https://ip.seeip.org)
	[[ -z $ip ]] && ip=$(curl -s https://ifconfig.co/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.myip.com | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
	[[ -z $ip ]] && ip=$(curl -s icanhazip.com)
	[[ -z $ip ]] && ip=$(curl -s myip.ipip.net | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
	[[ -z $ip ]] && echo -e "\n 这小鸡鸡还是割了吧！\n" && exit
}
Check_System()
{
    if [[ "${ID}" == "centos" && ${VERSION_ID} -ge 7 ]];then
        Echo_Green "当前系统为 Centos ${VERSION_ID}"
        PM="yum"
    elif [[ "${ID}" == "debian" && ${VERSION_ID} -ge 8 ]];then
        Echo_Green "当前系统为 Debian ${VERSION_ID}"
        PM="apt-get"
    elif [[ "${ID}" == "ubuntu" && `echo "${VERSION_ID}" | cut -d '.' -f1` -ge 16 ]];then
        Echo_Green "当前系统为 Ubuntu ${VERSION_ID}"
        PM="apt-get"
	elif [[ `rpm -q centos-release |cut -d - -f1` == "centos" && `rpm -q centos-release |cut -d - -f3` == 6 ]];then
		Echo_Green "当前系统为 Centos 6"
        PM="yum"
		ID="centos"
		VERSION_ID="6"
    else
        Echo_Red "当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内，安装中断"
        exit 1
    fi
	MemTotal=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
	Cores=$(cat /proc/cpuinfo | grep "cpu cores" | uniq |awk '{print $4}')
	i=`expr $MemTotal / 1024`;#echo $i;
	if [[ ${i} -lt 480 ]] || [[ ${Cores} -lt 1 ]];then
		Echo_Red "当前系统内存(${i}MB < 480MB) 内核(${Cores} < 1)不足，安装中断"
		exit 0;
	fi
}
Download_speed_test()
{
	#自动选择下载节点
	GIT='raw.githubusercontent.com'
	LIB='qcloud.coding.net'
	GIT_PING=`ping -c 1 -w 1 $GIT|grep time=|awk '{print $7}'|sed "s/time=//"`
	LIB_PING=`ping -c 1 -w 1 $LIB|grep time=|awk '{print $7}'|sed "s/time=//"`
	echo "$GIT_PING $GIT" > ping.pl
	echo "$LIB_PING $LIB" >> ping.pl
	Download=`sort -V ping.pl|sed -n '1p'|awk '{print $2}'`
	if [ "$Download" == "$GIT" ];then
		Download='https://raw.githubusercontent.com/marisn2017/donation_shell/master'
	else
		Download='https://qcloud.coding.net/u/marisn/p/donation_shell/git/raw/master'
	fi
	rm -f ping.pl		
}

InputIPAddress()
{
    if [ "$IPAddress" == '' ]; then
        Echo_Red "无法检测您的IP";
        read -p '请输入您的公网IP:' IPAddress;
        [ "$IPAddress" == '' ] && InputIPAddress;
    fi;
    [ "$IPAddress" != '' ] && echo -n '[  OK  ] 您的IP是:' && echo $IPAddress;
	export IPAddress=$IPAddress
    sleep 1
}

Start_install()
{
    clear
	Get_Ip
    IPAddress=$ip;
	Check_System
	InputIPAddress
	check_sq=`curl -s http://sq.67cc.cn/check.php?ip=${IPAddress}`;
	if [[ "$check_sq" != 1 ]]; then
	Echo_Green "检测您的IP暂未授权，请按照下面提示进行授权：";
	read -p "请输入授权绑定QQ:" QQ_209224407
	read -p "请输入授权卡密:" KM_209224407
	sq="http://sq.67cc.cn/api.php?ip=$IPAddress&qq=$QQ_209224407&km=$KM_209224407"
	km_sq=`curl -s ${sq}`;
	key="[$IPAddress]授权成功";
		if [[ "$km_sq" != "$key" ]];then
		Echo_Red "$km_sq"
		exit 0;
		else
		Echo_Green "$km_sq"
		Set_Web
		fi
	else
	Set_Web
	fi
}

Install_Oneinstack()
{
    # Check_System #获取系统信息
	${PM} -y remove httpd
	${PM} -y install wget screen curl python #for CentOS/Redhat
	# apt-get -y install wget screen curl python #for Debian/Ubuntu
	#修改系统DNS
	# echo "nameserver 114.114.114.114
# nameserver 114.114.114.115" > /etc/resolv.conf
    # service network restart
	wget http://mirrors.linuxeye.com/oneinstack-full.tar.gz #>/dev/null 2>&1 #包含源码，国内外均可下载
	OneinstackFile="/root/oneinstack-full.tar.gz"  
	if [[ ! -f ${OneinstackFile} ]];then
        Echo_Red "Oneinstack 下载失败"
        exit 0
    fi
	tar xzf oneinstack-full.tar.gz && rm -rf oneinstack-full.tar.gz
	cd oneinstack #如果需要修改目录(安装、数据存储、Nginx日志)，请修改options.conf文件
	#screen -S oneinstack #如果网路出现中断，可以执行命令`screen -R oneinstack`重新连接安装窗口
	if [[ ${Choose_Web} == 1 ]];then
	./install.sh --nginx_option 1 --php_option 6  --phpmyadmin  --db_option 3  --dbinstallmethod 1  --dbrootpwd ${Input_Dbpwd}  --iptables #--reboot #注：请勿sh install.sh或者bash install.sh这样执行
	else
	./install.sh --nginx_option 1 --php_option 6  --phpmyadmin  --db_option 3  --dbinstallmethod 1  --dbrootpwd ${DB_PASS}  --iptables
	fi
	cp -f /usr/local/php/bin/php /usr/bin/ && chmod +x /usr/bin/php
	cp -f /usr/local/mysql/bin/mysql /usr/bin/ && chmod +x /usr/bin/mysql
}

Set_Web_Parameter()
{
	clear
	Echo_Green "请选择搭建面板："
	Echo_Blue "1.sspanel"
	Echo_Blue "2.ssrpanel[暂不支持小内存机]"
	read -p "选择:" Choose_Web
	Choose_Web=${Choose_Web:-"1"}
	clear
	case $Choose_Web in
	"1")
	Install_Sspanel_Web
	;;
	"2")
	Install_Ssrpanel_Web
	;;
	*)
	Echo_Red "输入错误"
	exit 0;
	esac
}

Install_Sspanel_Web_to_Bt()
{
    Echo_Yellow "此脚本为sspanel对接宝塔，请确认你已经认真看了搭建前的教程？"
	read -p "y/n?" ABCD
	if [[ "$ABCD" != "y" ]];then
	Echo_Red "教程地址:https://sybk.tw/archives/commercial-version-of-oneclick-script-has-been-released.html"
	exit 0;
	fi
	clear
	echo -e "欢迎使用 [\033[34m ss-panel-v3-mod_Uim宝塔快速部署工具 \033[0m]"
	echo "----------------------------------------------------------------------------"
	echo -e "请注意这个要求：宝塔版本=\033[31m 5.9 \033[0m,php版本=\033[31m 7.1\033[0m ！"
	echo "----------------------------------------------------------------------------"
	echo -e "\033[1;5;33m请在搭建前认真看清楚搭建所需要的环境，请勿直接搭建\033[0m"
	echo "----------------------------------------------------------------------------"
	sleep 2
	read -p "请输入宝塔面板添加的网站域名：(请不要修改添加之后的默认地址，只输入域名即可)" Input_Web
	# if [["$Input_Web" == ""]];then
		# Echo_Red "请勿回车"
		# exit 0;
	# fi
	#read -p "请输入网站目录(eg:/www/wwwroot/www.baidu.com)[此配置很重要,错误导致将搭建失败]" Input_MU
	read -p "请输入宝塔面板添加的MySQL用户名：" Input_Dbuser
	Input_Dbuser=${Input_Dbuser:-"sspanel"}
	read -p "请输入宝塔面板添加的MySQL密码：" Input_Dbpwd
	Input_Dbpwd=${Input_Dbpwd:-"sspanel"}
	read -p "请输入网站站点名称：" Input_Webname
	Input_Webname=${Input_Webname:-"sspanel"}
	read -p "请输入节点对接token：" Input_Token
    Input_Token=${Input_Token:-"marisn"}
	sleep 1
	echo "请等待系统自动操作......"
	yum update -y
	yum install epel-* -y
	yum install gcc  gcc-c++ unzip zip   -y 
	Download_speed_test
	echo "正在安装依赖环境......";
	sleep 2
	cd /www/wwwroot/${Input_Web}
	rm -rf index.html 404.html
	#下载官方源码
	wget ${Download}/sspanel.tar.gz
	Sspanel_resources="/data/wwwroot/default/sspanel.tar.gz"  
	if [[ ! -f ${Sspanel_resources} ]];then
        echo "面板程序 下载失败" > /root/error.log
		exit 0;
    fi
	tar xzf sspanel.tar.gz && rm -rf sspanel.tar.gz
	rm -rf composer.lock && rm -rf composer.phar
	chown -R root:root *
	chmod -R 755 *
	chown -R www:www storage
	wget https://getcomposer.org/installer -O composer.phar
	php composer.phar
	php composer.phar install
	# mv tool/alipay-f2fpay vendor/
	# mv -f tool/cacert.pem vendor/guzzle/guzzle/src/Guzzle/Http/Resources/
	# mv -f tool/autoload_classmap.php vendor/composer/system,
	sed -i 's/proc_open,//g' /www/server/php/71/etc/php.ini
	sed -i 's/system,//g' /www/server/php/71/etc/php.ini
	sed -i 's/proc_get_status,//g' /www/server/php/71/etc/php.ini
    sed -i 's/putenv,//g' /www/server/php/71/etc/php.ini	   
	cd /www/wwwroot/${Input_Web}/config
    sed -i "s/dbname/$Input_Dbuser/g" .config.php
	sed -i "s/dbuser/$Input_Dbuser/g" .config.php
	sed -i "s/dbpassword/$Input_Dbpwd/g" .config.php
	sed -i "s/zhandianmingcheng/$Input_Webname/g" .config.php
	sed -i "s/jiaoyankey/$Input_Token/g" .config.php
	WEB_URL_SZ="http://$Input_Web"
	sed -i "s/zhandiandizhi/$WEB_URL_SZ/g" .config.php
	cd /www/wwwroot/${Input_Web}
	mysql -u${Input_Dbuser} -p${Input_Dbpwd} ${Input_Dbuser} < /www/wwwroot/${Input_Web}/sql/sspanel.sql >/dev/null 2>&1
	clear
	chown -R www:www storage/
	chmod -R 777 storage/                        
	php xcat initdownload 
	sleep 3
	#修改伪静态以及默认路径
	sed -i "s/\/www\/wwwroot\/$Input_Web/\/www\/wwwroot\/$Input_Web\/public/g" /www/server/panel/vhost/nginx/${Input_Web}.conf
	echo '
	location / {
	  try_files $uri $uri/ /index.php$is_args$args;
	  }
	' >/www/server/panel/vhost/rewrite/${Input_Web}.conf
	echo "正在重启php&Nginx服务..."
	service php-fpm-71 reload
	service nginx reload
	echo "----------------------------------------------------------------------------"
	echo "部署完成，请打开http://$Input_Web即可浏览"
	echo "默认用户名&密码： marisn@67cc.cn   marisn 第一次登陆请务必到后台修改密码！"
	echo "如果打不开站点，请到宝塔面板中软件管理重启nginx和php7.1"
	echo "这个原因触发几率<10%，原因是修改配置后需要重启Nginx服务和php服务才能正常运行"
	echo "----------------------------------------------------------------------------"
}

Install_Ssrpanel_Web_to_Bt()
{
    Echo_Yellow "此脚本为ssrpanel对接宝塔，请确认你已经认真看了搭建前的教程？"
	read -p "y/n?" ABCD
	if [[ "$ABCD" != "y" ]];then
	Echo_Red "教程地址:https://sybk.tw/archives/commercial-version-of-oneclick-script-has-been-released.html"
	exit 0;
	fi
	clear
	echo -e "欢迎使用 [\033[34m ssrpanel 宝塔快速部署工具 \033[0m]"
	echo "----------------------------------------------------------------------------"
	echo -e "请注意这个要求：宝塔版本=\033[31m 5.9 \033[0m,php版本=\033[31m 7.1\033[0m ！"
	echo "----------------------------------------------------------------------------"
	echo -e "\033[1;5;33m请在搭建前认真看清楚搭建所需要的环境，请勿直接搭建\033[0m"
	echo "----------------------------------------------------------------------------"
	sleep 2
	read -p "请输入宝塔面板添加的网站域名：(请不要修改添加之后的默认地址，只输入域名即可)" Input_Web
	# if [["$Input_Web" == ""]];then
		# Echo_Red "请勿回车"
		# exit 0;
	# fi
	#read -p "请输入网站目录(eg:/www/wwwroot/www.baidu.com)[此配置很重要,错误导致将搭建失败]" Input_MU
	read -p "请输入宝塔面板添加的MySQL用户名：" Input_Dbuser
	Input_Dbuser=${Input_Dbuser:-"ssrpanel"}
	read -p "请输入宝塔面板添加的MySQL密码：" Input_Dbpwd
	Input_Dbpwd=${Input_Dbpwd:-"root"}
	sleep 1
	echo "请等待系统自动操作......"
	yum update -y
	yum install epel-* -y
	yum install gcc  gcc-c++ unzip zip   -y 
	vphp='7.1'
	version='71'
	Download_speed_test
	echo "正在安装fileinfo到服务器......";
	if [ ! -d "/www/server/php/71/src/ext/fileinfo" ];then
	wget -O ext-71.zip https://raw.githubusercontent.com/marisn2017/donation_shell/master/ext-71.zip
	unzip -o ext-71.zip -d /www/server/php/71/ > /dev/null
	rm -f ext-71.zip
	fi
	cd /www/server/php/71/
	mv ext-71 ext
	cd /www/server/php/71/ext/fileinfo
	/www/server/php/71/bin/phpize
	./configure --with-php-config=/www/server/php/71/bin/php-config
	make && make install
	echo -e " extension = \"fileinfo.so\"\n" >> /www/server/php/71/etc/php.ini
	service php-fpm-71 reload
	echo '==============================================='
	echo 'fileinfo安装完成!'
	sleep 1
	echo "正在安装依赖环境......";
	sleep 2
	cd /www/wwwroot/${Input_Web}
	rm -rf index.html 404.html
	#下载官方源码
	git clone https://github.com/marisn2017/ssrpanel_resource.git tmp && mv tmp/.git . && rm -rf tmp && git reset --hard
	chown -R root:root *
	chmod -R 755 *
	chown -R www:www storage
	sed -i 's/proc_open,//g' /www/server/php/71/etc/php.ini
	sed -i 's/system,//g' /www/server/php/71/etc/php.ini
	sed -i 's/proc_get_status,//g' /www/server/php/71/etc/php.ini 
	sed -i 's/putenv,//g' /www/server/php/71/etc/php.ini    
	cd /www/wwwroot/${Input_Web}
    cp .env.example .env
	sed -i '/DB_DATABASE/c \DB_DATABASE='${Input_Dbuser}'' .env
	sed -i '/DB_USERNAME/c \DB_USERNAME='${Input_Dbuser}'' .env
	sed -i '/DB_PASSWORD/c \DB_PASSWORD='${Input_Dbpwd}'' .env
	mysql -u${Input_Dbuser} -p${Input_Dbpwd} ${Input_Dbuser} < /www/wwwroot/${Input_Web}/sql/db.sql >/dev/null 2>&1
	wget https://getcomposer.org/installer -O composer.phar
	php composer.phar
	php composer.phar install
	php artisan key:generate
	clear
	chown -R www:www storage/
	chmod -R 777 storage/
	sleep 3
	#修改伪静态以及默认路径
	sed -i "s/\/www\/wwwroot\/$Input_Web/\/www\/wwwroot\/$Input_Web\/public/g" /www/server/panel/vhost/nginx/${Input_Web}.conf
	echo '
	location / {
	  try_files $uri $uri/ /index.php$is_args$args;
	  }
	' >/www/server/panel/vhost/rewrite/${Input_Web}.conf
	echo "正在重启php&Nginx服务..."
	service php-fpm-71 reload
	service nginx reload
	echo "----------------------------------------------------------------------------"
	echo "部署完成，请打开http://$Input_Web即可浏览"
	echo "默认用户名&密码：admin   123456 第一次登陆请务必到后台修改密码！"
	echo "如果打不开站点，请到宝塔面板中软件管理重启nginx和php7.1"
	echo "这个原因触发几率<10%，原因是修改配置后需要重启Nginx服务和php服务才能正常运行"
	echo "----------------------------------------------------------------------------"
}

Install_Ssrpanel_Web()
{
    clear
    Echo_Green "Start configuring the site parameters..."
	read -p "设置数据库密码[回车默认为root]: " DB_PASS
	DB_PASS=${DB_PASS:-"root"}
	Echo_Green "你设置的密码为 ${DB_PASS}"
	echo -e "\033[1;5;31m即将开始搭建网站环境，此过程较耗时，请耐心等待...\033[0m"
	sleep 5
    if [[ `ps -ef | grep nginx |grep -v grep | wc -l` -ge 1 ]];then
	Echo_Red "提示本机存有nginx环境，跳过环境搭建"
	mkdir /data/wwwroot/default/
	else
	Install_Oneinstack
	cd /root/oneinstack && rm -rf addons.sh
	wget -N -P /root/oneinstack/ --no-check-certificate ${Download}/addons.sh  >/dev/null 2>&1
		if [[ ! -f "/root/oneinstack/addons.sh" ]];then
		wget -N -P /root/oneinstack/ --no-check-certificate https://raw.githubusercontent.com/marisn2017/donation_shell/master/addons.sh
		echo "fileinfo环境未搭建" > /root/error.log
		fi
	chmod +x addons.sh && ./addons.sh
	fi
	clear
	echo -e "\033[1;5;31m即将开始安装所需依赖...\033[0m"
	sleep 2
	${PM} install unzip zip git -y >/dev/null 2>&1
	echo -e "\033[1;5;31m即将开始安装WEB环境...\033[0m"
	#进入网站目录
	cd /data/wwwroot/default/ 
	#删除首页静态文件
	rm -rf index.html 
	#测试节点ping
	Download_speed_test
	#下载官方源码
	if [[ ! -d "/data/wwwroot/default/config/" ]];then
	git clone https://github.com/marisn2017/ssrpanel_resource.git tmp && mv tmp/.git . && rm -rf tmp && git reset --hard
	fi
	#修改源码权限
	chown -R root:root *
	chmod -R 777 *
	chown -R www:www storage
	#修改网站配置文件
	# wget -N -P /data/wwwroot/default/config/ -c --no-check-certificate "https://blog.67cc.cn/shell/config_new.conf"  >/dev/null 2>&1
	# cd /data/wwwroot/default/config/
    # mv config_new.conf .config.php && chmod 755 .config.php
	echo -e "\033[1;5;31m即将开始下载修改网站配置...\033[0m"
	cp .env.example .env
	sed -i '/DB_PASSWORD/c \DB_PASSWORD='${DB_PASS}'' .env
	#修改nginx php配置
	wget -N -P  /usr/local/nginx/conf/ --no-check-certificate ${Download}/nginx.conf  >/dev/null 2>&1
	wget -N -P /usr/local/php/etc/ --no-check-certificate ${Download}/php.ini  >/dev/null 2>&1
	#重启nginx
	service nginx restart
	echo -e "\033[1;5;31m即将开始导入数据库...\033[0m"
	#导入数据
mysql -hlocalhost -uroot -p${DB_PASS} <<EOF
create database ssrpanel;
use ssrpanel;
source /data/wwwroot/default/sql/db.sql;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${DB_PASS}' WITH GRANT OPTION;
flush privileges;
EOF
	#进入网站目录
	echo -e "\033[1;5;31m即将开始安装网站所需依赖...\033[0m"
	cd /data/wwwroot/default/ 
	#安装依赖
	wget https://getcomposer.org/installer -O composer.phar
	php composer.phar
	php composer.phar install
	php artisan key:generate
	chown -R www:www storage/
	chmod -R 755 storage/
	#设置phpMyAdmin权限
	chmod -R 755 /data/wwwroot/default/phpMyAdmin/
	service nginx restart
    service php-fpm restart
	echo -e "\033[1;5;31m即将开始创建监控...\033[0m"
	#创建监控
	${PM} -y install vixie-cron crontabs
	#rm -rf /var/spool/cron/root
	echo "* * * * * php /data/wwwroot/default/artisan schedule:run >> /dev/null 2>&1" > /var/spool/cron/root
	echo -e "\033[1;5;31m即将开始设置防火墙...\033[0m"
	#设置iptables 
	iptables -I INPUT 4 -p tcp -m state --state NEW -m tcp --dport 3306 -j ACCEPT
	iptables -I INPUT 4 -p tcp -m state --state NEW -m tcp --dport 888 -j ACCEPT
	iptables -I INPUT 4 -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
	iptables -I INPUT 4 -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
	if [[ ${PM}  == "yum" ]];then
	/sbin/service crond restart #重启cron
	service iptables save #保存iptables规则
	elif [[ ${PM}  == "apt-get" ]];then
	/etc/init.d/cron restart #重启cron
	iptables-save > /etc/iptables.up.rules #保存iptables规则
	else
	Echo_Red "Error saving iptables rule and cron."
	fi
}

Install_Sspanel_Web()
{
    clear
	Echo_Green "开始设置网站参数(不会的请直接回车)..."
	read -p "请设置MySQL密码：" Input_Dbpwd
	Input_Dbpwd=${Input_Dbpwd:-"root"}
	read -p "请输入网站站点名称：" Input_Webname
	Input_Webname=${Input_Webname:-"sspanel"}
	read -p "请输入网站域名(eg:http://www.baidu.com)：" Input_Url
	Input_Url=${Input_Url:-"http://${IPAddress}"}
	read -p "请输入节点对接token：" Input_Token
    Input_Token=${Input_Token:-"marisn"}
	clear
    echo -e "\033[1;5;31m即将开始搭建网站环境，此过程较耗时，请耐心等待...\033[0m"
	sleep 5
	if [[ `ps -ef | grep nginx |grep -v grep | wc -l` -ge 1 ]];then
	Echo_Red "提示本机存有nginx环境，跳过环境搭建"
	mkdir /data/wwwroot/default/
	else
	Install_Oneinstack
	fi
	echo -e "\033[1;5;31m即将开始安装所需依赖...\033[0m"
	sleep 2
	${PM} install unzip zip git -y
	echo -e "\033[1;5;31m即将开始安装WEB环境...\033[0m"
	#进入网站目录
	cd /data/wwwroot/default/ 
	#删除首页静态文件
	rm -rf index.html 
	#测试节点ping
	Download_speed_test
	#下载官方源码
	if [[ ! -d "/data/wwwroot/default/config/" ]];then
	wget ${Download}/sspanel.tar.gz  >/dev/null 2>&1
	fi
	Sspanel_resources="/data/wwwroot/default/sspanel.tar.gz"  
	if [[ ! -f ${Sspanel_resources} ]];then
        echo "面板程序 下载失败" > /root/error.log
		exit 0;
    fi
	tar xzf sspanel.tar.gz && rm -rf sspanel.tar.gz
	rm -rf composer.lock && rm -rf composer.phar
	#修改源码权限
	chown -R root:root *
	chmod -R 777 *
	chown -R www:www storage
	echo -e "\033[1;5;31m即将开始下载修改网站配置...\033[0m"
	#修改网站配置文件
	# wget -N -P /data/wwwroot/default/config/ -c --no-check-certificate ${resources}/config_new.conf  >/dev/null 2>&1
	cd /data/wwwroot/default/config/
    # mv config_new.conf .config.php && 
	chmod 755 .config.php
	#########修改配置##########
	sed -i "s#dbname#sspanel#" ${config_adr}
    sed -i "s#dbuser#root#" ${config_adr}
	sed -i "s#dbpassword#${Input_Dbpwd}#" ${config_adr}
	sed -i "s#zhandianmingcheng#${Input_Webname}#" ${config_adr}
	sed -i "s#zhandiandizhi#${Input_Url}#" ${config_adr}
	sed -i "s#jiaoyankey#${Input_Token}#" ${config_adr}
	###########################
	# sed -i '21d' /data/wwwroot/default/config/.config.php #删除
	# sed -i "20a\$System_Config[\'db_password\'] = \'${DB_PASS}\';				//数据库密码" /data/wwwroot/default/config/.config.php #插入
	#修改nginx php配置
	wget -N -P  /usr/local/nginx/conf/ --no-check-certificate ${Download}/nginx.conf  >/dev/null 2>&1
	wget -N -P /usr/local/php/etc/ --no-check-certificate ${Download}/php.ini  >/dev/null 2>&1
	#重启nginx
	service nginx restart
	#设置phpMyAdmin权限
	chmod -R 755 /data/wwwroot/default/phpMyAdmin/
	echo -e "\033[1;5;31m即将开始导入数据库...\033[0m"
	#导入数据
mysql -hlocalhost -uroot -p${Input_Dbpwd} <<EOF
create database sspanel;
use sspanel;
source /data/wwwroot/default/sql/sspanel.sql;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${Input_Dbpwd}' WITH GRANT OPTION;
flush privileges;
EOF
	#进入网站目录
	echo -e "\033[1;5;31m即将开始安装网站所需依赖...\033[0m"
	cd /data/wwwroot/default/ 
	#安装依赖
	wget https://getcomposer.org/installer -O composer.phar
	php composer.phar
	php composer.phar install
	php xcat initQQWry            #下载IP解析库
	php xcat initdownload         #下载ssr程式
	echo -e "\033[1;5;31m即将开始创建监控...\033[0m"
	#创建监控
	${PM} -y install vixie-cron crontabs
	#rm -rf /var/spool/cron/root
	echo "SHELL=/bin/bash
	PATH=/sbin:/bin:/usr/sbin:/usr/bin
	*/20 * * * * /usr/sbin/ntpdate pool.ntp.org > /dev/null 2>&1
	0 0 * * * php -n /data/wwwroot/default/xcat dailyjob
	*/1 * * * * php /data/wwwroot/default/xcat checkjob
	*/1 * * * * php /data/wwwroot/default/xcat syncnode
	30 22 * * * php /data/wwwroot/default/xcat sendDiaryMail" > /var/spool/cron/root
	echo -e "\033[1;5;31m即将开始设置防火墙...\033[0m"
	#设置iptables 
	iptables -I INPUT 4 -p tcp -m state --state NEW -m tcp --dport 3306 -j ACCEPT
	iptables -I INPUT 4 -p tcp -m state --state NEW -m tcp --dport 888 -j ACCEPT
	iptables -I INPUT 4 -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
	iptables -I INPUT 4 -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
	if [[ ${PM}  == "yum" ]];then
	/sbin/service crond restart #重启cron
	service iptables save #保存iptables规则
	elif [[ ${PM}  == "apt-get" ]];then
	/etc/init.d/cron restart #重启cron
	iptables-save > /etc/iptables.up.rules #保存iptables规则
	else
	Echo_Red "Error saving iptables rule and cron."
	fi
	echo -e "\033[1;5;31m即将开始设置快捷工具...\033[0m"
	wget -N -P  /bin/ --no-check-certificate  ${Download}/a.sh  >/dev/null 2>&1
	wget -N -P  /bin/ --no-check-certificate  ${Download}/b.sh  >/dev/null 2>&1
	cd /bin/
	mv a.sh setss && chmod +x setss
	mv b.sh setweb && chmod +x setweb
}

Libtest()
{
	#自动选择下载节点
	Lib_GIT='raw.githubusercontent.com'
	Lib_LIB='download.libsodium.org'
	Lib_GIT_PING=`ping -c 1 -w 1 $Lib_GIT|grep time=|awk '{print $7}'|sed "s/time=//"`
	Lib_LIB_PING=`ping -c 1 -w 1 $Lib_LIB|grep time=|awk '{print $7}'|sed "s/time=//"`
	echo "$Lib_GIT_PING $Lib_GIT" > ping.pl
	echo "$Lib_LIB_PING $Lib_LIB" >> ping.pl
	libAddr=`sort -V ping.pl|sed -n '1p'|awk '{print $2}'`
	if [ "$libAddr" == "$Lib_GIT" ];then
		libAddr='https://raw.githubusercontent.com/marisn2017/ss-panel-v3-mod_Uim/master/libsodium-1.0.13.tar.gz'
	else
		libAddr='https://download.libsodium.org/libsodium/releases/libsodium-1.0.13.tar.gz'
	fi
	rm -f ping.pl		
}
Get_Dist_Version()
{
    if [ -s /usr/bin/python3 ]; then
        Version=`/usr/bin/python3 -c 'import platform; print(platform.linux_distribution()[1][0])'`
    elif [ -s /usr/bin/python2 ]; then
        Version=`/usr/bin/python2 -c 'import platform; print platform.linux_distribution()[1][0]'`
    fi
}
python_test()
{
	#测速决定使用哪个源
	tsinghua='pypi.tuna.tsinghua.edu.cn'
	pypi='mirror-ord.pypi.io'
	doubanio='pypi.doubanio.com'
	pubyun='pypi.pubyun.com'	
	tsinghua_PING=`ping -c 1 -w 1 $tsinghua|grep time=|awk '{print $8}'|sed "s/time=//"`
	pypi_PING=`ping -c 1 -w 1 $pypi|grep time=|awk '{print $8}'|sed "s/time=//"`
	doubanio_PING=`ping -c 1 -w 1 $doubanio|grep time=|awk '{print $8}'|sed "s/time=//"`
	pubyun_PING=`ping -c 1 -w 1 $pubyun|grep time=|awk '{print $8}'|sed "s/time=//"`
	echo "$tsinghua_PING $tsinghua" > ping.pl
	echo "$pypi_PING $pypi" >> ping.pl
	echo "$doubanio_PING $doubanio" >> ping.pl
	echo "$pubyun_PING $pubyun" >> ping.pl
	pyAddr=`sort -V ping.pl|sed -n '1p'|awk '{print $2}'`
	if [ "$pyAddr" == "$tsinghua" ]; then
		pyAddr='https://pypi.tuna.tsinghua.edu.cn/simple'
	elif [ "$pyAddr" == "$pypi" ]; then
		pyAddr='https://mirror-ord.pypi.io/simple'
	elif [ "$pyAddr" == "$doubanio" ]; then
		pyAddr='http://pypi.doubanio.com/simple --trusted-host pypi.doubanio.com'
	elif [ "$pyAddr" == "$pubyun_PING" ]; then
		pyAddr='http://pypi.pubyun.com/simple --trusted-host pypi.pubyun.com'
	fi
	rm -f ping.pl
}
install_centos_ssr()
{
	cd /root
	Get_Dist_Version
	if [ $Version == "7" ]; then
		wget --no-check-certificate https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm 
		rpm -ivh epel-release-latest-7.noarch.rpm	
	else
		wget --no-check-certificate https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
		rpm -ivh epel-release-latest-6.noarch.rpm
	fi
	rm -rf *.rpm
	yum -y update --exclude=kernel*	
	yum -y install git gcc python-setuptools lsof lrzsz python-devel libffi-devel openssl-devel iptables
	yum -y update nss curl libcurl 
	yum -y groupinstall "Development Tools" 
	#第一次yum安装 supervisor pip
	yum -y install supervisor python-pip
	supervisord
	#第二次pip supervisor是否安装成功
	if [ -z "`pip`" ]; then
    curl -O https://bootstrap.pypa.io/get-pip.py
		python get-pip.py 
		rm -rf *.py
	fi
	if [ -z "`ps aux|grep supervisord|grep python`" ]; then
    pip install supervisor
    supervisord
	fi
	#第三次检测pip supervisor是否安装成功
	if [ -z "`pip`" ]; then
		if [ -z "`easy_install`"]; then
    wget http://peak.telecommunity.com/dist/ez_setup.py
		python ez_setup.py
		fi		
		easy_install pip
	fi
	if [ -z "`ps aux|grep supervisord|grep python`" ]; then
    easy_install supervisor
    supervisord
	fi
	pip install --upgrade pip
	Libtest
	wget --no-check-certificate $libAddr
	tar xf libsodium-1.0.13.tar.gz && cd libsodium-1.0.13
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	git clone -b manyuser https://github.com/glzjin/shadowsocks.git "/root/shadowsocks"
	cd /root/shadowsocks
	chkconfig supervisord on
	#第一次安装
	python_test
	pip install -r requirements.txt -i $pyAddr	
	#第二次检测是否安装成功
	if [ -z "`python -c 'import requests;print(requests)'`" ]; then
		pip install -r requirements.txt #用自带的源试试再装一遍
	fi
	#第三次检测是否成功
	if [ -z "`python -c 'import requests;print(requests)'`" ]; then
		mkdir python && cd python
		git clone https://github.com/shazow/urllib3.git && cd urllib3
		python setup.py install && cd ..
		git clone https://github.com/nakagami/CyMySQL.git && cd CyMySQL
		python setup.py install && cd ..
		git clone https://github.com/requests/requests.git && cd requests
		python setup.py install && cd ..
		git clone https://github.com/pyca/pyopenssl.git && cd pyopenssl
		python setup.py install && cd ..
		git clone https://github.com/cedadev/ndg_httpsclient.git && cd ndg_httpsclient
		python setup.py install && cd ..
		git clone https://github.com/etingof/pyasn1.git && cd pyasn1
		python setup.py install && cd ..
		rm -rf python
	fi	
	systemctl stop firewalld.service
	systemctl disable firewalld.service
	cd /root/shadowsocks
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json
}
install_ubuntu_ssr()
{
	apt-get update -y
	apt-get install supervisor lsof -y
	apt-get install build-essential wget -y
	apt-get install iptables git -y
	Libtest
	wget --no-check-certificate $libAddr
	tar xf libsodium-1.0.13.tar.gz && cd libsodium-1.0.13
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	apt-get install python-pip git -y
	pip install cymysql
	cd /root
	git clone -b manyuser https://github.com/glzjin/shadowsocks.git "/root/shadowsocks"
	cd shadowsocks
	pip install -r requirements.txt
	chmod +x *.sh
	# 配置程序
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json
}
install_node_api()
{
	clear
	echo
	#Check Root
	[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
	#check OS version
	check_sys(){
		if [[ -f /etc/redhat-release ]]; then
			release="centos"
		elif cat /etc/issue | grep -q -E -i "debian"; then
			release="debian"
		elif cat /etc/issue | grep -q -E -i "ubuntu"; then
			release="ubuntu"
		elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
			release="centos"
		elif cat /proc/version | grep -q -E -i "debian"; then
			release="debian"
		elif cat /proc/version | grep -q -E -i "ubuntu"; then
			release="ubuntu"
		elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
			release="centos"
	  fi
	}
	install_ssr_for_each(){
		check_sys
		if [[ ${release} = "centos" ]]; then
			install_centos_ssr
		else
			install_ubuntu_ssr
		fi
	}
	clear
	# 取消文件数量限制
	sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf
	echo -e "如果以下手动配置错误，请在${config}手动编辑修改"
	read -p "请输入你的对接域名或IP(例如:http://www.baidu.com 默认为本机对接): " WEBAPI_URL
	read -p "请输入muKey(在你的配置文件中 默认marisn):" WEBAPI_TOKEN
	read -p "请输入测速周期(回车默认为每6小时测速):" SPEEDTEST
	read -p "请输入你的节点编号(回车默认为节点ID 3):  " NODE_ID
	install_ssr_for_each
	cd /root/shadowsocks
	echo -e "modify Config.py...\n"
	WEBAPI_URL=${WEBAPI_URL:-"http://${IPAddress}"}
	sed -i '/WEBAPI_URL/c \WEBAPI_URL = '\'${WEBAPI_URL}\''' ${config}
	#sed -i "s#https://zhaoj.in#${WEBAPI_URL}#" /root/shadowsocks/userapiconfig.py
	WEBAPI_TOKEN=${WEBAPI_TOKEN:-"marisn"}
	sed -i '/WEBAPI_TOKEN/c \WEBAPI_TOKEN = '\'${WEBAPI_TOKEN}\''' ${config}
	#sed -i "s#glzjin#${WEBAPI_TOKEN}#" /root/shadowsocks/userapiconfig.py
	SPEEDTEST=${SPEEDTEST:-"6"}
	sed -i '/SPEED/c \SPEEDTEST = '${SPEEDTEST}'' ${config}
	NODE_ID=${NODE_ID:-"3"}
	sed -i '/NODE_ID/c \NODE_ID = '${NODE_ID}'' ${config}
	# 启用supervisord
	supervisorctl shutdown
	#某些机器没有echo_supervisord_conf 
	wget -N -P  /etc/ --no-check-certificate  https://raw.githubusercontent.com/marisn2017/ss-panel-v3-mod_Uim/master/supervisord.conf
	supervisord
	#iptables
	iptables -F
	iptables -X  
	iptables -I INPUT -p tcp -m tcp --dport 22:65535 -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 22:65535 -j ACCEPT
	iptables-save >/etc/sysconfig/iptables
	echo 'iptables-restore /etc/sysconfig/iptables' >> /etc/rc.local
	echo "/usr/bin/supervisord -c /etc/supervisord.conf" >> /etc/rc.local
	chmod +x /etc/rc.d/rc.local
	Echo_Green "安装完成，节点即将重启使配置生效"
	Echo_Yellow "对接失败的请看https://sybk.tw/archives/summary-of-building-node-problems-frequently-encountered.html"
	reboot now
}
install_node_db()
{
	clear
	echo
	#Check Root
	[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
	#check OS version
	check_sys(){
		if [[ -f /etc/redhat-release ]]; then
			release="centos"
		elif cat /etc/issue | grep -q -E -i "debian"; then
			release="debian"
		elif cat /etc/issue | grep -q -E -i "ubuntu"; then
			release="ubuntu"
		elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
			release="centos"
		elif cat /proc/version | grep -q -E -i "debian"; then
			release="debian"
		elif cat /proc/version | grep -q -E -i "ubuntu"; then
			release="ubuntu"
		elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
			release="centos"
	  fi
	}
	install_ssr_for_each(){
		check_sys
		if [[ ${release} = "centos" ]]; then
			install_centos_ssr
		else
			install_ubuntu_ssr
		fi
	}
	# 取消文件数量限制
	sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf
	echo -e "如果以下手动配置错误，请在${config}手动编辑修改"
	read -p "请输入你的对接数据库IP(例如:127.0.0.1 如果是本机请直接回车): " MYSQL_HOST
	read -p "请输入你的数据库名称(默认sspanel):" MYSQL_DB
	read -p "请输入你的数据库端口(默认3306):" MYSQL_PORT
	read -p "请输入你的数据库用户名(默认root):" MYSQL_USER
	read -p "请输入你的数据库密码(默认root):" MYSQL_PASS
	read -p "请输入你的节点编号(回车默认为节点ID 3):  " NODE_ID
	install_ssr_for_each
	cd /root/shadowsocks
	echo -e "modify Config.py...\n"
	sed -i '/API_INTERFACE/c \API_INTERFACE = '\'glzjinmod\''' ${config}
	MYSQL_HOST=${MYSQL_HOST:-"${IPAddress}"}
	sed -i '/MYSQL_HOST/c \MYSQL_HOST = '\'${MYSQL_HOST}\''' ${config}
	MYSQL_DB=${MYSQL_DB:-"sspanel"}
	sed -i '/MYSQL_DB/c \MYSQL_DB = '\'${MYSQL_DB}\''' ${config}
	MYSQL_USER=${MYSQL_USER:-"root"}
	sed -i '/MYSQL_USER/c \MYSQL_USER = '\'${MYSQL_USER}\''' ${config}
	MYSQL_PASS=${MYSQL_PASS:-"root"}
	sed -i '/MYSQL_PASS/c \MYSQL_PASS = '\'${MYSQL_PASS}\''' ${config}
	MYSQL_PORT=${MYSQL_PORT:-"3306"}
	sed -i '/MYSQL_PORT/c \MYSQL_PORT = '${MYSQL_PORT}'' ${config}
	NODE_ID=${NODE_ID:-"3"}
	sed -i '/NODE_ID/c \NODE_ID = '${NODE_ID}'' ${config}
	# 启用supervisord
	supervisorctl shutdown
	#某些机器没有echo_supervisord_conf 
	wget -N -P  /etc/ --no-check-certificate  https://raw.githubusercontent.com/marisn2017/ss-panel-v3-mod_Uim/master/supervisord.conf	
	supervisord
	#iptables
	iptables -F
	iptables -X  
	iptables -I INPUT -p tcp -m tcp --dport 22:65535 -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 22:65535 -j ACCEPT
	iptables-save >/etc/sysconfig/iptables
	iptables-save >/etc/sysconfig/iptables
	echo 'iptables-restore /etc/sysconfig/iptables' >> /etc/rc.local
	echo "/usr/bin/supervisord -c /etc/supervisord.conf" >> /etc/rc.local
	chmod +x /etc/rc.d/rc.local
	Echo_Green "安装完成，节点即将重启使配置生效"
	Echo_Yellow "对接失败的请看https://sybk.tw/archives/summary-of-building-node-problems-frequently-encountered.html"
	reboot now
}

Install_SS_Node()
{
	Echo_Blue "请选择节点对接模式："
	Echo_Yellow "1.API对接"
	Echo_Yellow "2.数据库对接"
	read -p "选择：" jiedian
	case $jiedian in
	"1")
	install_node_api
	;;
	"2")
	install_node_db
	;;
	*)
	Echo_Red "选择错误"
	exit 0;
	esac
}

Install_SSR_Node()
{
    source /etc/os-release &>/dev/null
    if [[ "${ID}" != "centos" && ${VERSION_ID} -lt 7 ]];then
	Echo_Red "抱歉，本节点对接暂仅支持Centos 7.x系统，其他系统请等待更新..."
	exit 0;
	else
	wget -N --no-check-certificate https://raw.githubusercontent.com/maxzh0916/Shadowsowcks1Click/master/Shadowsowcks1Click.sh;chmod +x Shadowsowcks1Click.sh;./Shadowsowcks1Click.sh
    fi
}

Install_Bbr()
{
    wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh&&chmod +x bbr.sh&&./bbr.sh
}

Update_Panel()
{
    #进入网站目录
	cd /data/wwwroot/default/
	#开始升级
	git fetch --all
	git reset --hard origin/master
	git pull
	php /data/wwwroot/default/xcat update
	if [[ $? -eq 0 ]];then
        echo -e "SsPanel升级成功"
        sleep 1
    else
        echo -e "SsPanel升级失败"
        exit 1
    fi
}

Set_Web_Parameter_For_Bt()
{
	clear
	Echo_Green "请选择搭建面板："
	Echo_Blue "1.sspanel for bt"
	Echo_Blue "2.ssrpanel for bt"
	read -p "选择:" Choose_Web
	Choose_Web=${Choose_Web:-"1"}
	clear
	case $Choose_Web in
	"1")
	Install_Sspanel_Web_to_Bt
	;;
	"2")
	Install_Ssrpanel_Web_to_Bt
	;;
	*)
	Echo_Red "输入错误"
	exit 0;
	esac
}

Set_Web()
{
    clear
	echo -e "Welcome to use the sspanel or ssrpanel with one click. V1.04"
	echo -e "Update_time: $update_time"
	echo -e "Please choose the build mode."
	echo -e "1.sspanel or ssrpanel"
	echo -e "2.sspanel or ssrpanel for bt.cn"
	#echo -e "2.sspanel node"
	#echo -e "3.ssrpanel node"
	#echo -e "4.sspanel for bt.cn"
	#echo -e "5.ssrpanel for bt.cn"
	read -p "Please Enter a character and press Enter to confirm：" choose
	case $choose in
	"1")
	  Set_Web_Parameter
	;;
	"2")
	  Set_Web_Parameter_For_Bt
	;;
	# "3")
	# Echo_Yellow "暂未支持，更新请加群953539179"
	# exit 0;
	  # Install_SSR_Node
	# ;;
	# "4")
	  # Install_Sspanel_Web_to_Bt
	# ;;
	# "5")
	  # Install_Sspanel_Web_to_Bt
	# ;;
	*)
	  Echo_Red "The choose is wrong...Now is exiting..."
	  exit 0;
	esac
}

Check_nginx_php_mysql()
{
    if [[ `ps -ef | grep nginx |grep -v grep | wc -l` -ge 1 ]];then
	    Echo_Green "Nginx环境搭建成功"
	else
		Echo_Red "Nginx环境搭建失败"
		Echo_Red "请重装系统后重试"
		exit 0;
	fi
    if [[ `ps -ef | grep php-fpm |grep -v grep | wc -l` -ge 1 ]];then
	    Echo_Green "PHP环境搭建成功"
	else
		Echo_Red "PHP环境搭建失败"
		Echo_Red "请重装系统后重试"
		exit 0;
	fi
	if [[ `ps -ef | grep mysql |grep -v grep | wc -l` -ge 1 ]];then
	    Echo_Green "Mysql环境搭建成功"
	else
		Echo_Red "Mysql环境搭建失败"
		Echo_Red "请重装系统后重试"
		exit 0;
	fi
}

End_install()
{
    if [[ ${choose} == 1 ]];then
    Check_nginx_php_mysql
	fi
	if [[ ${Choose_Web} == 1 ]];then
	#php /data/wwwroot/default/xcat createAdmin #创建管理用户
	clear
	Echo_Green "本次搭建共用时间： "$((end_seconds-start_seconds))"s"
	echo
	Echo_Yellow "请访问 http://${IPAddress}/ 查看站点"
	echo
	Echo_Yellow "请访问 http://${IPAddress}:888/ 查看数据库"
	echo
	Echo_Yellow "数据库信息："
	Echo_Yellow "端口：3306"
	Echo_Yellow "数据库名：sspanel"
	Echo_Yellow "数据库用户名：root"
	Echo_Yellow "数据库密码：${Input_Dbpwd}"
	echo
	Echo_Yellow "节点对接token: ${Input_Token}"
	Echo_Yellow "默认管理账户：marisn@67cc.cn  密码：marisn"
	Echo_Yellow "快捷管理工具：setss 节点快捷管理 setweb 前端快捷管理"
	Echo_Yellow "若访问站点出现500错误，请访问/data/wwwroot/default/config/编辑隐藏文件.config.php中数据库配置"
	echo
	Echo_Yellow "查看本提示请使用命令 cat /root/info.txt 查看"
	echo "本次搭建共用时间： "$((end_seconds-start_seconds))"s
	请访问 http://${IPAddress}/ 查看站点
	请访问 http://${IPAddress}:888/ 查看数据库
	数据库信息：
	端口：3306
	数据库名：sspanel
	数据库用户名：root
	数据库密码：${Input_Dbpwd}
	节点对接token: ${Input_Token}
	默认管理账户：marisn@67cc.cn  密码：marisn
	若访问站点出现500错误，请访问/data/wwwroot/default/config/编辑隐藏文件.config.php中数据库配置" > /root/info.txt
	elif [[ ${Choose_Web} == 2 ]];then
	clear
	Echo_Green "本次搭建共用时间： "$((end_seconds-start_seconds))"s"
	echo
	Echo_Yellow "请访问 http://${IPAddress}/ 查看站点"
	echo
	Echo_Yellow "请访问 http://${IPAddress}:888/ 查看数据库"
	echo
	Echo_Yellow "数据库信息："
	Echo_Yellow "端口：3306"
	Echo_Yellow "数据库名：ssrpanel"
	Echo_Yellow "数据库用户名：root"
	Echo_Yellow "数据库用户名：${DB_PASS}"
	echo
	Echo_Yellow "若访问站点出现500错误，请访问/data/wwwroot/default/编辑隐藏文件.env中数据库配置"
	echo
	Echo_Yellow "查看本提示请使用命令 cat /root/info.txt 查看"
	echo "本次搭建共用时间： "$((end_seconds-start_seconds))"s
	请访问 http://${IPAddress}/ 查看站点
	请访问 http://${IPAddress}:888/ 查看数据库
	数据库信息：
	端口：3306
	数据库名：ssrpanel
	数据库用户名：root
	数据库用户名：${DB_PASS}
	若访问站点出现500错误，请访问/data/wwwroot/default/编辑隐藏文件.env中数据库配置" > /root/info.txt
	fi
}

Tj_Time_E()
{
	endtime=`date +'%Y-%m-%d %H:%M:%S'`
	start_seconds=$(date --date="$starttime" +%s);
	end_seconds=$(date --date="$endtime" +%s);
}
Tj_Time_S()
{
    starttime=`date +'%Y-%m-%d %H:%M:%S'`
}
Color_Text()
{
  echo -e " \e[0;$2m$1\e[0m"
}

Echo_Red()
{
  echo $(Color_Text "$1" "31")
}

Echo_Green()
{
  echo $(Color_Text "$1" "32")
}

Echo_Yellow()
{
  echo $(Color_Text "$1" "33")
}

Echo_Blue()
{
  echo $(Color_Text "$1" "34")
}
Tj_Time_S
Start_install
Tj_Time_E
End_install