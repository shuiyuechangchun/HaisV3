
# HaisV3

此工具是Hais为方便修改MIUI系统所制作的一修改工具。
目前是第三个大版本所以称之为V3。当前仅支持Debian、Ubuntu电脑版。
使用中遇到问题可前往Q群 [927251103](https://jq.qq.com/?_wv=1027&k=7SaV9nzM) 进行讨论。

PS：此工具为Hais群友福利工具,如非群友可输入Test进行试用.(偷偷说一句.群内有无限试用方法)

#### 兼容和支持

1.  支持MIUI的安卓10、11、12(暂不支持EROFS)
2.  自由选择打卡刷包或线刷包(配置文件中设置)
3.  兼容制作 [Eu](https://sourceforge.net/projects/xiaomi-eu-multilang-miui-roms/files/xiaomi.eu/MIUI-WEEKLY-RELEASES/) 并带半本地化(需要前往交流群下载依赖)

#### HaisV3特点

1.  便捷配置、一键出包
2.  纯净仅集成破解卡米
3.  禁用DM、AVB等。


#### 安装教程


###### 在电脑的Ubuntu、Debian中可直接输入命令使用。

`bash <(curl -s https://gitee.com/hais/HaisV3/raw/master/Bin/0.NetInstall.sh)`

###### 在支持 WSL 的 Windows10、11上使用。
1、使用Powershell管理员身份运行下面命令启用WSL后重启电脑。

`Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux`

2、下载 http://u.hais.pw/6xluc 打开 HaisV3.exe 即可开始按照提示做包。

Ps:不使用的话在命令行输入 `wslconfig /u Debian` 卸载依赖，然后删除文件夹即可


#### 出包：

###### 常规出包

根据图形界面操作进行出包.--也就是手动执行命令 `sudo ./HaisAuto.sh` 或打开HaisV3.exe 

###### 方便批量做包的进阶做包

做好设置后 `sudo ./HaisAuto.sh http://xxx.xxx.xxx./xxx.zip` 即可快速出包。


#### 工具内文件说明

1.    工具启动脚本					HaisAuto.sh

2.    使用说明						Readme.md

3.    存放核心						Bin\

3.1 此处存放的全是工具依赖			Bin\Lib

3.2   配置文件,一键出包的各种设置	Bin\Config

3.2.1 设置作者、压缩、包类型等		Bin\Config\BuildConfig.ini

3.2.2 精简列表(群共享有参考) 		Bin\Config\DeleteFileConfig.ini

3.2.3 刷机脚本描述和修改			Bin\Config\FlashScriptConfig.ini

3.2.4 制作EU时需要额外添加的文件	Bin\Config\AddEuReplaceFile

3.2.5 制作ROM需要添加的文件			Bin\Config\AddReplaceFile

3.2.6 制作线刷时添加的				Bin\Config\FlashImageTools

3.2.7 VAB机型制作卡刷需要添加		Bin\Config\InitCopy

3.2.8 往某文件中追加的文字			Bin\Config\MergeFile

3.2.9 插桩修改的配置项				Bin\Config\SmallPatchFile



#### 版本说明

V1版本：https://gitee.com/hais/Hais_Build_Tools

V2版本：https://tx.me/haisROM

V3版本：https://gitee.com/hais/HaisV3


