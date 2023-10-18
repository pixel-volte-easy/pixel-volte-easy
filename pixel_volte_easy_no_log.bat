@echo off 
REM @chcp 949
@chcp 65001
REM Set Language English
REM chcp 437
REM Set Language Korean
REM chcp 949
setlocal enableextensions enabledelayedexpansion
set VER=2.2
title Google Pixel VoLTE Easy v!VER!

pushd %~dp0

set NLM=^


set NL=^^^%NLM%%NLM%^%NLM%%NLM%

echo !PATH! | findstr /iv "system32;" >nul 2>&1
if !errorlevel! == 0 (
	PATH=!PATH!;"!SYSTEMROOT!\System32"
)

bcdedit >nul
if !errorlevel! == 1 (
	echo.
	echo 'pixel_volte_easy.bat' 파일을 마우스 오른쪽 버튼으로 클릭 후, 
	echo '관리자 권한'으로 다시 실행해주세요. 
	echo.
	pause
	exit
)

REM Auto update check
for /f "tokens=2" %%a in ('tools\curl.exe -Lsi "https://github.com/pixel-volte-easy/pixel-volte-easy/releases/latest" ^| findstr /i "^location"') do set LATEST_VER_CHECK=%%a
@powershell.exe -Command "$LATEST_VER_CHECK='!LATEST_VER_CHECK!'; $LATEST_VER_CHECK -match '.*\/tag\/v(.*)'; $Matches.1 | Set-Content -Encoding String tmp_update_check;"
set /p LATEST_VER=< tmp_update_check
del /s /q tmp_update_check >nul 2>&1

if "!LATEST_VER!" == "" (
	goto VERSION_CHECK_PASS
) else if "!VER!" LSS "!LATEST_VER!" (
	REM Auto update
	echo ============================================================ 
	echo.
	echo Pixel VoLTE Easy 를 최신버전^(v!LATEST_VER!^)으로 업데이트 할 수 있습니다. 
	echo "Enter"^(또는 "Y"^) 를 입력하시면 Pixel VoLTE Easy 를 업데이트 하며 
	echo "C" 를 입력하시면 업데이트를 생략한 후 진행할 수 있고, 
	echo "Q" 를 입력하시면 프로그램을 종료합니다. 
	echo.
	echo ============================================================ 
	echo.
	set /p PIXEL_VOLTE_EASY_UPDATE_CHK=업데이트 하시겠습니까? [Y/C/Q]%NL%%NL%: 
	if /i "!PIXEL_VOLTE_EASY_UPDATE_CHK!" == "y" (
		goto DO_PIXEL_VOLTE_EASY_UPDATE
	) else if "!PIXEL_VOLTE_EASY_UPDATE_CHK!" == "" (
		:DO_PIXEL_VOLTE_EASY_UPDATE
		tools\curl.exe -Ls "https://github.com/pixel-volte-easy/pixel-volte-easy/releases/download/v!LATEST_VER!/pixel_volte_easy_v!LATEST_VER!.zip" -o "pixel_volte_easy_v!LATEST_VER!.zip"
		echo.
		echo 업데이트 다운로드 완료됨.
		echo.
		tools\7za.exe x "pixel_volte_easy_v!LATEST_VER!.zip" -aoa
		del /s /q pixel_volte_easy_v!LATEST_VER!.zip >nul 2>&1
		echo.
		echo 업데이트 완료됨.
		echo 업데이트의 적용을 위해 볼티지를 다시 실행해주시기 바랍니다.
		echo.
		pause
		exit
	) else if /i "!PIXEL_VOLTE_EASY_UPDATE_CHK!" == "c" (
		goto VERSION_CHECK_PASS
	) else if /i "!PIXEL_VOLTE_EASY_UPDATE_CHK!" == "q" (
		goto QUIT
	) else (
		echo 잘못된 입력입니다. KT 나 SKT 또는 LGU 를 입력해주세요. 
		goto CARRIER_SINGLE_CHECK
	)
) else (
	goto VERSION_CHECK_PASS
)

:VERSION_CHECK_PASS
platform-tools\adb.exe kill-server >nul 2>&1
cls
echo.
echo.
echo ============================================================ 
echo.
echo * 주의 * 
echo.
echo 패치 진행 과정 중에 기기의 전원버튼을 눌러야 하는 등 
echo.
echo 조작이 필요한 경우는 이 화면으로 미리 안내를 해드립니다. 
echo.
echo ^( 그러니 진행 중의 안내문구는 꼭 정독 부탁드립니다 ^) 
echo.
echo 패치 진행 중 부팅할 때 휴대폰 화면에 나타나는 문구에 반응하여 
echo.
echo ^          ^^! 전원버튼을 누르지 마십시오 ^^! 
echo.
echo ============================================================ 
echo.
echo.
pause
cls

REM Get Windows Version
for /f "tokens=*" %%a in ('wmic os get caption ^| findstr /v ^"Caption^" ^| findstr /v "^$"') do set USER_OS_VER=%%a

echo 사용자의 OS : !USER_OS_VER! 

if not exist "TEMP" (
	mkdir "TEMP"
) else (
	del /s /q "TEMP\*" >nul
)

REM Set Variables
set UPDATE_TARGET_CARRIER=ALL
set LATEST_MAGISK_VER=26.3
set MAGISK_APK=Magisk.v!LATEST_MAGISK_VER!.apk
set IS_CUSTOM_ROM=
set IS_OTA_ZIP=
set USER_DEVICE_SERIAL=
set CARRIER_SIM1=
set CARRIER_SIM2=
set DSDS_ON=
set DATE_TODAY=
set UNROOT_CHK=
set KEEP_ROOT=
set MAGISK_CHK=
set MAGISK_VER=
set ADB_SHELL_ROOTED=
set FIRST_GEN_MODEL=
set EXINOS_MODEL=
set 5G_SUPPORT=

REM no more needs vbmeta.img above magisk v25
REM set NEED_VBMETA=

echo.
echo # ADB 연결 상태 및 드라이버 설치 유무 확인 # 
echo.
echo [ 설치 여부를 묻는 창이 나타나면 설치를 진행해주세요. 
echo 필수 드라이버 설치 과정입니다. ] 
echo.

pnputil >nul
if !errorlevel! == 9009 (
	echo.
	echo 'pnputil' 이 확인되지 않습니다. 
	echo 시스템 환경변수가 잘못되지는 않았는지, 
	echo 커스텀 윈도우 등 특수한 환경이 아닌지 확인해주세요. 
	echo.
	echo 드라이버 설치 기능을 위해 pnputil 이 
	echo 시스템 환경변수에 등록되어 있어야 합니다. 
	echo.
	pause
	exit
)

REM Android Driver Install
pnputil /add-driver "drivers\android_winusb.inf" /install >nul

REM Qualcomm Driver Install
pnputil /add-driver "drivers\qcser.inf_amd64_011cf7b068aef58d\qcser.inf" /install >nul

REM Dotnet Runtime Install
dotnet >nul 2>&1
if !errorlevel! == 9009 (
	goto DOTNET_5_0_INSTALL
) else (
	dotnet --info | findstr "5\.0" >nul 2>&1
	if !errorlevel! == 1 (
		:DOTNET_5_0_INSTALL
		dir "C:\Program Files\dotnet\shared\Microsoft.NETCore.App" | findstr "5\.0" >nul 2>&1
		if !errorlevel! == 1 (
				echo 닷넷 런타임 설치가 필요합니다. 
				echo.
				tools\curl.exe -s "https://dotnet.microsoft.com/download/dotnet/5.0" > TEMP\tmp_curl_result
				findstr "runtime" TEMP\tmp_curl_result > TEMP\tmp_find_result
				findstr /v "desktop" TEMP\tmp_find_result > TEMP\tmp_find_result2
				findstr /v "aspnet" TEMP\tmp_find_result2 > TEMP\tmp_find_result3
				findstr "windows-x64-installer" TEMP\tmp_find_result3 > TEMP\tmp_find_result4
				findstr "download" TEMP\tmp_find_result4 > TEMP\tmp_dotnet5_url
				set /p DOTNET5_URL=< TEMP\tmp_dotnet5_url

				@powershell.exe -Command "$DOTNET5_URL='!DOTNET5_URL!'; $DOTNET5_URL -match '.*href=(.*installer).*'; $Matches.1 | Set-Content -Encoding String TEMP\tmp_dotnet5_url;"
				set /p DOTNET5_URL=< TEMP\tmp_dotnet5_url
				tools\curl.exe -s "https://dotnet.microsoft.com!DOTNET5_URL!" > TEMP\tmp_curl_result
				findstr /i "exe" TEMP\tmp_curl_result > TEMP\tmp_find_result
				findstr /i "directlink" TEMP\tmp_find_result > TEMP\tmp_find_result2
				set /p DOTNET5_DOWNLOAD_URL=< TEMP\tmp_find_result2
				@powershell.exe -Command "$DOTNET5_DOWNLOAD_URL='!DOTNET5_DOWNLOAD_URL!'; $DOTNET5_DOWNLOAD_URL -match '.*href=(.*/(.*\.exe))\ aria\-label=.*'; $Matches.1 | Set-Content -Encoding String TEMP\tmp_dotnet5_download_url; $Matches.2 | Set-Content -Encoding String TEMP\tmp_dotnet5_download_fname;"
				set /p DOTNET5_DOWNLOAD_URL=< TEMP\tmp_dotnet5_download_url
				set /p DOTNET5_FILE_NAME=< TEMP\tmp_dotnet5_download_fname
				tools\curl.exe "!DOTNET5_DOWNLOAD_URL!" -o "TEMP\!DOTNET5_FILE_NAME!"
				del /s /q TEMP\tmp_* >nul 2>&1

				echo.
				echo 닷넷 런타임 5.0 설치 파일을 실행합니다. 
				echo 설치 창이 나타나면 "설치(I)"를 눌러 설치를 진행해주세요. 
				echo.

				TEMP\!DOTNET5_FILE_NAME!

				echo.
				echo 닷넷 런타임 설치가 완료되었습니다. 
				echo 볼티지를 재시작 해야 적용되므로 프로그램을 종료합니다. 
				echo 다시 실행해주시기 바랍니다. 
				echo.
				pause
				exit
		)
	)
)

echo.
echo ============================================================ 
echo.
echo 픽셀 기기와 컴퓨터를 USB 케이블로 연결해주세요. 
echo 이미 연결하신 상태에서는 그냥 두시면 됩니다. 
echo 작업 진행에 영향을 줄 가능성이 있는 기타 USB장치는 
echo 잠시 제거하시고 사용하시는 것을 권장드립니다. 
echo.
echo 픽셀 기기에서 반드시 '개발자 옵션'에 있는 USB 디버깅을 '사용' 상태로 켜주셔야 합니다. 
echo 아울러 아직 부트로더 언락을 하지 않은^(=한 번도 루팅을 하지 않은^) 사용자께서는 
echo '개발자 옵션'의 'OEM 잠금 해제'도 반드시 켜주셔야 과정이 정상 진행됩니다. 
echo ^(버라이즌 기기 등 OEM 잠금 해제를 하지 못하는 경우에는 이 패치를 사용하실 수 없습니다^) 
echo.
echo 위 사항을 준비하셨다면 아무 키를 입력하여 다음 과정을 진행해주세요. 
echo.
echo.
pause
cls

:ADB_CONNECT_CHECK
echo.
echo ============================================================ 
echo.
echo [ 픽셀 기기에서 'USB 디버깅을 허용하시겠습니까?' 확인창이 나오면 
echo '이 컴퓨터에서 항상 허용'을 체크하신 후 '허용'을 눌러주세요. ] 
echo.
echo 혹시 드라이버 설치가 완료되었고 기기가 정상 연결되었는데 
echo 10초 이상 응답이 없다면 픽셀 기기의 USB케이블을 제거했다가 다시 삽입해주세요. 
echo.

platform-tools\adb.exe wait-for-device >nul 2>&1

echo ============================================================ 
echo.
set DEVICE_COUNTER=0
for /f "tokens=1,4" %%a in ('platform-tools\adb.exe devices -l ^| findstr /v "List of devices attached"') do set /a DEVICE_COUNTER+=1& set DEVICE_SERIAL[!DEVICE_COUNTER!]=%%a& set DEVICE_NAME=%%b& set DEVICE_NAME=!DEVICE_NAME:model:=!& set DEVICE_NAME=!DEVICE_NAME:model^:==UNKNOWN_DEVICE!&set DEVICE_NAME[!DEVICE_COUNTER!]=!DEVICE_NAME!& echo !DEVICE_COUNTER!. !DEVICE_NAME! 
echo.

if "!DEVICE_COUNTER!" == "1" (
	echo 사용자의 기기 !DEVICE_NAME! 
	set USER_DEVICE_SERIAL=!DEVICE_SERIAL[1]!
	echo.
	pause
	goto DEVICE_SELECTED
) else if "!DEVICE_COUNTER!" == "0" (
	echo ADB 연결 확인 되지 않음. 
	echo USB 디버깅 허용 또는 USB 케이블 연결 상태를 확인해주시기 바랍니다. 
	echo 연결 확인 재시도 중 ... 
	ping -n 5 127.0.0.1 >nul
	goto ADB_CONNECT_CHECK
) else (
	echo.
	echo 안드로이드 기기가 하나 이상 연결된 것으로 감지됩니다. 
	set /p _USER_DEVICE_SELECT=위 목록 중에서 사용자의 픽셀 기기의 번호를 입력해주세요. ^( 1 ~ !DEVICE_COUNTER! ^)%NL%%NL%: 

	for /l %%a in (1,1,!DEVICE_COUNTER!) do (
		if "!_USER_DEVICE_SELECT!" == "%%a" set USER_DEVICE_SERIAL=!DEVICE_SERIAL[%%a]!& echo 사용자의 기기 !DEVICE_NAME[%%a]! [!USER_DEVICE_SERIAL!] & goto DEVICE_SELECTED 
	)
	goto ADB_CONNECT_CHECK
)

:DEVICE_SELECTED
echo.
echo ============================================================ 
echo.
set ADB_STATUS=
for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! get-state') do set ADB_STATUS=%%a
if "!ADB_STATUS!" == "device" (
	echo ADB USB 연결 상태 확인. 

	REM remove temp files
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "rm -rf /data/local/tmp/volte*temp*"

	REM create working directory and magisk tools
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "mkdir /data/local/tmp/volte_easy_temp"
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! push tools\tools.tar.gz /data/local/tmp/volte_easy_temp/
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! push tools\!MAGISK_APK! /data/local/tmp/volte_easy_temp/
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "cd /data/local/tmp/volte_easy_temp; tar zxf tools.tar.gz"
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "cd /data/local/tmp/volte_easy_temp; unzip !MAGISK_APK! -x AndroidManifest.xml classes.dex META-INF/* org/* res/* resources.arsc -d magisk_tools/"
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "cd /data/local/tmp/volte_easy_temp; mv magisk_tools/assets/* ./magisk_tools/"
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "cd /data/local/tmp/volte_easy_temp/magisk_tools; chmod 755 *.sh"
	echo.

	REM Select menu
	:MENU_CHOICE
	set CHOSEN_MENU=
	cls
	echo ============================================================ 
	echo  ______  _______  ___ ___  _______  _____    
	echo ^|   __ :^|_     _^|^|   ^|   ^|^|    ___^|^|     ^|_  
	echo ^|    __/ _^|   ^|_ ^|-     -^|^|    ___^|^|       ^| 
	echo ^|___^|   ^|_______^|^|___^|___^|^|_______^|^|_______^| 

	echo		  ___ ___  _______  _____    _______  _______ 
	echo		 ^|   ^|   ^|^|       ^|^|     ^|_ ^|_     _^|^|    ___^|
	echo		 ^|   ^|   ^|^|   -   ^|^|       ^|  ^|   ^|  ^|    ___^|
	echo		  :_____/ ^|_______^|^|_______^|  ^|___^|  ^|_______^|

	echo				  _______  _______  _______  ___ ___ 
	echo				 ^|    ___^|^|   _   ^|^|     __^|^|   ^|   ^|
	echo				 ^|    ___^|^|       ^|^|__     ^| :     / 
	echo				 ^|_______^|^|___^|___^|^|_______^|  ^|___^| 
	echo.
	echo ^                                                ^( Ver. !VER! ^) 
	echo.
	echo ^ 1. VoLTE 패치 ^(번호없이 Enter 입력시에도 VoLTE 패치 진행^) 
	echo ^ 2. EFS 백업 
	echo ^ 3. EFS 복구 
	echo ^ 4. 안드로이드 업데이트 
	echo ^ 5. 부트로더 락/언락 
	echo ^ 6. 루팅/언루팅 
	echo ^ H. 도움말 
	echo ^ Q. 프로그램 종료 
	echo.
	echo ============================================================ 
	echo.
	set /p CHOSEN_MENU=원하시는 기능의 번호를 입력해주세요. [1~6/H/Q]%NL%%NL%: 
	if "!CHOSEN_MENU!" == "1" (
		echo # VoLTE 패치 # 진행합니다. 
	) else if "!CHOSEN_MENU!" == "" (
		set CHOSEN_MENU=1
		echo # VoLTE 패치 # 진행합니다. 
	) else if "!CHOSEN_MENU!" == "2" (
		echo # EFS 백업 # 진행합니다. 
	) else if "!CHOSEN_MENU!" == "3" (
		echo # EFS 복구 # 진행합니다. 
	) else if "!CHOSEN_MENU!" == "4" (
		echo # 안드로이드 업데이트 # 진행합니다. 
	) else if "!CHOSEN_MENU!" == "5" (
		echo # 부트로더 락/언락 # 진행합니다. 
	) else if "!CHOSEN_MENU!" == "6" (
		echo # 루팅/언루팅 # 진행합니다. 
	) else if /i "!CHOSEN_MENU!" == "h" (
		echo ============================================================ 
		echo.
		echo # 도움말 # 
		echo.
		echo - 'VoLTE 패치' 기능은 한국 통신 3사망으로 VoLTE 전화 기능을 사용하실 수 있도록 
		echo 패치를 수행합니다. 작업을 위해 부트로더가 언락되어 있지 않은 경우 
		echo 부트로더 언락을 먼저 수행하라고 안내를 드리며, 
		echo 루팅이 되어 있지 않으면 루팅, 언루팅 과정까지 자동화 하여 패치 과정으로 수행합니다. 
		echo 이 프로그램^(=볼티지^)의 핵심 기능입니다. 
		echo.
		echo - 'EFS 백업' 기능은 VoLTE 패치 내용을 제거하고 원상태로 되돌릴 수 있도록 원본을 따로 저장합니다. 
		echo 원본 저장에 의의가 있으므로 가급적 한 번도 VoLTE 패치를 적용하신 적이 없으신 경우에 사용을 권장합니다. 
		echo.
		echo - 'EFS 복구' 기능은 백업해두신 EFS가 있다면 해당 EFS로 VoLTE 패치를 되돌리고 
		echo 백업해두신 내용이 없다면 볼티지 자체적으로 VoLTE 패치 내용을 제거합니다. 
		echo.
		echo - '부트로더 락/언락' 기능은 VoLTE 패치나 루팅 등 다른 과정없이 부트로더의 잠금 상태를 확인하고 
		echo 부트로더 잠금 또는 잠금해제를 수행합니다. 
		echo 부트로더 언락 기능을 따로 선택하지 않아도 언락이 되어 있지 않으면 
		echo 볼티지를 통한 모든 작업이 불가능하므로, 부트로더 언락을 선행하도록 안내합니다. 
		echo.
		echo - '루팅/언루팅' 기능은 VoLTE 패치 등 다른 과정없이 기기의 루팅 상태를 확인하고 
		echo 루팅 또는 언루팅을 수행합니다. 
		echo.
		pause
		goto MENU_CHOICE
	) else if /i "!CHOSEN_MENU!" == "q" (
		goto QUIT
	) else (
		echo 잘못된 입력입니다. 
		goto MENU_CHOICE
	)

	echo.
	goto ADB_DEVICE_CHECK

) else (
	echo ADB 연결 확인 되지 않음. 
	echo USB 디버깅 허용 또는 USB 케이블 연결 상태를 확인해주시기 바랍니다. 
	echo 연결 확인 재시도 중 ... 
	ping -n 5 127.0.0.1 >nul
	goto ADB_CONNECT_CHECK
)

:ADB_DEVICE_CHECK
platform-tools\adb.exe -s !USER_DEVICE_SERIAL! devices | findstr ".device$"
if !errorlevel! == 1 (
	echo 기기의 USB 디버깅 연결이 확인되지 않습니다. 
	echo USB 디버깅 허용 또는 USB 케이블 연결 상태를 확인해주시기 바랍니다. 
	echo 연결 확인 재시도 중 ... 
	ping -n 5 127.0.0.1 >nul
	goto ADB_DEVICE_CHECK
) else (
	echo.
	echo 준비 중 ... 
	echo.

	REM Get date for set variable
	for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getdate') do set DATE_TODAY=%%a

	REM Get Android Version
	set ANDROID_VERSION=
	for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getver') do set ANDROID_VERSION=%%a

	REM Get Provisioning VoLTE if Andoriod 12 and above case
	if "!ANDROID_VERSION!" GEQ "12" (
		for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getprovision') do set PROVISIONED=%%a
	)

	REM Check Pixel Experience ROM case
	set CUSTOM_ROM_VERSION=
	for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getcustomversion') do set CUSTOM_ROM_VERSION=%%a
	if not "!CUSTOM_ROM_VERSION!" == "" (
		set IS_CUSTOM_ROM=TRUE
		set 5G_SUPPORT=TRUE
	)

	REM Get Model name
	for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getmodel') do set MODEL=%%a

	if "!MODEL!" == "sailfish" (
		set FIRST_GEN_MODEL=Pixel 1
	) else if "!MODEL!" == "marlin" (
		set FIRST_GEN_MODEL=Pixel 1 XL
	) else if "!MODEL!" == "bramble" (
		set 5G_SUPPORT=TRUE
	) else if "!MODEL!" == "redfin" (
		set 5G_SUPPORT=TRUE
	) else if "!MODEL!" == "barbet" (
		set 5G_SUPPORT=TRUE
	) else if "!MODEL!" == "oriole" (
		set EXINOS_MODEL=TRUE
	) else if "!MODEL!" == "raven" (
		set EXINOS_MODEL=TRUE
	) else if "!MODEL!" == "bluejay" (
		set EXINOS_MODEL=TRUE
	) else if "!MODEL!" == "panther" (
		set EXINOS_MODEL=TRUE
	) else if "!MODEL!" == "cheetah" (
		set EXINOS_MODEL=TRUE
	) else if "!MODEL!" == "lynx" (
		set EXINOS_MODEL=TRUE
	) else if "!MODEL!" == "tangorpro" (
		set EXINOS_MODEL=TRUE
	) else if "!MODEL!" == "felix" (
		set EXINOS_MODEL=TRUE
	) else if "!MODEL!" == "shiba" (
		set EXINOS_MODEL=TRUE
	) else if "!MODEL!" == "husky" (
		set EXINOS_MODEL=TRUE
	)

	REM Get Build
	set BUILD=
	for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getbuild') do set BUILD=%%a

	REM magisk boot flashing complete, continue install magisk app
	if "!MAGISK_CHK!" == "INSTALLING" (
		if "!CHOSEN_MENU!" == "1" (
			goto ROOTING_CONTINUE
		) else if "!CHOSEN_MENU!" == "2" (
			goto ROOTING_CONTINUE
		) else if "!CHOSEN_MENU!" == "3" (
			goto ROOTING_CONTINUE
		) else if "!CHOSEN_MENU!" == "6" (
			:ROOTING_CONTINUE
			echo.
			echo adb shell 에 root 권한을 부여합니다. 잠시 후 아무 키를 입력하시면 
			echo 픽셀 기기에서 '슈퍼유저 요청'이라는 팝업창이 나오며 
			echo '셸'에 대해 '영구적으로' 옵션 확인 후 '일괄 허용'을 눌러주세요. ^(10초 이내^) 
			echo.
			pause
			echo.

			:GRANT_ROOT_TO_ADB
			platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "su -c date > /dev/null 2>&1"
			if !errorlevel! == 0 (
				echo.
				echo adb shell 에 root 권한 할당 완료. 
				echo.

				platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell su -c "/data/local/tmp/volte_easy_temp/parser.sh magiskcopy"
				echo.
				echo 필수 파일 복사 중... 
				echo.
				ping -n 3 127.0.0.1 >nul
				REM platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell su -c "/data/local/tmp/volte_easy_temp/stock_boot_backup_check.sh"
			) else if !errorlevel! == 13 (
				echo adb shell 에 root 권한이 할당되지 않았습니다. 
				echo.
				echo ^(Magisk 앱을 실행하신 후, 
				echo 메인 화면 하단 집 모양 아이콘 우측 '방패 모양 아이콘'^(=슈퍼유저 메뉴^)에 진입하셔서 
				echo '셸'에 대한 권한 스위치가 꺼져있다면 켜주세요.^) 
				echo.
				ping -n 5 127.0.0.1 >nul
				goto GRANT_ROOT_TO_ADB
			) else (
				echo errorlevel = !errorlevel! 
				echo 알 수 없는 오류가 발생했습니다. 
				goto QUIT
			)

			set MAGISK_CHK=INSTALLED
			echo.
			echo 루팅 과정이 완료되었습니다. 
			echo.

			if "!CHOSEN_MENU!" == "1" (
				echo VoLTE 패치 과정을 계속 진행합니다. 
				goto DO_VOLTE_CHECK
			) else if "!CHOSEN_MENU!" == "2" (
				echo EFS 백업 과정을 계속 진행합니다. 
				goto EFS_BACKUP
			) else if "!CHOSEN_MENU!" == "3" (
				echo EFS 복구 과정을 계속 진행합니다. 
				goto EFS_RESTORE
			) else if "!CHOSEN_MENU!" == "6" (
				pause
				goto MENU_CHOICE
			)
		)
	)

	REM Get Bootloader status with magisk
	set MAGISK_CHK=
	set MAGISK_VER=
	set BOOTLOADER=

	REM Get magisk status
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "magisk >/dev/null 2>&1"
	if !errorlevel! == 127 (
		set MAGISK_CHK=NOT_INSTALLED

		REM Get Booloader status
		for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getbootloaderstat') do set BOOTLOADER=%%a
		if "!BOOTLOADER!" == "0" (
			set BOOTLOADER=UNLOCKED
			echo 부트로더 : 언락됨 
		) else if "!IS_CUSTOM_ROM!" == "TRUE" (
			set BOOTLOADER=UNLOCKED
			echo 부트로더 : 언락됨 
		) else if "!BOOTLOADER!" == "1" (
			set BOOTLOADER=LOCKED
			echo 부트로더 : 언락되지 않음 
		)

		echo Magisk 루팅되어 있지 않음. 
		echo.
	) else (
		for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getmagiskver') do set MAGISK_VER=%%a
		set MAGISK_CHK=INSTALLED
		set BOOTLOADER=UNLOCKED

		echo Magisk-!MAGISK_VER! 루팅되어 있음. 
		echo.

		:SHELL_PERM_CHECK
		set ADB_SHELL_ROOTED=
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "su -c date > /dev/null 2>&1"
		if !errorlevel! == 0 (
			set ADB_SHELL_ROOTED=OK
			echo adb shell 에 할당된 root 권한 확인됨. 
			echo.

		) else if !errorlevel! == 13 (
			set ADB_SHELL_ROOTED=NO
			echo adb shell 에 root 권한이 할당되지 않았습니다. 
			echo.
			echo ^(Magisk 앱을 실행하신 후, 
			echo 메인 화면 하단 집 모양 아이콘 우측 '방패 모양 아이콘'^(=슈퍼유저 메뉴^)에 진입하셔서 
			echo '셸'에 대한 권한 스위치가 꺼져있다면 켜주세요.^) 
			echo.
			ping -n 5 127.0.0.1 >nul
			goto SHELL_PERM_CHECK
		) else (
			echo errorlevel = !errorlevel! 
			echo 알 수 없는 오류가 발생했습니다. 
			goto QUIT
		)
	)

	if "!BOOTLOADER!" == "LOCKED" (
		if not "!CHOSEN_MENU!" == "5" (
			echo.
			echo 부트로더가 잠긴 상태에서는 작업을 진행할 수 없습니다. 
			echo 부트로더 언락을 먼저 진행하시기 바랍니다. 
			echo.
			pause
			goto MENU_CHOICE
		)
	)

	if "!CHOSEN_MENU!" == "2" (
		goto EFS_BACKUP
	) else if "!CHOSEN_MENU!" == "3" (
		goto EFS_RESTORE
	) else if "!CHOSEN_MENU!" == "4" (
		if "!IS_CUSTOM_ROM!" == "TRUE" (
			echo.
			echo Pixel Experience 등 커스텀롬에 대한 안드로이드 업데이트 기능은 지원되지 않습니다. 
			echo.
			pause
			goto MENU_CHOICE
		)
		goto UPDATE_CHECK
	) else if "!CHOSEN_MENU!" == "5" (
		goto BOOTLOADER_LOCK_CHECK
	) else if "!CHOSEN_MENU!" == "6" (
		goto ROOTING_CHECK
	)

	REM Pixel 6, 7 Serieses can not use this VoLTE patch
	if not "!EXINOS_MODEL!" == "" (
		if "!CHOSEN_MENU!" == "1" (
			echo 엑시노스 탑재 모델^(픽셀 6, 7, 8 시리즈^)은 볼티지를 통한 VoLTE 패치가 지원되지 않습니다. 
			goto MENU_CHOICE
		)
	)

	REM Check DSDS on, if off case, process to single sim
	for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getdsds') do set DSDS_ON=%%a
	if "!DSDS_ON!" == "" (
		goto SINGLE_SIM
	) else if "!DSDS_ON!" == "dsds" (
		goto DUAL_SIM
	) else (
		goto SINGLE_SIM
	)

	:SINGLE_SIM
	REM Get Carrier
	if "!CARRIER_SIM1!" == "" (
		for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getcarrier') do set CARRIER_SIM1=%%a

		REM SKT carrier expression is 2 case, [SKT] or [SKTelecom]
		echo !CARRIER_SIM1! | findstr /i "skt" >nul
		if !errorlevel! == 0 (
			set CARRIER_SIM1=SKT
		)

		echo !CARRIER_SIM1! | findstr /i "lg" >nul
		if !errorlevel! == 0 (
			set CARRIER_SIM1=LGU
		)

		if /i "!CARRIER_SIM1!" == "kt" (
			set CARRIER_SIM1=SIM1_KT
		) else if /i "!CARRIER_SIM1!" == "skt" (
			set CARRIER_SIM1=SIM1_SKT
		) else if /i "!CARRIER_SIM1!" == "lgu" (
			set CARRIER_SIM1=SIM1_LGU
		) else (
			echo 한국 통신 3사망^(KT, SKT, LGU+^)의 유심이 삽입된 상태가 아닌 것 같습니다. 
			echo 유심 삽입 후에 다시 작업하기를 권장드립니다만, 일단 계속 진행하시겠습니까? 
			:CARRIER_SINGLE_CHECK
			set _CARRIER_SIM1=
			set /p _CARRIER_SIM1=계속 진행하시려면 이용 중이신 또는 이용 예정인 통신사망을 입력해주세요. [KT/SKT/LGU]%NL%%NL%: 

			if /i "!_CARRIER_SIM1!" == "kt" (
				set CARRIER_SIM1=SIM1_KT
			) else if /i "!_CARRIER_SIM1!" == "skt" (
				set CARRIER_SIM1=SIM1_SKT
			) else if /i "!_CARRIER_SIM1!" == "lgu" (
				set CARRIER_SIM1=SIM1_LGU
			) else (
				echo 잘못된 입력입니다. KT 나 SKT 또는 LGU 를 입력해주세요. 
				goto CARRIER_SINGLE_CHECK
			)
		)

		REM Setting for 5G
		if "!5G_SUPPORT!" == "TRUE" (
			goto SINGLE_SIM_5G_CHECK
		) else (
			goto SINGLE_SIM_LTE_ONLY
		)

		:SINGLE_SIM_5G_CHECK
		if not "!CARRIER_SIM1!" == "SIM1_LGU" (
			echo.
			echo 5G 요금제 사용자께서는 "5G"를, 
			echo 이외에는 "Enter"^(또는 "LTE"^)를 입력해주세요. 

			set _IS_5G=
			set /p _IS_5G=패치를 적용하실 통신망^(요금제^)을 선택해주세요. [LTE/5G]%NL%%NL%: 

			if /i "!_IS_5G!" == "5g" (
				set CARRIER_SIM1=!CARRIER_SIM1!_5G
			) else if "!_IS_5G!" == "" (
				set CARRIER_SIM1=!CARRIER_SIM1!_LTE
			) else if /i "!_IS_5G!" == "lte" (
				set CARRIER_SIM1=!CARRIER_SIM1!_LTE
			) else (
				echo 잘못된 입력입니다. LTE 또는 5G 를 입력해주세요. 
				goto SINGLE_SIM_5G_CHECK
			)

			goto CARRIER_CHECK_COMPLETED
		)

		:SINGLE_SIM_LTE_ONLY
		if not "!CARRIER_SIM1!" == "SIM1_LGU" (
			set CARRIER_SIM1=!CARRIER_SIM1!_LTE
		)
		goto CARRIER_CHECK_COMPLETED
	)

	:DUAL_SIM
	REM Get SIM1 Carrier
	if "!CARRIER_SIM2!" == "" (
		:GET_DUAL_SIM
		echo.
		echo ============================================================ 
		echo.
		echo [ 유심 ] 
		echo.
		echo 유심을 사용하지 않으신다면 유심에 대한 VoLTE 패치는 생략하시면 되며, 
		echo 패치를 수행하고자 하시는 경우, 유심 삽입 후에 다시 작업하기를 권장드립니다. 
		echo ^( "Enter" 입력시 유심 VoLTE 패치 생략 ^) 
		echo.
		:CARRIER_SIM1_CHECK
		set _CARRIER_SIM1=
		set /p _CARRIER_SIM1=계속 진행하시려면 이용 중이신 또는 이용 예정인 통신사망을 입력해주세요. [KT/SKT/LGU]%NL%%NL%: 

		if /i "!_CARRIER_SIM1!" == "kt" (
			set CARRIER_SIM1=SIM1_KT
		) else if /i "!_CARRIER_SIM1!" == "skt" (
			set CARRIER_SIM1=SIM1_SKT
		) else if /i "!_CARRIER_SIM1!" == "lgu" (
			set CARRIER_SIM1=SIM1_LGU
		) else if "!_CARRIER_SIM1!" == "" (
			set CARRIER_SIM1=
		) else (
			echo 잘못된 입력입니다. KT 나 SKT 또는 LGU 를 입력해주세요. 
			goto CARRIER_SIM1_CHECK
		)

		REM Get SIM2
		echo.
		echo ============================================================ 
		echo.
		echo [ eSIM ] 
		echo.
		echo eSIM 을 사용하지 않으신다면 eSIM 에 대한 VoLTE 패치는 생략하시면 되며, 
		echo 패치를 수행하고자 하시는 경우, eSIM 삽입 후에 다시 작업하기를 권장드립니다. 
		echo ^( "Enter" 입력시 eSIM VoLTE 패치 생략 ^) 
		echo.
		:CARRIER_SIM2_CHECK
		set _CARRIER_SIM2=
		set /p _CARRIER_SIM2=계속 진행하시려면 이용 중이신 또는 이용 예정인 통신사망을 입력해주세요. [KT/SKT/LGU]%NL%%NL%: 

		if /i "!_CARRIER_SIM2!" == "kt" (
			set CARRIER_SIM2=SIM2_KT
		) else if /i "!_CARRIER_SIM2!" == "skt" (
			set CARRIER_SIM2=SIM2_SKT
		) else if /i "!_CARRIER_SIM2!" == "lgu" (
			set CARRIER_SIM2=SIM2_LGU
		) else if "!_CARRIER_SIM2!" == "" (
			set CARRIER_SIM2=
			if "!CARRIER_SIM1!" == "" (
				goto CARRIER_CHECK_COMPLETED
			)
		) else (
			echo 잘못된 입력입니다. KT, SKT, LGU 또는 "Enter" 를 입력해주세요. 
			goto CARRIER_SIM2_CHECK
		)

		:SIM1_5G_CHECK
		if "!5G_SUPPORT!" == "TRUE" (
			if not "!CARRIER_SIM1!" == "SIM1_LGU" (
				echo.
				echo [*유심*] 5G 요금제 사용자께서는 "5G"를, 
				echo 이외에는 "Enter"^(또는 "LTE"^)를 입력해주세요. 

				set _IS_5G=
				set /p _IS_5G=패치를 적용하실 통신망^(요금제^)을 선택해주세요. [LTE/5G]%NL%%NL%: 

				if /i "!_IS_5G!" == "5g" (
					set CARRIER_SIM1=!CARRIER_SIM1!_5G
				) else if "!_IS_5G!" == "" (
					set CARRIER_SIM1=!CARRIER_SIM1!_LTE
				) else if /i "!_IS_5G!" == "lte" (
					set CARRIER_SIM1=!CARRIER_SIM1!_LTE
				) else (
					echo 잘못된 입력입니다. LTE 또는 5G 를 입력해주세요. 
					goto SIM1_5G_CHECK
				)

				goto SIM2_5G_CHECK
			)
		) else (
			REM SIM1_LTE_ONLY
			if "!CARRIER_SIM1!" == "SIM1_LGU" (
				set CARRIER_SIM1=SIM1_LGU
			) else if "!CARRIER_SIM1!" == "" (
				set CARRIER_SIM1=
			) else (
				set CARRIER_SIM1=!CARRIER_SIM1!_LTE
			)
		)

		:SIM2_5G_CHECK
		if "!5G_SUPPORT!" == "TRUE" (
			if not "!CARRIER_SIM2!" == "SIM2_LGU" (
				echo.
				echo [*eSIM*] 5G 요금제 사용자께서는 "5G"를, 
				echo 이외에는 "Enter"^(또는 "LTE"^)를 입력해주세요. 

				set _IS_5G=
				set /p _IS_5G=패치를 적용하실 통신망^(요금제^)을 선택해주세요. [LTE/5G]%NL%%NL%: 

				if /i "!_IS_5G!" == "5g" (
					set CARRIER_SIM2=!CARRIER_SIM2!_5G
				) else if "!_IS_5G!" == "" (
					set CARRIER_SIM2=!CARRIER_SIM2!_LTE
				) else if /i "!_IS_5G!" == "lte" (
					set CARRIER_SIM2=!CARRIER_SIM2!_LTE
				) else (
					echo 잘못된 입력입니다. LTE 또는 5G 를 입력해주세요. 
					goto SIM2_5G_CHECK
				)

				goto CARRIER_CHECK_COMPLETED
			)
		) else (
			REM SIM2_LTE_ONLY
			if "!CARRIER_SIM2!" == "SIM2_LGU" (
				set CARRIER_SIM2=SIM2_LGU
			) else if "!CARRIER_SIM2!" == "" (
				set CARRIER_SIM2=
			) else (
				set CARRIER_SIM2=!CARRIER_SIM2!_LTE
			)
		)

		:CARRIER_CHECK_COMPLETED
		if "!CARRIER_SIM1!" == "" (
			if "!CARRIER_SIM2!" == "" (
				echo.
				echo 유심, eSIM 중 최소한 하나는 패치 대상^(통신사^)을 정해야 합니다. 
				echo.
				goto DUAL_SIM
			)
		)
		goto AFTER_CARRIER_CHECK
	) else if "!CARRIER_SIM1!" == "" (
		goto GET_DUAL_SIM
	)

	:AFTER_CARRIER_CHECK
	if "!BOOTLOADER!" == "UNLOCKED" (
		REM In case of Pixel 1st Gen, go to flashing modem process
		if not "!FIRST_GEN_MODEL!" == "" (
			if "!BUILD!" == "qp1a.191005.007.a3" (
				echo.
				echo 픽셀 1세대 최신 업데이트 적용 상태^(!BUILD!^) 확인됨. 
				echo.

				:PIXEL_FIRST_GEN_VOLTE_CHECK
				set PIXEL_FIRST_GEN_VOLTE_CHK=
				echo ============================================================ 
				echo.
				echo "Enter"^(또는 "Y"^) 를 입력하시면 VoLTE 패치 과정을 시작하며, 
				echo "M" 을 입력하시면 초기 메뉴로 돌아가고, 
				echo "Q" 를 입력하시면 프로그램을 종료합니다. 
				echo.
				echo ============================================================ 
				echo.
				set /p PIXEL_FIRST_GEN_VOLTE_CHK=!FIRST_GEN_MODEL! 기기의 VoLTE 패치를 진행할까요? [Y/M/Q]%NL%%NL%: 
				if /i "!PIXEL_FIRST_GEN_VOLTE_CHK!" == "y" (
					goto DO_PIXEL_FIRST_GEN_VOLTE
				) else if "!PIXEL_FIRST_GEN_VOLTE_CHK!" == "" (
					goto DO_PIXEL_FIRST_GEN_VOLTE
				) else if /i "!PIXEL_FIRST_GEN_VOLTE_CHK!" == "m" (
					goto MENU_CHOICE
				) else if /i "!PIXEL_FIRST_GEN_VOLTE_CHK!" == "q" (
					goto QUIT
				) else (
					echo 잘못된 입력입니다. 
					goto PIXEL_FIRST_GEN_VOLTE_CHECK
				)
			) else (
				echo 본 프로그램에서는 픽셀 1세대^(Pixel, Pixel XL^)에 대하여 
				echo 안드로이드 10 최신 업데이트를 적용한 경우에만 VoLTE 패치를 지원하고 있습니다. 
				echo 업데이트 과정으로 진행됩니다. 
				echo.
				goto UPDATE_CHECK
			)
		REM In case of Pixel above 2 Gen
		) else (
			if "!MAGISK_CHK!" == "INSTALLED" (
				:DO_VOLTE_CHECK
				set _DO_VOLTE_CHK=
				echo ============================================================ 
				echo.
				if not "!CARRIER_SIM1!" == "" (
					echo 사용자의 유심 통신사망 = [ !CARRIER_SIM1:SIM1_=! ] 
				)
				if not "!CARRIER_SIM2!" == "" (
					echo 사용자의 eSIM 통신사망 = [ !CARRIER_SIM2:SIM2_=! ] 
				)
				echo.
				echo "Enter"^(또는 "Y"^) 를 입력하시면 VoLTE 패치 과정을 시작하며, 
				echo "M" 을 입력하시면 초기 메뉴로 돌아가고, 
				echo "Q" 를 입력하시면 프로그램을 종료합니다. 
				echo.
				if "!IS_CUSTOM_ROM!" == "TRUE" (
					echo *주의* Pixel Experience 등 커스텀롬이 적용된 기기에는 
					echo 볼티지를 통한 VoLTE 패치가 정상 적용되지 않을 수 있습니다. 
					echo 특히 스냅드래곤이 탑재되지 않은 엑시노스, 미디어텍 칩셋 등이 탑재된 기기에는 
					echo Qualcomm DIAG 포트 통신을 통한 efs 파일 작업을 진행할 수 없으므로 
					echo 작업 진행이 불가능함을 유의하시기 바랍니다. 
					echo.
				)
				echo ============================================================ 
				echo.
				set /p _DO_VOLTE_CHK=VoLTE 패치를 진행할까요? [Y/M/Q]%NL%%NL%: 
				if /i "!_DO_VOLTE_CHK!" == "y" (
					REM No need boot.img if installed magisk already
					goto SET_VOLTE
				) else if "!_DO_VOLTE_CHK!" == "" (
					goto SET_VOLTE
				) else if /i "!_DO_VOLTE_CHK!" == "m" (
					set CARRIER_SIM1=
					set CARRIER_SIM2=
					goto MENU_CHOICE
				) else if /i "!_DO_VOLTE_CHK!" == "q" (
					set CARRIER_SIM1=
					set CARRIER_SIM2=
					goto QUIT
				) else (
					echo 잘못된 입력입니다. 
					goto DO_VOLTE_CHECK
				)
			) else (
				REM rooting first
				goto BOOT_IMG_CHECK
			)
		)
	)
)

:BOOTLOADER_LOCK_CHECK
set DO_BOOTLOADER_CHK=
echo ============================================================ 
echo.
if "!BOOTLOADER!" == "LOCKED" (
	echo 부트로더 현재 상태 : Locked 
) else (
	echo 부트로더 현재 상태 : Unlocked 
)
echo.
echo "U" 를 입력하시면 부트로더 언락^(잠금 해제^) 과정을 진행하며, 
echo "L" 을 입력하시면 부트로더 락^(잠금^) 과정을 진행하고, 
echo "M" 을 입력하시면 초기 메뉴로 돌아가며, 
echo "Q" 를 입력하시면 프로그램을 종료합니다. 
echo.
echo VoLTE 패치 작업을 위해서는 부트로더가 언락 되어야 합니다.  
echo *주의* 부트로더를 락/언락하면 픽셀 기기가 초기화 됩니다. 
echo.
echo ============================================================ 
echo.

set /p DO_BOOTLOADER_CHK=부트로더 락/언락 과정을 진행할까요? [U/L/M/Q]%NL%%NL%: 

if /i "!DO_BOOTLOADER_CHK!" == "u" (
	if "!BOOTLOADER!" == "LOCKED" (
		echo.
		echo 기기가 곧 자동으로 재시작 됩니다. 
		echo ^ # 별도의 안내를 드리기 전까지 전원버튼을 누르지 마십시오. # 
		ping -n 3 127.0.0.1 >nul
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! reboot bootloader
		echo.
		ping -n 7 127.0.0.1 >nul
		goto BOOTLOADER_MODE
	) else (
		echo 이미 부트로더가 언락된 상태입니다. 
		goto BOOTLOADER_LOCK_CHECK
	)
) else if /i "!DO_BOOTLOADER_CHK!" == "l" (
	if "!MAGISK_CHK!" == "INSTALLED" (
		echo.
		echo 루팅된 기기의 부트로더 락을 수행하면 부팅 불가 상태가 되므로 
		echo 부트로더 락을 허용하지 않습니다. 
		echo 부트로더 락을 원하시는 경우 루팅 해제부터 진행하시기 바랍니다. 
		echo.
		goto BOOTLOADER_LOCK_CHECK
	) else if "!IS_CUSTOM_ROM!" == "TRUE" (
		echo.
		echo 커스텀롬을 적용한 기기에 부트로더 락을 수행하면 부팅 불가 상태가 되므로 
		echo 부트로더 락을 허용하지 않습니다. 
		echo 부트로더 락을 원하시는 경우 순정 상태로 복구를 먼저 진행하시기 바랍니다. 
		echo.
		goto BOOTLOADER_LOCK_CHECK
	)

	if "!BOOTLOADER!" == "UNLOCKED" (
		echo.
		echo 기기가 곧 자동으로 재시작 됩니다. 
		echo ^ # 별도의 안내를 드리기 전까지 전원버튼을 누르지 마십시오. # 
		ping -n 3 127.0.0.1 >nul
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! reboot bootloader
		echo.
		ping -n 7 127.0.0.1 >nul
		goto BOOTLOADER_MODE
	) else (
		echo 이미 부트로더가 락된 상태입니다. 
		goto BOOTLOADER_LOCK_CHECK
	)
) else if /i "!DO_BOOTLOADER_CHK!" == "m" (
	goto MENU_CHOICE
) else if /i "!DO_BOOTLOADER_CHK!" == "q" (
	goto QUIT
) else (
	echo 잘못된 입력입니다. 
	goto BOOTLOADER_LOCK_CHECK
)

:ROOTING_CHECK
set DO_ROOTING_CHK=
echo ============================================================ 
echo.
if "!MAGISK_CHK!" == "INSTALLED" (
	echo 루팅 현재 상태 : 루팅되어 있음 
) else (
	echo 루팅 현재 상태 : 루팅되어 있지 않음 
)
echo.
echo "R" 을 입력하시면 루팅 과정을 진행하며, 
echo "U" 를 입력하시면 루팅 해제 과정을 진행하고, 
echo "M" 을 입력하시면 초기 메뉴로 돌아가며, 
echo "Q" 를 입력하시면 프로그램을 종료합니다. 
echo.
echo 루팅 시 보안, 뱅킹, 결제 등에 문제가 있을 수 있으므로 
echo 루팅 상태로 기기를 사용하는 것을 권장드리지 않습니다. 
echo.
echo ============================================================ 
echo.

set /p DO_ROOTING_CHK=루팅/루팅 해제 과정을 진행할까요? [R/U/M/Q]%NL%%NL%: 

if /i "!DO_ROOTING_CHK!" == "r" (
	if "!BOOTLOADER!" == "LOCKED" (
		echo.
		echo 부트로더가 잠금 해제된 상태가 아닙니다. 
		echo 루팅 과정을 진행하기 위해서는 부트로더 언락을 먼저 수행하시기 바랍니다. 
		echo.
		pause
		goto MENU_CHOICE
	)

	if "!MAGISK_CHK!" == "INSTALLED" (
		echo 이미 루팅된 상태입니다. 
		goto ROOTING_CHECK
	) else (
		goto BOOT_IMG_CHECK
	)
) else if /i "!DO_ROOTING_CHK!" == "u" (
	if "!MAGISK_CHK!" == "INSTALLED" (
		goto UNROOT
	) else (
		echo 이미 루팅되어 있지 않은 상태입니다. 
		goto ROOTING_CHECK
	)
) else if /i "!DO_ROOTING_CHK!" == "m" (
	goto MENU_CHOICE
) else if /i "!DO_ROOTING_CHK!" == "q" (
	goto QUIT
) else (
	echo 잘못된 입력입니다. 
	goto ROOTING_CHECK
)

:EFS_BACKUP
if "!MAGISK_CHK!" == "NOT_INSTALLED" (
	goto BOOT_IMG_CHECK
) else if "!MAGISK_CHK!" == "INSTALLED" (
	set EFS_BACKUP_CHK=
	echo ============================================================ 
	echo.
	echo "B" 를 입력하시면 EFS 파일의 백업을 진행하고, 
	echo "M" 을 입력하시면 초기 메뉴로 돌아가며, 
	echo "Q" 를 입력하시면 프로그램을 종료합니다. 
	echo.
	echo ============================================================ 
	echo.

	set /p EFS_BACKUP_CHK=EFS 백업을 진행할까요? [B/M/Q]%NL%%NL%: 

	if /i "!EFS_BACKUP_CHK!" == "b" (
		mkdir "efs_files\BACKUP_!DATE_TODAY!"
		if !errorlevel! == 1 (
			echo.
			set /p EFS_BACKUP_OVERWRITE_CHK=EFS 백업 덮어쓰기를 진행할까요? [Y/N]%NL%%NL%: 
			if /i "!EFS_BACKUP_OVERWRITE_CHK!" == "y" (
				goto DO_EFS_BACKUP
			) else if "!EFS_BACKUP_OVERWRITE_CHK!" == "n" (
				goto EFS_BACKUP
			) else (
				echo 잘못된 입력입니다. 
				goto EFS_BACKUP
			)
		) else if !errorlevel! == 0 (
			:DO_EFS_BACKUP
			echo.
			echo # EFS 백업 # 
			echo.

			echo diag 포트 개방 중 ... 
			platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell su -c "resetprop ro.bootmode usbradio"
			platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell su -c "resetprop ro.build.type userdebug"
			platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell su -c "setprop sys.usb.config diag,diag_mdm,adb"

			platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "svc usb setFunctions mtp"
			ping -n 3 127.0.0.1 >nul
			platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "svc usb setFunctions"
			ping -n 3 127.0.0.1 >nul

			:DIAG_CONNECTION_CHECK_FOR_BACKUP
			echo.
			echo diag 포트 통신 확인 중 ... 
			echo.

			set DIAG_STATUS=
			EfsTools\EfsTools.exe efsInfo | findstr /b "Version:"
			if !errorlevel! == 0 (
				set DIAG_STATUS=CONNECTED
			) else (
				set DIAG_STATUS=UNCONNECTED
				echo.
				echo diag 포트 통신 불가. 재확인 중 ... 
				echo.
				ping -n 5 127.0.0.1 >nul
				goto DIAG_CONNECTION_CHECK_FOR_BACKUP
			)

			echo.
			echo DIAG_STATUS = !DIAG_STATUS! 
			echo.

			echo efs 파일 다운로드 중 ... 
			echo.

			EfsTools\EfsTools.exe downloadDirectory -n -i /policyman -o efs_files\BACKUP_!DATE_TODAY!\policyman
			ping -n 2 127.0.0.1 >nul
			EfsTools\EfsTools.exe downloadDirectory -n -i /data -o efs_files\BACKUP_!DATE_TODAY!\data
			ping -n 2 127.0.0.1 >nul
			EfsTools\EfsTools.exe downloadDirectory -n -i /Data_Profiles -o efs_files\BACKUP_!DATE_TODAY!\Data_Profiles
			ping -n 2 127.0.0.1 >nul
			EfsTools\EfsTools.exe downloadDirectory -n -i /google -o efs_files\BACKUP_!DATE_TODAY!\google
			ping -n 2 127.0.0.1 >nul
			EfsTools\EfsTools.exe downloadDirectory -n -i /nv/item_files/data -o efs_files\BACKUP_!DATE_TODAY!\nv\item_files\data
			ping -n 2 127.0.0.1 >nul
			EfsTools\EfsTools.exe downloadDirectory -n -i /nv/item_files/ims -o efs_files\BACKUP_!DATE_TODAY!\nv\item_files\ims
			ping -n 2 127.0.0.1 >nul
			EfsTools\EfsTools.exe downloadDirectory -n -i /nv/item_files/modem/lte -o efs_files\BACKUP_!DATE_TODAY!\nv\item_files\modem\lte
			ping -n 2 127.0.0.1 >nul
			EfsTools\EfsTools.exe downloadDirectory -n -i /nv/item_files/modem/mmode -o efs_files\BACKUP_!DATE_TODAY!\nv\item_files\modem\mmode
			ping -n 5 127.0.0.1 >nul

			echo.
			echo efs 다운로드 및 백업이 완료되었습니다. 
			echo.
			echo 백업 경로 : !cd!\efs_files\BACKUP_!DATE_TODAY! 
			echo.
			echo 추후 볼티지가 업데이트 되면 백업 폴더를 전체 복사하여 아래 경로에 올려주시면 
			echo EFS 복구에 사용하실 수 있습니다. 
			echo.
			echo EFS 복구용 경로 : 볼티지 경로\efs_files\ 
			echo.
			pause

			if "!KEEP_ROOT!" == "FALSE" (
				echo.
				echo 루팅 해제 과정을 진행합니다. 
				echo.
				goto UNROOT
			) else (
				set KEEP_ROOT=
				goto MENU_CHOICE
			)
		)
	) else if /i "!EFS_BACKUP_CHK!" == "m" (
		goto MENU_CHOICE
	) else if /i "!EFS_BACKUP_CHK!" == "q" (
		goto QUIT
	) else (
		echo 잘못된 입력입니다. 
		goto EFS_BACKUP
	)
)

:EFS_RESTORE
if "!MAGISK_CHK!" == "NOT_INSTALLED" (
	goto BOOT_IMG_CHECK
) else if "!MAGISK_CHK!" == "INSTALLED" (

	REM Check user backup efs exists
	dir efs_files | findstr "BACKUP_*" >nul 2>&1
	if !errorlevel! == 0 (
		for /f "tokens=5" %%a in ('dir efs_files ^| findstr BACKUP') do set EFS_DIR=%%a
		for /f %%a in ('forfiles /p efs_files\!EFS_DIR!\google /m user_agent_template /c "cmd /c echo @fsize"') do set EFS_SIZE_CHECK=%%a 
		if "!EFS_SIZE_CHECK!" == "" (
			echo 백업 경로의 EFS 파일이 정상적이지 않다고 판단되므로 자체 EFS 파일을 사용합니다. 
			set EFS_DIR=RESTORE
		) else if "!EFS_SIZE_CHECK!" LSS "1024" (
			echo 백업 경로의 EFS 파일이 정상적이지 않다고 판단되므로 자체 EFS 파일을 사용합니다. 
			set EFS_DIR=RESTORE
		)
	) else (
		set EFS_DIR=RESTORE
	)

	set EFS_RESTORE_CHK=
	echo ============================================================ 
	echo.
	echo VoLTE 패치 과정과 반대로, EFS 복구 과정은 유심과 
	echo eSIM 을 제거한 상태에서 진행하시기를 권장드립니다. 
	echo.
	echo EFS 복구 과정은 유심과 eSIM을 구분하지 않고 통째로 복구합니다. 
	echo 따라서 유심만 복구하시거나 eSIM만 복구하시려면 
	echo EFS 복구 과정을 먼저 수행하신 후 복구를 원하지 않으시는 쪽 SIM은 
	echo 다시 VoLTE 패치를 수행하셔야 합니다. 
	echo.
	echo "R" 을 입력하시면 EFS 파일 복구를 진행하여 VoLTE 패치를 제거하고, 
	echo "M" 을 입력하시면 초기 메뉴로 돌아가며, 
	echo "Q" 를 입력하시면 프로그램을 종료합니다. 
	echo.
	echo *주의* EFS 복구 기능은 실험적 기능입니다. 
	echo.
	echo ============================================================ 
	echo.

	echo 복구 파일 경로 : !cd!\efs_files\!EFS_DIR! 
	echo.
	set /p EFS_RESTORE_CHK=EFS 복구를 진행할까요? [R/M/Q]%NL%%NL%: 

	if /i "!EFS_RESTORE_CHK!" == "r" (
		echo.
		echo # EFS 복구 # 
		echo.

		echo diag 포트 개방 중 ... 
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell su -c "resetprop ro.bootmode usbradio"
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell su -c "resetprop ro.build.type userdebug"
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell su -c "setprop sys.usb.config diag,diag_mdm,adb"

		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "svc usb setFunctions mtp"
		ping -n 3 127.0.0.1 >nul
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "svc usb setFunctions"
		ping -n 3 127.0.0.1 >nul

		:DIAG_CONNECTION_CHECK_FOR_RESTORE
		echo.
		echo diag 포트 통신 확인 중 ... 
		echo.

		set DIAG_STATUS=
		EfsTools\EfsTools.exe efsInfo | findstr /b "Version:"
		if !errorlevel! == 0 (
			set DIAG_STATUS=CONNECTED
		) else (
			set DIAG_STATUS=UNCONNECTED
			echo.
			echo diag 포트 통신 불가. 재확인 중 ... 
			echo.
			ping -n 5 127.0.0.1 >nul
			goto DIAG_CONNECTION_CHECK_FOR_RESTORE
		)

		echo.
		echo DIAG_STATUS = !DIAG_STATUS! 
		echo.
		echo efs 파일 복구 중 ... 
		echo.

		echo efs 재설정을 위한 파일 삭제 중 ... ^(속도가 느립니다. 기다려주세요^) 
		echo.
		EfsTools\EfsTools.exe deleteDirectory -p /data
		ping -n 2 127.0.0.1 >nul
		EfsTools\EfsTools.exe deleteDirectory -p /Data_Profiles
		ping -n 2 127.0.0.1 >nul
		EfsTools\EfsTools.exe deleteDirectory -p /nv/item_files/ims >nul
		ping -n 2 127.0.0.1 >nul

		echo.
		echo efs 파일 업로드 중 ... ^(속도가 느립니다. 기다려주세요^) 
		echo.

		EfsTools\EfsTools.exe uploadDirectory -i efs_files\!EFS_DIR!\data -o /data
		ping -n 2 127.0.0.1 >nul
		EfsTools\EfsTools.exe uploadDirectory -i efs_files\!EFS_DIR!\Data_Profiles -o /Data_Profiles
		ping -n 2 127.0.0.1 >nul
		EfsTools\EfsTools.exe uploadDirectory -i efs_files\!EFS_DIR!\google -o /google
		ping -n 2 127.0.0.1 >nul
		EfsTools\EfsTools.exe uploadDirectory -i efs_files\!EFS_DIR!\nv\item_files\data -o /nv/item_files/data
		ping -n 2 127.0.0.1 >nul
		EfsTools\EfsTools.exe uploadDirectory -i efs_files\!EFS_DIR!\nv\item_files\ims -o /nv/item_files/ims
		ping -n 2 127.0.0.1 >nul
		EfsTools\EfsTools.exe uploadDirectory -i efs_files\!EFS_DIR!\nv\item_files\modem -o /nv/item_files/modem
		ping -n 2 127.0.0.1 >nul

		if "!EFS_DIR!" == "RESTORE" (
			if "!5G_SUPPORT!" == "TRUE" (
				EfsTools\EfsTools.exe uploadDirectory -i efs_files\!EFS_DIR!\policyman_5G -o /policyman
			) else (
				EfsTools\EfsTools.exe uploadDirectory -i efs_files\!EFS_DIR!\policyman -o /policyman
			)
		) else (
			EfsTools\EfsTools.exe uploadDirectory -i efs_files\!EFS_DIR!\policyman -o /policyman
		)

		ping -n 5 127.0.0.1 >nul
		echo.
		echo EFS 복구가 완료되었습니다. 
		echo.

		if "!KEEP_ROOT!" == "FALSE" (
			echo 루팅 해제 과정을 진행합니다. 
			echo.
			goto UNROOT
		) else (
			echo 복구 내용의 적용을 위해, 아무 키를 입력하시면 기기가 곧 자동으로 재시작 됩니다. 
			echo ^ # 전원버튼을 누르지 마십시오. # 
			echo.
			set KEEP_ROOT=
			pause
			platform-tools\adb.exe -s !USER_DEVICE_SERIAL! reboot
			goto MENU_CHOICE
		)
	) else if /i "!EFS_RESTORE_CHK!" == "m" (
		goto MENU_CHOICE
	) else if /i "!EFS_RESTORE_CHK!" == "q" (
		goto QUIT
	) else (
		echo 잘못된 입력입니다. 
		goto EFS_RESTORE
	)
)

:BOOTLOADER_MODE
platform-tools\fastboot.exe wait-for-device >nul 2>&1
platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! devices | findstr "fastboot"
if !errorlevel! == 0 (
	platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! getvar unlocked 2>&1 | findstr "unlocked:\ yes"
	REM Case of bootloader unlocked function
	if !errorlevel! == 0 (
		REM Bootloader lock/unlock
		if "!CHOSEN_MENU!" == "5" (
			if /i "!DO_BOOTLOADER_CHK!" == "u" (
				echo 부트로더 언락 완료. 
				echo.
				platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! reboot
				ping -n 3 127.0.0.1 >nul

				echo ============================================================ 
				echo.
				echo 부트로더 락/언락을 하신 경우에는 기기가 공장 초기화 되므로 
				echo '개발자 옵션 켜기' 및 'USB 디버깅 허용' 과정을 다시 진행해주셔야 합니다. 
				echo.
				echo *주의* 부트로더 언락 이후에는 기기를 켜거나 재시작 할 때마다 
				echo 보안 관련 내용의 영문 안내 문구가 나오게 됩니다. 
				echo 이는 에러나 바이러스 감염 등 문제 상황이 아니라 
				echo 정상 부팅 중인 것이므로 # 전원버튼을 누르지 마십시오. # 
				echo 전원버튼을 누르면 안내문구대로 부팅이 일시중지 되게 됩니다. 
				echo.
				echo USB 디버깅 허용 여부 등을 빠짐없이 진행했는지 확인하신 이후에 
				echo 아무 키를 입력하여 다음 과정을 진행해주세요. 
				echo.
				echo ============================================================ 
				ping -n 5 127.0.0.1 >nul
				pause
				goto ADB_CONNECT_CHECK
			) else if /i "!DO_BOOTLOADER_CHK!" == "l" (
				:BOOTLOADER_LOCK_CHK
				set _BOOTLOADER_LOCK_CHK=
				echo ============================================================ 
				echo.
				echo # 부트로더 락 # 
				echo.
				echo 부트로더를 락^(잠금^) 하여 순정상태와 동일하게 되돌립니다. 
				platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! flashing lock
				echo.
				echo 픽셀 기기의 볼륨 업 또는 다운 버튼을 눌러 
				echo "Lock the bootloader" 가 나오도록 해주시고, 
				echo 전원 버튼을 누르신 후 "L" 을 입력하고 기다려주세요. 
				echo.
				echo *주의*이 과정에는 공장 초기화가 강제로 진행되므로 
				echo 기기에 설치한 앱이나 데이터, 모든 계정이 삭제됩니다. 
				echo.
				echo 이를 원치 않으신다면 
				echo "Do not lock the bootloader" 를 선택하시고 
				echo 전원 버튼을 누르신 후 "C" 를 입력하고 기다려주세요. 
				echo.
				echo ============================================================ 

				set /p _BOOTLOADER_LOCK_CHK=부트로더 락을 진행하셨습니까? [L/C]%NL%%NL%: 
				if /i "!_BOOTLOADER_LOCK_CHK!" == "l" (
					goto BOOTLOADER_MODE
				) else if /i "!_BOOTLOADER_LOCK_CHK!" == "c" (
					platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! reboot
					echo.
					echo 기기를 부팅합니다. 
					echo ^ # 전원버튼을 누르지 마십시오. # 
					echo.
					pause
					goto MENU_CHOICE
				) else (
					echo 잘못된 입력입니다. 
					goto BOOTLOADER_LOCK_CHK
				)
			)
		REM flashing factory zip (=update)
		) else if "!CHOSEN_MENU!" == "4" (
			echo 업데이트를 시작하는 중 ... 
			echo ^ # 전원버튼을 누르지 마십시오. # 
			echo.
			cd TEMP\!MODEL!-!LATEST_BUILD!
			call flash-update.bat !USER_DEVICE_SERIAL!
			pushd %~dp0

			echo.
			echo 업데이트를 완료하였습니다. 
			echo.

			if "!MAGISK_CHK!" == "INSTALLED" (
				ping -n 3 127.0.0.1 >nul
				echo 기존 루팅 유저. Magisk 적용 중 ... 
				REM Set disable verification above pixel 4a5g model
				if "!NEED_VBMETA!" == "TRUE" (
					platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! --disable-verity --disable-verification flash --slot=all vbmeta BOOT.IMG_HERE\vbmeta.img
				)
				platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! flash boot TEMP\magisk_patched.img
				platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! reboot
			) else (
				platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! reboot
			)

			echo 부팅 중 ... 
			echo ^ # 전원버튼을 누르지 마십시오. # 
			echo.
			echo 업데이트 이후에는 기기의 부팅에 시간이 오래 소요되는 편이니 기다려 주세요. 
			echo.
			ping -n 15 127.0.0.1 >nul
			pause
			echo.
			goto MENU_CHOICE
		) else if "!CHOSEN_MENU!" == "1" (
			goto FLASH_BOOT
		) else if "!CHOSEN_MENU!" == "2" (
			goto FLASH_BOOT
		) else if "!CHOSEN_MENU!" == "3" (
			goto FLASH_BOOT
		) else if "!CHOSEN_MENU!" == "6" (
			:FLASH_BOOT
			REM Flashing magisk boot (=rooting)
			echo Magisk boot 적용 중 ... 
			echo.

			if "!KEEP_ROOT!" == "TRUE" (
				REM Set disable verification above pixel 4a5g model
				if "!NEED_VBMETA!" == "TRUE" (
					platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! --disable-verity --disable-verification flash --slot=all vbmeta BOOT.IMG_HERE\vbmeta.img
				)
				platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! flash boot TEMP\magisk_patched.img
				platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! reboot
			) else if "!KEEP_ROOT!" == "FALSE" (
				platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! boot TEMP\magisk_patched.img
			) else (
				platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! flash boot TEMP\magisk_patched.img
				platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! reboot
			)

			set MAGISK_CHK=INSTALLING
			echo Magisk boot 적용 완료. 
			echo.
			echo 부팅 중 ... 
			echo ^ # 전원버튼을 누르지 마십시오. # 
			echo.

			ping -n 5 127.0.0.1 >nul

			echo.
			echo.
			echo 기기가 정상 부팅되면 기기의 잠금을 해제 해주세요. 
			echo 잠금 해제 후 아무 키를 입력하여 다음 과정을 진행해주세요. 
			echo.
			pause
			goto ADB_DEVICE_CHECK
		)
	REM Case of bootloader locked function
	) else (
		if "!CHOSEN_MENU!" == "5" (
			if "!DO_BOOTLOADER_CHK!" == "u" (
				:BOOTLOADER_UNLOCK
				platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! flashing get_unlock_ability 2>&1 | findstr "get_unlock_ability:\ 1"
				if !errorlevel! == 0 (
					:BOOTLOADER_UNLOCK_CHK
					set _BOOTLOADER_UNLOCK_CHK=
					echo ============================================================ 
					echo.
					echo # 부트로더 언락 # 
					echo.
					echo 부트로더를 언락합니다. 
					platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! flashing unlock
					echo.
					echo 픽셀 기기의 볼륨 업 또는 다운 버튼을 눌러 
					echo "Unlock the bootloader" 가 나오도록 해주시고, 
					echo 전원 버튼을 누르신 후 "U" 을 입력하고 기다려주세요. 
					echo.
					echo *주의*이 과정에는 공장 초기화가 강제로 진행되므로 
					echo 기기에 설치한 앱이나 데이터, 모든 계정이 삭제됩니다. 
					echo.
					echo 이를 원치 않으신다면 
					echo "Do not unlock the bootloader" 를 선택하시고 
					echo 전원 버튼을 누르신 후 "C" 를 입력하고 기다려주세요. 
					echo.
					echo ============================================================ 

					set /p _BOOTLOADER_UNLOCK_CHK=부트로더 언락을 진행하셨습니까? [U/C]%NL%%NL%: 
					if /i "!_BOOTLOADER_UNLOCK_CHK!" == "u" (
						goto BOOTLOADER_MODE
					) else if /i "!_BOOTLOADER_UNLOCK_CHK!" == "c" (
						platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! reboot
						echo.
						echo 기기를 부팅합니다. 
						echo ^ # 전원버튼을 누르지 마십시오. # 
						echo.
						pause
						goto MENU_CHOICE
					) else (
						echo 잘못된 입력입니다. 
						goto BOOTLOADER_UNLOCK_CHK
					)
				) else (
					echo 부트로더 언락이 불가한 것으로 보입니다. 
					echo 부트로더 언락이 가능한 기기라면 수동으로 언락을 진행하신 후 다시 시도해주시기 바랍니다. 
					platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! reboot
					ping -n 10 127.0.0.1 >nul
					goto QUIT
				)
			) else if "!DO_BOOTLOADER_CHK!" == "l" (
				echo 부트로더 락 완료. 
				echo.
				platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! reboot
				ping -n 10 127.0.0.1 >nul
				echo.
				pause
				goto QUIT
			)
		)
	)
) else (
	echo.
	echo 기기의 USB 연결이 확인되지 않습니다. 
	echo USB 케이블 연결 상태를 확인해주시기 바랍니다. 
	echo 연결 확인 재시도 중 ... 
	echo.
	ping -n 5 127.0.0.1 >nul
	goto BOOTLOADER_MODE
)

:BOOT_IMG_CHECK
if "!CHOSEN_MENU!" == "1" (
	goto KEEP_ROOT_CHECK
) else if "!CHOSEN_MENU!" == "2" (
	goto KEEP_ROOT_CHECK
) else if "!CHOSEN_MENU!" == "3" (
	if "!MAGISK_CHK!" == "NOT_INSTALLED" (
		:KEEP_ROOT_CHECK
		if "!KEEP_ROOT!" == "" (
			set UNROOT_CHK=
			echo.
			echo ============================================================ 
			echo.
			echo 해당 과정은 루팅이 필수적입니다. 
			echo.
			echo "Enter"^(또는 "Y"^) 를 입력하시면 작업 후 루팅을 해제하며, 
			echo "N" 을 입력하시면 작업 후 루팅을 유지하고, 
			echo "M" 을 입력하시면 초기 메뉴로 돌아가며, 
			echo "Q" 를 입력하시면 프로그램을 종료합니다. 
			echo.
			echo 루팅을 유지하실 경우 금융 앱을 비롯한 각종 앱의 사용이나 
			echo 안드로이드 OTA 업데이트 등에 제한 사항이 발생할 수 있으므로 
			echo 해제 하시는 것을 권장드립니다. 
			echo.
			echo ============================================================ 
			echo.
			set /p UNROOT_CHK=작업 이후에 루팅을 해제할까요? [Y/N/M/Q]%NL%%NL%: 
			if /i "!UNROOT_CHK!" == "y" (
				set KEEP_ROOT=FALSE
			) else if "!UNROOT_CHK!" == "" (
				set KEEP_ROOT=FALSE
			) else if /i "!UNROOT_CHK!" == "n" (
				set KEEP_ROOT=TRUE
			) else if /i "!UNROOT_CHK!" == "m" (
				goto MENU_CHOICE
			) else if /i "!UNROOT_CHK!" == "q" (
				goto QUIT
			) else (
				echo 잘못된 입력입니다. 
				goto KEEP_ROOT_CHECK
			)
			echo.
		)
	)
)

REM No need boot.img in case of custom ROM like Pixel Experience
if "!IS_CUSTOM_ROM!" == "TRUE" (
	goto MAGISK_INSTALL
)

dir BOOT.IMG_HERE | findstr "boot.img" >nul 2>&1
if !errorlevel! == 0 (
	echo.
	echo boot.img 파일 확인 중 ... 
	echo.
	set BOOT_IMG_FSIZE=
	for /f %%a in ('forfiles /p BOOT.IMG_HERE /m boot.img /c "cmd /c echo @fsize"') do set BOOT_IMG_FSIZE=%%a 
	if "!BOOT_IMG_FSIZE!" == "" (
		goto BOOT_IMG_NOT_AVAIL
	) else if "!BOOT_IMG_FSIZE!" LSS "10000000" (
		:BOOT_IMG_NOT_AVAIL
		echo.
		echo 준비된 boot.img 파일이 정상적이지 않다고 판단됩니다. 
		echo.
		del /s /q BOOT.IMG_HERE\boot.img
		REM if has factory.zip then, extract boot.img
		goto FACTORY_ZIP_CHECK
	) else (
		echo.
		echo 준비된 boot.img 파일 확인됨. 
		echo.
		echo 필요 파일 준비 중 ... 

		REM boot.img bakcup
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "mv /sdcard/Download/boot.img /sdcard/Download/boot.img.!DATE_TODAY! 2> /dev/null"
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "mv /sdcard/Download/magisk_patched.img /sdcard/Download/magisk_patched.img.!DATE_TODAY! 2> /dev/null"
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! push BOOT.IMG_HERE\boot.img /sdcard/Download/ >nul
		echo.
		goto MAGISK_INSTALL
	)
)

:OTA_ZIP_CHECK
dir OTA.ZIP_HERE | findstr ".*.zip" >nul 2>&1
if !errorlevel! == 0 (
	echo.
	echo OTA 압축파일 확인 중 ... 
	echo.
	for /f %%a in ('forfiles /p OTA.ZIP_HERE /m "*.zip"') do set OTA_ZIP_FILE_NAME=%%a& set OTA_ZIP_FILE_NAME=!OTA_ZIP_FILE_NAME:"=!
	set OTA_ZIP_FSIZE=
	for /f %%a in ('forfiles /p OTA.ZIP_HERE /m "!OTA_ZIP_FILE_NAME!" /c "cmd /c echo @fsize"') do set OTA_ZIP_FSIZE=%%a 
	if "!OTA_ZIP_FSIZE!" == "" (
		goto OTA_ZIP_NOT_AVAIL
	) else if "!OTA_ZIP_FSIZE!" LSS "100000000" (
		:OTA_ZIP_NOT_AVAIL
		echo.
		echo 준비된 OTA 압축파일이 정상적이지 않다고 판단됩니다. 
		echo.
		del /s /q OTA.ZIP_HERE\!OTA_ZIP_FILE_NAME!
		goto OTA_ZIP_CHECK
	) else (
		echo OTA 압축해제 중 ... 
		echo.
		tools\7za.exe x "OTA.ZIP_HERE\!OTA_ZIP_FILE_NAME!" payload.bin -bsp1 -oTEMP\
		if !errorlevel! == 0 (
			echo payload.bin 파일 전송 중 ...
			echo.
			platform-tools\adb.exe -s !USER_DEVICE_SERIAL! push TEMP\payload.bin /sdcard/Download/
			del /s /q TEMP\* >nul 2>&1
			echo.
			set IS_OTA_ZIP=TRUE
			goto MAGISK_INSTALL
		) else (
			:OTA_ZIP_UNZIP_ERROR
			echo.
			echo 압축해제 중 문제가 발생했습니다. 
			echo 준비된 OTA 압축파일이 정상적이지 않다고 판단됩니다. 
			echo.
			del /s /q OTA.ZIP_HERE\!OTA_ZIP_FILE_NAME! >nul 2>&1
			goto FACTORY_ZIP_CHECK
		)
	)
)

:FACTORY_ZIP_CHECK
dir FACTORY.ZIP_HERE | findstr ".*-factory-.*.zip" >nul 2>&1
if !errorlevel! == 0 (
	echo.
	echo 팩토리 이미지 압축파일 확인 중 ... 
	echo.
	for /f %%a in ('forfiles /p FACTORY.ZIP_HERE /m "*-factory-*.zip"') do set FACTORY_ZIP_FILE_NAME=%%a& set FACTORY_ZIP_FILE_NAME=!FACTORY_ZIP_FILE_NAME:"=!
	set FACTORY_ROM_FSIZE=
	for /f %%a in ('forfiles /p FACTORY.ZIP_HERE /m "!FACTORY_ZIP_FILE_NAME!" /c "cmd /c echo @fsize"') do set FACTORY_ROM_FSIZE=%%a 
	if "!FACTORY_ROM_FSIZE!" == "" (
		goto FACTORY_ZIP_NOT_AVAIL
	) else if "!FACTORY_ROM_FSIZE!" LSS "100000000" (
		:FACTORY_ZIP_NOT_AVAIL
		echo.
		echo 준비된 팩토리 이미지 압축파일이 정상적이지 않다고 판단됩니다. 
		echo.
		del /s /q FACTORY.ZIP_HERE\!FACTORY_ZIP_FILE_NAME!
		goto BOOT_IMG_DOWNLOAD
	) else (
		echo 팩토리 이미지 압축해제 중 ... 
		echo.
		tools\7za.exe x "FACTORY.ZIP_HERE\!FACTORY_ZIP_FILE_NAME!" -bsp1 -oTEMP\
		if !errorlevel! == 0 (
			del /s /q BOOT.IMG_HERE\boot.img >nul 2>&1
			tools\7za.exe x "TEMP\!MODEL!-!BUILD!\image-*" boot.img -bsp1 -oBOOT.IMG_HERE\
			if !errorlevel! == 0 (
				platform-tools\adb.exe -s !USER_DEVICE_SERIAL! push BOOT.IMG_HERE\boot.img /sdcard/Download/ >nul 2>&1
				del /s /q TEMP\* >nul 2>&1
				echo.
				goto BOOT_IMG_CHECK
			) else (
				goto FACTORY_ZIP_UNZIP_ERROR
			)
		) else (
			:FACTORY_ZIP_UNZIP_ERROR
			echo.
			echo 압축해제 중 문제가 발생했습니다. 
			echo 준비된 팩토리 이미지 압축파일이 정상적이지 않다고 판단됩니다. 
			echo.
			del /s /q BOOT.IMG_HERE\boot.img >nul 2>&1
			del /s /q FACTORY.ZIP_HERE\!FACTORY_ZIP_FILE_NAME! >nul 2>&1
			goto BOOT_IMG_DOWNLOAD
		)
	)
)

:BOOT_IMG_DOWNLOAD
echo.
echo boot.img 다운로드를 시도합니다. 
echo boot.img [!MODEL!-!BUILD!] 다운로드 중 ... 
echo.

set BOOT_IMG_URL=
set CHECKED_BUILD=

tools\curl.exe -s "https://github.com/pixel-volte-easy-bootimg/!MODEL!" > TEMP\tmp_curl_result
platform-tools\adb.exe -s !USER_DEVICE_SERIAL! push TEMP\tmp_curl_result /data/local/tmp/volte_easy_temp/
platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell grep "!BUILD!-boot" /data/local/tmp/volte_easy_temp/tmp_curl_result >nul 2>&1
if !errorlevel! == 1 (
	REM Try download in google
	:FACTORY_ZIP_DOWNLOAD
	echo.
	echo git 서버에 에러가 발생했거나, 파일 서버에 boot.img 가 준비되지 않음. 
	echo 구글 다운로드 페이지에서 팩토리 이미지 다운로드를 시도합니다. 
	echo.

	tools\curl.exe -s "https://developers.google.com/android/images" -H "cookie:devsite_wall_acks=nexus-image-tos" > TEMP\tmp_curl_result
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! push TEMP\tmp_curl_result /data/local/tmp/volte_easy_temp/

	for /f "tokens=1,2" %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getfactory !BUILD! !MODEL!') do (set FACTORY_IMG_URL=%%a& set FACTORY_ZIP_FILE_NAME=%%b)

	echo.
	echo 팩토리 이미지 다운로드 중 ... 
	echo.
	tools\curl.exe "!FACTORY_IMG_URL!" -o "FACTORY.ZIP_HERE\!FACTORY_ZIP_FILE_NAME!"
	echo.
	goto FACTORY_ZIP_CHECK
REM Try download in git
) else if !errorlevel! == 0 (
	for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getbootimg !BUILD! !MODEL!') do set BOOT_IMG_FILE_NAME=%%a
	tools\curl.exe "https://raw.githubusercontent.com/pixel-volte-easy-bootimg/!MODEL!/main/!BOOT_IMG_FILE_NAME!" -o "TEMP\!BOOT_IMG_FILE_NAME!"

	echo.
	echo boot.img 압축파일 해제 중 ... 
	tools\7za.exe x "TEMP\!BOOT_IMG_FILE_NAME!" -so > "BOOT.IMG_HERE\boot.img"
	if !errorlevel! == 0 (
		echo boot.img 파일 추출 완료. 
		del /s /q TEMP\tmp_* >nul 2>&1
		echo.
		goto BOOT_IMG_CHECK
	) else (
		if !GIT_DOWNLOAD_COUNT! == 1 (
			goto BOOTIMG_DOWNLOAD_IN_GIT_RETRY
		) else if !GIT_DOWNLOAD_COUNT! == 2 (
			goto BOOTIMG_DOWNLOAD_IN_GIT_RETRY
		) else if !GIT_DOWNLOAD_COUNT! == 3 (
			set GIT_DOWNLOAD_COUNT=
			del /s /q BOOT.IMG_HERE\boot.img >nul 2>&1
			goto FACTORY_ZIP_DOWNLOAD
		) else (
			:BOOTIMG_DOWNLOAD_IN_GIT_RETRY
			set /a GIT_DOWNLOAD_COUNT+=1
			echo.
			echo 압축해제 중 문제가 발생했습니다. 재시도 중 ... [ !GIT_DOWNLOAD_COUNT!/3 ]
			echo.
			del /s /q BOOT.IMG_HERE\boot.img >nul 2>&1
			goto BOOT_IMG_CHECK
		)
	)
)


:UPDATE_CHECK
echo.
echo 업데이트를 확인 중입니다 ... 
echo.

dir OTA.ZIP_HERE | findstr ".*.zip" >nul 2>&1
if !errorlevel! == 0 (
	set OTA_ZIP_FSIZE=
	for /f %%a in ('forfiles /p OTA.ZIP_HERE /m "*.zip"') do set OTA_ZIP_FILE_NAME=%%a& set OTA_ZIP_FILE_NAME=!OTA_ZIP_FILE_NAME:"=!
	for /f %%a in ('forfiles /p OTA.ZIP_HERE /m "!OTA_ZIP_FILE_NAME!" /c "cmd /c echo @fsize"') do set OTA_ZIP_FSIZE=%%a 
	if "!OTA_ZIP_FSIZE!" == "" (
		del /s /q OTA.ZIP_HERE\!OTA_ZIP_FILE_NAME!
	) else if "!OTA_ZIP_FSIZE!" LSS "100000000" (
		del /s /q OTA.ZIP_HERE\!OTA_ZIP_FILE_NAME!
	) else (
		echo 준비된 OTA 압축파일 확인됨. 
		set IS_OTA_ZIP=TRUE
		echo.

		set DO_UPDATE_USER_OTA_CHK=
		echo ============================================================ 
		echo.
		echo "Enter"^(또는 "Y"^) 를 입력하시면 OTA.ZIP_HERE 폴더에 
		echo 직접 준비하신 OTA 압축파일을 통해 업데이트를 시작하며, 
		echo "N" 을 입력하시면 준비하신 파일은 삭제한 후에 
		echo 현행 최신 업데이트를 검색하여 다운로드 받고 업데이트를 진행합니다. 
		echo "M" 을 입력하시면 초기 메뉴로 돌아가고, 
		echo "Q" 를 입력하시면 프로그램을 종료합니다. 
		echo.
		echo ============================================================ 
		echo.
		set /p DO_UPDATE_USER_OTA_CHK=업데이트를 진행 하시겠습니까? [Y/N/M/Q]%NL%%NL%: 
		if /i "!DO_UPDATE_USER_OTA_CHK!" == "y" (
			goto AFTER_OTA_ZIP_PREPARED
		) else if "!DO_UPDATE_USER_OTA_CHK!" == "" (
			goto AFTER_OTA_ZIP_PREPARED
		) else if /i "!DO_UPDATE_USER_OTA_CHK!" == "n" (
			del /s /q OTA.ZIP_HERE\*.zip
			set IS_OTA_ZIP=
		) else if /i "!DO_UPDATE_USER_OTA_CHK!" == "m" (
			set IS_OTA_ZIP=
			goto MENU_CHOICE
		) else if /i "!DO_UPDATE_USER_OTA_CHK!" == "q" (
			goto QUIT
		)
	)
)

set LATEST_BUILD=
dir FACTORY.ZIP_HERE | findstr ".*-factory-.*.zip" >nul 2>&1
if !errorlevel! == 0 (
	set FACTORY_ROM_FSIZE=
	for /f %%a in ('forfiles /p FACTORY.ZIP_HERE /m "*-factory-*.zip"') do set FACTORY_ZIP_FILE_NAME=%%a& set FACTORY_ZIP_FILE_NAME=!FACTORY_ZIP_FILE_NAME:"=!
	for /f %%a in ('forfiles /p FACTORY.ZIP_HERE /m "!FACTORY_ZIP_FILE_NAME!" /c "cmd /c echo @fsize"') do set FACTORY_ROM_FSIZE=%%a 
	if "!FACTORY_ROM_FSIZE!" == "" (
		del /s /q FACTORY.ZIP_HERE\!FACTORY_ZIP_FILE_NAME!
	) else if "!FACTORY_ROM_FSIZE!" LSS "100000000" (
		del /s /q FACTORY.ZIP_HERE\!FACTORY_ZIP_FILE_NAME!
	) else (
		echo 준비된 팩토리 이미지 압축파일 확인됨. 
		echo.

		for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getlatestbuild prepared !MODEL! !FACTORY_ZIP_FILE_NAME!') do set LATEST_BUILD=%%a

		set DO_UPDATE_USER_ROM_CHK=
		echo ============================================================ 
		echo.
		echo "Enter"^(또는 "Y"^) 를 입력하시면 FACTORY.ZIP_HERE 폴더에 
		echo 직접 준비하신 팩토리 이미지 압축파일을 통해 업데이트를 시작하며, 
		echo "N" 을 입력하시면 준비하신 파일은 삭제한 후에 
		echo 현행 최신 업데이트를 검색하여 다운로드 받고 업데이트를 진행합니다. 
		echo "M" 을 입력하시면 초기 메뉴로 돌아가고, 
		echo "Q" 를 입력하시면 프로그램을 종료합니다. 
		echo.
		echo *주의* 직접 준비하신 팩토리 이미지 압축파일로 업데이트를 진행하실 경우, 
		echo 해당 파일에 대한 적합성 검증을 하지 않습니다. 
		echo 따라서 이 기능을 통해 다운그레이드도 진행 가능하지만 권장드리지는 않습니다. 
		echo 공장초기화 과정이 수반되는 등 문제를 겪으실 수 있으니 유의하시기 바랍니다. 
		echo.
		echo * 업데이트를 하는 경우 루팅이 해제되므로 필요시 다시 루팅을 수행하셔야 할 수 있습니다. * 
		echo.
		echo ============================================================ 
		echo.
		set /p DO_UPDATE_USER_ROM_CHK=업데이트를 진행 하시겠습니까? [Y/N/M/Q]%NL%%NL%: 
		if /i "!DO_UPDATE_USER_ROM_CHK!" == "y" (
			goto AFTER_FACTORY_ROM_PREPARED
		) else if "!DO_UPDATE_USER_ROM_CHK!" == "" (
			goto AFTER_FACTORY_ROM_PREPARED
		) else if /i "!DO_UPDATE_USER_ROM_CHK!" == "n" (
			del /s /q FACTORY.ZIP_HERE\*-factory-*.zip
			set LATEST_BUILD=
		) else if /i "!DO_UPDATE_USER_ROM_CHK!" == "m" (
			goto MENU_CHOICE
		) else if /i "!DO_UPDATE_USER_ROM_CHK!" == "q" (
			goto QUIT
		)
	)
)

tools\curl.exe -s "https://github.com/pixel-volte-easy-bootimg/!MODEL!" > TEMP\tmp_curl_result
platform-tools\adb.exe -s !USER_DEVICE_SERIAL! push TEMP\tmp_curl_result /data/local/tmp/volte_easy_temp/

if "%UPDATE_TARGET_CARRIER%" == "ALL" (
	for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getlatestbuild car_all !MODEL!') do set LATEST_BUILD=%%a
) else if "%UPDATE_TARGET_CARRIER%" == "Fi" (
	for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getlatestbuild car_fi !MODEL!') do set LATEST_BUILD=%%a
) else if "%UPDATE_TARGET_CARRIER%" == "JP" (
	for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getlatestbuild car_jp !MODEL!') do set LATEST_BUILD=%%a
) else if "%UPDATE_TARGET_CARRIER%" == "EU" (
	for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getlatestbuild car_eu !MODEL!') do set LATEST_BUILD=%%a
)

if "!BUILD!" == "!LATEST_BUILD!" (
	echo.
	echo 현재 기기의 업데이트 버전이 최신 상태입니다. 
	echo.
	pause
	goto MENU_CHOICE
) else (
	echo.
	echo 가능한 업데이트 [!MODEL!-!LATEST_BUILD!] 가 확인 되었습니다. 
	echo.

	:UPDATE_CHK
	set DO_UPDATE_CHK=
	echo ============================================================ 
	echo.
	echo "Enter"^(또는 "Y"^) 를 입력하시면 업데이트를 시작하며, 
	echo "M" 을 입력하시면 초기 메뉴로 돌아가고, 
	echo "Q" 를 입력하시면 프로그램을 종료합니다. 
	echo.
	echo * 업데이트를 하는 경우 루팅이 해제되므로 필요시 다시 루팅을 수행하셔야 할 수 있습니다. * 
	echo.
	echo ============================================================ 
	echo.
	set /p DO_UPDATE_CHK=업데이트를 진행 하시겠습니까? [Y/M/Q]%NL%%NL%: 
	if /i "!DO_UPDATE_CHK!" == "y" (
		goto DO_UPDATE
	) else if "!DO_UPDATE_CHK!" == "" (
		goto DO_UPDATE
	) else if /i "!DO_UPDATE_CHK!" == "m" (
		goto MENU_CHOICE
	) else if /i "!DO_UPDATE_CHK!" == "q" (
		goto QUIT
	) else (
		echo 잘못된 입력입니다. 
		goto UPDATE_CHK
	)
)

:DO_UPDATE
tools\curl.exe -s "https://developers.google.com/android/ota" -H "cookie:devsite_wall_acks=nexus-ota-tos" > TEMP\tmp_curl_result
platform-tools\adb.exe -s !USER_DEVICE_SERIAL! push TEMP\tmp_curl_result /data/local/tmp/volte_easy_temp/

for /f "tokens=1,2" %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getupdate !LATEST_BUILD! !MODEL!') do (set OTA_ZIP_URL=%%a& set OTA_ZIP_FILE_NAME=%%b)

del /s /q TEMP\* >nul 2>&1

echo OTA 압축파일 다운로드 중 ... 
echo.
tools\curl.exe "!OTA_ZIP_URL!" -o "OTA.ZIP_HERE\!OTA_ZIP_FILE_NAME!"
echo.

set OTA_ZIP_FSIZE=
for /f %%a in ('forfiles /p OTA.ZIP_HERE /m "!OTA_ZIP_FILE_NAME!" /c "cmd /c echo @fsize"') do set OTA_ZIP_FSIZE=%%a 
if "!OTA_ZIP_FSIZE!" == "" (
	goto UPDATE_OTA_ZIP_NOT_AVAIL
) else if "!OTA_ZIP_FSIZE!" LSS "100000000" (
	:UPDATE_OTA_ZIP_NOT_AVAIL
	echo.
	echo OTA 압축파일이 정상적이지 않다고 판단됩니다. 
	echo 인터넷에 정상 연결되었다면 안드로이드 베타 버전을 사용 중이시거나 
	echo 파일 서버가 작업 중일 수 있습니다. 
	echo.
	echo 이 경우 픽셀 기기 모델에 맞는 OTA 압축파일 또는 팩토리 이미지 압축파일을 
	echo 직접 준비하여 "OTA.ZIP_HERE" 또는 "FACTORY.ZIP_HERE" 폴더에 넣고 
	echo 다시 실행하시면 업데이트 및 패치 작업이 가능합니다. 
	echo.
	echo OTA 압축파일 다운로드를 재시도 합니다. 
	echo.
	set IS_OTA_ZIP=
	del /s /q OTA.ZIP_HERE\!OTA_ZIP_FILE_NAME!
	pause
	goto DO_UPDATE
) else (
	echo OTA 압축파일 다운로드 완료됨. 
	echo.
	set IS_OTA_ZIP=TRUE
	goto AFTER_OTA_ZIP_PREPARED

	:AFTER_FACTORY_ROM_PREPARED
	echo 팩토리 이미지 압축해제 중 ... 
	echo.
	tools\7za.exe x "FACTORY.ZIP_HERE\!FACTORY_ZIP_FILE_NAME!" -bsp1 -oTEMP\
	if !errorlevel! == 0 (
		del /s /q BOOT.IMG_HERE\boot.img >nul 2>&1
		tools\7za.exe x "TEMP\!MODEL!-!LATEST_BUILD!\image-*" boot.img -bsp1 -oBOOT.IMG_HERE\
		if !errorlevel! == 0 (
			platform-tools\adb.exe -s !USER_DEVICE_SERIAL! push BOOT.IMG_HERE\boot.img /sdcard/Download/ >nul 2>&1

			REM Get vbmeta.img above pixel 4a5g model
			if "!NEED_VBMETA!" == "TRUE" (
				del /s /q BOOT.IMG_HERE\vbmeta.img >nul 2>&1
				tools\7za.exe x "TEMP\!MODEL!-!LATEST_BUILD!\image-*" vbmeta.img -bsp1 -oBOOT.IMG_HERE\
				if !errorlevel! == 0 (
					echo.
				) else (
					goto UPDATE_UNZIP_ERROR
				)
			)
		) else (
			goto UPDATE_UNZIP_ERROR
		)
	) else (
		:UPDATE_UNZIP_ERROR
		echo.
		echo 압축해제 중 문제가 발생했습니다. 
		echo 다시 시도해보시고 문제가 반복된다면 
		echo 구글 다운로드 페이지[ https://developers.google.com/android/images ] 에서 
		echo 팩토리 이미지 압축파일을 다운로드 받으신 후 "FACTORY.ZIP_HERE" 폴더에 넣고 
		echo 다시 실행해주세요. 
		echo.
		REM del FACTORY.ZIP_HERE\!FACTORY_ZIP_FILE_NAME!
		goto QUIT
	)

	
	if "!MAGISK_CHK!" == "INSTALLED" (
		echo.
		echo magisk_patched 부트로더 이미지 생성 중 ... 

		if "!MAGISK_VER!" LSS "!LATEST_MAGISK_VER!" (
			echo.
			echo Magisk 루팅된 상태입니다. 
			echo 안드로이드 업데이트를 진행하시려면 루팅을 해제하시거나 
			echo Magisk 를 !LATEST_MAGISK_VER! 버전으로 업데이트를 진행하신 후에 
			echo 다시 시도해보시기 바랍니다. 
			echo.
			set MAGISK_CHK=
			del /s /q "TEMP\*" >nul
			pause
			goto MENU_CHOICE
		)

		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "cd /data/local/tmp/volte_easy_temp/magisk_tools; ./boot_patch.sh /sdcard/Download/boot.img"
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "mv -f /data/local/tmp/volte_easy_temp/magisk_tools/new-boot.img /sdcard/Download/magisk_patched.img"
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! pull /sdcard/Download/magisk_patched.img TEMP\
		ping -n 3 127.0.0.1 >nul
	)

	:AFTER_OTA_ZIP_PREPARED
	if "!IS_OTA_ZIP!" == "TRUE" (
		REM Do update sideloading method
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! reboot sideload-auto-reboot
		ping -n 7 127.0.0.1 >nul
		platform-tools\adb.exe wait-for-sideload >nul 2>&1
		echo.
		echo 업데이트 적용 중 ... 
		echo.
		echo ^( 업데이트 작업은 시간이 많이 소요됩니다. 기다려주세요. ^) 
		echo.
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! sideload OTA.ZIP_HERE\!OTA_ZIP_FILE_NAME!
		set IS_OTA_ZIP=
		ping -n 10 127.0.0.1 >nul
		echo.
		echo 업데이트를 완료하였습니다. 
		echo.
		pause
		echo.
		goto MENU_CHOICE
	) else (
		REM Do update factory image flashing method in bootloader
		for /f "delims=" %%a in (TEMP\!MODEL!-!LATEST_BUILD!\flash-all.bat) do set FLASH_UPDATE=!FLASH_UPDATE!%%a%NL%

		set FLASH_UPDATE=!FLASH_UPDATE:fastboot=..\..\platform-tools\fastboot.exe!
		set FLASH_UPDATE=!FLASH_UPDATE:fastboot.exe=fastboot.exe -s %%1!
		set FLASH_UPDATE=!FLASH_UPDATE:-w=--skip-reboot!
		set FLASH_UPDATE=!FLASH_UPDATE:echo Press any key to exit...=! 
		set FLASH_UPDATE=!FLASH_UPDATE:pause ^>nul=!
		set FLASH_UPDATE=!FLASH_UPDATE:exit=!

		echo !FLASH_UPDATE! > TEMP\!MODEL!-!LATEST_BUILD!\flash-update.bat 
		echo.
		echo 업데이트 적용을 위해 기기가 곧 자동으로 재시작 됩니다. 
		echo ^ # 전원버튼을 누르지 마십시오. # 
		echo.
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! reboot bootloader
		ping -n 7 127.0.0.1 >nul
		goto BOOTLOADER_MODE
	)
)

:MAGISK_INSTALL
echo.
if "!MAGISK_CHK!" == "NOT_INSTALLED" (
	if "!BOOTLOADER!" == "UNLOCKED" (
		echo # Magisk 루팅 # 
		echo.
		echo 루팅 과정을 진행합니다. 

		echo.
		echo Magisk 앱 설치 중 ... 

		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! install tools\!MAGISK_APK!
		ping -n 7 127.0.0.1 >nul
		echo.
		echo Magisk 앱 설치 완료 
		echo.
	)
)

REM in case of custom ROM like Pixel Experience, Elixir do adb sideload
if "!IS_CUSTOM_ROM!" == "TRUE" (
	echo.
	echo 커스텀 리커버리 설치용 파일 준비 중 ... 
	echo.
	copy /y tools\!MAGISK_APK! TEMP\Magisk-v!LATEST_MAGISK_VER!.zip
	copy /y tools\custom_recovery_boot_patch.sh TEMP\boot_patch.sh
	tools\7za.exe a TEMP\Magisk-v!LATEST_MAGISK_VER!.zip -bsp1 TEMP\boot_patch.sh
	tools\7za.exe d TEMP\Magisk-v!LATEST_MAGISK_VER!.zip -bsp1 assets\boot_patch.sh
	tools\7za.exe rn TEMP\Magisk-v!LATEST_MAGISK_VER!.zip -bsp1 TEMP\boot_patch.sh assets\boot_patch.sh
	echo.
	echo 기기가 곧 자동으로 재시작 됩니다. 
	echo ^ # 전원버튼을 누르지 마십시오. # 
	echo.
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! reboot sideload-auto-reboot
	ping -n 7 127.0.0.1 >nul
	platform-tools\adb.exe wait-for-sideload >nul 2>&1
	echo.
	echo Magisk boot 적용 중 ... 
	echo.
	echo ^( 진행률이 멈춘 것처럼 보여도 정상 진행 중입니다. 10분 이상 무응답인 경우가 아니라면 기다려주세요. ^) 
	echo.
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! sideload TEMP\Magisk-v!LATEST_MAGISK_VER!.zip
	ping -n 3 127.0.0.1 >nul
	echo.
	set MAGISK_CHK=INSTALLING
	echo Magisk boot 적용 완료. 
	echo.
	echo 부팅 중 ... 
	echo ^ # 전원버튼을 누르지 마십시오. # 
	echo.
	ping -n 5 127.0.0.1 >nul
	echo.
	echo.
	echo 기기가 정상 부팅되면 기기의 잠금을 해제 해주세요. 
	echo 잠금 해제 후 아무 키를 입력하여 다음 과정을 진행해주세요. 
	echo.
	pause
	goto ADB_DEVICE_CHECK
)

REM in case of full OTA zip file, magisk supported making boot.img file in payload.bin since v26.2
if "!IS_OTA_ZIP!" == "TRUE" (
	echo.
	echo payload.bin 파일에서 boot.img 추출 중 ... 
	echo.
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "cd /data/local/tmp/volte_easy_temp/magisk_tools; ./magiskboot extract /sdcard/Download/payload.bin"
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "mv /data/local/tmp/volte_easy_temp/magisk_tools/boot.img /sdcard/Download/"
)

REM Stock ROM case, do flashing in bootloader
echo Magisk boot 이미지 생성 중 ... 
echo.
platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "cd /data/local/tmp/volte_easy_temp/magisk_tools; ./boot_patch.sh /sdcard/Download/boot.img"
platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "mv -f /data/local/tmp/volte_easy_temp/magisk_tools/new-boot.img /sdcard/Download/magisk_patched.img"
platform-tools\adb.exe -s !USER_DEVICE_SERIAL! pull /sdcard/Download/magisk_patched.img TEMP\
ping -n 5 127.0.0.1 >nul
echo.
echo Magisk boot 이미지 생성 완료. 
echo.
echo 기기가 곧 자동으로 재시작 됩니다. 
echo ^ # 전원버튼을 누르지 마십시오. # 
echo.
platform-tools\adb.exe -s !USER_DEVICE_SERIAL! reboot bootloader
ping -n 7 127.0.0.1 >nul
goto BOOTLOADER_MODE

:SET_VOLTE
echo.
echo # VoLTE 패치 # 
echo.

echo diag 포트 개방 중 ... 
platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell su -c "resetprop ro.bootmode usbradio"
platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell su -c "resetprop ro.build.type userdebug"
platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell su -c "setprop sys.usb.config diag,diag_mdm,adb"

platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "svc usb setFunctions mtp"
ping -n 3 127.0.0.1 >nul
platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "svc usb setFunctions"
ping -n 3 127.0.0.1 >nul

:DIAG_CONNECTION_CHECK
echo.
echo diag 포트 통신 확인 중 ... 
echo.

set DIAG_STATUS=
EfsTools\EfsTools.exe efsInfo | findstr /b "Version:"
if !errorlevel! == 0 (
	set DIAG_STATUS=CONNECTED
) else (
	set DIAG_STATUS=UNCONNECTED
	echo.
	echo diag 포트 통신 불가. 재확인 중 ... 
	echo.
	ping -n 5 127.0.0.1 >nul
	goto DIAG_CONNECTION_CHECK
)

echo.
echo DIAG_STATUS = !DIAG_STATUS! 
echo.

if not "!CARRIER_SIM1!" == "" (
	if "!CARRIER_SIM1!" == "SIM1_KT_LTE" (
		echo 사용자의 유심 = [KT망] ^(LTE^) 
	) else if "!CARRIER_SIM1!" == "SIM1_KT_5G" (
		echo 사용자의 유심 = [KT망] ^(5G^) 
		set EFS_DELETE_NEED=TRUE
	) else if "!CARRIER_SIM1!" == "SIM1_SKT_LTE" (
		echo 사용자의 유심 = [SKT망] ^(LTE^) 
	) else if "!CARRIER_SIM1!" == "SIM1_SKT_5G" (
		echo 사용자의 유심 = [SKT망] ^(5G^) 
		set EFS_DELETE_NEED=TRUE
	) else if "!CARRIER_SIM1!" == "SIM1_LGU" (
		echo 사용자의 유심 = [LGU플러스망] 
		set EFS_DELETE_NEED=TRUE
	) else (
		echo 알 수 없는 오류가 발생했습니다. ^(CARRIER 확인 불가^) 
		goto QUIT
	)
)

if not "!CARRIER_SIM2!" == "" (
	if "!CARRIER_SIM2!" == "SIM2_KT_LTE" (
		echo 사용자의 eSIM = [KT망] ^(LTE^) 
	) else if "!CARRIER_SIM2!" == "SIM2_KT_5G" (
		echo 사용자의 eSIM = [KT망] ^(5G^) 
		set EFS_DELETE_NEED=TRUE
	) else if "!CARRIER_SIM2!" == "SIM2_SKT_LTE" (
		echo 사용자의 eSIM = [SKT망] ^(LTE^) 
	) else if "!CARRIER_SIM2!" == "SIM2_SKT_5G" (
		echo 사용자의 eSIM = [SKT망] ^(5G^) 
		set EFS_DELETE_NEED=TRUE
	) else if "!CARRIER_SIM2!" == "SIM2_LGU" (
		echo 사용자의 eSIM = [LGU플러스망] 
		set EFS_DELETE_NEED=TRUE
	) else (
		echo 알 수 없는 오류가 발생했습니다. ^(CARRIER 확인 불가^) 
		goto QUIT
	)
)

echo.

if "!EFS_DELETE_NEED!" == "TRUE" (
	echo efs 재설정을 위한 파일 삭제 중 ... ^(속도가 느립니다. 기다려주세요^) 
	REM EfsTools\EfsTools.exe deleteDirectory -p /policyman
	ping -n 2 127.0.0.1 >nul
	EfsTools\EfsTools.exe deleteDirectory -p /nv/item_files/modem/nr5g/RRC >nul
	ping -n 2 127.0.0.1 >nul
	EfsTools\EfsTools.exe deleteDirectory -p /nv/item_files/modem/lte/rrc/efs >nul
	ping -n 2 127.0.0.1 >nul
	echo efs 재설정을 위한 파일 삭제 완료됨. 
	echo.
	set EFS_DELETE_NEED=
)

if not "!CARRIER_SIM1!" == "" (
	echo.
	echo [유심] !CARRIER_SIM1:SIM1_=!망 통신사 efs 파일 업로드 중 ... ^(속도가 느립니다. 기다려주세요^) 
	echo.
	EfsTools\EfsTools.exe uploadDirectory -i efs_files\!CARRIER_SIM1!\data -o /data
	ping -n 2 127.0.0.1 >nul
	EfsTools\EfsTools.exe uploadDirectory -i efs_files\!CARRIER_SIM1!\Data_Profiles -o /Data_Profiles
	ping -n 2 127.0.0.1 >nul
	EfsTools\EfsTools.exe uploadDirectory -i efs_files\!CARRIER_SIM1!\google -o /google
	ping -n 2 127.0.0.1 >nul
	EfsTools\EfsTools.exe uploadDirectory -i efs_files\!CARRIER_SIM1!\nv\item_files\data -o /nv/item_files/data
	ping -n 2 127.0.0.1 >nul
	EfsTools\EfsTools.exe uploadDirectory -i efs_files\!CARRIER_SIM1!\nv\item_files\ims -o /nv/item_files/ims
	ping -n 2 127.0.0.1 >nul
	EfsTools\EfsTools.exe uploadDirectory -i efs_files\!CARRIER_SIM1!\nv\item_files\modem -o /nv/item_files/modem
	ping -n 2 127.0.0.1 >nul
	EfsTools\EfsTools.exe uploadDirectory -i efs_files\!CARRIER_SIM1!\policyman -o /policyman
	ping -n 5 127.0.0.1 >nul
)

if not "!CARRIER_SIM2!" == "" (
	echo.
	echo [eSIM] !CARRIER_SIM2:SIM2_=!망 통신사 efs 파일 업로드 중 ... ^(속도가 느립니다. 기다려주세요^) 
	echo.
	EfsTools\EfsTools.exe uploadDirectory -i efs_files\!CARRIER_SIM2!\data -o /data
	ping -n 2 127.0.0.1 >nul
	EfsTools\EfsTools.exe uploadDirectory -i efs_files\!CARRIER_SIM2!\Data_Profiles -o /Data_Profiles
	ping -n 2 127.0.0.1 >nul
	EfsTools\EfsTools.exe uploadDirectory -i efs_files\!CARRIER_SIM2!\google -o /google
	ping -n 2 127.0.0.1 >nul
	EfsTools\EfsTools.exe uploadDirectory -i efs_files\!CARRIER_SIM2!\nv\item_files\data -o /nv/item_files/data
	ping -n 2 127.0.0.1 >nul
	EfsTools\EfsTools.exe uploadDirectory -i efs_files\!CARRIER_SIM2!\nv\item_files\ims -o /nv/item_files/ims
	ping -n 2 127.0.0.1 >nul
	EfsTools\EfsTools.exe uploadDirectory -i efs_files\!CARRIER_SIM2!\nv\item_files\modem -o /nv/item_files/modem
	ping -n 2 127.0.0.1 >nul
	EfsTools\EfsTools.exe uploadDirectory -i efs_files\!CARRIER_SIM2!\policyman -o /policyman
	ping -n 5 127.0.0.1 >nul
)

echo.
echo efs 파일 업로드 완료됨. 
echo.

REM Set Provisioning VoLTE Andoriod 12 and above case
if "!ANDROID_VERSION!" GEQ "12" (
	if not "!PROVISIONED!" == "1" (
		echo VoLTE 프로비저닝 설정 중 ... 
		set COUNTER_RETRY_PROVISION=0
		:TRY_SET_PROVISIONING
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell su -c "setprop persist.dbg.volte_avail_ovr 1"
		set /a COUNTER_RETRY_PROVISION=!COUNTER_RETRY_PROVISION! + 1
		echo.
		set PROVISIONED=
		for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell /data/local/tmp/volte_easy_temp/parser.sh getprovision') do set PROVISIONED=%%a
		if "!PROVISIONED!" == "1" (
			echo VoLTE 프로비저닝 설정 완료됨. 
		) else (
			if "!COUNTER_RETRY_PROVISION!" == "3" (
				echo VoLTE 프로비저닝 설정되지 않음. 
				echo "전화"-"다이얼"-"*#*#4636#*#*"-"휴대전화 정보"에서 
				echo "VoLTE 프로비저닝됨" [켜짐] 상태를 직접 확인해보시기 바랍니다. 
			) else (
				goto TRY_SET_PROVISIONING
			)
		)
	)
)

if "!KEEP_ROOT!" == "FALSE" (
	goto UNROOT
) else (
	goto QUIT
)

:DO_PIXEL_FIRST_GEN_VOLTE
if "!BUILD!" == "qp1a.191005.007.a3" (
	echo.
	echo # VoLTE 패치 ^(픽셀 1세대용^) # 
	echo.
	echo 1세대 픽셀 기기의 VoLTE 패치를 위한 modem.img 파일을 다운로드 받는 중 ... 
	echo.
	tools\curl.exe "https://raw.githubusercontent.com/pixel-volte-easy-bootimg/pixel1_modem_img/main/01_modem-190403.zip" -o "TEMP\01_modem-190403.zip"
	tools\curl.exe "https://raw.githubusercontent.com/pixel-volte-easy-bootimg/pixel1_modem_img/main/02_modem-190527-mix-eu.zip" -o "TEMP\02_modem-190527-mix-eu.zip"
	tools\curl.exe "https://raw.githubusercontent.com/pixel-volte-easy-bootimg/pixel1_modem_img/main/03_modem-190527.zip" -o "TEMP\03_modem-190527.zip"

	echo.
	echo.
	echo 압축을 해제하는 중 ... 
	echo.
	tools\7za.exe x "TEMP\01_modem-190403.zip" -bsp1 -oTEMP\
	tools\7za.exe x "TEMP\02_modem-190527-mix-eu.zip" -bsp1 -oTEMP\
	tools\7za.exe x "TEMP\03_modem-190527.zip" -bsp1 -oTEMP\

	echo.
	echo modem 파일 준비 완료됨. 
	echo modem 재설정을 위해 기기를 재시작합니다. 
	echo.
	echo.
	echo 기기를 몇차례 재시작하므로 안내드리기 전까지 
	echo 잠시 기기의 USB 케이블을 연결한 상태로 기다려주시기 바랍니다. 
	echo.

	ping -n 5 127.0.0.1 >nul
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! reboot bootloader
	ping -n 5 127.0.0.1 >nul
	echo modem 파일 플래싱 중 ... [ 1/3 ] 
	echo.
	platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! flash modem TEMP\01_modem-190403.img
	platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! reboot
	echo 정상 부팅 후 안정화 대기중 ... [ 1/3 ] 
	ping -n 50 127.0.0.1 >nul
	echo.
	echo.

	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! reboot bootloader
	ping -n 5 127.0.0.1 >nul
	echo modem 파일 플래싱 중 ... [ 2/3 ] 
	echo.
	platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! flash modem TEMP\02_modem-190527-mix-eu.img
	platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! reboot
	echo 정상 부팅 후 안정화 대기중 ... [ 2/3 ] 
	ping -n 50 127.0.0.1 >nul
	echo.
	echo.

	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! reboot bootloader
	ping -n 5 127.0.0.1 >nul
	echo modem 파일 플래싱 중 ... [ 3/3 ] 
	echo.
	platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! flash modem TEMP\03_modem-190527.img
	platform-tools\fastboot.exe -s !USER_DEVICE_SERIAL! reboot
	echo 정상 부팅 후 안정화 대기중 ... [ 3/3 ] 
	ping -n 30 127.0.0.1 >nul

	echo.
	echo VoLTE 패치가 완료되었습니다. 
	echo.
	goto QUIT
) else (
	echo 본 프로그램에서는 픽셀 1세대^(Pixel, Pixel XL^)에 대하여 
	echo 안드로이드 10 최신 업데이트를 적용한 경우에만 VoLTE 패치를 지원하고 있습니다. 
	echo.
	set DO_UPDATE_CHK=
	echo ============================================================ 
	echo.
	echo "Enter"^(또는 "Y"^) 를 입력하시면 업데이트 확인으로 돌아가며, 
	echo "M" 을 입력하시면 초기 메뉴로 돌아가고, 
	echo "Q" 를 입력하시면 프로그램을 종료합니다. 
	echo.
	echo ============================================================ 
	echo.
	set /p DO_UPDATE_CHK=업데이트를 진행 하시겠습니까? [Y/M/Q]%NL%%NL%: 

	if /i "!DO_UPDATE_CHK!" == "y" (
		goto UPDATE_CHECK
	) else if "!DO_UPDATE_CHK!" == "" (
		goto UPDATE_CHECK
	) else if /i "!DO_UPDATE_CHK!" == "m" (
		goto MENU_CHOICE
	) else if /i "!DO_UPDATE_CHK!" == "q" (
		goto QUIT
	) else (
		echo 잘못된 입력입니다. 
		goto QUIT
	)
)

:UNROOT
echo.
echo # 루팅 해제 # 
echo.

set MAGISK_PKG=
for /f %%a in ('platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell su -c /data/local/tmp/volte_easy_temp/parser.sh getmagiskpkg') do set MAGISK_PKG=%%a
if "!MAGISK_PKG!" == "" (
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell pm list packages | findstr "com.topjohnwu.magisk"
	if !errorlevel! == 0 (
		set MAGISK_PKG=com.topjohnwu.magisk
		goto UNROOT_EXEC
	) else (
		echo.
		echo Magisk 앱을 찾을 수 없습니다. 
		echo 사용자가 Magisk 앱을 임의로 삭제한 경우 등으로 판단되므로 
		echo 루팅 해제를 위해서는 Magisk 앱을 재설치 하신 이후, 
		echo 직접 Magisk 앱에서 'Magisk 제거'-'완전히 제거'를 눌러 
		echo 루팅을 해제하시기 바랍니다. 
		echo.
		pause
		goto MENU_CHOICE
	)
) else (
	platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell pm list packages | findstr "!MAGISK_PKG!"
	if !errorlevel! == 0 (
		:UNROOT_EXEC
		echo.
		echo Magisk 관련 파일 삭제 중 ... 
		echo.
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell su -c "/data/local/tmp/volte_easy_temp/magisk_tools/custom_uninstaller.sh"
		ping -n 5 127.0.0.1 >nul
		echo.
		echo Magisk 앱 삭제 중 ... 
		echo.
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell pm uninstall !MAGISK_PKG!
		set MAGISK_CHK=
		set KEEP_ROOT=
		echo.
		echo 루팅 해제를 위한 기기 재시작 중 ... 
		echo ^ # 전원버튼을 누르지 마십시오. # 
		echo.
		echo 루팅 해제 과정이 완료되었습니다. 
		echo.
		if "!CHOSEN_MENU!" == "1" (
			platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "rm -f /sdcard/Download/boot.img /sdcard/Download/magisk_patched.img" >nul 2>&1
			platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "rm -rf /data/local/tmp/volte_easy_temp" >nul 2>&1
			platform-tools\adb.exe -s !USER_DEVICE_SERIAL! reboot
			pause
			goto QUIT
		) else (
			platform-tools\adb.exe -s !USER_DEVICE_SERIAL! reboot
			pause
			goto MENU_CHOICE
		)
	)
)


:QUIT
rmdir /s /q TEMP >nul 2>&1

dir BOOT.IMG_HERE | findstr "boot.img" >nul 2>&1
if !errorlevel! == 0 (
	echo ============================================================ 
	echo.
	echo "Enter"^(또는 "Y"^) 를 입력하시면 BOOT.IMG_HERE 폴더의 
	echo boot.img 파일을 삭제 처리하며, 
	echo "N" 을 입력하시면 삭제하지 않고 유지합니다. 
	echo ^( 삭제를 권장합니다 ^) 
	echo.
	echo ============================================================ 
	echo.
	set /p DEL_BOOT_IMG_CHK=boot.img 파일을 삭제하시겠습니까? [Y/N]%NL%%NL%: 
	if /i "!DEL_BOOT_IMG_CHK!" == "y" (
		del /s /q "BOOT.IMG_HERE\*" >nul
	) else if /i "!DEL_BOOT_IMG_CHK!" == "n" (
		echo.
	) else (
		del /s /q  BOOT.IMG_HERE\boot.img >nul 2>&1
	)
)

dir OTA.ZIP_HERE | findstr ".*.zip" >nul 2>&1
if !errorlevel! == 0 (
	echo ============================================================ 
	echo.
	echo "Enter"^(또는 "Y"^) 를 입력하시면 OTA.ZIP_HERE 폴더의 
	echo OTA 압축파일을 삭제 처리하며, 
	echo "N" 을 입력하시면 삭제하지 않고 유지합니다. 
	echo ^( 삭제를 권장합니다 ^) 
	echo.
	echo ============================================================ 
	echo.
	set /p DEL_OTA_ZIP_CHK=OTA 파일을 삭제하시겠습니까? [Y/N]%NL%%NL%: 
	if /i "!DEL_OTA_ZIP_CHK!" == "y" (
		del /s /q "OTA.ZIP_HERE\*" >nul
	) else if /i "!DEL_OTA_ZIP_CHK!" == "n" (
		echo.
	) else (
		del /s /q OTA.ZIP_HERE\* >nul
	)
)

dir FACTORY.ZIP_HERE | findstr ".*-factory-.*.zip" >nul 2>&1
if !errorlevel! == 0 (
	echo ============================================================ 
	echo.
	echo "Enter"^(또는 "Y"^) 를 입력하시면 FACTORY.ZIP_HERE 폴더의 
	echo 팩토리 이미지 압축파일을 삭제 처리하며, 
	echo "N" 을 입력하시면 삭제하지 않고 유지합니다. 
	echo ^( 삭제를 권장합니다 ^) 
	echo.
	echo ============================================================ 
	echo.
	set /p DEL_FACTORY_ROM_CHK=팩토리 이미지를 삭제하시겠습니까? [Y/N]%NL%%NL%: 
	if /i "!DEL_FACTORY_ROM_CHK!" == "y" (
		del /s /q "FACTORY.ZIP_HERE\*" >nul
	) else if /i "!DEL_FACTORY_ROM_CHK!" == "n" (
		echo.
	) else (
		del /s /q FACTORY.ZIP_HERE\* >nul
	)
)

platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "rm -f /sdcard/Download/boot.img /sdcard/Download/magisk_patched.img /sdcard/Download/payload.bin" >nul 2>&1
platform-tools\adb.exe -s !USER_DEVICE_SERIAL! shell "rm -rf /data/local/tmp/volte_easy_temp" >nul 2>&1

REM Need reboot to activate VoLTE patch
if "!CHOSEN_MENU!" == "1" (
	echo.
	echo VoLTE 패치가 완료되었습니다. 
	echo.
	if "!KEEP_ROOT!" == "TRUE" (
		goto REBOOT
	) else if "!MAGISK_CHK!" == "INSTALLED" (
		:REBOOT
		echo.
		echo 적용을 위해 기기가 곧 자동으로 재시작 됩니다. 
		echo ^ # 전원버튼을 누르지 마십시오. # 
		echo.
		platform-tools\adb.exe -s !USER_DEVICE_SERIAL! reboot
	) else (
		echo.
		echo *주의* 루팅을 해제하시는 경우 '개발자 옵션'의 '자동 시스템 업데이트'의 체크를 
		echo 해제하시는 것을 권장드립니다. 
		echo 해당 옵션의 활성화로 인해 시스템이 자동 업데이트 되면 
		echo VoLTE 패치가 해제될 수 있습니다. 
		echo.
	)
)

echo.
echo 프로그램을 종료합니다. 
platform-tools\adb.exe kill-server >nul 2>&1
echo.
pause
exit
