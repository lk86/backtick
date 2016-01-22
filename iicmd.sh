#!/usr/bin/env bash

nick="$1"
mesg="$2"
netw="$3"
chan="$4"

read -r cmd extra <<< "$mesg"

commands=(
    man
    bc
    qdb
    echo
    grep
    fortune
    ping
    w
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
        printf -- "%s\n" "$(sed -e 's/^[@/\!]/&/' <<< ${extra})"
        ;;
    grep)
        file="$(grep -rilh --include=[1-9]*.qdb "${extra#/}" $botdir/qdb/)"
        if [[ $? -eq 0 ]]; then
            tail "$file"
        else
            echo "QDB entry not found"
        fi
        ;;
    fortune)
        if [[ -n "$extra" ]]; then
            tail <<< "$(fortune -sea -m "${extra#/}")"
        else
            printf -- "%s\n" "$(fortune -sea)"
        fi
        ;;
    ping)
        printf -- "%s: pong!\n" "$nick"
        ;;
    w)
        url="https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exsentences=2&exintro=&explaintext=&titles=${extra}"
        url="$(sed -e 's/ /_/g' <<< ${url})"
        printf -- "%s\n" "$(curl -s "${url}" | jq '.query.pages|keys[0] as $page|.[$page].extract')"
        ;;
esac
