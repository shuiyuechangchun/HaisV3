@echo off
title HaisؼHaisDevice ��ˢ - QȺ��927251103
echo.***********************************************
echo.
echo.  1��ˢ���з��ա�ˢ��ǰ�뱸�ݺ����ݣ����ñ�ש׼����
echo.  2���˰�δ�����ԣ�ˢ������κ������Լ�����
echo.  3��ˢ�����ȡ�����������Fastbootģʽ��򿪴˽ű���
echo.  4��ˢ��ʧ������USB���������ֻ��Ƿ�������
echo.
echo.***********************************************
echo.
echo.  Y=��������ˢ��(Ĭ��)           N=�����������ˢ��
echo.
set /p CHOICE=����ѡ��
echo.
echo.�뽫�ֻ����뵽bin\fastbootģʽ
cd %~dp0
bin\fastboot %* getvar product 2>&1 | findstr /r /c:"^product: *HaisDevice" || echo Missmatching image and device
bin\fastboot %* getvar product 2>&1 | findstr /r /c:"^product: *HaisDevice" || exit /B 1
echo.



bin\fastboot %* flash super firmware-update\super.img
echo.����������Fastbootd(��ɫ��TWRP)
echo.�ȴ�������ɺ��������ˢ��
echo.�翨��ɫFastbootd���Ⱥ���������������鰴������
bin\fastboot %* reboot fastboot
bin\fastboot %* flash odm_a firmware-update\odm.img
bin\fastboot %* flash system_a firmware-update\system.img
bin\fastboot %* flash vendor_a firmware-update\vendor.img
bin\fastboot %* flash product_a firmware-update\product.img
bin\fastboot %* flash system_ext_a firmware-update\system_ext.img
bin\fastboot %* set_active a 
if "%CHOICE%" == "N" (
	echo.
	echo.�û��������������...
	echo.
	bin\fastboot %* erase userdata 2>nul
	bin\fastboot %* erase secdata 2>nul
	bin\fastboot %* erase metadata 2>nul
	bin\fastboot %* erase exaid 2>nul
	bin\fastboot -w
)
bin\fastboot %* reboot 
echo.***********************************************
echo.
echo.  1����ϲ��ˢ����ɣ�ϵͳ����������
echo.  2���˰�δ�����ԣ�ˢ������κ������Լ�����
echo.  3���粻�ܿ������ɳ���REC�ָ����ʽ��data�󿪻���
echo.  4���粻�ܿ�������ʹ�ùٷ�MiFlashˢ�ٰ��ָ���
echo.  5������ò���ϣ�����Ⱥ��֧��һ��Hais��
echo.
echo.***********************************************
echo.  ��������رմ˴���
echo.
pause
exit