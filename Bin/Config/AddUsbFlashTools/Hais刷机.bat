@echo off
title Hais丶HaisDevice 线刷 - Q群：927251103
echo.***********************************************
echo.
echo.  1、刷机有风险、刷入前请备份好数据，做好变砖准备。
echo.  2、此包未经测试，刷入出现任何问题自己负责。
echo.  3、刷入请先【解锁】进入Fastboot模式后打开此脚本。
echo.  4、刷入失败请检查USB、驱动、手机是否正常。
echo.
echo.***********************************************
echo.
echo.  Y=保留数据刷入(默认)           N=清空所有数据刷入
echo.
set /p CHOICE=您的选择：
echo.
echo.请将手机进入到bin\fastboot模式
cd %~dp0
bin\fastboot %* getvar product 2>&1 | findstr /r /c:"^product: *HaisDevice" || echo Missmatching image and device
bin\fastboot %* getvar product 2>&1 | findstr /r /c:"^product: *HaisDevice" || exit /B 1
echo.



bin\fastboot %* flash super firmware-update\super.img
if "%CHOICE%" == "N" (
	echo.
	echo.
	echo.
	echo.
	echo.
	echo.
	echo.用户数据正在清除中...
	echo.
	echo.
	echo.
	echo.
	echo.
	echo.
	bin\fastboot %* erase userdata 2>nul
	bin\fastboot %* erase secdata 2>nul
	bin\fastboot %* erase metadata 2>nul
	bin\fastboot %* erase exaid 2>nul
	bin\fastboot -w
	echo.
	echo.
	echo.
	echo.
	echo.
	echo.
)
echo.正在重启到Fastbootd(金色或TWRP)
echo.
echo.重启后手机会进入金色米兔(Fastbootd)或TWRP界面
echo.
echo.如卡住不动下载驱动安装 https://hais.lanzouw.com/b07b4pnbc (密码:dr87)
echo.
echo.等待重启完成驱动检测通过后自动开始继续刷入
echo.
echo.
echo.
echo.
echo.
bin\fastboot %* reboot fastboot
bin\fastboot %* flash odm_a firmware-update\odm.img
bin\fastboot %* flash system_a firmware-update\system.img
bin\fastboot %* flash vendor_a firmware-update\vendor.img
bin\fastboot %* flash product_a firmware-update\product.img
bin\fastboot %* flash system_ext_a firmware-update\system_ext.img
bin\fastboot %* set_active a 
bin\fastboot %* reboot 
echo.***********************************************
echo.
echo.  1、恭喜您刷机完成，系统正在重启。
echo.  2、此包未经测试，刷入出现任何问题自己负责。
echo.  3、如不能开机，可尝试REC恢复或格式化data后开机。
echo.  4、如不能开机，可使用官方MiFlash刷官包恢复。
echo.  5、如觉得不错，希望你进群能支持一下Hais。
echo.
echo.***********************************************
echo.  按任意键关闭此窗口
echo.
pause
exit