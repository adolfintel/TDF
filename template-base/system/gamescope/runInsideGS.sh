#/bin/bash
XRES=$(cat /sys/class/graphics/*/virtual_size | cut -d ',' -f 1)
YRES=$(cat /sys/class/graphics/*/virtual_size | cut -d ',' -f 2)
dispid=""
tempFile="/tmp/displayid$RANDOM"
rm -f "$tempFile"
(
    if [ -z "$gamescopeParameters" ]; then
        gamescopeParameters="-f -w $XRES -h $YRES"
    fi
    gamescope $gamescopeParameters 2>&1 | grep --line-buffered "Starting Xwayland on" > "$tempFile"
) &
gspid=$!
for i in $(seq 1 10); do
    if [ -e "$tempFile" ]; then
        dispid=$(cat "$tempFile" | rev | cut -d ':' -f -1 | rev)
        if [ ! -z "$dispid" ]; then
            dispid=":$dispid"
            rm -f "$tempFile"
            break
        fi
    fi
    sleep 1
done
if [ -z "$dispid" ]; then
    zenity --error --text "Gamescope failed to start"
    exit 1
fi
( DISPLAY="$dispid" $* ) &
wait $!
sleep 1
pkill -P $gspid
