#!/bin/bash
# Copy a script into /root of a GNS3 node through its telnet console, then check that the checksum matches.
# Usage: tools/push-script.sh <script.sh> <console-port> [gns3-host]
#   example: tools/push-script.sh 01/01_jichi_router.sh 5027
set -e
FILE=${1:?usage: $0 <script.sh> <console-port> [gns3-host]}
PORT=${2:?usage: $0 <script.sh> <console-port> [gns3-host]}
HOST=${3:-10.4.89.250}
NAME=$(basename "$FILE")
B64=$(base64 -w0 "$FILE")

# send the file as base64, so quotes and special characters in the script survive the console
exec 3<>/dev/tcp/"$HOST"/"$PORT"
sleep 1; printf '\r\n' >&3; sleep 0.5
printf 'echo %s | base64 -d > /root/%s && chmod +x /root/%s\r\n' "$B64" "$NAME" "$NAME" >&3
sleep 3
exec 3>&-

# read the checksum back from the node
exec 3<>/dev/tcp/"$HOST"/"$PORT"
REMOTE=$( { sleep 0.5; printf '\r\nmd5sum /root/%s 2>&1\r\n' "$NAME" >&3; sleep 2; } & \
          timeout 5 cat <&3 | tr -d '\000\r' | sed 's/\x1b\[[0-9;?]*[a-zA-Z]//g' | grep -aoE '^[0-9a-f]{32}' | tail -n1 || true )
exec 3>&-
LOCAL=$(md5sum < "$FILE" | cut -c1-32)
if [ "$LOCAL" = "$REMOTE" ]; then
    echo "OK    /root/$NAME on port $PORT ($LOCAL)"
else
    echo "FAIL  /root/$NAME on port $PORT (local $LOCAL, node ${REMOTE:-none})" >&2
    exit 1
fi
