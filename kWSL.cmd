@ECHO OFF
SET GITORG=DesktopECHO
SET GITPRJ=kWSL
SET BASE=https://github.com/%GITORG%/%GITPRJ%/raw/master
REM ## UAC Check 
NET SESSION >NUL 2>&1
 if %errorLevel% == 0 (
      echo Administrative permissions confirmed...
  ) else (
      echo You need to run this command with administrative rights.  User Account Control enabled?
      pause
      goto ENDSCRIPT
  )

REM ## Enable WSL
POWERSHELL.EXE -command "Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

REM ## Set WSL1 and TimeStamp
WSL.EXE --set-default-version 1 > NUL
CLS && SET RUNSTART=%date% @ %time%

REM ## Determine ideal DPI
IF NOT EXIST %TEMP%\dpi.ps1 POWERSHELL.EXE -Command "wget %BASE%/dpi.ps1 -UseBasicParsing -OutFile %TEMP%\dpi.ps1"
for /f "delims=" %%a in ('powershell -executionpolicy bypass -command "%TEMP%\dpi.ps1" ') do set "LINDPI=%%a"

REM ## Get install name and port numbers
ECHO kWSL for Devuan Linux
:DI
SET DISTRO=kWSL& SET /p DISTRO=Enter a unique name for the distro or hit Enter to use default [kWSL]: 
IF EXIST %DISTRO% GOTO DI
SET RDPPRT=3399& SET /p RDPPRT=Enter port number for xRDP traffic or hit Enter to use default [3399]: 
SET SSHPRT=3322& SET /p SSHPRT=Enter port number for SSHd traffic or hit Enter to use default [3322]: 
                 SET /p LINDPI=Enter DPI Scaling or hit Enter to use default [%LINDPI%]: 

REM ## Download distro base
IF /I %CD%==C:\Windows\System32 CD %HOMEPATH%
SET DISTROFULL=%CD%\%DISTRO%
SET _rlt=%DISTROFULL:~2,2%
IF "%_rlt%"=="\\" SET DISTROFULL=%CD%%DISTRO%
SET GO=%DISTROFULL%\LxRunOffline.exe r -n %DISTRO% -c 
ECHO %DISTRO% to be installed in %DISTROFULL% && ECHO Downloading... (or using local copy if available)
IF NOT EXIST %TEMP%\Debian.zip POWERSHELL.EXE -Command "wget https://aka.ms/wsl-debian-gnulinux -UseBasicParsing -OutFile %TEMP%\Debian.zip"
POWERSHELL.EXE -command "Expand-Archive -Path %TEMP%\Debian.zip -DestinationPath %TEMP% -force

REM ## Install Distro with LxRunOffline / https://github.com/DDoSolitary/LxRunOffline
IF NOT EXIST %TEMP%\LxRunOffline.exe POWERSHELL.EXE -Command "wget %BASE%/LxRunOffline.exe -UseBasicParsing -OutFile %TEMP%\LxRunOffline.exe"
%TEMP%\LxRunOffline.exe  i -n %DISTRO% -d .\%DISTRO% -f %TEMP%\install.tar.gz
%TEMP%\LxRunOffline.exe sd -n %DISTRO%
COPY %TEMP%\LxRunOffline.* %DISTROFULL% > NUL

REM ## Add exclusions in Windows Defender
IF NOT EXIST %TEMP%\excludeWSL.ps1 POWERSHELL.EXE -Command "wget %BASE%/excludeWSL.ps1 -UseBasicParsing -OutFile %TEMP%\excludeWSL.ps1"
POWERSHELL.EXE  -executionpolicy bypass -command "%TEMP%\excludeWSL.ps1"

REM ## Configure
%GO% "cd /tmp ; wget -q http://deb.devuan.org/devuan/pool/main/d/devuan-keyring/devuan-keyring_2017.10.03_all.deb ; wget -q http://ftp.br.debian.org/debian/pool/main/c/ca-certificates/ca-certificates_20200601~deb9u1_all.deb ; wget -q http://ftp.br.debian.org/debian/pool/main/o/openssl/openssl_1.1.0l-1~deb9u1_amd64.deb ; wget -q http://ftp.br.debian.org/debian/pool/main/o/openssl/libssl1.1_1.1.0l-1~deb9u1_amd64.deb"
%GO% "cd /tmp ; dpkg -i --force-all ./devuan-keyring_2017.10.03_all.deb ./ca-certificates_20200601~deb9u1_all.deb ./openssl_1.1.0l-1~deb9u1_amd64.deb ./libssl1.1_1.1.0l-1~deb9u1_amd64.deb" > NUL
%GO% "echo deb     http://deb.devuan.org/merged chimaera main >  /etc/apt/sources.list ; 
%GO% "echo deb-src http://deb.devuan.org/merged chimaera main >> /etc/apt/sources.list"
%GO% "cd /tmp ; apt-get update ; touch /etc/mtab ; wget -q %BASE%/deb/libc6_2.30-8_amd64.deb ; wget -q %BASE%/deb/libc-bin_2.30-8_amd64.deb ; apt-get -qq install ./libc6_2.30-8_amd64.deb ./libc-bin_2.30-8_amd64.deb ; apt-mark hold libc6"
%GO% "cd /tmp ; apt-get -y install base-files dirmngr git --no-install-recommends ; wget -q %BASE%/deb/locales_2.30-8_all.deb ; apt-get -y install ./locales_2.30-8_all.deb"
%GO% "DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade --no-install-recommends"
%GO% "update-locale LC_ALL=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LANG=en_US.UTF-8 ; dpkg-reconfigure --frontend noninteractive locales"
%GO% "cd /tmp ; git clone --depth=1 https://github.com/%GITORG%/%GITPRJ%.git"
%GO% "cd /tmp ; wget -q %BASE%/deb/libc-dev-bin_2.30-8_amd64.deb ; wget -q %BASE%/deb/libc6-dev_2.30-8_amd64.deb ; apt-get -qq install ./libc-dev-bin_2.30-8_amd64.deb ./libc6-dev_2.30-8_amd64.deb"
%GO% "DEBIAN_FRONTEND=noninteractive apt-get -y install /tmp/kWSL/deb/gksu_2.0.2-9_amd64.deb /tmp/kWSL/deb/libgksu2-0_2.0.13_amd64.deb /tmp/kWSL/deb/libgnome-keyring0_3.12.0-1build1_amd64.deb /tmp/kWSL/deb/libgnome-keyring-common_3.12.0-1build1_all.deb /tmp/kWSL/deb/xrdp_0.9.9-1_amd64.deb /tmp/kWSL/deb/xorgxrdp_0.2.9-1_amd64.deb /tmp/kWSL/deb/wslu_3.1.1-1_all.deb dialog elogind libelogind0 libpam-elogind --no-install-recommends ; apt-get -y remove rsyslog  ; apt-mark hold xorgxrdp xrdp"
%GO% "DEBIAN_FRONTEND=noninteractive apt-get -y install xdg-utils kde-plasma-desktop kinfocenter kwin-x11 ssh avahi-daemon libnss-mdns binutils systemsettings gnome-terminal putty mousepad synaptic kde-config-gtk-style-preview breeze-gtk-theme inetutils-syslogd kmix pulseaudio-utils pulseaudio mesa-utils ntp ksysguard ksysguard-data kmenuedit kde-config-gtk-style ark bzip2 p7zip-full unar unzip zip flameshot kolourpaint extremetuxracer distro-info-data lsb-release dumb-init --no-install-recommends"

REM ## Extras go here
REM %GO% "apt-get -y install pithos"

REM ## Customize
%GO% "sed -i 's/port=3389/port=%RDPPRT%/g' /tmp/kWSL/dist/etc/xrdp/xrdp.ini ; cp /tmp/kWSL/dist/etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini"
%GO% "sed -i 's/#Port 22/Port %SSHPRT%/g' /etc/ssh/sshd_config"
%GO% "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
%GO% "sed -i 's/thinclient_drives/.kWSL/g' /etc/xrdp/sesman.ini"
%GO% "sed -i 's/forceFontDPI=0/forceFontDPI=%LINDPI%/g' /tmp/kWSL/dist/etc/skel/.config/kcmfonts"
%GO% "sed -i 's/#enable-dbus=yes/enable-dbus=no/g' /etc/avahi/avahi-daemon.conf ; sed -i 's/#host-name=foo/host-name=%COMPUTERNAME%-%DISTRO%/g' /etc/avahi/avahi-daemon.conf"
%GO% "ln -s /mnt/c/Windows/Fonts /usr/share/fonts/truetype/microsoft ; rm -rf /etc/pam.d/systemd-user ; rm -rf /etc/systemd ; rm -rf /usr/share/icons/breeze_cursors ; rm -rf /usr/share/icons/Breeze_Snow/cursors ; ssh-keygen -A ; adduser xrdp ssl-cert"
%GO% "rm /usr/lib/x86_64-linux-gnu/libexec/kscreenlocker_greet ; strip --remove-section=.note.ABI-tag /usr/lib/x86_64-linux-gnu/libQt5Core.so.5 ; apt-get -qq remove udev"
%GO% "mv /usr/bin/pkexec /usr/bin/pkexec.orig ; echo gksudo -k -S -g \$1 > /usr/bin/pkexec ; chmod 755 /usr/bin/pkexec"
%GO% "chmod 644 /tmp/kWSL/dist/etc/wsl.conf"
%GO% "chmod 644 /tmp/kWSL/dist/var/lib/xrdp-pulseaudio-installer/*.so"
%GO% "chmod 700 /tmp/kWSL/dist/usr/local/bin/initWSL ; chmod 700 /tmp/kWSL/dist/etc/skel/.config"
%GO% "chmod 644 /tmp/kWSL/dist/etc/profile.d/WinNT.sh"
%GO% "chmod 644 /tmp/kWSL/dist/etc/xrdp/xrdp.ini"
%GO% "cp -r /tmp/kWSL/dist/* /"

REM ## Patch dependancies on shared memory 
%GO% "dpkg -i --force-all /tmp/kWSL/deb/libkf5activitiesstats1_5.70.0-1_amd64.deb /tmp/kWSL/deb/kactivitymanagerd_5.17.5-2_amd64.deb /tmp/kWSL/deb/libkscreenlocker5_5.17.5-9wsl_amd64.deb /tmp/kWSL/deb/kde-config-screenlocker_5.17.5-9wsl_amd64.deb ; apt-mark hold kactivitymanagerd libkf5activitiesstats1 libkscreenlocker5 kde-config-screenlocker"

REM ## Install Mozilla
%GO% "echo deb http://downloads.sourceforge.net/project/ubuntuzilla/mozilla/apt all main >> /etc/apt/sources.list"
%GO% "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 2667CA5C"
%GO% "apt-get update ; apt-get -y install seamonkey-mozilla-build ; apt-get -qq autoremove ; apt-get -qq clean ; apt-get -qq purge"
%GO% "update-alternatives --install /usr/bin/www-browser www-browser /usr/bin/seamonkey 100 ; update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /usr/bin/seamonkey 100 ; update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/seamonkey 100"
SET RUNEND=%date% @ %time%

REM ## Setup user access 
CD %DISTROFULL% 
ECHO. 
ECHO.
SET /p XU=Enter name of %DISTRO% user: 
BASH -c "useradd -m -p nulltemp -s /bin/bash %XU%"
POWERSHELL -Command $prd = read-host "Enter password" -AsSecureString ; $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($prd) ; [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) > .tmp.txt & set /p PWO=<.tmp.txt
BASH -c "echo %XU%:%PWO% | chpasswd"
%GO% "sed -i 's/PLACEHOLDER/%XU%/g' /tmp/kWSL/kWSL.rdp"
%GO% "sed -i 's/COMPY/%COMPUTERNAME%/g' /tmp/kWSL/kWSL.rdp"
%GO% "sed -i 's/RDPPRT/%RDPPRT%/g' /tmp/kWSL/kWSL.rdp"
%GO% "cp /tmp/kWSL/kWSL.rdp ./kWSL._"
ECHO $prd = Get-Content .tmp.txt > .tmp.ps1
ECHO ($prd ^| ConvertTo-SecureString -AsPlainText -Force) ^| ConvertFrom-SecureString ^| Out-File .tmp.txt  >> .tmp.ps1
POWERSHELL -Command .tmp.ps1 
TYPE .tmp.txt>.tmpsec.txt
COPY /y /b %DISTROFULL%\kWSL._+.tmpsec.txt "%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp" > NUL
DEL /Q  kWSL._ .tmp*.* > NUL
BASH -c "echo '%XU% ALL=(ALL:ALL) ALL' >> /etc/sudoers"

REM ## Open Firewall Ports
NETSH AdvFirewall Firewall add rule name="%DISTRO% xRDP" dir=in action=allow protocol=TCP localport=%RDPPRT% > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% Secure Shell" dir=in action=allow protocol=TCP localport=%SSHPRT% > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% Avahi Multicast DNS" dir=in action=allow program="%DISTROFULL%\rootfs\usr\sbin\avahi-daemon" enable=yes > NUL

REM ## Build RDP, Console, Init Links, Scheduled Task...
ECHO @WSLCONFIG /t %DISTRO% > "%DISTROFULL%\%DISTRO%-Init.cmd"
ECHO @WSL ~ -u root -d %DISTRO% -e initWSL 2 >> "%DISTROFULL%\%DISTRO%-Init.cmd"
ECHO @WSL ~ -u %XU% -d %DISTRO% >  "%DISTROFULL%\%DISTRO% (%XU%) Console.cmd"
COPY /Y "%DISTROFULL%\%DISTRO% (%XU%) Console.cmd" "%USERPROFILE%\Desktop\%DISTRO% (%XU%) Console.cmd" > NUL
COPY /Y "%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp" "%USERPROFILE%\Desktop\%DISTRO% (%XU%) Desktop.rdp" > NUL
START /MIN "%DISTRO% Init" WSL ~ -u root -d %DISTRO% -e initWSL 2
FOR /f "delims=" %%n in ('whoami') do set WAI=%%n
SCHTASKS /CREATE /RU "%WAI%" /RL HIGHEST /SC ONSTART /TN %DISTRO% /TR "%DISTROFULL%\%DISTRO%-Init.cmd" /F > NUL
ECHO $task = Get-ScheduledTask %DISTRO% ; $task.Settings.ExecutionTimeLimit = "PT0S" ; Set-ScheduledTask $task > %TEMP%\ExecTimeLimit.ps1
POWERSHELL -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -COMMAND %TEMP%\ExecTimeLimit.ps1 > NUL
ECHO.
ECHO.      Start: %RUNSTART%
ECHO.        End: %RUNEND%
%GO%  "echo -ne '   Packages:'\   ; dpkg-query -l | grep "^ii" | wc -l "
ECHO. 
ECHO.  - xRDP Server listening on port %RDPPRT% and SSHd on port %SSHPRT%.
ECHO. 
ECHO.  - Links for GUI and Console sessions have been placed on your desktop.
ECHO. 
ECHO.  - (Re)launch init from the Task Scheduler or by running the following command: 
ECHO.    schtasks /run /tn %DISTRO%
ECHO. 
ECHO. %DISTRO% Installation Complete!  GUI will start in a few seconds...  
PING -n 6 LOCALHOST > NUL 
START "Remote Desktop Connection" "MSTSC.EXE" "/V" "%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp"
:ENDSCRIPT
