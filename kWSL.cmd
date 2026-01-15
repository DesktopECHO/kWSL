@ECHO OFF & NET SESSION >NUL 2>&1 
IF %ERRORLEVEL% == 0 (ECHO Administrator check passed...) ELSE (ECHO You need to run this command with administrative rights.  Is User Account Control enabled? && pause && goto ENDSCRIPT)

REM ============================================================================
REM CONFIGURATION SECTION
REM ============================================================================
COLOR 1F
SET WSLREV=20260103
SET DISTRO=kWSL
SET GITORG=DesktopECHO
SET GITPRJ=kWSL
SET BRANCH=next
SET BASE=https://github.com/%GITORG%/%GITPRJ%/raw/%BRANCH%
SET RDPPRT_DEFAULT=3399
SET SSHPRT_DEFAULT=3322

REM ============================================================================
REM INITIALIZATION
REM ============================================================================
REM Enable WSL if required
POWERSHELL -Command "$WSL = Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' ; if ($WSL.State -eq 'Disabled') {Enable-WindowsOptionalFeature -FeatureName $WSL.FeatureName -Online}"

REM Find system DPI setting
IF NOT EXIST "%TEMP%\windpi.ps1" POWERSHELL.EXE -ExecutionPolicy Bypass -Command "Invoke-WebRequest '%BASE%/windpi.ps1' -UseBasicParsing -OutFile '%TEMP%\windpi.ps1'"
FOR /f "delims=" %%a in ('powershell -ExecutionPolicy bypass -command "%TEMP%\windpi.ps1" ') do set "WINDPI=%%a"

REM ============================================================================
REM USER INPUT SECTION
REM ============================================================================
:DI
CLS && SET RUNSTART=%date% @ %time:~0,5%

REM Prevent installation to System32
IF EXIST .\CMD.EXE CD ..\..

ECHO [kWSL Installer %WSLREV%]
ECHO:

REM Get custom distro name
ECHO Enter a unique name for your distro or hit Enter for default.
SET /p DISTRO=Keep this name simple, no space or underscore characters [kWSL]: 

REM Validate distro name doesn't already exist
IF EXIST "%DISTRO%" (
  ECHO. & ECHO Folder exists with that name, choose a new folder name. & PAUSE & GOTO DI
)

REM Check if distro is already registered with WSL
WSL.EXE -d %DISTRO% -e . > "%TEMP%\InstCheck.tmp"
FOR /f %%i in ("%TEMP%\InstCheck.tmp") do set CHKIN=%%~zi 
IF %CHKIN% == 0 (
  ECHO. & ECHO There is a WSL distribution registered with that name; uninstall it or choose a new name.
  PAUSE & GOTO DI
)

REM Get DNS settings from system
FOR /f "tokens=2" %%a in ('nslookup . 2^>nul ^| findstr /C:"Address:"') do (set "DNS=nameserver %%a")

REM Get port numbers for services
ECHO:
SET RDPPRT=%RDPPRT_DEFAULT%
SET /p RDPPRT=    Port number for xRDP traffic or hit Enter to use default [%RDPPRT_DEFAULT%]: 

SET SSHPRT=%SSHPRT_DEFAULT%
SET /p SSHPRT=Port number for SSHd traffic or hit Enter to use default [%SSHPRT_DEFAULT%]: 

REM Get DPI scale setting
SET /p WINDPI=Set a custom display scale or hit Enter for Windows default [%WINDPI%]: 

REM Calculate Linux DPI values (96 DPI base for X11, 32 for panel height)
FOR /f "delims=" %%a in ('PowerShell -Command 96 * "%WINDPI%" ') do set "LINDPI=%%a"
FOR /f "delims=" %%a in ('PowerShell -Command 32 * "%WINDPI%" ') do set "PANEL=%%a"

REM Windows Defender exclusion option
SET DEFEXL=NONO
SET /p DEFEXL=Not recommended!  Hit X to eXclude distro from Windows Defender: 

REM ============================================================================
REM SETUP DISTRO PATH
REM ============================================================================
SET DISTROFULL=%CD%\%DISTRO%
SET _rlt=%DISTROFULL:~2,2%
IF "%_rlt%"=="\\" SET DISTROFULL=%CD%%DISTRO%
SET GO="%DISTROFULL%\LxRunOffline.exe" r -n "%DISTRO%" -c
REM %GO% "rm -rf /etc/resolv.conf ; echo %DNS% > /etc/resolv.conf"

:: ===========================================================================
:: DOWNLOADS
:: ===========================================================================
ECHO Downloading image from salsa.debian.org . . .

SET "DEBIAN_URL=https://salsa.debian.org/debian/WSL/-/raw/master/x64/install.tar.gz?ref_type=heads"
SET "IMG_NAME=Debian.tar.gz"
:DLIMG
POWERSHELL.EXE -Command "Start-BitsTransfer -Source '%DEBIAN_URL%' -Destination '%TEMP%\%IMG_NAME%'" >NUL 2>&1
IF NOT EXIST "%TEMP%\%IMG_NAME%" GOTO DLIMG

REM Create distro directory structure
%DISTROFULL:~0,1%: 
MKDIR "%DISTROFULL%"
CD "%DISTROFULL%"
MKDIR logs > NUL

REM Log installation inputs
(
  ECHO [kWSL Inputs]
  ECHO.
  ECHO.   Distro: %DISTRO%
  ECHO.     Path: %DISTROFULL%
  ECHO. RDP Port: %RDPPRT%
  ECHO. SSH Port: %SSHPRT%
  ECHO.DPI Scale: %WINDPI%
  ECHO.
) > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% kWSL Inputs.log"

REM Download LxRunOffline tool if needed
IF NOT EXIST "%TEMP%\LxRunOffline.exe" (
  POWERSHELL.EXE -Command "Invoke-WebRequest %BASE%/LxRunOffline.exe -UseBasicParsing -OutFile '%TEMP%\LxRunOffline.exe'"
  COPY "%TEMP%\LxRunOffline.exe" "%DISTROFULL%"
)

REM ============================================================================
REM CREATE UNINSTALL SCRIPT
REM ============================================================================
SETLOCAL ENABLEDELAYEDEXPANSION
(
  ECHO @COLOR 1F
  ECHO @ECHO Ensure you are running this command with elevated rights.  Uninstall %DISTRO%?
  ECHO @PAUSE
  ECHO @COPY /Y "%DISTROFULL%\LxRunOffline.exe" "%APPDATA%"
  ECHO @POWERSHELL -Command "Remove-Item ([Environment]::GetFolderPath('Desktop')+'\%DISTRO% (*) Console.cmd')"
  ECHO @POWERSHELL -Command "Remove-Item ([Environment]::GetFolderPath('Desktop')+'\%DISTRO% (*) Desktop.rdp')"
  ECHO @SCHTASKS /Delete /TN:%DISTRO% /F
  ECHO @CLS
  ECHO @ECHO Uninstalling %DISTRO%, please wait...
  ECHO @CD ..
  ECHO @WSLCONFIG.EXE /t %DISTRO% ^&^& WSL.EXE --unregister %DISTRO%
  ECHO @"%APPDATA%\LxRunOffline.exe" ur -n %DISTRO%
  ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% xRDP"
  ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% Secure Shell"
  ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% Avahi Multicast DNS"
  ECHO @RD /S /Q "%DISTROFULL%"
) > "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ENDLOCAL
ECHO:

REM ============================================================================
REM INSTALL WSL DISTRIBUTION
REM ============================================================================
ECHO Installing kWSL Distro [%DISTRO%] to "%DISTROFULL%"
ECHO This will take a few minutes, please wait...

REM Add Windows Defender exclusions if requested
IF %DEFEXL%==X (
  POWERSHELL.EXE -Command "Invoke-WebRequest %BASE%/excludeWSL.ps1 -UseBasicParsing -OutFile '%DISTROFULL%\excludeWSL.ps1'"
  START /WAIT /MIN "Add exclusions in Windows Defender" "POWERSHELL.EXE" "-ExecutionPolicy" "Bypass" "-Command" ".\excludeWSL.ps1" "%DISTROFULL%"
  DEL ".\excludeWSL.ps1"
)

ECHO: & ECHO [%TIME:~0,8%] Installing Debian             (~0m15s)
START /WAIT /MIN "Creating WSL userspace..." "%TEMP%\LxRunOffline.exe" "i" "-n" "%DISTRO%" "-f" "%TEMP%\%IMG_NAME%" "-d" "%DISTROFULL%" 

REM Set permissions and finalize installation
(FOR /F "usebackq delims=" %%v IN (`PowerShell -Command "whoami"`) DO set "WAI=%%v")
ICACLS "%DISTROFULL%" /grant "%WAI%":(CI)(OI)F > NUL
COPY /Y "%TEMP%\LxRunOffline.exe" "%DISTROFULL%" > NUL
"%DISTROFULL%\LxRunOffline.exe" sd -n "%DISTRO%" 

REM ============================================================================
REM PACKAGE INSTALLATION SECTION
REM ============================================================================
REM Install prerequisite components

ECHO [%TIME:~0,8%] Prerequisite packages         (~5m00s)
%GO% "echo %DNS% > /etc/resolv.conf ; apt-get -qq update ; apt-get -qqy install git ca-certificates aria2 acl --no-install-recommends ; echo 'exit 0' > /usr/bin/lspci ; chmod +x /usr/bin/lspci ; echo 'exit 0' > /bin/setfacl ; rm -rf /etc/apt/apt.conf.d/20snapd.conf /etc/systemd/system/snap* /var/cache/snapd /etc/rc2.d/S01whoopsie /etc/init.d/console-setup.sh ; echo 'echo 1' > /usr/sbin/runlevel ; cd /tmp ; git clone -b %BRANCH% --depth=1 https://github.com/%GITORG%/%GITPRJ%.git ; chmod +x /tmp/kWSL/dist/usr/local/bin/apt-fast ; cp -p /tmp/kWSL/dist/usr/local/bin/apt-fast /usr/local/bin ; mv /tmp/kWSL/dist/etc/dpkg/dpkg.cfg.d/01_nodoc /etc/dpkg/dpkg.cfg.d ; dpkg -r --force-all libpam-systemd systemd-sysv systemd ; apt-fast -y install opensysusers sysvinit-core initscripts sysv-rc elogind insserv startpar ; DEBIAN_FRONTEND=noninteractive apt-fast -qqy dist-upgrade" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Setup apt-fast and clone repo.log" 2>&1

%GO% "echo %DNS% > /etc/resolv.conf ; DEBIAN_FRONTEND=noninteractive apt-fast -qqy install /tmp/kWSL/deb/*.deb opensysusers elogind avahi-daemon base-files fuse3 dbus-x11 python3-xdg ssh ssl-cert synaptic unace unzip wget x11-apps x11-common x11-session-utils x11-utils x11-xfs-utils x11-xkb-utils x11-xserver-utils x264 xauth xbase-clients xcvt xdg-utils xfonts-100dpi xfonts-base xfonts-encodings xfonts-scalable xfonts-utils xinit xinput xorg xserver-common xserver-xorg xserver-xorg-core xserver-xorg-input-all xserver-xorg-input-libinput xserver-xorg-legacy xserver-xorg-video-dummy xterm --no-install-recommends ; wget -q https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb ; apt-fast -qqy install ./chrome-remote-desktop_current_amd64.deb ; rm -f ./chrome-remote-desktop_current_amd64.deb" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Prerequisite components.log" 2>&1

: REM Install Xfce
: ECHO [%TIME:~0,8%] Xfce desktop environment      (~1m30s)
: %GO% "echo %DNS% > /etc/resolv.conf ; DEBIAN_FRONTEND=noninteractive apt-fast -qqy install dmz-cursor-theme evince gigolo gvfs-fuse libxfce4ui-utils mousepad ncompress xarchiver xfce4 xfce4-appfinder xfce4-clipman xfce4-clipman-plugin xfce4-cpugraph-plugin xfce4-datetime-plugin xfce4-notifyd xfce4-panel xfce4-pulseaudio-plugin xfce4-screenshooter xfce4-session xfce4-settings xfce4-taskmanager xfce4-terminal xfce4-whiskermenu-plugin xfwm4 --no-install-recommends" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Xfce Desktop Environment.log" 2>&1

: REM Install KDE
: ECHO [%TIME:~0,8%] K Desktop Environment         (~4m00s)
: %GO% "echo %DNS% > /etc/resolv.conf ; DEBIAN_FRONTEND=noninteractive apt-fast -qqy install /tmp/kWSL/deb-kde/*.deb kwin-x11 konsole systemsettings breeze-gtk-theme kde-config-gtk-style kdeplasma-addons-data libplasma5support-data libplasma5support6 libplasma6 libplasmaactivities6 libplasmaactivitiesstats1 libplasmaquick6 plasma-browser-integration plasma-desktop plasma-desktop-data plasma-desktoptheme plasma-integration plasma-pa plasma-runners-addons plasma-wallpapers-addons plasma-widgets-addons plasma-workspace plasma-workspace-data qml6-module-org-kde-plasma-plasma5support webext-plasma-browser-integration --no-install-recommends ; DEBIAN_FRONTEND=noninteractive apt-fast -qqy install falkon" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% K Desktop Environment.log" 2>&1 

: REM Retrieve Mozilla keys for Seamonkey repository
: START /MIN "Get Mozilla keys..." %GO% "echo %DNS% > /etc/resolv.conf ; echo 'deb http://downloads.sourceforge.net/project/ubuntuzilla/mozilla/apt all main' > /etc/apt/sources.list.d/seamonkey.list ; apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 2667CA5C ; apt-key export 2667CA5C | gpg --dearmour -o /etc/apt/trusted.gpg.d/seamonkey.gpg --batch --yes"

: REM Final cleanup and configuration
: %GO% "apt-get -qqy purge --autoremove ; apt-get clean" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Post-install clean-up.log"

REM Get scheduler path for restart script
%GO% "which schtasks.exe" > "%TEMP%\SCHT.tmp" & set /p SCHT=<"%TEMP%\SCHT.tmp"

REM Configure distro-specific settings
%GO% "sed -i 's#SCHT#%SCHT%#g' /tmp/kWSL/dist/usr/local/bin/restartwsl ; sed -i 's#DISTRO#%DISTRO%#g' /tmp/kWSL/dist/usr/local/bin/restartwsl"

REM Apply DPI scaling to Xfce configuration
IF %LINDPI% GEQ 288 ( %GO% "sed -i 's/HISCALE/3/g' /tmp/kWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" )
IF %LINDPI% GEQ 192 ( %GO% "sed -i 's/HISCALE/2/g' /tmp/kWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" )
IF %LINDPI% LSS 192 ( %GO% "sed -i 's/HISCALE/1/g' /tmp/kWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" )

REM Apply font DPI settings
IF %LINDPI% GEQ 192 ( %GO% "sed -i 's/QQQ/96/g' /tmp/kWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" )
IF %LINDPI% LSS 192 ( %GO% "sed -i 's/QQQ/%LINDPI%/g' /tmp/kWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" )

REM Apply panel height settings
IF %LINDPI% GEQ 192 ( %GO% "sed -i 's/PANEL/32/g' /tmp/kWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" )
IF %LINDPI% LSS 192 ( %GO% "sed -i 's/PANEL/%PANEL%/g' /tmp/kWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" )

REM Apply window manager theme scaling
IF %LINDPI% LSS 144 ( %GO% "sed -i 's/Default-hdpi/Default/g' /tmp/kWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" )

%GO% "sed -i 's/ kWSL/ %DISTRO%/g' /tmp/kWSL/dist/etc/skel/.config/xfce4/panel/whiskermenu-1.rc"

%GO% "sed -i 's/\\h/%DISTRO%/g' /tmp/kWSL/dist/etc/skel/.bashrc ; sed -i 's/\\h/%DISTRO%/g' /root/.bashrc"
%GO% "sed -i 's/#Port 22/Port %SSHPRT%/g' /etc/ssh/sshd_config"
%GO% "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
%GO% "sed -i 's/WSLINSTANCENAME/%DISTRO%/g' /tmp/kWSL/dist/usr/local/bin/initwsl"
%GO% "sed -i 's/#enable-dbus=yes/enable-dbus=no/g' /etc/avahi/avahi-daemon.conf ; sed -i 's/#host-name=foo/host-name=%DISTRO%/g' /etc/avahi/avahi-daemon.conf ; sed -i 's/use-ipv4=yes/use-ipv4=no/g' /etc/avahi/avahi-daemon.conf"
%GO% "cp /mnt/c/Windows/Fonts/*.ttf /usr/share/fonts/truetype ; ssh-keygen -A ; adduser xrdp ssl-cert" > NUL
%GO% "chmod 644 /tmp/kWSL/dist/etc/wsl.conf"
REM  chmod +x /tmp/kWSL/dist/etc/xrdp/startwm.sh"
%GO% "chmod 755 /tmp/kWSL/dist/etc/profile.d/kWSL.sh /tmp/kWSL/dist/usr/local/bin/restartwsl /tmp/kWSL/dist/usr/local/bin/initwsl /tmp/kWSL/dist/etc/init.d/xrdp ; chmod -R 700 /tmp/kWSL/dist/etc/skel/.config ; chmod -R 7700 /tmp/kWSL/dist/etc/skel/.local ; chmod 700 /tmp/kWSL/dist/etc/skel/.mozilla"
%GO% "cp -Rp /tmp/kWSL/dist/* / ; cp -Rp /tmp/kWSL/dist/etc/skel/.config /root ; cp -Rp /tmp/kWSL/dist/etc/skel/.local /root ; update-rc.d xrdp defaults"
%GO% "sed -i 's/allowed_users=console/allowed_users=anybody/' /etc/X11/Xwrapper.config"
%GO% "rm -f /etc/xrdp/cert.pem /etc/xrdp/key.pem ; cp /etc/ssl/certs/ssl-cert-snakeoil.pem  /etc/xrdp/cert.pem ; cp /etc/ssl/private/ssl-cert-snakeoil.key /etc/xrdp/key.pem ; chmod 640 /etc/xrdp/rsakeys.ini ; chown root:xrdp /etc/xrdp/rsakeys.ini ; chown xrdp:root /etc/xrdp/key.pem ; chmod 440 /etc/xrdp/key.pem"
%GO% "sed -i 's/port=3389/port=%RDPPRT%/g' /etc/xrdp/xrdp.ini"

REM ============================================================================
REM POST-INSTALLATION CONFIGURATION
REM ============================================================================
SET RUNEND=%date% @ %time:~0,5%
CD %DISTROFULL% 
ECHO:
REM Create user account and set password
SET /p XU=Enter name of primary user for %DISTRO%: 
POWERSHELL -Command $prd = read-host "Enter password for %XU%" -AsSecureString ; $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($prd) ; [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) > .tmp & set /p PWO=<.tmp

REM Add user and configure sudo privileges
%GO% "useradd -m -p nulltemp -s /bin/bash %XU%"
%GO% "(echo '%XU%:%PWO%') | chpasswd"
%GO% "echo '%XU% ALL=(ALL:ALL) ALL' >> /etc/sudoers"

REM Create RDP connection file with user credentials
%GO% "sed -i 's/PLACEHOLDER/%XU%/g' /tmp/kWSL/kWSL.rdp"
%GO% "sed -i 's/COMPY/localhost/g' /tmp/kWSL/kWSL.rdp"
%GO% "sed -i 's/RDPPRT/%RDPPRT%/g' /tmp/kWSL/kWSL.rdp"
%GO% "cp /tmp/kWSL/kWSL.rdp ./kWSL._"

REM Encrypt and embed password in RDP file
ECHO $prd = Get-Content .tmp > .tmp.ps1
ECHO ($prd ^| ConvertTo-SecureString -AsPlainText -Force) ^| ConvertFrom-SecureString ^| Out-File .tmp >> .tmp.ps1
POWERSHELL -ExecutionPolicy Bypass -Command ./.tmp.ps1
TYPE .tmp>.tmpsec.txt
COPY /y /b kWSL._+.tmpsec.txt "%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp" > NUL
DEL /Q kWSL._ .tmp*.* > NUL

REM Configure gksu for GUI password prompts
%GO% "sudo -u %XU% bash -c 'gconftool-2 --set "/apps/gksu/disable-grab" --type bool "true" ; gconftool-2 --set "/apps/gksu/sudo-mode" --type bool "true"'"

REM Configure Windows Firewall for services
ECHO:
ECHO Open Windows Firewall Ports for xRDP, SSH, mDNS...
NETSH AdvFirewall Firewall add rule name="%DISTRO% xRDP" dir=in action=allow protocol=TCP localport=%RDPPRT% > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% Secure Shell" dir=in action=allow protocol=TCP localport=%SSHPRT% > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% Avahi Multicast DNS" dir=in action=allow program="%DISTROFULL%\rootfs\usr\sbin\avahi-daemon" enable=yes > NUL

REM Initialize services
ECHO Building Scheduled Task...
POWERSHELL -C "$WAI = (whoami) ; (Get-Content .\rootfs\tmp\kWSL\kWSL.xml).replace('AAAA', $WAI) | Set-Content .\rootfs\tmp\kWSL\kWSL.xml"
POWERSHELL -C "$WAC = (pwd)    ; (Get-Content .\rootfs\tmp\kWSL\kWSL.xml).replace('QQQQ', $WAC) | Set-Content .\rootfs\tmp\kWSL\kWSL.xml"
SCHTASKS /Create /TN:%DISTRO% /XML .\rootfs\tmp\kWSL\kWSL.xml /F
START /MIN "%DISTRO% Init" WSL ~ -u root -d %DISTRO% -e initwsl 2
ECHO Building RDP Connection file, Console link, Init system...
REM Create init script to restart services on system boot
ECHO @ECHO OFF > "%DISTROFULL%\Init.cmd"
ECHO IF EXIST "%PROGRAMFILES%\WSL\WSL.EXE" ( >> "%DISTROFULL%\Init.cmd"
ECHO   @"%PROGRAMFILES%\WSL\WSL.EXE" -t %DISTRO% >> "%DISTROFULL%\Init.cmd"
ECHO   @PING 127.0.0.1 ^> NUL >> "%DISTROFULL%\Init.cmd"
ECHO   @START /MIN "%DISTRO%" "%PROGRAMFILES%\WSL\WSL.EXE" ~ -u root -d %DISTRO% -e initwsl 2 >> "%DISTROFULL%\Init.cmd"
ECHO   @EXIT >> "%DISTROFULL%\Init.cmd"
ECHO ) ELSE ( >> "%DISTROFULL%\Init.cmd"
ECHO   @WSLCONFIG.EXE /t %DISTRO% >> "%DISTROFULL%\Init.cmd"
ECHO   @PING 127.0.0.1 ^> NUL >> "%DISTROFULL%\Init.cmd"
ECHO   @START /MIN "%DISTRO%" "WSL.EXE" ~ -u root -d %DISTRO% -e initwsl 2 >> "%DISTROFULL%\Init.cmd"
ECHO   @EXIT >> "%DISTROFULL%\Init.cmd"
ECHO ) >> "%DISTROFULL%\Init.cmd"

REM Create console shortcut
ECHO @WSL ~ -u %XU% -d %DISTRO% > "%DISTROFULL%\%DISTRO% (%XU%) Console.cmd"

REM Set default user UID
"%DISTROFULL%\LxRunOffline.exe" su -n %DISTRO% -v 1000

REM Copy shortcuts to desktop
POWERSHELL -Command "Copy-Item '%DISTROFULL%\%DISTRO% (%XU%) Console.cmd' ([Environment]::GetFolderPath('Desktop'))"
POWERSHELL -Command "Copy-Item '%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp' ([Environment]::GetFolderPath('Desktop'))"

REM Display installation summary
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
