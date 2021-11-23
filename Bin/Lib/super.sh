#!/bin/bash
SHELL=$(readlink -f "$0")					#脚本文件
SHELL_PATH=$(dirname $SHELL)				#脚本路径
if [[ $(uname -m) != "aarch64" ]]; then su="sudo ";fi;

PROJECT=${1} 	#项目路径，后面带斜杠 
PARTITION_END=${2}	#挂载点，a、ab
IS_USB=${3}			#是否线刷包，线刷就打空super.img
IS_SPARSE='--sparse'  #动态

SUPER_SIZE=0	#统计总大小
DO_MAKE=""		#执行的命令
DO_MAKE_B=""	#AB分区时候的B
RM_FILES="rm -rf xxxxxxx " #要删除的文件

generateCMD(){
	IMG_NAME=$1
	IMG="$PROJECT/${IMG_NAME}.img"
	if [ -f "${IMG}" ] ;then
		IMG_SIZE=`wc -c < ${IMG}`
		SUPER_SIZE=`expr $SUPER_SIZE + $IMG_SIZE + 4096000`
		DO_MAKE="${DO_MAKE} --partition ${IMG_NAME}${PARTITION_END}:readonly:$IMG_SIZE:main "
		
		if [ "${IS_USB}" = 'FALSE' ];then
			DO_MAKE="${DO_MAKE} --image ${IMG_NAME}${PARTITION_END}=${IMG}"
			RM_FILES="$RM_FILES $IMG"
			IS_SPARSE=''
		fi
		
		
		if [ "${PARTITION_END}" = '_a' ] ;then
			DO_MAKE_B="${DO_MAKE_B} --partition ${IMG_NAME}_b:readonly:0:main "
		fi
	fi
}

if [ "${PARTITION_END}" == '_a' ] ; then
	echo '开始进行(v)ab分区打super'
else
	echo '开始进行only_a分区打super'
fi

generateCMD 'system'
generateCMD 'vendor'
generateCMD 'system_ext'
generateCMD 'product'
generateCMD 'odm'

#SUPER_SIZE=9126805504

DO_MAKE="$SHELL_PATH/lpmake --metadata-size 65536  --super-name super --metadata-slots 2 --device super:$SUPER_SIZE --group main:$SUPER_SIZE ${DO_MAKE} ${DO_MAKE_B}"
$DO_MAKE -F $IS_SPARSE --output $PROJECT/super.img 
#echo "$DO_MAKE -F $IS_SPARSE --output $PROJECT/super.img "
$RM_FILES
