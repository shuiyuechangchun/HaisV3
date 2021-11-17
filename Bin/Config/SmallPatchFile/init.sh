#!/bin/bash
SHELL=$(readlink -f "$0")			#脚本文件
SHELL_PATH=$(dirname $SHELL)		#脚本路径
PROJECT=${1}						#项目路径
if [[ $(uname -m) != "aarch64" ]]; then su="sudo ";fi;


#准备工作
${su} rm -rf ${1}/system/system/framework/oat/arm64/services.art
${su} rm -rf ${1}/system/system/framework/oat/arm64/services.odex
${su} rm -rf ${1}/system/system/framework/oat/arm64/services.vdex

#${su} rm -rf ${1}/system/system/priv-app/MIUISecurityCenter/oat


