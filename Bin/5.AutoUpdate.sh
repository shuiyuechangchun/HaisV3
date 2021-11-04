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
AliYun="python3 $SHELL_PATH/Lib/aliyunpan/main.py -t ${Ali_TOKEN}"

updateFilesNum=0
upUpdateFilesAliyunNum=0
updateFiles(){
	updateFilesNum=`expr $updateFilesNum + 1`
	
	$AliYun m "$Ali_ROOT_DIR_NAME"
	$AliYun m "$Ali_ROOT_DIR_NAME/$Ali_ROOT_2_DIR_NAME"
	$AliYun m "$Ali_ROOT_DIR_NAME/$Ali_ROOT_2_DIR_NAME/${DeviceName}"
	$AliYun rm "$Ali_ROOT_DIR_NAME/$Ali_ROOT_2_DIR_NAME/${DeviceName}/${DeviceName}_${RomVersion}/$ROMID"
	$AliYun m "$Ali_ROOT_DIR_NAME/$Ali_ROOT_2_DIR_NAME/${DeviceName}/${DeviceName}_${RomVersion}"
	
	nowUpdateFilesAliyunNum=`grep -o 'aliyunpan' $SHELL_PATH/../$ROMID/log.txt |wc -l`
	$AliYun u "$SHELL_PATH/../$ROMID/" "$Ali_ROOT_DIR_NAME/$Ali_ROOT_2_DIR_NAME/${DeviceName}/${DeviceName}_${RomVersion}"
	
	nowUpdateFilesAliyunNum=`grep -o 'aliyunpan' $SHELL_PATH/../$ROMID/log.txt |wc -l`
	if [ "$nowUpdateFilesAliyunNum" -ne "$upUpdateFilesAliyunNum" ];then 
		upUpdateFilesAliyunNum=$nowUpdateFilesAliyunNum
		if [ "$updateFilesNum" -ge "5" ] ;then
			exit
		else
			echo "上传失败，60秒后进行第${updateFilesNum}次重试！"
			sleep 60
			updateFiles
		fi
	fi
}

#上传到阿里云。。。。。。。。。。。。。
if [ "$(getConfig 'Ali_IS_OPEN')" == "TRUE" ] ; then 
	
	${su} rm -rf $SHELL_PATH/../$ROMID/Backups
	${su} rm -rf $SHELL_PATH/../$ROMID/build.prop
	cp $SHELL_PATH/../Readme.md $SHELL_PATH/../$ROMID/Readme.md
	
	
	echo "文件正在上传到网盘，请耐心等待！"
	
	updateFiles
	
	data="{\"path\":\"${Ali_ROOT_2_DIR_NAME}/${DeviceName}/${DeviceName}_${RomVersion}/${ROMID}\",\"id\":\"${ROMID}\"}"
	echo $data
	
	
	#curl -H 'Authorization:83a81f29cd29f22e2fb0dfe60be92e55' http://p.hais.pw/api/admin/clear_cache
	
	sleep 10
fi
