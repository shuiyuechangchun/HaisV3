
# HaisV3

此工具是Hais为方便修改MIUI系统所制作的一修改工具。
目前是第三个大版本所以称之为V3。当前仅支持Debian、Ubuntu电脑版。
使用中遇到问题可前往Q群 927251103 进行讨论。

#### 兼容和支持

1.  支持MIUI的安卓10、11、12(暂不支持EROFS)
2.  自由选择打卡刷包或线刷包(配置文件中设置)

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

2、下载 http://u.hais.pw/6xluc 解压后打开debian.exe根据提示创建用户设置密码。

3、设置好密码后关闭 debian.exe 并打开 HaisV3.bat 即可开始按照提示做包。

4、不使用的话在命令行输入 `wslconfig /u Debian` 即可卸载


#### 出包：

1.  寻找 ROM直链后 `sudo ./HaisAuto.sh http://xxx.xxx.xxx./xxx.zip` 即可快速出包。
2.  目前仅支持上述方法。

PS：如需手动可运行
1.  `Bin\0.Install.sh` 安装依赖
2.  `Bin\2.UnPack.sh` 解包
3.  `Bin\3.StartHMO.sh` 进行优化
4.  `Bin\4.ZipPack.sh` 打包
	

#### 一键出包定制说明

1.  修改是否制作USB包、作者名字等  	Bin\Config\BuildConfig.ini
2.  修改精简列表可以到 				Bin\Config\DeleteFileConfig.ini
3.  增加或者替换内容到 				Bin\Config\AddReplaceFile
4.  修改文件内容的追加				Bin\Config\MergeFile
5.  刷机脚本描述和修改				Bin\Config\FlashScriptConfig.ini
6.  VAB机型默认默认文件				Bin\Config\InitCopy
7.  线刷工具默认文件				Bin\Config\FlashImageTools
8.  增加或替换的EU文件				Bin\Config\AddEuReplaceFile
9.  自定义插装破解文件				Bin\Config\SmallPatchFile

#### 版本说明

V1版本：https://gitee.com/hais/Hais_Build_Tools

V2版本：https://tx.me/haisROM

V3版本：https://gitee.com/hais/HaisV3


