#!/bin/bash
config="/data/wwwroot/default/config/.config.php"

Set_WEB_Parameter()
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
	Set_WEB
	#Echo_Yellow "暂未支持，更新请加群953539179"
	#exit 0;
	;;
	"2")
	vi ${config}
	;;
	*)
	Echo_Red "选择错误"
	exit 0;
	esac
	
}

Set_WEB()
{
    Echo_Green "请输入修改参数："
	read -p "请输入你的数据库密码(默认root):" MYSQL_PASS
	MYSQL_PASS=${MYSQL_PASS:-"root"}
	echo -e "modify Config.py...\n"
	sed -i '21d' ${config} #删除
    sed -i "20a\$System_Config[\'db_password\'] = \'${MYSQL_PASS}\';				//数据库密码" ${config} #插入
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
Set_WEB_Parameter