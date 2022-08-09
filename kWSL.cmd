@ECHO OFF & NET SESSION >NUL 2>&1 
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

ECHO [kWSL Installer 20220728]
ECHO:
ECHO Set a name for this KDE Neon instance.  Hit Enter to use default. 
SET DISTRO=NeonWSL& SET /p DISTRO=Keep this name simple, no space or underscore characters [NeonWSL]: 
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
IF NOT EXIST "%TEMP%\Ubuntu2004.tar.gz" POWERSHELL.EXE -Command "Start-BitsTransfer -source https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64-wsl.rootfs.tar.gz -destination '%TEMP%\Ubuntu2004.tar.gz'"
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
ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% Avahi Multicast DNS"                                 >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% KDE Connect"                                         >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% KDEinit"                                             >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @RD /S /Q "%DISTROFULL%"                                                                                 >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO Installing kWSL Distro [%DISTRO%] to "%DISTROFULL%" & ECHO This will take a few minutes, please wait... 
IF %DEFEXL%==X (POWERSHELL.EXE -Command "wget %BASE%/excludeWSL.ps1 -UseBasicParsing -OutFile '%DISTROFULL%\excludeWSL.ps1'" & START /WAIT /MIN "Add exclusions in Windows Defender" "POWERSHELL.EXE" "-ExecutionPolicy" "Bypass" "-Command" ".\excludeWSL.ps1" "%DISTROFULL%" &  DEL ".\excludeWSL.ps1")
ECHO:& ECHO [%TIME:~0,8%] Importing distro userspace (~1m30s)
START /WAIT /MIN "Installing Distro Base..." "%TEMP%\LxRunOffline.exe" "i" "-n" "%DISTRO%" "-f" "%TEMP%\Ubuntu2004.tar.gz" "-d" "%DISTROFULL%"
(FOR /F "usebackq delims=" %%v IN (`PowerShell -Command "whoami"`) DO set "WAI=%%v") & ICACLS "%DISTROFULL%" /grant "%WAI%":(CI)(OI)F > NUL
(COPY /Y "%TEMP%\LxRunOffline.exe" "%DISTROFULL%" > NUL ) & "%DISTROFULL%\LxRunOffline.exe" sd -n "%DISTRO%"
ECHO [%TIME:~0,8%] Git clone and update repositories (~1m15s)
%GO% "echo 'deb http://archive.ubuntu.com/ubuntu/ focal main restricted universe' > /etc/apt/sources.list"
%GO% "echo 'deb http://archive.ubuntu.com/ubuntu/ focal-updates main restricted universe' >> /etc/apt/sources.list"
%GO% "echo 'deb http://security.ubuntu.com/ubuntu/ focal-security main restricted universe' >> /etc/apt/sources.list"
%GO% "echo 'deb http://downloads.sourceforge.net/project/ubuntuzilla/mozilla/apt all main' > /etc/apt/sources.list.d/mozilla.list"
%GO% "echo 'deb http://archive.neon.kde.org/user/ focal main' >>  /etc/apt/sources.list.d/neon.list"
%GO% "rm -rf /etc/apt/apt.conf.d/20snapd.conf /etc/rc2.d/S01whoopsie /etc/init.d/console-setup.sh" 
:APTRELY
START /MIN /WAIT "Git Clone kWSL" %GO% "cd /tmp ; git clone -b %BRANCH% --depth=1 https://github.com/%GITORG%/%GITPRJ%.git"
START /MIN /WAIT "Acquire KDE Neon Keys" %GO% "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com E6D4736255751E5D"
START /MIN /WAIT "Acquire Mozilla Seamonkey Keys" %GO% "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 2667CA5C"
START /MIN /WAIT "apt-get update" %GO% "apt-get update 2> /tmp/apterr"
FOR /F %%A in ("%DISTROFULL%\rootfs\tmp\apterr") do If %%~zA NEQ 0 GOTO APTRELY 

ECHO [%TIME:~0,8%] Remove un-needed packages (~1m30s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-get -y purge apparmor apport bolt cloud-init cloud-initramfs-copymods cloud-initramfs-dyn-netconf cryptsetup cryptsetup-initramfs dmeventd finalrd fwupd initramfs-tools initramfs-tools-core irqbalance isc-dhcp-client klibc-utils kpartx libaio1 libarchive13 libdevmapper-event1.02.1 libdns-export1109 libefiboot1 libefivar1 libestr0 libfastjson4 libfwupd2 libfwupdplugin1 libgcab-1.0-0 libgpgme11 libgudev-1.0-0 libgusb2 libisc-export1105 libisns0 libjson-glib-1.0-0 libjson-glib-1.0-common libklibc liblvm2cmd2.03 libmspack0 libnuma1 libsgutils2-2 libsmbios-c2 libtss2-esys0 liburcu6 libxmlb1 libxmlsec1 libxmlsec1-openssl libxslt1.1 linux-base lvm2 lz4 mdadm multipath-tools open-iscsi open-vm-tools overlayroot plymouth plymouth-theme-ubuntu-text popularity-contest sbsigntool secureboot-db sg3-utils sg3-utils-udev snapd squashfs-tools thin-provisioning-tools tpm-udev zerofree ; apt-get -y autoremove --purge" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Remove un-needed packages.log" 2>&1

ECHO [%TIME:~0,8%] Configure apt-fast Downloader (~0m45s)
%GO% "DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/kWSL/deb/aria2_1.35.0-1build1_amd64.deb /tmp/kWSL/deb/libaria2-0_1.35.0-1build1_amd64.deb /tmp/kWSL/deb/libssh2-1_1.8.0-2.1build1_amd64.deb /tmp/kWSL/deb/libc-ares2_1.15.0-1build1_amd64.deb" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Configure apt-fast Downloader .log" 2>&1
%GO% "chmod +x /tmp/kWSL/dist/usr/local/bin/apt-fast ; cp -p /tmp/kWSL/dist/usr/local/bin/apt-fast /usr/local/bin" > NUL

ECHO [%TIME:~0,8%] Remote Desktop Components (~2m45s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install /tmp/kWSL/deb/picom_9.1-1_amd64.deb /tmp/kWSL/deb/xrdp_0.9.19-1_amd64.deb /tmp/kWSL/deb/xorgxrdp_0.2.18-1_amd64.deb /tmp/kWSL/deb/libfdk-aac1_0.1.6-1_amd64.deb /tmp/kWSL/deb/fonts-cascadia-code_2102.03-1_all.deb x11-apps x11-session-utils x11-xserver-utils dialog dumb-init inetutils-syslogd xdg-utils avahi-daemon libnss-mdns binutils putty unzip zip unar unzip samba-common-bin base-files ubuntu-release-upgrader-core python3-distupgrade lhasa arj unace liblhasa0 apt-config-icons apt-config-icons-hidpi apt-config-icons-large apt-config-icons-large-hidpi libgtkd-3-0 libphobos2-ldc-shared90 libvte-2.91-0 libvte-2.91-common libvted-3-0 moreutils tilix tilix-common libdbus-glib-1-2 libgdk-pixbuf2.0-bin libgtk-3-bin python3-gpg samba-dsdb-modules --no-install-recommends" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Remote Desktop Components.log" 2>&1

ECHO [%TIME:~0,8%] KDE Neon User Edition (~7m30s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install apulse ark aspell-en breeze-gtk-theme desktop-file-utils gdb gdbserver gstreamer1.0-plugins-base hunspell-en-us im-config javascript-common kaccounts-providers kactivities-bin kde-config-gtk-style kde-config-gtk-style-preview kde-plasma-desktop kdeconnect kdiff3 kgamma5 khelpcenter kimageformat-plugins kinfocenter kio-extras kmenuedit kpackagelauncherqml kpackagetool5 krename krusader kscreen ksshaskpass ksysguard ksysguard-data kuserfeedback-doc kwalletmanager kwin-x11 kwrited libaacs0 libappstream-glib8 libavahi-glib1 libbdplus0 libcanberra-gtk3-module libcc1-0 libc-dbg libfftw3-single3 libfwupd2 libjs-jquery libkf5baloowidgets-bin libkf5config-bin libkf5dbusaddons-bin libkf5iconthemes-bin libkf5kdelibs4support5-bin libkf5khtml-bin libkf5pulseaudioqt2 libkf5purpose-bin libkf5xmlgui-bin libmarkdown2 libmtp-runtime libostree-1-1 libpam-kwallet5 libproxy-tools libqt5designer5 libqt5help5 libqt5multimedia5-plugins libqt5test5 media-player-info mesa-utils mesa-va-drivers debconf-kde-data libdebconf-kde1 muon p11-kit p11-kit-modules p7zip-full pulseaudio pavucontrol plasma-discover plasma-discover-common plasma-workspace-wallpapers policykit-desktop-privileges poppler-data pulseaudio-equalizer python3-dbus.mainloop.pyqt5 python3-pyqt5 python3-sip qml-module-org-kde-runnermodel qml-module-org-kde-purpose qml-module-org-kde-prison qt5-gtk-platformtheme qtspeech5-speechd-plugin qttranslations5-l10n qtwayland5 libqt5waylandcompositor5 libwayland-client0 ruby sonnet-plugins systemsettings va-driver-all xdg-dbus-proxy apt-xapian-index libqapt3 libqapt3-runtime neon-apport python3-apport python3-problem-report python3-systemd python3-xapian qapt-batch debconf-kde-helper software-properties-qt ksystemlog ubuntu-drivers-common libcanberra-pulse plasma-pa pulseaudio-module-gsettings python3-psutil xbase-clients xinit xvfb dolphin kfind kwrite libdolphinvcs5 libkuserfeedbackwidgets1 fonts-urw-base35 libgs9 libgs9-common libijs-0.35 libjbig2dec0 libkf5kexiv2-15.0.0 libokular5core9 libpaper1 libqmobipocket2 libspectre1 qml-module-org-kde-syntaxhighlighting okular okular-backends kde-spectacle libkcolorpicker0 libkf5kipi-data libkf5kipi32.0.0 libkimageannotator-common libkimageannotator0 mesa-utils-extra khotkeys kaccounts-integration libkf5guiaddons-bin libpaper-utils libvlc-bin alsa-base alsa-utils anacron distro-release-notifier dolphin-plugins drkonqi-pk-debug-installer fonts-noto-color-emoji fonts-noto-core fonts-noto-hinted fonts-noto-ui-core ghostscript ghostscript-x gwenview inputattach kdegraphics-thumbnailers kdeplasma-addons-data kross ksystemstats kwin-addons libaio1 libappimage0 libatopology2 libcfitsio8 libglu1-mesa libiw30 libjasper4 libkf5krosscore5 libkf5krossui5 libkf5unitconversion-data libkf5unitconversion5 libmng2 libqt5script5 libqt5xmlpatterns5 libraw19 libtinyxml2-6a linux-sound-base neon-adwaita neon-configure-inotify neon-keyring neon-settings-2 neon-ubuntu-advantage-tools plasma-calendar-addons plasma-dataengines-addons plasma-runners-addons plasma-systemmonitor plasma-vault plasma-wallpapers-addons plasma-widgets-addons qml-module-org-kde-breeze qml-module-org-kde-kio qml-module-qt-labs-qmlmodels qml-module-qtquick-xmllistmodel qml-module-qtwebengine qt5-image-formats-plugins spice-vdagent ubuntu-release-upgrader-qt xfonts-base xfonts-encodings xfonts-utils xinput --no-install-recommends" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% KDE Neon User Edition.log" 2>&1

ECHO [%TIME:~0,8%] Install Web Browser and CRD (~1m30s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install falkon seamonkey-mozilla-build vlc vlc-bin vlc-l10n vlc-plugin-notify vlc-plugin-qt vlc-plugin-samba vlc-plugin-skins2 vlc-plugin-video-splitter vlc-plugin-visualization --no-install-recommends ; update-alternatives --install /usr/bin/www-browser www-browser /usr/bin/seamonkey 100 ; update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /usr/bin/seamonkey 100 ; update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/seamonkey 100 ; cd /tmp/kWSL/deb ; wget -q https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb ; dpkg -i /tmp/kWSL/deb/chrome-remote-desktop_current_amd64.deb" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Web Browser and CRD.log" 2>&1

REM ## Additional items to install can go here...
REM ## %GO% "cd /tmp ; wget https://files.multimc.org/downloads/multimc_1.4-1.deb"
REM ## %GO% "apt-get -y install supertuxkart /tmp/multimc_1.4-1.deb"

ECHO [%TIME:~0,8%] Cleaning-up... (~0m45s)
%GO% "apt-get -y purge libimobiledevice6 libplist3 libupower-glib3 libusbmuxd6 wayland-utils ubuntu-advantage-tools distro-info upower mesa-vulkan-drivers gnustep-base-runtime libgnustep-base1.26 gnustep-base-common gnustep-common libgc1c2 libobjc4 powermgmt-base unar ; apt-get -y clean" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Final clean-up.log"

SET /A SESMAN = %RDPPRT% - 50
%GO% "which schtasks.exe" > "%TEMP%\SCHT.tmp" & set /p SCHT=<"%TEMP%\SCHT.tmp"
%GO% "sed -i 's#SCHT#%SCHT%#g' /tmp/kWSL/dist/usr/local/bin/restartwsl ; sed -i 's#DISTRO#%DISTRO%#g' /tmp/kWSL/dist/usr/local/bin/restartwsl"
%GO% "sed -i 's/QQQ/%WINDPI%/g' /tmp/kWSL/dist/etc/skel/.config/kdeglobals"
%GO% "sed -i 's/QQQ/%LINDPI%/g' /tmp/kWSL/dist/etc/skel/.config/kcmfonts"
%GO% "sed -i 's/KPANEL/%KPANEL%/g' /tmp/kWSL/dist/etc/skel/.config/plasmashellrc"
%GO% "sed -i 's/ListenPort=3350/ListenPort=%SESMAN%/g' /etc/xrdp/sesman.ini"
%GO% "sed -i 's/thinclient_drives/.kWSL/g' /etc/xrdp/sesman.ini"
%GO% "sed -i 's/port=3389/port=%RDPPRT%/g' /tmp/kWSL/dist/etc/xrdp/xrdp.ini ; cp /tmp/kWSL/dist/etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini"
%GO% "sed -i 's/#Port 22/Port %SSHPRT%/g' /etc/ssh/sshd_config"
%GO% "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
%GO% "sed -i 's/WSLINSTANCENAME/%DISTRO%/g' /tmp/kWSL/dist/usr/local/bin/initwsl"
%GO% "sed -i 's/\\h/%DISTRO%/g' /tmp/kWSL/dist/etc/skel/.bashrc ; ln -s /usr/lib/x86_64-linux-gnu/libexec/kf5/kdesu /usr/bin/kdesu"
%GO% "rm /usr/lib/x86_64-linux-gnu/qt5/plugins/discover/fwupd-backend.so"
%GO% "sed -i 's#Exec=ksystemlog -qwindowtitle %%c#Exec=kdesu -n --noignorebutton -d -- bash -c +source /etc/profile.d/kWSL.sh ; ksystemlog -qwindowtitle %%c+#g' /usr/share/applications/org.kde.ksystemlog.desktop ; sed -i 's#+#\"#g' /usr/share/applications/org.kde.ksystemlog.desktop ; sed -i 's#X-KDE-SubstituteUID=true#X-KDE-SubstituteUID=false#g' /usr/share/applications/org.kde.ksystemlog.desktop"
%GO% "sed -i 's#Exec=plasma-discover %%F#Exec=kdesu -n --noignorebutton -d -- bash -c +source /etc/profile.d/kWSL.sh ; plasma-discover --backends packagekit-backend,kns-backend %%F+#g' /usr/share/applications/org.kde.discover.desktop"
%GO% "sed -i 's#Exec=plasma-discover --mode update#Exec=kdesu -n --noignorebutton -d -- bash -c +source /etc/profile.d/kWSL.sh ; plasma-discover --backends packagekit-backend,kns-backend --mode update+#g' /usr/share/applications/org.kde.discover.desktop ; sed -i 's#+#\"#g' /usr/share/applications/org.kde.discover.desktop"
%GO% "sed -i 's#Exec=plasma-discover --mode update#Exec=kdesu -n --noignorebutton -d -- bash -c +source /etc/profile.d/kWSL.sh ; plasma-discover --backends packagekit-backend,kns-backend --mode update+#g' /usr/share/applications/org.kde.discover.urlhandler.desktop ; sed -i 's#+#\"#g' /usr/share/applications/org.kde.discover.urlhandler.desktop"
%GO% "sed -i 's#Exec=plasma-discover --mode update#Exec=kdesu -n --noignorebutton -d -- bash -c +source /etc/profile.d/kWSL.sh ; plasma-discover --backends packagekit-backend,kns-backend --mode update+#g' /usr/share/applications/org.kde.discover.apt.urlhandler.desktop ; sed -i 's#+#\"#g' /usr/share/applications/org.kde.discover.apt.urlhandler.desktop"
%GO% "sed -i 's#Exec=muon#Exec=kdesu -n --noignorebutton -d -- bash -c +source /etc/profile.d/kWSL.sh ; muon+#g' /usr/share/applications/org.kde.muon.desktop ; sed -i 's#+#\"#g' /usr/share/applications/org.kde.muon.desktop"
%GO% "sed -i 's/#enable-dbus=yes/enable-dbus=no/g' /etc/avahi/avahi-daemon.conf ; sed -i 's/#host-name=foo/host-name=%COMPUTERNAME%-%DISTRO%/g' /etc/avahi/avahi-daemon.conf ; sed -i 's/use-ipv4=yes/use-ipv4=no/g' /etc/avahi/avahi-daemon.conf"
%GO% "cp /mnt/c/Windows/Fonts/*.ttf /usr/share/fonts/truetype ; rm -rf /etc/pam.d/systemd-user ; rm -rf /etc/systemd ; ssh-keygen -A ; adduser xrdp ssl-cert" > NUL
%GO% "sed -i 's/adwaita//g' /usr/share/themes/Breeze/gtk-2.0/widgets/misc ; sed -i 's/adwaita//g' /usr/share/themes/Breeze-Dark/gtk-2.0/widgets/misc ; rm -rf /usr/share/themes/Default ; cp -Rp /usr/share/themes/Breeze-Dark /usr/share/themes/Default"
%GO% "chmod 644 /tmp/kWSL/dist/etc/wsl.conf ; chmod 644 /tmp/kWSL/dist/var/lib/xrdp-pulseaudio-installer/*.so"
%GO% "chmod 755 /tmp/kWSL/dist/usr/local/bin/restartwsl ; cp /tmp/kWSL/dist/usr/local/bin/restartwsl /tmp/kWSL/dist/etc/skel/.config/plasma-workspace/shutdown/restartwsl ; chmod 755 /tmp/kWSL/dist/usr/local/bin/initwsl ; chmod -R 700 /tmp/kWSL/dist/etc/skel/.config ; chmod -R 7700 /tmp/kWSL/dist/etc/skel/.local ; chmod -R 7700 /tmp/kWSL/dist/etc/skel/.cache ; chmod 700 /tmp/kWSL/dist/etc/skel/.mozilla"
%GO% "chmod 755 /tmp/kWSL/dist/etc/profile.d/kWSL.sh ; chmod +x /tmp/kWSL/dist/etc/profile.d/kWSL.sh ; chmod 755 /tmp/kWSL/dist/etc/xrdp/startwm.sh ; chmod +x /tmp/kWSL/dist/etc/xrdp/startwm.sh"
%GO% "rm /usr/lib/systemd/system/dbus-org.freedesktop.login1.service /usr/share/dbus-1/system-services/org.freedesktop.login1.service /usr/share/polkit-1/actions/org.freedesktop.login1.policy"
%GO% "rm /usr/share/dbus-1/services/org.freedesktop.systemd1.service /usr/share/dbus-1/system-services/org.freedesktop.systemd1.service /usr/share/dbus-1/system.d/org.freedesktop.systemd1.conf /usr/share/polkit-1/actions/org.freedesktop.systemd1.policy"
%GO% "unamestr=`uname -r` ; if [[ "$unamestr" == '4.4.0-17763-Microsoft' ]]; then apt-get purge -y plasma-discover ; sed -i 's/discover/muon/g' /tmp/kWSL/dist/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc ; ln -s /usr/bin/software-properties-qt /usr/bin/software-properties-kde ; fi" > NUL
%GO% "cp -Rp /tmp/kWSL/dist/* / ; cp -Rp /tmp/kWSL/dist/etc/skel/.cache /root ; cp -Rp /tmp/kWSL/dist/etc/skel/.config /root ; cp -Rp /tmp/kWSL/dist/etc/skel/.local /root"
START /MIN /WAIT "KDE Patches for WSL1" "%DISTROFULL%\LxRunOffline.exe" "r" "-n" "%DISTRO%" "-c" "dpkg -i /tmp/kWSL/deb/libkf5activitiesstats1_5.95.0-0xneon+20.04+focal+release+build42_amd64.deb /tmp/kWSL/deb/kactivitymanagerd_5.25.0-0xneon+20.04+focal+release+build44_amd64.deb /tmp/kWSL/deb/kinfocenter_5.18.5-0ubuntu0.1_amd64.deb ; apt-mark hold libkf5activitiesstats1 kactivitymanagerd kinfocenter ; DEBIAN_FRONTEND=noninteractive apt-get -qqy dist-upgrade"
SET RUNEND=%date% @ %time:~0,5%
CD %DISTROFULL% 
ECHO:
SET /p XU=Enter name of primary user for %DISTRO%: 
POWERSHELL -Command $prd = read-host "Enter password for %XU%" -AsSecureString ; $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($prd) ; [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) > .tmp & set /p PWO=<.tmp
%GO% "useradd -m -p nulltemp -s /bin/bash %XU%"
%GO% "(echo '%XU%:%PWO%') | chpasswd"
%GO% "echo '%XU% ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
%GO% "sed -i 's/PLACEHOLDER/%XU%/g' /tmp/kWSL/kWSL.rdp"
%GO% "sed -i 's/COMPY/%COMPUTERNAME%/g' /tmp/kWSL/kWSL.rdp"
%GO% "sed -i 's/RDPPRT/%RDPPRT%/g' /tmp/kWSL/kWSL.rdp"
%GO% "cp /tmp/kWSL/kWSL.rdp ./kWSL._"
ECHO $prd = Get-Content .tmp > .tmp.ps1
ECHO ($prd ^| ConvertTo-SecureString -AsPlainText -Force) ^| ConvertFrom-SecureString ^| Out-File .tmp >> .tmp.ps1
POWERSHELL -ExecutionPolicy Bypass -Command ./.tmp.ps1
TYPE .tmp>.tmpsec.txt
COPY /y /b kWSL._+.tmpsec.txt "%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp" > NUL
DEL /Q kWSL._ .tmp*.* > NUL
ECHO:
ECHO Open Windows Firewall Ports for xRDP, SSH, mDNS...
NETSH AdvFirewall Firewall add rule name="%DISTRO% xRDP" dir=in action=allow protocol=TCP localport=%RDPPRT% > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% Secure Shell" dir=in action=allow protocol=TCP localport=%SSHPRT% > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% Avahi Multicast DNS" dir=in action=allow program="%DISTROFULL%\rootfs\usr\sbin\avahi-daemon" enable=yes > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% KDE Connect" dir=in action=allow program="%DISTROFULL%\rootfs\usr\lib\x86_64-linux-gnu\libexec\kdeconnectd" enable=yes > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% KDEinit" dir=in action=allow program="%DISTROFULL%\rootfs\usr\bin\kdeinit5" enable=yes > NUL
START /MIN "%DISTRO% Init" WSL ~ -u root -d %DISTRO% -e initwsl 2
ECHO Building RDP Connection file, Console link, Init system...
ECHO @START /MIN "%DISTRO%" WSLCONFIG.EXE /t %DISTRO%                  >  "%DISTROFULL%\Init.cmd"
ECHO @Powershell.exe -Command "Start-Sleep 3"                          >> "%DISTROFULL%\Init.cmd"
ECHO @START /MIN "%DISTRO%" WSL.EXE ~ -u root -d %DISTRO% -e initwsl 2 >> "%DISTROFULL%\Init.cmd"
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
