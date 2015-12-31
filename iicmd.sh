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
        nicks="$(tail -n2 "$ircdir/$netw/out" | grep "[[:digit:]-]\+ [[:digit:]:]\+ = $chan" | cut -d" " -f5-)"
        sleep .5
    done
fi

commands=(
    man
    bc
    qdb
    grep
    fortune
    ping
    talkto
    whereami
)

qdb() {
    file="$botdir/qdb/$(date +%s).qdb"

    sed -ne '/'"$1"'/,$p' -e '/'"$2"'/q' "$ircdir/$netw/$chan/out" > "$file"

    echo "Added the $(wc -l $file | cut -f1 -d' ') messages starting with:"
    echo "$(head -1 $file)"
}

case "$cmd" in
    man)
        [[ -n "$nicks" ]] && printf -- "%s: %s\n" "$nicks" "${commands[*]}" || printf -- "%s: %s | " "$nick" "${commands[*]}"
        echo "See my source at https://github.com/lk86/iibot"
        ;;
    bc)
        [[ -n "$extra" ]] && printf -- "%f\n" "$(bc -l <<< "$extra")"
        ;;
    talkto)
        printf -- "@talk %s \n" "${extra#/}"
        ;;
    qdb)
        qdb ${extra#/}
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
        printf -- "%s\n" "$(fortune -osea)"
        ;;
    ping)
        [[ -n "$nicks" ]] && printf -- "%s: ping!\n" "$nicks" || printf -- "%s: pong!\n" "$nick"
        ;;
    die)
        if [[ "$nick" == \`lhk\` ]]
        then
            killall ii
        else
            printf -- "%s: Go Die\n" "$nick"
        fi
        ;;
    restart)
        killall ii
        ./iibot.sh
        ;;
    whereami)
        printf -- "%s: That's a damn good question. I'm gonna guess %s?\n" "$nick" "$chan"
        ;;
esac

