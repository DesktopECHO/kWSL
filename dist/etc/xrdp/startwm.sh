#!/bin/sh
# xrdp X session start script (c) 2015, 2017, 2021 mirabilos
# published under The MirOS Licence

# Rely on /etc/pam.d/xrdp-sesman using pam_env to load both
# /etc/environment and /etc/default/locale to initialise the
# locale and the user environment properly.

if test -r /etc/profile; then
        . /etc/profile
fi

if test -r ~/.profile; then
        . ~/.profile
fi

#test -x /etc/X11/Xsession && exec /etc/X11/Xsession
#exec /bin/sh /etc/X11/Xsession

nohup bash -c '
sleep 15
while true; do
    # --- Check KWin (Window Manager) ---
    if ! pgrep -u "$USER" kwin_x11 >/dev/null; then
        echo "$(date): KWin missing. Restarting..." >> /tmp/kde-watchdog.log
        dbus-launch kwin_x11 --replace >> /tmp/kde-watchdog.log 2>&1 &
        sleep 2
    fi

    # --- Check Plasma (Taskbar/Desktop) ---
    if ! pgrep -u "$USER" plasmashell >/dev/null; then
        echo "$(date): Plasmashell missing. Restarting..." >> /tmp/kde-watchdog.log
        dbus-launch plasmashell >> /tmp/kde-watchdog.log 2>&1 &
        sleep 2
    fi

    sleep 1
done' >/dev/null 2>&1 &

dbus-run-session startplasma-x11
