#!/bin/bash

set -e

APP_NAME="com.batterymonitor"

BIN_DIR="$HOME/bin"
SCRIPT="$BIN_DIR/battery-monitor.sh"
INSTALLER="$BIN_DIR/install-batterymonitor.sh"

PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST="$PLIST_DIR/$APP_NAME.plist"



show_help () {
cat <<EOF

Battery Monitor

Usage:

  $0 --install
      Install Battery Monitor

  $0 --test
      Test alerts

  $0 --uninstall
      Remove Battery Monitor

  $0 --help
      Show this help

EOF
}



test_mode () {

echo "=== Battery Monitor Test ==="

afplay /System/Library/Sounds/Sosumi.aiff >/dev/null 2>&1 &


osascript <<EOF
display dialog "Save your work and connect the charger." \
with title "Battery 30%" \
buttons {"OK"} \
default button "OK" \
with icon caution
EOF


osascript <<EOF
display dialog "Connect the charger as soon as possible." \
with title "Low Battery 25%" \
buttons {"OK"} \
default button "OK" \
with icon caution
EOF


osascript <<EOF
display dialog "The computer will shut down in 5 minutes to prevent an unexpected power loss.\n\nConnect the charger now." \
with title "Critical Battery 20%" \
buttons {"Cancel","OK"} \
default button "OK" \
cancel button "Cancel" \
with icon caution
EOF

}



uninstall () {

echo "Removing Battery Monitor"

launchctl unload "$PLIST" >/dev/null 2>&1 || true

rm -f "$PLIST"
rm -f "$SCRIPT"
rm -f "$INSTALLER"

rm -f /tmp/.battery30
rm -f /tmp/.battery25
rm -f /tmp/.battery20

rm -f /tmp/batterymonitor.log
rm -f /tmp/batterymonitor.out
rm -f /tmp/batterymonitor.err

echo "Removed"

}



case "$1" in

--install)
;;

--test)
test_mode
exit 0
;;

--uninstall)
uninstall
exit 0
;;

--help|-h|"")
show_help
exit 0
;;

*)
show_help
exit 1
;;

esac



mkdir -p "$BIN_DIR"


cp "$0" "$INSTALLER"
chmod +x "$INSTALLER"



case ":$PATH:" in

*":$BIN_DIR:"*)
;;

*)
echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bash_profile"
echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
;;

esac



echo "Installing battery monitor script"



cat > "$SCRIPT" <<'BATTERY_SCRIPT'
#!/bin/bash

WARN1=30
WARN2=25
CRITICAL=20

FLAG30="/tmp/.battery30"
FLAG25="/tmp/.battery25"
FLAG20="/tmp/.battery20"

LOG="/tmp/batterymonitor.log"


log () {
echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG"
}


play_sound () {
afplay /System/Library/Sounds/Sosumi.aiff >/dev/null 2>&1 &
}


show_warning () {

TITLE="$1"
MESSAGE="$2"

play_sound

osascript <<DIALOG
display dialog "$MESSAGE" \
with title "$TITLE" \
buttons {"OK"} \
default button "OK" \
with icon caution
DIALOG

}



show_critical () {

TITLE="$1"
MESSAGE="$2"

play_sound

osascript <<DIALOG
display dialog "$MESSAGE" \
with title "$TITLE" \
buttons {"Cancel","OK"} \
default button "OK" \
cancel button "Cancel" \
with icon caution
DIALOG

}



reset_flags () {
rm -f "$FLAG30" "$FLAG25" "$FLAG20"
}



PERCENT=$(pmset -g batt | grep -o '[0-9]\+%' | head -1 | tr -d '%')


if ! [[ "$PERCENT" =~ ^[0-9]+$ ]]; then
exit 1
fi



if pmset -g batt | grep -q "AC Power"; then

log "Charger connected"

sudo killall shutdown >/dev/null 2>&1

reset_flags

exit 0

fi



log "Battery ${PERCENT}%"



if [ "$PERCENT" -le "$CRITICAL" ]; then

if [ ! -f "$FLAG20" ]; then


show_critical \
"Critical Battery ${PERCENT}%" \
"The computer will shut down in 5 minutes to prevent an unexpected power loss.\n\nConnect the charger now."


if [ $? -ne 0 ]; then

log "Shutdown cancelled"

exit 0

fi


touch "$FLAG20"


sudo /sbin/shutdown -h +5


fi

exit 0

fi



if [ "$PERCENT" -le "$WARN2" ] && [ ! -f "$FLAG25" ]; then

touch "$FLAG25"

show_warning \
"Low Battery ${PERCENT}%" \
"Connect the charger as soon as possible."

exit 0

fi



if [ "$PERCENT" -le "$WARN1" ] && [ ! -f "$FLAG30" ]; then

touch "$FLAG30"

show_warning \
"Battery ${PERCENT}%" \
"Save your work and connect the charger."

fi
BATTERY_SCRIPT



chmod +x "$SCRIPT"



echo "Installing LaunchAgent"



mkdir -p "$PLIST_DIR"



cat > "$PLIST" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">

<dict>

<key>Label</key>
<string>com.batterymonitor</string>

<key>ProgramArguments</key>
<array>
<string>$SCRIPT</string>
</array>

<key>RunAtLoad</key>
<true/>

<key>StartInterval</key>
<integer>180</integer>

<key>LimitLoadToSessionType</key>
<string>Aqua</string>

<key>StandardOutPath</key>
<string>/tmp/batterymonitor.out</string>

<key>StandardErrorPath</key>
<string>/tmp/batterymonitor.err</string>

</dict>

</plist>
PLIST_EOF



launchctl unload "$PLIST" >/dev/null 2>&1 || true

launchctl load "$PLIST"



echo ""
echo "Installed successfully"
echo ""
echo "Test:"
echo "$INSTALLER --test"