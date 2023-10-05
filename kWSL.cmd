@ECHO OFF & NET SESSION >NUL 2>&1 
REM ---  mkdir /var/run/dbus ; wget https://github.com/gdraheim/docker-systemctl-replacement/raw/master/files/docker/systemctl3.py -O /usr/bin/systemctl
IF %ERRORLEVEL% == 0 (ECHO Administrator check passed...) ELSE (ECHO You need to run this command with administrative rights.  Is User Account Control enabled? && pause && goto ENDSCRIPT)
COLOR 1F
SET GITORG=DesktopECHO
SET GITPRJ=kWSL
SET BRANCH=master
SET BASE=https://github.com/%GITORG%/%GITPRJ%/raw/%BRANCH%

REM ## Enable WSL if required
POWERSHELL -Command "$WSL = Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' ; if ($WSL.State -eq 'Disabled') {Enable-WindowsOptionalFeature -FeatureName $WSL.FeatureName -Online}"

REM ## Find system DPI setting and get installation parameters
IF NOT EXIST "%TEMP%\windpi.ps1" POWERSHELL.EXE -ExecutionPolicy Bypass -Command "wget '%BASE%/windpi.ps1' -UseBasicParsing -OutFile '%TEMP%\windpi.ps1'"
FOR /f "delims=" %%a in ('powershell -ExecutionPolicy bypass -command "%TEMP%\windpi.ps1" ') do set "WINDPI=%%a"
:DI
CLS && SET RUNSTART=%date% @ %time:~0,5%
IF EXIST .\CMD.EXE CD ..\..

ECHO [kWSL Installer 20220921]
ECHO:
ECHO Set a name for this KDE Desktop.  Hit Enter to use default. 
SET DISTRO=kWSL& SET /p DISTRO=Keep this name simple, no space or underscore characters [kWSL]: 
IF EXIST "%DISTRO%" (ECHO. & ECHO Folder exists with that name, choose a new folder name. & PAUSE & GOTO DI)
WSL.EXE -d %DISTRO% -e . > "%TEMP%\InstCheck.tmp"
FOR /f %%i in ("%TEMP%\InstCheck.tmp") do set CHKIN=%%~zi 
IF %CHKIN% == 0 (ECHO. & ECHO There is a WSL distribution registered with that name; uninstall it or choose a new name. & PAUSE & GOTO DI)
SET RDPPRT=3399& SET /p RDPPRT=Port number for xRDP traffic or hit Enter to use default [3399]: 
SET SSHPRT=3322& SET /p SSHPRT=Port number for SSHd traffic or hit Enter to use default [3322]: 
                 SET /p WINDPI=Set a custom DPI scale, or hit Enter for Windows default [%WINDPI%]: 
FOR /f "delims=" %%a in ('PowerShell -Command "%WINDPI% * 96" ') do set "LINDPI=%%a"
FOR /f "delims=" %%a in ('PowerShell -Command 40 * "%WINDPI%" ') do set "KPANEL=%%a"
SET DEFEXL=NONO& SET /p DEFEXL=[Not recommended!] Type X to eXclude from Windows Defender: 
SET DISTROFULL=%CD%\%DISTRO%
SET /A SESMAN = %RDPPRT% - 1
SET _rlt=%DISTROFULL:~2,2%
IF "%_rlt%"=="\\" SET DISTROFULL=%CD%%DISTRO%
SET GO="%DISTROFULL%\LxRunOffline.exe" r -n "%DISTRO%" -c
REM ## Download Ubuntu and install packages
IF NOT EXIST "%TEMP%\centos8-stream-amd64.tar.gz" POWERSHELL.EXE -Command "Start-BitsTransfer -source https://github.com/DesktopECHO/wsl-images/releases/download/v1.0/centos8-stream-amd64.tar.gz -destination '%TEMP%\centos8-stream-amd64.tar.gz'"
%DISTROFULL:~0,1%: & MKDIR "%DISTROFULL%" & CD "%DISTROFULL%" & MKDIR logs > NUL
(ECHO [kWSL Inputs] && ECHO. && ECHO.   Distro: %DISTRO% && ECHO.     Path: %DISTROFULL% && ECHO. RDP Port: %RDPPRT% && ECHO. SSH Port: %SSHPRT% && ECHO.DPI Scale: %WINDPI% && ECHO.) > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% kWSL Inputs.log"
IF NOT EXIST "%TEMP%\LxRunOffline.exe" POWERSHELL.EXE -Command "wget %BASE%/LxRunOffline.exe -UseBasicParsing -OutFile '%TEMP%\LxRunOffline.exe'"
ECHO:
ECHO @COLOR 1F                                                                                                >  "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @ECHO Uninstall %DISTRO%?                                                                                >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @PAUSE                                                                                                   >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @COPY /Y "%DISTROFULL%\LxRunOffline.exe" "%APPDATA%"                                                     >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @POWERSHELL -Command "Remove-Item ([Environment]::GetFolderPath('Desktop')+'\%DISTRO% (*) Console.cmd')" >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @POWERSHELL -Command "Remove-Item ([Environment]::GetFolderPath('Desktop')+'\%DISTRO% (*) Desktop.rdp')" >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @SCHTASKS /Delete /TN:%DISTRO% /F                                                                        >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @CLS                                                                                                     >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @ECHO Uninstalling %DISTRO%, please wait...                                                              >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @CD ..                                                                                                   >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @WSLCONFIG /T %DISTRO%                                                                                   >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @"%APPDATA%\LxRunOffline.exe" ur -n %DISTRO%                                                             >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% xRDP"                                                >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"   
ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% Secure Shell"                                        >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% KDE Connect"                                         >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% KDEinit"                                             >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @RD /S /Q "%DISTROFULL%"                                                                                 >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO Installing kWSL Distro [%DISTRO%] to "%DISTROFULL%" & ECHO This will take a few minutes, please wait... 
IF %DEFEXL%==X (POWERSHELL.EXE -Command "wget %BASE%/excludeWSL.ps1 -UseBasicParsing -OutFile '%DISTROFULL%\excludeWSL.ps1'" & START /WAIT /MIN "Add exclusions in Windows Defender" "POWERSHELL.EXE" "-ExecutionPolicy" "Bypass" "-Command" ".\excludeWSL.ps1" "%DISTROFULL%" &  DEL ".\excludeWSL.ps1")
ECHO:& ECHO [%TIME:~0,8%] Importing distro userspace (~0m15s)
START /WAIT /MIN "Installing Distro Base..." "%TEMP%\LxRunOffline.exe" "i" "-n" "%DISTRO%" "-f" "%TEMP%\centos8-stream-amd64.tar.gz" "-d" "%DISTROFULL%"
(FOR /F "usebackq delims=" %%v IN (`PowerShell -Command "whoami"`) DO set "WAI=%%v") & ICACLS "%DISTROFULL%" /grant "%WAI%":(CI)(OI)F > NUL
(COPY /Y "%TEMP%\LxRunOffline.exe" "%DISTROFULL%" > NUL ) & "%DISTROFULL%\LxRunOffline.exe" sd -n "%DISTRO%"
ECHO [%TIME:~0,8%] Installing RPM packages (~5m00s)

START /MIN /WAIT "Git" %GO% "rpm -i --nodeps --force https://github.com/DesktopECHO/kWSL/raw/master/Packages/WSL1/git-core-2.39.3-1.el8.x86_64.rpm ; git clone --depth=1 https://github.com/DesktopECHO/kWSL.git /kWSL"
START /MIN /WAIT "WSL1 Fixup" %GO% "rpm -Uvh --nodeps /kWSL/Packages/CentOS/glibc-common-2.28-236.el8.6.x86_64.rpm ; rpm -Uvh --nodeps /kWSL/Packages/CentOS/glibc-2.28-236.el8.6.x86_64.rpm ; rm -rf /var/lib/rpm/.rpm.lock ;  rpm -Uvh --nodeps /kWSL/Packages/CentOS/dnf-4.7.0-19.el8.noarch.rpm"
START /MIN /WAIT "RPM Package Install" %GO% "dnf --setopt=install_weak_deps=False --disablerepo=* -y install /kWSL/Packages/CentOS/*.rpm /kWSL/Packages/WSL1/plasma-systemsettings-5.24.7-2.el8.x86_64.rpm /kWSL/Packages/WSL1/kinfocenter-5.24.7-2.el8.x86_64.rpm"

%GO% "/bin/cp /kWSL/Packages/WSL1/systemctl /usr/bin/systemctl"
%GO% "mkdir -p /etc/skel/.config ; chmod 700 /etc/skel/.config"
%GO% "printf '[super-user-command]\nsuper-user-command=sudo\n' > /etc/skel/.config/kdesurc"
%GO% "printf '[KSplash]\nTheme=None\nEngine=None\n' > /etc/skel/.config/ksplashrc"
%GO% "printf 'export NO_AT_BRIDGE=1\nexport LIBXCB_ALLOW_SLOPPY_LOCK=1\nexport MOZ_FORCE_DISABLE_E10S=1\nexport MOZ_LAYERS_ALLOW_SOFTWARE_GL=1\nexport QT_X11_NO_MITSHM=1\nexport QT_ACCESSIBILITY=0\nexport XDG_SESSION_TYPE=x11\nexport DESKTOP_SESSION=plasma\nexport XDG_SESSION_DESKTOP=KDE\nexport XDG_CURRENT_DESKTOP=KDE\nexport XDG_CONFIG_HOME=$HOME/.config\nexport XDG_RUNTIME_DIR=$HOME/.local\nexport XDG_CACHE_HOME=$HOME/.cache\nexport XDG_DATA_HOME=$HOME/.local/share\nexport KDE_FULL_SESSION=true\nexport KDE_SESSION_VERSION=5\nexport QTWEBENGINE_CHROMIUM_FLAGS="--single-process"\n' > /etc/profile.d/kWSL.sh ; chmod 644 /etc/profile.d/kWSL.sh"
%GO% "sed -i 's/ListenPort=3350/ListenPort=%SESMAN%/g' /etc/xrdp/sesman.ini"
%GO% "sed -i 's/port=3389/port=%RDPPRT%/g' /etc/xrdp/xrdp.ini"
%GO% "chmod -x /usr/libexec/kscreenlocker_greet /usr/libexec/drkonqi"
%GO% "useradd -m zero ; passwd zero ; usermod -aG wheel zero"
%GO% "systemctl start xrdp xrdp-sesman ; systemctl status xrdp xrdp-sesman | grep 'daemon\|active'"
