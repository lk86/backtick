#! /usr/bin/env bash

. config.sh

trap : SIGTERM SIGINT

export ircdir botdir nickname

botpid=$$

# some privacy please, thanks
chmod 700 "$ircdir"
chmod 600 "$ircdir"/*/ident &>/dev/null

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
        done > "$ircdir/$network/$channel/in"
}

for network in ${!networks[@]} ; do
    # cleanup
    rm -f "$ircdir/$network/in"

    # connect to network - password is set through the env var IIPASS
    iistart="ii -i $ircdir -n $nickname -f $fullname -k IIPASS -s $network "
    if [[ -v ii_mod ]] ; then
        $iistart -u "$username" &
    else
        $iistart &
    fi
    pids+=($!)

    # wait for the connection
    while ! test -p "$ircdir/$network/in"; do sleep 1; done

    # auth to services
    [[ -e "$ircdir/$network/ident" ]] && \
        printf -- "/j nickserv identify %s\n" "${pass}" > "$ircdir/$network/in"
    rm -f "$ircdir/$network/nickserv/out" # clean that up - ident passwd is in there

    # join channels
    for channel in ${networks[$network]} ; do
        printf -- "/j %s\n" "$channel" > "$ircdir/$network/in"
        monitor $botpid &
    done
done

if [[ -v mc_shit ]] ; then
    . mc.sh
fi

if [[ -v ii_mod ]] ; then
    . pm.sh
fi

for pid in "${pids[@]}" ; do
    wait "$pid"
done

if [[ $? -gt 128 ]]
then
    for pid in "${pids[@]}" ; do
        kill "$pid"
    done
fi
