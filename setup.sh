#!/usr/bin/env bash

APPNAME='display-is-sleeping'
AGENT="${APPNAME}-agent"
PLIST="${AGENT}.plist"
AGENT_DIR="$HOME/Library/LaunchAgents"
BINDIR='/usr/local/bin'

_usage() {
cat <<EOF
Setup tool for $APPNAME LaunchAgent
Usage: ${0##*/} [args]
    -u,--uninstall   uninstall the LaunchAgent
    -i,--install     install the LaunchAgent
EOF
}

_uninstall() {
  launchctl bootout gui/$UID "${AGENT_DIR}/$PLIST" 2>/dev/null
}

case $1 in
  -u|--uninstall)
    if _uninstall; then
      echo "uninstalled $APPNAME LaunchAgent"
    else
      echo "nothing was uninstalled (maybe it was already removed?)"
    fi
    pkill -x $APPNAME
    rm "$BINDIR/$APPNAME" 2>/dev/null
    exit
    ;;
  -i|--install) : ;;
  -h|--help|*) _usage; exit;;
esac

mkdir -p "$BINDIR"
if ! cp -f ./$APPNAME "$BINDIR" ; then
  echo "failed to copy $APPNAME to $BINDIR"
  exit 1
fi
chmod +x "$BINDIR/$APPNAME"
_uninstall

cat >"${AGENT_DIR}/$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$AGENT</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BINDIR/$APPNAME</string>
    <string>--agent</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardErrorPath</key>
  <string>/tmp/${AGENT}.stderr</string>
  <key>StandardOutPath</key>
  <string>/tmp/${AGENT}.stdout</string>
  <key>WorkingDirectory</key>
  <string>/tmp</string>
</dict>
</plist>
EOF
chmod 644 "${AGENT_DIR}/$PLIST"

if launchctl bootstrap gui/$UID "${AGENT_DIR}/$PLIST"; then
  echo "installed $APPNAME LaunchAgent"
  echo "run \`$APPNAME --help\` for syntax"
fi
