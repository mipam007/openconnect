#!/bin/sh

. ./.vars

case "$1" in
  start)
    if [ -f "$PIDFILE" ]; then
      PID=$(cat "$PIDFILE")
      if ps -p "$PID" > /dev/null 2>&1; then
        echo "The VPN is already running with PID $PID."
        exit 1
      else
        rm "$PIDFILE"
      fi
    fi

    echo "Starting VPN connection..."

    sudo openconnect --usergroup="$USERGROUP" \
        --form-entry=main:username="$USERNAME" \
        --form-entry=main:password="$PASSWORD" \
        --form-entry=main:secondary_password="$PIN" \
        --os="$OS" --protocol=anyconnect \
        --cafile="$CAFILE" "$VPN_URL" > /dev/null 2>&1 &

    VPN_PID=$!
    echo "The VPN process has started with PID $VPN_PID."

    if [ "$REQUEST_SMS_TOKEN" = "yes" ]; then
      TOKEN_CODE=""
      while [ -z "$TOKEN_CODE" ]; do
        echo "Please check your SMS for the SecurID Token code."
        printf "Enter your SecurID Token code (press ENTER to refresh): "
        read TOKEN_CODE
        if [ -n "$TOKEN_CODE" ]; then
          if ps -p "$VPN_PID" > /dev/null 2>&1; then
           
        sudo kill -s SIGUSR2 "$VPN_PID"
        sleep 2
      else
        echo "The VPN process is no longer running. Restarting the VPN connection."
      fi

      sudo openconnect --usergroup="$USERGROUP" \
          --form-entry=main:username="$USERNAME" \
          --form-entry=main:password="$PASSWORD" \
          --form-entry=main:secondary_password="$PIN$TOKEN_CODE" \
          --os="$OS" --protocol=anyconnect \
          --cafile="$CAFILE" "$VPN_URL" > /dev/null 2>&1 &

      NEW_VPN_PID=$!
      echo $NEW_VPN_PID > "$PIDFILE"
      echo "The VPN has been updated with the token and is now running with PID $NEW_VPN_PID."
    fi
  done
else
  echo $VPN_PID > "$PIDFILE"
fi
;;
  stop)
    if [ -f "$PIDFILE" ]; then
      PID=$(cat "$PIDFILE")
      sudo kill "$PID"
      rm "$PIDFILE"
      echo "The VPN has been stopped."
    else
      echo "The VPN is not running."
    fi
    ;;

  status)
    if [ -f "$PIDFILE" ]; then
      PID=$(cat "$PIDFILE")
      if ps -p "$PID" > /dev/null 2>&1; then
        echo "The VPN is running with PID $PID."
      else
        rm "$PIDFILE"
        echo "The VPN is not running."
      fi
    else
      echo "The VPN is not running."
    fi
    ;;

  *)
    echo "Usage: $0 {start|stop|status}"
    exit 1
    ;;
esac

