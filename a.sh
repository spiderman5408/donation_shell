#!/bin/bash
config="/root/shadowsocks/userapiconfig.py"
IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
Set_SS_Parameter()
{
	Echo_Green "请选择修改模式："
	Echo_Blue "1.参数编辑"
	Echo_Blue "2.手动编辑"
	read -p "选择：" choose
	case $choose in
	"1")
	if [[ ! -f ${config} ]];then
	Echo_Red "配置文件路径错误"
	exit 0;
	fi
	Set_SS
	;;
	"2")
	vi ${config}
	;;
	*)
	Echo_Red "选择错误"
	exit 0;
	esac
}

Set_SS()
{
    Echo_Green "请选择对接模式："
	Echo_Blue "1.API对接"
	Echo_Blue "2.数据库对接" 
	read -p "选择：" choose_ss
	case $choose_ss in
	"1")
	Set_SS_API
	;;
	"2")
	Set_SS_DB
	;;
	*)
	Echo_Red "选择错误"
	exit 0;
	esac
}

Set_SS_DB()
{
	Echo_Green "请输入修改参数："
	read -p "节点ID：" NODE_ID
	read -p "测速周期：" SPEEDTEST
	read -p "请输入你的对接数据库IP(例如:127.0.0.1): " MYSQL_HOST
	read -p "请输入你的数据库名称(默认sspanel):" MYSQL_DB
	read -p "请输入你的数据库端口(默认3306):" MYSQL_PORT
	read -p "请输入你的数据库用户名(默认root):" MYSQL_USER
	read -p "请输入你的数据库密码(默认root):" MYSQL_PASS
	read -p "请输入你的节点编号(回车默认为节点ID 3):  " NODE_ID
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
	SPEEDTEST=${SPEEDTEST:-"6"}
	sed -i '/SPEED/c \SPEEDTEST = '${SPEEDTEST}'' ${config}
}

Set_SS_API()
{
	Echo_Green "请输入修改参数："
	read -p "节点ID(默认3)：" NODE_ID
	read -p "测速周期(默认6)：" SPEEDTEST
	read -p "对接域名或IP[加上http://]：" IPAddress
	read -p "对接秘钥(默认marisn)：" WEBAPI_TOKEN
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
Set_SS_Parameter