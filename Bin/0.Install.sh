#!/bin/bash
printf "\033c"
SHELL=$(readlink -f "$0")			#脚本文件
SHELL_PATH=$(dirname $SHELL)		#脚本路径
if [[ $(uname -m) != "aarch64" ]]; then su="sudo ";fi;

echo "
	
		·····································
		
		正在安装HaisDNA所需依赖，请耐心等待！
		
		·····································
		
	"

${su} apt update
${su} apt upgrade -y
${su} apt install -y git cpio bc file aria2 brotli android-sdk-libsparse-utils openjdk-11-jre p7zip-full curl python3 python3-pip zipalign zip unzip img2simg dos2unix jq
#${su} pip3 install aliyunpan
${su} pip3 install -r $SHELL_PATH/Lib/extract_android_ota_payload/requirements.txt
