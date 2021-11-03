#!/data/data/com.termux/files/usr/bin/bash
# 在这里设置需要的linux系统 暂适配apt和pkg为管理器的系统
linux="ubuntu"
linux_ver="focal"
linux_Version="cloud"

clear

case `dpkg --print-architecture` in
	aarch64)
		arch="arm64"
		if [ ! -d ~/storage  ]; then
			termux-setup-storage
		fi
		;;
	*)
		echo "系统架构【$(dpkg --print-architecture)】不支持"
		exit 1
		;;
esac

if [[ -x "$(command -v pkg)" ]]; then
	if [[ ! -x  $(command -v proot) ]] || [[ ! -x  $(command -v wget) ]] || [[ ! -x  $(command -v tar) ]]; then
		echo "修改软件源并更新可用软件包列表和已安装的软件包 ..."
		sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/termux-packages-24 stable main@' $PREFIX/etc/apt/sources.list
		sed -i 's@^\(deb.*games stable\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/game-packages-24 games stable@' $PREFIX/etc/apt/sources.list.d/game.list
		sed -i 's@^\(deb.*science stable\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/science-packages-24 science stable@' $PREFIX/etc/apt/sources.list.d/science.list
		apt-get update
		apt-get install -y git tar proot wget curl unzip
	fi
fi

if [ -d $HOME/$linux  ]; then
	echo "由于$HOME/${linux}文件夹已存在，即将执行[ rm -rf $HOME/$linux ]清理后重新安装！"
	rm -rf $HOME/$linux
fi

if [ -f $HOME/proot_linux/${linux}.tar.xz ] && [ -f $HOME/proot_linux/install_linux.sh ]; then
    echo "${linux}存在，即将自动安装!"
    cp -rf $HOME/proot_linux/${linux}.tar.xz $HOME
else
    echo "${linux}不存在，即将自动下载!"
fi

if [ ! -f $HOME/${linux}.tar.xz ]; then
	if [ ! -f $HOME/images.json ]; then
		wget "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/streams/v1/images.json"
	fi
	#解析json
	rootfs_url=`cat images.json | awk -F '[,"}]' '{for(i=1;i<=NF;i++){print $i}}' | grep "images/${linux}/" | grep "${linux_ver}" | grep "/${arch}/${linux_Version}/" | grep "rootfs.tar.xz" | awk 'END {print}'`
	clear
	echo "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/${rootfs_url}"
	if [ $rootfs_url ]; then
		#删除json
		rm images.json
		echo "正在下载 ${linux} ${linux_ver} ${linux_Version} ..."
		wget -c --user-agent="Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.204 Safari/534.16" -O $HOME/${linux}.tar.xz "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/${rootfs_url}" && echo "下载完成 !"

	else
		#删除json
		rm images.json
		echo "错误: 未找到 ${linux} ${linux_ver} ${linux_Version} !"
		exit 1
	fi
fi
if [ -f $HOME/${linux}.tar.xz ]; then
	echo "开始安装"
	mkdir -p "$HOME/$linux"
	cd "$HOME/$linux"
	echo "正在解压rootfs，请稍候 ..."
	proot --link2symlink tar -xJf $HOME/${linux}.tar.xz --exclude='dev' --exclude='etc/rc.d' --exclude='usr/lib64/pm-utils'
	echo "更新DNS"
	echo "127.0.0.1 localhost" > etc/hosts
	rm -rf etc/resolv.conf
	echo "nameserver 114.114.114.114" > etc/resolv.conf
	echo "nameserver 8.8.4.4" >> etc/resolv.conf
	echo "export  TZ='Asia/Shanghai'" >> root/.bashrc
    echo "更换国内清华源"
    mv etc/apt/sources.list etc/apt/sources.list.bak
    echo -e "deb https://mirrors.tuna.tsinghua.edu.cn/${linux}-ports/ focal main restricted universe multiverse\ndeb https://mirrors.tuna.tsinghua.edu.cn/${linux}-ports/ focal-updates main restricted universe multiverse\ndeb https://mirrors.tuna.tsinghua.edu.cn/${linux}-ports/ focal-backports main restricted universe multiverse\ndeb https://mirrors.tuna.tsinghua.edu.cn/${linux}-ports/ focal-security main restricted universe multiverse" >> etc/apt/sources.list
	cd "$HOME"

	if [ $linux == "${linux}" ]; then
		touch "$HOME/${linux}/root/.hushlogin"
	fi

	bin=$PREFIX/bin/${linux}

echo "写入启动脚本"
cat > $bin <<- EOM

cd $HOME

unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $linux"
command+=" -b /dev"
command+=" -b /proc"
command+=" -b $linux/root:/dev/shm"
command+=" -b /sdcard"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM


	termux-fix-shebang $bin

	chmod +x $bin
	if [ -d "$HOME/.git" ]; then
		rm -rf "$HOME/.git" "$HOME/.gitignore" "LICENSE" "README.md" 2>/dev/null 2>&1
	fi
	echo "${linux} ${linux_ver} ${linux_Version} 安装完成了 !"
fi
    echo -e "if [ -d ${linux} ] && [ $(command -v ${linux}) ]; then\n\t${linux}\nfi" > .bashrc
    

cat <<Ms >$HOME/${linux}/tmp/${linux}.sh
rm -f /tmp/${linux}.sh

echo "即将部署${linux}汉化"

sleep 3

echo "更新${linux}可用软件包列表和已安装的软件包 ..."
apt-get update && apt-get upgrade -y &> /dev/null

echo "汉化${linux}..."
apt-get install -y curl wget git language-pack-zh-han* &> /dev/null

echo "
LANG="zh_CN.UTF-8"
LANGUAGE="zh_CN:zh"
LC_NUMERIC="zh_CN"
LC_TIME="zh_CN"
LC_MONETARY="zh_CN"
LC_PAPER="zh_CN"
LC_NAME="zh_CN"
LC_ADDRESS="zh_CN"
LC_TELEPHONE="zh_CN"
LC_MEASUREMENT="zh_CN"
LC_IDENTIFICATION="zh_CN"
LC_ALL="zh_CN.UTF-8"
" > /etc/default/locale

echo -en "
LANG="zh_CN.UTF-8"
LANGUAGE="zh_CN:zh"
LC_NUMERIC="zh_CN"
LC_TIME="zh_CN"
LC_MONETARY="zh_CN"
LC_PAPER="zh_CN"
LC_NAME="zh_CN"
LC_ADDRESS="zh_CN"
LC_TELEPHONE="zh_CN"
LC_MEASUREMENT="zh_CN"
LC_IDENTIFICATION="zh_CN"
LC_ALL="zh_CN.UTF-8"
" > /etc/environment

mkdir /etc/sysconfig &> /dev/null

touch /etc/sysconfig/i18n &> /dev/null

echo "
LANG="zh_CN.utf8"
SYSFONT="latarcyrheb-sun16"
" > /etc/sysconfig/i18n

echo -en "
source /etc/sysconfig/i18n
" > /etc/bash.bashrc

echo "部署${linux}汉化完成 重启${linux}生效"

Ms

$linux bash /tmp/${linux}.sh

init() {
	mkdir $HOME/proot_linux
	cp -rf $HOME/$linux.tar.xz $HOME/proot_linux/
	cp -rf $HOME/install_linux.sh $HOME/proot_linux/
	rm -rf $HOME/$linux.tar.xz
	rm -rf $HOME/install_linux.sh
}

init &> /dev/null

apt update && apt install git curl -y

bash <(curl -s https://gitee.com/hais/HaisV3/raw/master/Bin/0.NetInstall.sh)

echo -en '\n\n安装完成\n\n工具所在目录为 '$(pwd)'/HaisV3\n\n请通过  cd HaisV3 && ./HaisAuto.sh 启动制作工具\n\n'
    