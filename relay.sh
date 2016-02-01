network="irc.foonetic.net"
channel="#builds-mc"
chat="$botdir/mc-logs/chat.txt"
joins="$botdir/mc-logs/connections.txt"
main="$ircdir/$network/$channel"

relay() {
    tail -F -n0 --pid=$1 "$2" | \
        while read -r date time nick 'msg'; do
            [[ "$nick" == '-!-' ]] || [[ "$nick" == "<$user>" ]] || printf -- "%s %s \n" "$nick" "${msg}"
        done > "$3/in"
}

relay $botpid $joins $main &
relay $botpid $chat $main &
