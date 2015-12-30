# Private Messaging extenstion, relies on an ii patch

priv-mon() {
    tail -F -n0 --pid=$1 "$ircdir/$network/out" | \
        while read -r date time source 'msg'; do
            if [[ "$msg" =~ ^'`'(.*)'`'$ && "$source" == '-!-' ]] ; then
                channel=${msg#\`}
                channel=${channel%\`}
                monitor $1 &
            fi
        done
}

for network in ${!networks[@]} ; do
    priv-mon $botpid &
done

