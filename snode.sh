#!/bin/bash
config="/data/shadowsocks/userapiconfig.py"
#判断是否已安装ss
check_ss()
{
if [[ ! -d "/root/shadowsocks" ]];then
echo "未安装节点1，请先安装节点1"
exit 0;
else
echo "已安装节点1，即将对接节点2"
sleep 2
fi
}
ss_install()
{
	mkdir /data/shadowsocks
	cd /data
	git clone -b manyuser https://github.com/esdeathlove/shadowsocks.git "/data/shadowsocks"
	cd /data/shadowsocks
	pip install -r requirements.txt
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json
	mv server.py server_2.py
	sed -i "s/server.py/server_2.py/g" /data/shadowsocks/run.sh
}
db(){
    clear
	echo -e "如果以下手动配置错误，请在${config}手动编辑修改"
	read -p "请输入你的对接数据库IP(例如:127.0.0.1 如果是本机请直接回车): " MYSQL_HOST
	read -p "请输入你的数据库名称(默认sspanel):" MYSQL_DB
	read -p "请输入你的数据库端口(默认3306):" MYSQL_PORT
	read -p "请输入你的数据库用户名(默认root):" MYSQL_USER
	read -p "请输入你的数据库密码(默认root):" MYSQL_PASS
	read -p "请输入你的节点编号(回车默认为节点ID 3):  " NODE_ID
	ss_install
	cd /data/shadowsocks
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
}
check_ss
db
#开启SS
cd /data/shadowsocks && chmod +x *.sh
./run.sh #后台运行shadowsocks
if [[ `ps -ef | grep server_2.py |grep -v grep | wc -l` -ge 1 ]];then
	echo -e "${OK} ${GreenBG} 后端已启动 ${Font}"
else
	echo -e "${OK} ${RedBG} 后端未启动 ${Font}"
	echo -e "请检查是否为Centos 7.x系统、检查配置文件是否正确、检查是否代码错误请反馈"
	exit 1
fi