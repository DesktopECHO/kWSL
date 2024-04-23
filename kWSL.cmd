@ECHO OFF & NET SESSION >NUL 2>&1
IF %ERRORLEVEL% == 0 (ECHO Administrator check passed...) ELSE (ECHO You need to run this command with administrative rights.  Is User Account Control enabled? && pause && goto ENDSCRIPT)
COLOR 1F
SET WSLREV=20240423
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

ECHO [KDE Neon 6 Installer for WSL v.%WSLREV%]
ECHO:
ECHO Set a name for this KDE Neon instance.  Hit Enter to use default.
SET DISTRO=Neon& SET /p DISTRO=Keep this name simple, no space or underscore characters [Neon]: 
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
SET _rlt=%DISTROFULL:~2,2%
IF "%_rlt%"=="\\" SET DISTROFULL=%CD%%DISTRO%
SET GO="%DISTROFULL%\LxRunOffline.exe" r -n "%DISTRO%" -c
REM ## Download Ubuntu and install packages
IF NOT EXIST "%TEMP%\neon-6.0.4-amd64.tar.gz" POWERSHELL.EXE -Command "Start-BitsTransfer -source https://github.com/DesktopECHO/wsl-images/releases/download/v1.0/neon-6.0.4-amd64.tar.gz -destination '%TEMP%\neon-6.0.4-amd64.tar.gz'"
%DISTROFULL:~0,1%: & MKDIR "%DISTROFULL%" & CD "%DISTROFULL%" & MKDIR logs > NUL
(ECHO [kWSL Inputs] && ECHO. && ECHO.   Distro: %DISTRO% && ECHO.     Path: %DISTROFULL% && ECHO. RDP Port: %RDPPRT% && ECHO. SSH Port: %SSHPRT% && ECHO.DPI Scale: %WINDPI% && ECHO.) > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% kWSL Inputs.log"
IF NOT EXIST "%TEMP%\LxRunOffline.exe" POWERSHELL.EXE -Command "wget %BASE%/LxRunOffline.exe -UseBasicParsing -OutFile '%TEMP%\LxRunOffline.exe'"
ECHO:
ECHO @COLOR 1F                                                                                                >  "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @ECHO Ensure you are running this command with elevated rights.  Uninstall %DISTRO%?                     >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @PAUSE                                                                                                   >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @COPY /Y "%DISTROFULL%\LxRunOffline.exe" "%APPDATA%"                                                     >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @POWERSHELL -Command "Remove-Item ([Environment]::GetFolderPath('Desktop')+'\%DISTRO% (*) Console.cmd')" >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @POWERSHELL -Command "Remove-Item ([Environment]::GetFolderPath('Desktop')+'\%DISTRO% (*) Desktop.rdp')" >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @SCHTASKS /Delete /TN:%DISTRO% /F                                                                        >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @CLS                                                                                                     >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @ECHO Uninstalling %DISTRO%, please wait...                                                              >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @CD ..                                                                                                   >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @WSLCONFIG.EXE /t %DISTRO% ^&^& WSL.EXE --unregister %DISTRO%                                            >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @"%APPDATA%\LxRunOffline.exe" ur -n %DISTRO%                                                             >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% xRDP"                                                >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% Secure Shell"                                        >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% KDE Connect"                                         >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% KDEinit"                                             >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% DBUS Daemon"                                         >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @RD /S /Q "%DISTROFULL%"                                                                                 >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO Installing kWSL Distro [%DISTRO%] to "%DISTROFULL%" & ECHO This will take a few minutes, please wait...
IF %DEFEXL%==X (POWERSHELL.EXE -Command "wget %BASE%/excludeWSL.ps1 -UseBasicParsing -OutFile '%DISTROFULL%\excludeWSL.ps1'" & START /WAIT /MIN "Add exclusions in Windows Defender" "POWERSHELL.EXE" "-ExecutionPolicy" "Bypass" "-Command" ".\excludeWSL.ps1" "%DISTROFULL%" &  DEL ".\excludeWSL.ps1")
ECHO:& ECHO [%TIME:~0,8%] Importing distro userspace (~2m00s)
START /WAIT /MIN "Installing Distro Base..." "%TEMP%\LxRunOffline.exe" "i" "-n" "%DISTRO%" "-f" "%TEMP%\neon-6.0.4-amd64.tar.gz" "-d" "%DISTROFULL%"
(FOR /F "usebackq delims=" %%v IN (`PowerShell -Command "whoami"`) DO set "WAI=%%v") & ICACLS "%DISTROFULL%" /grant "%WAI%":(CI)(OI)F > NUL
(COPY /Y "%TEMP%\LxRunOffline.exe" "%DISTROFULL%" > NUL ) & "%DISTROFULL%\LxRunOffline.exe" sd -n "%DISTRO%"
ECHO [%TIME:~0,8%] Git clone and update repositories (~1m00s)
%GO% "echo 'deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe' > /etc/apt/sources.list"
%GO% "echo 'deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe' >> /etc/apt/sources.list"
%GO% "echo 'deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe' >> /etc/apt/sources.list"
%GO% "echo 'deb http://archive.neon.kde.org/user/ jammy main' >  /etc/apt/sources.list.d/neon.list"
%GO% "rm -rf /etc/apt/apt.conf.d/20snapd.conf /etc/rc2.d/S01whoopsie /etc/init.d/console-setup.sh"

:APTRELY
START /MIN /WAIT "Git Clone kWSL" %GO% "cd /tmp ; rm -rf kWSL ; git clone -b %BRANCH% --depth=1 https://github.com/%GITORG%/%GITPRJ%.git ; cp /tmp/kWSL/keyrings/*.gpg /etc/apt/trusted.gpg.d/"
START /MIN /WAIT "apt-get update" %GO% "apt-get update 2> /tmp/apterr"
FOR /F %%A in ("%DISTROFULL%\rootfs\tmp\apterr") do If %%~zA NEQ 0 GOTO APTRELY
START /MIN /WAIT "apt-get update" %GO% "add-apt-repository -y ppa:videolan/master-daily 2>> /tmp/apterr"
START /MIN /WAIT "apt-fast" %GO% "DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/kWSL/deb/aria2*.deb /tmp/kWSL/deb/libaria2-0*.deb /tmp/kWSL/deb/libssh2-1*.deb /tmp/kWSL/deb/libc-ares2*.deb ; chmod +x /tmp/kWSL/dist/usr/local/bin/apt-fast ; cp -p /tmp/kWSL/dist/usr/local/bin/apt-fast /usr/local/bin" > NUL

ECHO [%TIME:~0,8%] CRD, VLC 4 (~1m00s)
%GO% "RUNLEVEL=1 DEBIAN_FRONTEND=noninteractive apt-fast -qqy --allow-downgrades --allow-change-held-packages install /tmp/kWSL/deb/*.deb ssh vlc vlc-plugin-access-extra vlc-l10n vlc-plugin-notify vlc-plugin-qt vlc-plugin-samba vlc-plugin-skins2 vlc-plugin-video-splitter vlc-plugin-visualization vlc-plugin-access-extra vlc-plugin-svg libvncclient1 --no-install-recommends ; cd /tmp/kWSL/deb ; wget -q https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb ; apt-get -qy install pcmanfm /tmp/kWSL/deb/chrome-remote-desktop_current_amd64.deb" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Web Browser CRD VLC4.log" 2>&1

REM ## Additional items to install can go here...
REM ## %GO% "cd /tmp ; wget https://files.multimc.org/downloads/multimc_1.4-1.deb"
REM ## %GO% "apt-get -y install supertuxkart /tmp/multimc_1.4-1.deb"

ECHO [%TIME:~0,8%] Cleaning-up... (~0m15s)
%GO% "rm -f /var/lib/dbus/machine-id ; dbus-uuidgen --ensure ; make-ssl-cert generate-default-snakeoil --force-overwrite ; apt-get -qqy purge --autoremove apport-symptoms* libplymouth5* python3-apport* python3-problem-report* python3-systemd* ubuntu-advantage-tools* ubuntu-pro-client-l10n* update-manager-core* ; apt-get -y clean" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Final clean-up.log"

%GO% "which schtasks.exe" > "%TEMP%\SCHT.tmp" & set /p SCHT=<"%TEMP%\SCHT.tmp"
REM %GO% "sed -i 's/Exec=systemsettings5/Exec=systemsettings5 ./g' /usr/share/applications/kdesystemsettings.desktop"
REM %GO% "sed -i 's/Exec=systemsettings/Exec=systemsettings ./g' /usr/share/applications/systemsettings.desktop"
REM %GO% "sed -i 's/Exec=systemsettings/Exec=systemsettings ./g' /usr/share/kglobalaccel/systemsettings.desktop"

%GO% "grep -rl Exec=plasma-discover /usr/share/applications | xargs sed -i 's#Exec=plasma-discover#Exec=gksudo -k /usr/local/bin/plasma-discover-root#'"
%GO% "sed -i 's#SCHT#%SCHT%#g' /tmp/kWSL/dist/usr/local/bin/restartwsl ; sed -i 's#DISTRO#%DISTRO%#g' /tmp/kWSL/dist/usr/local/bin/restartwsl"
%GO% "sed -i 's/QQQ/%WINDPI%/g' /tmp/kWSL/dist/etc/skel/.config/kdeglobals"
%GO% "sed -i 's/QQQ/%LINDPI%/g' /tmp/kWSL/dist/etc/skel/.config/kcmfonts"
%GO% "sed -i 's/thinclient_drives/.kWSL/g' /etc/xrdp/sesman.ini"
%GO% "sed -i 's/port=3389/port=%RDPPRT%/g' /tmp/kWSL/dist/etc/xrdp/xrdp.ini ; cp /tmp/kWSL/dist/etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini"
%GO% "sed -i 's/#Port 22/Port %SSHPRT%/g' /etc/ssh/sshd_config"
%GO% "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
%GO% "sed -i 's/WSLINSTANCENAME/%DISTRO%/g' /tmp/kWSL/dist/usr/local/bin/initwsl"
%GO% "sed -i 's/\\h/%DISTRO%/g' /tmp/kWSL/dist/etc/skel/.bashrc"
%GO% "cp /mnt/c/Windows/Fonts/*.ttf /usr/share/fonts/truetype ; ln -s /usr/share/plasma/desktoptheme/breeze-light /usr/share/plasma/desktoptheme/breeze"
%GO% "ssh-keygen -A ; adduser xrdp ssl-cert" > NUL
%GO% "chmod 644 /tmp/kWSL/dist/etc/wsl.conf"
%GO% "echo 'exit 0' > /usr/lib/x86_64-linux-gnu/utempter/utempter"
REM %GO% "sed -i 's$<listen>.*</listen>$<listen>tcp:host=localhost,bind=*,port=15373,family=ipv4</listen>$' /usr/share/dbus-1/session.conf"
REM %GO% "sed -i 's$<auth>EXTERNAL</auth>$<auth>EXTERNAL</auth>\n  <auth>ANONYMOUS</auth>\n  <allow_anonymous/>$' /usr/share/dbus-1/session.conf"
%GO% "chmod 755 /tmp/kWSL/dist/usr/local/bin/* ; cp /tmp/kWSL/dist/usr/local/bin/restartwsl /tmp/kWSL/dist/etc/skel/.config/plasma-workspace/shutdown/restartwsl ; chmod -R 700 /tmp/kWSL/dist/etc/skel/.config ; chmod -R 7700 /tmp/kWSL/dist/etc/skel/.local ; chmod -R 7700 /tmp/kWSL/dist/etc/skel/.cache ; chmod 700 /tmp/kWSL/dist/etc/skel/.mozilla"
%GO% "chmod 755 /tmp/kWSL/dist/etc/profile.d/kWSL.sh ; chmod +x /tmp/kWSL/dist/etc/profile.d/kWSL.sh ; printf '#!/bin/bash' > /etc/xrdp/startwm.sh ; printf '\n. /etc/profile\ndbus-run-session startplasma-x11 >~/session.log 2>&1\n' >> /etc/xrdp/startwm.sh ; chmod +x /etc/xrdp/startwm.sh"
%GO% "unamestr=`uname -r` ; if [[ "$unamestr" == '4.4.0-17763-Microsoft' ]]; then apt-get purge -y plasma-discover ; sed -i 's/discover/muon/g' /tmp/kWSL/dist/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc ; ln -s /usr/bin/software-properties-qt /usr/bin/software-properties-kde ; fi" > NUL
%GO% "cp -Rp /tmp/kWSL/dist/* / ; cp -Rp /tmp/kWSL/dist/etc/skel/.cache /root ; cp -Rp /tmp/kWSL/dist/etc/skel/.config /root ; cp -Rp /tmp/kWSL/dist/etc/skel/.local /root ; cp /tmp/kWSL/dist/etc/init.d/xrdp /etc/init.d/ ; chmod +x /etc/init.d/xrdp ; update-rc.d -f xrdp defaults ; chmod +x /usr/local/bin/* "
%GO% "apt-mark hold kactivitymanagerd libkf6activitiesstats1 libpulse0 plasma-activities-stats pulseaudio qt6-webengine qt6-webview" > NUL
SET RUNEND=%date% @ %time:~0,5%
CD %DISTROFULL%
ECHO:
SET /p XU=Enter name of primary user for %DISTRO%: 
POWERSHELL -Command $prd = read-host "Enter password for %XU%" -AsSecureString ; $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($prd) ; [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) > .tmp & set /p PWO=<.tmp
%GO% "useradd -m -p nulltemp -s /bin/bash %XU%"
%GO% "(echo '%XU%:%PWO%') | chpasswd"
%GO% "echo '%XU% ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
%GO% "sed -i 's/PLACEHOLDER/%XU%/g' /tmp/kWSL/kWSL.rdp"
%GO% "sed -i 's/COMPY/LocalHost/g' /tmp/kWSL/kWSL.rdp"
%GO% "sed -i 's/RDPPRT/%RDPPRT%/g' /tmp/kWSL/kWSL.rdp"
%GO% "cp /tmp/kWSL/kWSL.rdp ./kWSL._"
ECHO $prd = Get-Content .tmp > .tmp.ps1
ECHO ($prd ^| ConvertTo-SecureString -AsPlainText -Force) ^| ConvertFrom-SecureString ^| Out-File .tmp >> .tmp.ps1
POWERSHELL -ExecutionPolicy Bypass -Command ./.tmp.ps1
TYPE .tmp>.tmpsec.txt
COPY /y /b kWSL._+.tmpsec.txt "%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp" > NUL
DEL /Q kWSL._ .tmp*.* > NUL
%GO% "sudo -u %XU% bash -c 'gconftool-2 --set "/apps/gksu/disable-grab" --type bool "true" ; gconftool-2 --set "/apps/gksu/sudo-mode" --type bool "true"'"
%GO% "sudo -u %XU% bash -c 'xdg-mime default pcmanfm.desktop inode/directory'"
ECHO:
ECHO Open Windows Firewall Ports for xRDP, SSH, mDNS...
NETSH AdvFirewall Firewall add rule name="%DISTRO% xRDP" dir=in action=allow protocol=TCP localport=%RDPPRT% > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% Secure Shell" dir=in action=allow protocol=TCP localport=%SSHPRT% > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% KDE Connect" dir=in action=allow program="%DISTROFULL%\rootfs\usr\lib\x86_64-linux-gnu\libexec\kdeconnectd" enable=yes > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% KDEinit" dir=in action=allow program="%DISTROFULL%\rootfs\usr\bin\kdeinit5" enable=yes > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% DBUS Daemon" dir=in action=allow program="%DISTROFULL%\rootfs\usr\bin\dbus-daemon" enable=yes > NUL
ECHO Building RDP Connection file, Console link, Init system...
ECHO @IF EXIST "%PROGRAMFILES%\WSL\WSL.EXE" (@"%PROGRAMFILES%\WSL\WSL.EXE" -t %DISTRO% ^&^& PING 127.0.0.1 ^>NUL ^&^& START /MIN "%DISTRO%" "%PROGRAMFILES%\WSL\WSL.EXE" ~ -u root -d %DISTRO% -e initwsl 2 ^&^& EXIT) ELSE (@WSLCONFIG.EXE /t %DISTRO% ^&^& PING 127.0.0.1 ^> NUL ^&^& START /MIN "%DISTRO%" "WSL.EXE" ~ -u root -d %DISTRO% -e initwsl 2 ^&^& EXIT) > "%DISTROFULL%\Init.cmd"
START /MIN "Neon Init" "%DISTROFULL%\Init.cmd"
ECHO @WSL ~ -u %XU% -d %DISTRO% > "%DISTROFULL%\%DISTRO% (%XU%) Console.cmd"
POWERSHELL -Command "Copy-Item '%DISTROFULL%\%DISTRO% (%XU%) Console.cmd' ([Environment]::GetFolderPath('Desktop'))"
POWERSHELL -Command "Copy-Item '%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp' ([Environment]::GetFolderPath('Desktop'))"
ECHO Building Scheduled Task...
POWERSHELL -C "$WAI = (whoami) ; (Get-Content .\rootfs\tmp\kWSL\kWSL.xml).replace('AAAA', $WAI) | Set-Content .\rootfs\tmp\kWSL\kWSL.xml"
POWERSHELL -C "$WAC = (pwd)    ; (Get-Content .\rootfs\tmp\kWSL\kWSL.xml).replace('QQQQ', $WAC) | Set-Content .\rootfs\tmp\kWSL\kWSL.xml"
SCHTASKS /Create /TN:%DISTRO% /XML .\rootfs\tmp\kWSL\kWSL.xml /F
ECHO:
ECHO:      Start: %RUNSTART%
ECHO:        End: %RUNEND%
%GO%  "echo -ne '   Packages:'\   ; dpkg-query -l | grep "^ii" | wc -l "
ECHO:
ECHO:  - xRDP Server listening on port %RDPPRT% and SSHd on port %SSHPRT%.
ECHO:
ECHO:  - Links for GUI and Console sessions have been placed on your desktop.
ECHO:
ECHO:  - (Re)launch init from the Task Scheduler or by running the following command:
ECHO:    schtasks /run /tn %DISTRO%
ECHO:
ECHO: %DISTRO% Installation Complete!  GUI will start in a few seconds...
PING -n 6 LOCALHOST > NUL
START "Remote Desktop Connection" "MSTSC.EXE" "/V" "%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp"
CD ..
ECHO:
:ENDSCRIPT
