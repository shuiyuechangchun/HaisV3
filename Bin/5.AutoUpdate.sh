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

USER_ID=$(getConfig 'ROM_ID')
Ali_Alist_PWD=$(getConfig 'Ali_Alist_PWD')
Ali_Alist_URL=$(getConfig 'Ali_Alist_URL')
Ali_TOKEN=$(getConfig 'Ali_TOKEN')
Ali_ROOT_DIR_NAME=$(getConfig 'Ali_ROOT_DIR_NAME')
Ali_ROOT_2_DIR_NAME=$(getConfig 'Ali_ROOT_2_DIR_NAME')
AliYun="python3 $SHELL_PATH/Lib/aliyunpan/main.py -t ${Ali_TOKEN}"
	

cleanCacherNum=0
cleanCacher(){
	cleanCacherNum=`expr $cleanCacherNum + 1`
	Ali_DEVICE_DIR_NAME=$Ali_ROOT_2_DIR_NAME
	if [ "$cleanCacherNum" -eq "3" ] || [ "$cleanCacherNum" -eq "6" ] ;then
		Ali_Device=""
	elif [ "${SETTING_OPTION}" = "5" ]; then
		Ali_DEVICE_DIR_NAME=""
		Ali_Device=""
	else
		Ali_Device="/${DeviceName}"
	fi
	
	Result=`curl -H "Content-Type:application/json" -H "Data_Type:msg" -X POST --data '{"path":"root/'${Ali_DEVICE_DIR_NAME}${Ali_Device}'","password":"'${Ali_Alist_PWD}'","depth":-1}' ${Ali_Alist_URL}`
	code=`echo $Result | jq '.code'`
	if [ "$code" != "200" ] && [ "$cleanCacherNum" -eq "7" ] ;then
		echo "网盘缓存更新失败，60秒后进行第${cleanCacherNum}次重试-->$Result"
		sleep 60
		cleanCacher
	fi
}

updateFilesNum=0
upUpdateFilesAliyunNum=0
updateFiles(){
	updateFilesNum=`expr $updateFilesNum + 1`
	
	$AliYun m "$Ali_ROOT_DIR_NAME"
	$AliYun m "$Ali_ROOT_DIR_NAME/$Ali_ROOT_2_DIR_NAME"
	$AliYun m "$Ali_ROOT_DIR_NAME/$Ali_ROOT_2_DIR_NAME/${DeviceName}"
	$AliYun rm "$Ali_ROOT_DIR_NAME/$Ali_ROOT_2_DIR_NAME/${DeviceName}/${DeviceName}_${RomVersion}/$ROMID"
	$AliYun m "$Ali_ROOT_DIR_NAME/$Ali_ROOT_2_DIR_NAME/${DeviceName}/${DeviceName}_${RomVersion}"
	$AliYun u "$SHELL_PATH/../$ROMID/" "$Ali_ROOT_DIR_NAME/$Ali_ROOT_2_DIR_NAME/${DeviceName}/${DeviceName}_${RomVersion}"
	
	nowUpdateFilesAliyunNum=`grep -o 'aliyunpan' $SHELL_PATH/../$ROMID/log.txt |wc -l`
	if [ "$nowUpdateFilesAliyunNum" -ne "$upUpdateFilesAliyunNum" ];then 
		echo "失败修改前：${upUpdateFilesAliyunNum}---${nowUpdateFilesAliyunNum}"
		upUpdateFilesAliyunNum=$nowUpdateFilesAliyunNum
		echo "失败修改后：${upUpdateFilesAliyunNum}---${nowUpdateFilesAliyunNum}"
		if [ "$updateFilesNum" -ge "10" ] ;then
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
	
	cleanCacher
	
	sleep 10
fi
