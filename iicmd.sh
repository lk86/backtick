#!/usr/bin/env bash

nick="$1"
mesg="$2"
netw="$3"
chan="$4"

read -r cmd extra <<< "$mesg"
if [[ "$mesg" =~ .*\>.+ ]]; then
    read -r nicks <<< "${extra#*>}"
    read -r extra <<< "${extra%>*}"
fi

if [[ "$nicks" == "@all" ]]; then
    printf -- "/names %s\n" "$chan"
    nicks=""
    while test -z "$nicks"; do # wait for the response
        nicks="$(tail -n2 "$ircd/$netw/out" | grep "[[:digit:]-]\+ [[:digit:]:]\+ = $chan" | cut -d" " -f5-)"
        sleep .5
    done
fi

commands=(
    man
    bc
    qdb
    echo
    grep
    die
    restart
    fortune
    ping
    whereami
)

qdb() {
    file="$botdir/qdb/$(date +%s).qdb"

    sed -ne '/'"$1"'/,$p' -e '/'"$2"'/q' "$ircdir/$netw/$chan/out" > "$file"

    echo "Added the $(wc -l $file | cut -f1 -d' ') messages starting with:"
    head -1 $file
}

case "$cmd" in
    man)
        printf -- "Commands: %s | Source: https://github.com/lk86/backtick\n" "${commands[*]}"
        ;;
    bc)
        export BC_LINE_LENGTH=0
        tail <<< "$nick: $(timeout 30 bc -lsq <<< "$extra")"
        ;;
    qdb)
        qdb ${extra#/}
        ;;
    echo)
        printf -- "%s\n" "$(sed -e 's/^[@|/|\!]/&/' <<< $extra)"
        ;;
    grep)
        file="$(grep -rilh --include=[1-9]*.qdb "${extra#/}" $botdir/qdb/)"
        if [[ $? -eq 0 ]]; then
            [[ "$chan" == \#builds ]] && tail "$file" || cat "$file"
        else
            echo "QDB entry not found"
        fi
        ;;
    fortune)
        if [[ -n "${extra}" ]]; then
            tail <<< "$(fortune -sea -m "${extra#/}")"
        else
            printf -- "%s\n" "$(fortune -sea)"
        fi
        ;;
    ping)
        [[ -n "$nicks" ]] && printf -- "%s: ping!\n" "$nicks" || printf -- "%s: pong!\n" "$nick"
        ;;
    die)
        if [[ "$nick" == '`lhk`' ]]
        then
            killall ii
        else
            printf -- "%s: Go Die \n" "$nick"
        fi
        ;;
    restart)
        killall ii
        ./iibot.sh
        ;;
    whereami)
        printf -- "%s: Seems like we're in %s.\n" "$nick" "$chan"
        ;;
esac

