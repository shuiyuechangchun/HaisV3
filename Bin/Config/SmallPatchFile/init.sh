#!/bin/bash
SHELL=$(readlink -f "$0")			#脚本文件
SHELL_PATH=$(dirname $SHELL)		#脚本路径
PROJECT=${1}						#项目路径
if [[ $(uname -m) != "aarch64" ]]; then su="sudo ";fi;
getProp() { grep "$1" "${PROJECT}/../build.prop" | cut -d "=" -f 2; } #读取机型配置

AndroidApi=$(getProp 'ro.build.version.sdk')

if [ "$AndroidApi" != '31' ] ; then
	#${su} rm -rf ${1}/system/system/framework/oat/arm64/services.art
	#${su} rm -rf ${1}/system/system/framework/oat/arm64/services.odex
	#${su} rm -rf ${1}/system/system/framework/oat/arm64/services.vdex
	sed -i 's@#/system/system/framework/services.jar@/system/system/framework/services.jar@g' "${SHELL_PATH}/FileConfig.ini"
else
	sed -i 's@/system/system/framework/services.jar@#/system/system/framework/services.jar@g' "${SHELL_PATH}/FileConfig.ini"
fi


