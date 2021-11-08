#!/bin/bash
SHELL=$(readlink -f "$0")					#脚本文件
SHELL_PATH=$(dirname $SHELL)				#脚本路径
getConfig() { grep "$1" "${SHELL_PATH}/Config/BuildConfig.ini" | cut -d "=" -f 2; }  #读取配置文件
if [[ $(uname -m) != "aarch64" ]]; then su="sudo ";fi;
ROMID=$(getConfig "ROM_ID")
getProp() { grep "$1" "${SHELL_PATH}/../$ROMID/build.prop" | cut -d "=" -f 2; } #读取机型配置

Device=$(getProp "ro.product.vendor.device")
RomVersion=$(getProp "ro.vendor.build.version.incremental")
DeviceName=${Device^}

Ali_TOKEN=$(getConfig 'Ali_TOKEN')
Ali_ROOT_DIR_NAME=$(getConfig 'Ali_ROOT_DIR_NAME')
Ali_ROOT_2_DIR_NAME=$(getConfig 'Ali_ROOT_2_DIR_NAME')
AliYun="${su} ./Lib/aliyunpan "

$AliYun login -RefreshToken=${Ali_TOKEN}


updateFiles(){
	
	$AliYun rm "$Ali_ROOT_DIR_NAME/$Ali_ROOT_2_DIR_NAME/${DeviceName}/${DeviceName}_${RomVersion}/$ROMID"
	$AliYun mkdir "$Ali_ROOT_DIR_NAME/$Ali_ROOT_2_DIR_NAME/${DeviceName}/${DeviceName}_${RomVersion}"
	$AliYun upload "$SHELL_PATH/../$ROMID/" "$Ali_ROOT_DIR_NAME/$Ali_ROOT_2_DIR_NAME/${DeviceName}/${DeviceName}_${RomVersion}"
	
}


#上传到阿里云。。。。。。。。。。。。。
if [ "$(getConfig 'Ali_IS_OPEN')" == "TRUE" ] ; then 
	
	${su} rm -rf $SHELL_PATH/../$ROMID/Backups
	${su} rm -rf $SHELL_PATH/../$ROMID/build.prop
	cp $SHELL_PATH/../Readme.md $SHELL_PATH/../$ROMID/Readme.md
	
	
	echo "文件正在上传到网盘，请耐心等待！"
	
	updateFiles

	POST_ROM_PATH="{\"path\":\"${Ali_ROOT_2_DIR_NAME}/${DeviceName}/${DeviceName}_${RomVersion}/${ROMID}\",\"id\":\"${ROMID}\"}"
	echo $POST_ROM_PATH
	
	
	sleep 10
fi
