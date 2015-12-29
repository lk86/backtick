#! /usr/bin/env bash

: "${ircdir:=$HOME/backtick/ii-fifos}"
: "${botdir:=$HOME/backtick}"
: "${nickname:=\`}"

export ircdir botdir nickname

botpid=$$

[[ -v networks ]] || declare -A networks=(
    # [irc.sushigirl.tokyo]="#(•ө•)♡"
    [irc.foonetic.net]="#test"
)

# some privacy please, thanks
chmod 700 "$ircdir"
chmod 600 "$ircdir"/*/ident &>/dev/null

monitor() {
    tail -F -n0 --pid=$1 "$ircdir/$network/$channel/out" | \
        while read -r date time source 'msg'; do
            # if msg is by the system ignore it
            [[ "$source" == '-!-' ]] && continue
            # strip < and >. if msg is by ourself ignore it
            source="${source:1:-1}"
            [[ "$source" == "$nickname" ]] && continue

            # if msg contains a url, transform to url command
            [[ "$msg" =~ https?:// ]] && \
                exec ./iicmd.sh "$source" "url ${msg#* }" "$network" "$channel" | fold -w 255 &
            # if msg is a command, invoke iicmd
            if [[ "$msg" =~ ^'`'(.*)'`'$ || "$msg" =~ ^'$('(.*)')'$ ]] ; then
                msg=${BASH_REMATCH[1]}
                exec ./iicmd.sh "$source" "$msg" "$network" "$channel" | fold -w 255 &
            fi
        done > "$ircdir/$network/$channel/in"
}

mc-builds() {
    tail -F -n0 --pid=$1 "$botdir/mc-logs/chat.txt" | \
        while read -r date time nick 'msg'; do
            [[ $msg == \`* ]] && printf -- "%s %s \n" "$nick" "${msg#\`}"
        done > "$ircdir/$network/$channel/in"
}
mc-chat() {
    tail -F -n0 --pid=$1 "$botdir/mc-logs/chat.txt" | \
        while read -r date time nick 'msg'; do
            printf -- "%s %s \n" "$nick" "${msg#\`}"
        done > "$ircdir/$network/$channel/in"
}
mc-connect() {
    tail -F -n0 --pid=$1 "$botdir/mc-logs/connections.txt" | \
        while read -r date time nick status ip; do
            printf -- "%s %s the server.\n" "$nick" "${status%\.}"
        done > "$ircdir/$network/$channel/in"
}
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
    # cleanup
    rm -f "$ircdir/$network/in"

    # connect to network - password is set through the env var IIPASS
    ii -i "$ircdir" -n "$nickname" -u "lhk-bot" -f "backtick" -k IIPASS -s "$network" &
    iid="$!"

    # wait for the connection
    while ! test -p "$ircdir/$network/in"; do sleep 1; done

    # auth to services
    [[ -e "$ircdir/$network/ident" ]] && \
        printf -- "/j nickserv identify %s\n" "$(<"$ircdir/$network/ident")" > "$ircdir/$network/in"
    rm -f "$ircdir/$network/nickserv/out" # clean that up - ident passwd is in there

    # join channels
    for channel in ${networks[$network]} ; do
        printf -- "/j %s\n" "$channel" > "$ircdir/$network/in"
        monitor $botpid &
        pids+=($!)
    done
done

network="irc.foonetic.net"
channel="#builds"
mc-builds $iid &

channel="#builds-mc"
mc-connect $iid &
mc-chat $iid &

for network in ${!networks[@]} ; do
    priv-mon $iid &
done

for pid in "${pids[@]}" ; do
    wait "$pid"
done
