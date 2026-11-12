action=$1

eww close profile

case $action in
    "shutdown")
        shutdown now
        ;;
    "reboot")
        reboot
        ;;
    "logout")
        loginctl terminate-user $USER
        # atau: pkill -KILL -u $USER
        ;;
    "sleep")
        systemctl suspend
        ;;
    "lock")
        hyprlock
        ;;
esac
