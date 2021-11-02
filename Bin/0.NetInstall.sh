#!/bin/bash

SHELL=$(readlink -f "$0")			#脚本文件
SHELL_PATH=$(dirname $SHELL)		#脚本路径
PackTmpPath="$SHELL_PATH/Output/Temp/PackTools"		#打包缓存目录
if [[ $(uname -m) != "aarch64" ]]; then su="sudo ";branch="master";else su=" ";branch="arm";fi;

echo "即将开始安装 Git 并获取工具包..."

sleep 3

echo "更新Ubuntu可用软件包列表和已安装的软件包 ..."
#${su} apt-get update && apt-get upgrade -y

echo "安装 Git 中..."
${su} apt-get install -y git

echo "获取 HaisV3 一键快速出包工具中..."
${su} git clone -b ${branch}  https://gitee.com/hais/HaisV3 --depth 1

echo "正在根据 HaisV3 安装运行依赖中..."
${su} chmod 0777 -R ./HaisV3

${su} ./HaisV3/Bin/0.Install.sh


echo "HaisV3 环境部署完成，具体使用请查看 Readme.md"
echo " "
echo "可前往 http://d.hais.pw/rom/miui/list 获取ROM地址后，进行一键快速出包！"
echo "快捷一键出包完整命令如下："
echo "sudo ./HaisAuto.sh https://hugeota.d.miui.com/V12.0.2.0.QDTCNXM/miui_MI8Lite_V12.0.2.0.QDTCNXM_2f3fece0c8_10.0.zip"
echo " "
echo " "

sleep 2

cd  && cd HaisV3 && sudo ./HaisAuto.sh
