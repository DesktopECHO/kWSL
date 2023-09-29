#!/bin/sh
# xrdp X session start script (c) 2015, 2017, 2021 mirabilos
# published under The MirOS Licence

# Rely on /etc/pam.d/xrdp-sesman using pam_env to load both
# /etc/environment and /etc/default/locale to initialise the
# locale and the user environment properly.

if test -r /etc/profile; then
        . /etc/profile
fi

if test -r $HOME/.profile; then
        . $HOME/.profile
fi

STARTUP=default

if [ -n "$DESKTOP_SESSION" ] && [ -d /usr/share/xsessions ] \
  && [ -f "/usr/share/xsessions/$DESKTOP_SESSION.desktop" ]; then
  STARTUP=$(grep ^Exec= "/usr/share/xsessions/$DESKTOP_SESSION.desktop")
  STARTUP=${STARTUP#Exec=*}
  XDG_CURRENT_DESKTOP=$(grep ^DesktopNames= "/usr/share/xsessions/$DESKTOP_SESSION.desktop")
  XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP#DesktopNames=*}
  export XDG_CURRENT_DESKTOP
fi

if [ "$XRDP_USE_MULTISESSION" = 1 ]; then
  eval $( /etc/xrdp/systemd_user_context.sh init -p $$ )
fi

test -d "$XDG_RUNTIME_DIR" && echo $XDG_SESSION_ID > $XDG_RUNTIME_DIR/login-session-id

if [ "$STARTUP" = "default" ]; then
  if test -x /etc/X11/Xsession; then
      exec /etc/X11/Xsession
  else
      exec /bin/sh /etc/X11/Xsession
  fi
else
  if test -x /etc/X11/Xsession; then
      exec /etc/X11/Xsession "$STARTUP"
  else
      exec /bin/sh /etc/X11/Xsession "$STARTUP"
  fi
fi

