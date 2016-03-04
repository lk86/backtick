#! /usr/bin/env bash

. config.sh

trap "cleanup" SIGTERM SIGINT

export ircdir botdir nickname

botpid=$$

# some privacy please, thanks
chmod 700 "$ircdir"
chmod 600 "$ircdir"/*/ident &>/dev/null

cleanup() {
    echo
    read -n 1 -rs -p "Kill ii's? (y/N)" choice
    echo
    case "$choice" in
        y|Y)
            kill ${pids[@]}
            exit ;;
        *)
            echo "pids+=\"${pids[@]}\"" >> pids
            echo "${pids[@]}"
            exit ;;
    esac
}


start_ii() {
    echo "Starting ii..."
    network=$1

    # cleanup
    rm -f "$ircdir/$network/in"

    # connect to network
    ${iistrings[$network]} 2> >(tee -a "$ircdir/$admin/in" >&2) &
    pids+=($!)

    # wait for the connection
    while ! test -p "$ircdir/$network/in"; do sleep 1; done

    # auth to services
    if [[ -n $ident ]] ; then # checks for config directive "ident"
        printf -- "/j nickserv identify %s\n" "${ident}" > "$ircdir/$network/in"
        rm -f "$ircdir/$network/nickserv/out" # ident passwd is in there
    fi
}

monitor() {
    tail -F -n0 --pid=$1 "$ircdir/$network/$channel/out" | \
        while read -r date time source 'msg'; do
            # if msg is by the system ignore it
            [[ "$source" == '-!-' ]] && continue
            # strip < and >. if msg is by ourself ignore it
            [[ "$source" == "<$nickname>" ]] && continue

            # if msg is a command, invoke iicmd
            if [[ "$msg" =~ ^'`'(.*)'`' || "$msg" =~ ^'$('(.*)')' ]] ; then
                msg=${BASH_REMATCH[1]}
                exec ./iicmd.sh "${source:1:-1}" "$msg" "$network" "$channel" &
            fi
        done > "$ircdir/$network/$channel/in" 2> >(tee "$ircdir/$admin/in" >&2)
}

restart_ii() {
    wait "${pids[-1]}"
    kill "${pids[@]}"
    while kill -0 "${pids[@]}" ; do sleep 2; done
    pids=()
    for network in ${!networks[@]} ; do
        start_ii $network
        for channel in ${networks[$network]} ; do
            printf -- "/j %s\n" "$channel" > "$ircdir/$network/in"
        done
    done
}

if [[ -r pids ]] ; then
    . pids
    ii_running="true"
    rm pids
fi


for network in ${!networks[@]} ; do
    [[ $ii_running ]] || start_ii $network

    for channel in ${networks[$network]} ; do
        printf -- "/j %s\n" "$channel" > "$ircdir/$network/in"
        monitor $botpid &
    done
done

if [[ -v relay ]] ; then
    . relay.sh
fi

if [[ -v pm ]] ; then
    . pm.sh
fi

echo "Bot is running."

while echo "Waiting on ${pids[-1]}" ; do
    restart_ii "${pids[-1]}"
done
