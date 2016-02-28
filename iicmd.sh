
nick="$1"
mesg="$2"
netw="$3"
chan="$4"

read -r cmd extra <<< "$mesg"

. ./config.sh

commands=( man bc cp echo fortune grep ping qdb google u wiki )
re=("${BASH_REMATCH[@]}")

qdb() { # Takes two patterns as $1 and $2, adds the messages to a file
    file="$qdbdir/$(date +%s).qdb"
    head -n-1 "$ircdir/$netw/$chan/out"\
        | tac | sed "/$1/q" | tac | sed "/$2/q" > "$file"
    echo "Added the $(wc -l $file | cut -f1 -d' ') messages starting with:"
    head -1 $file
}

unicode() {
    printf -- "%s\n" "$(curl -s 'http://codepoints.net/api/v1/search?na='"$1"'' | jq -r '.result | sort | implode' | sed 's/./& /g')"
}

codepoint() {
    cp="${1//[^0-9A-Fa-f]/}"
    printf -- "%s: \u$cp\n"\
        "$(curl -s 'http://codepoints.net/api/v1/codepoint/'$cp'?property=na'\
            | jq -r '.na')"
}

cook() { # Takes in a fortune query as $1, returns the first result
    out="$(timeout 3 fortune -ia -m "${1}" 2> /dev/null)"
    out="${out%%\%*}"
    echo "${out:=Fortune cookie not found.}"
}

guf() { # Takes either a part of speech or any word
  case ${1#\$} in
    adj|adv|noun|verb) # If PoS, return a random one, else return $1
      shuf -n1 "$botdir/dict/index.${1#\$}" | head -1 | cut -f1 -d" ";;
    *)
      echo "$1" ;;
  esac
}

rwiki() { # Takes no args, returns a random wiki page name
      url="https://en.wikipedia.org/w/api.php?format=json&action=query&list=random&rnnamespace=0&fnfilterredir=all&rnlimit=1"
      rand="$(curl -s "${url}" | jq '.query.random[0].title')"
      echo "${rand//\"/}" # http://xkcd.com/234/
}

pedia() { # Takes a wiki query as $1, returns the json search output
    url="https://en.wikipedia.org/w/api.php?format=json&action=opensearch&redirects=resolve&limit=1&search=${1}"
    echo "$(curl -s "${url}")"
}

case "$cmd" in
    man|help)
        if [[ -z "${extra}" ]]; then
            printf -- "Commands: %s | Source: https://github.com/lk86/backtick\n" "${commands[*]}"
        else
            # Takes a command as $1 and prints its help text
            ./help.sh ${extra#/}
        fi ;;
    bc|calc)
        export BC_LINE_LENGTH=0
        tail <<< "$nick: $(timeout 30 bc -lsq <<< "$extra")"
        ;;
    q|qdb)
        qdb ${extra#/}
        ;;
    echo|print)
        [[ "${extra}" =~ ^[@/!] ]] && extra="${extra}"
        printf -- "%s\n" "${extra}"
        ;;
    grep)
        file="$(grep -rilh --include=[0-9]*.qdb "${extra#/}" $qdbdir/)"
        if [[ $? -eq 0 ]]; then
            tail "$file"
        else
            echo "QDB entry not found"
        fi ;;
    # 4chan returns offensive fortunes.
    4chan|fortune)
        cookie="$([[ -n "$extra" ]] && cook "${extra}" || [[ $cmd == '4chan' ]] && fortune -seo || fortune -se)"
        printf -- "%s\n" "${cookie//	/  }"
        ;;
    ping)
        printf -- "%s: pong!\n" "${nick}"
        ;;
    # McGuf Aliases:
    mcguf) extra='$adj$ $noun$' ;&
    say)
        for w in $extra; do
            [[ $w =~ (.*)'$'(.*)'$'(.*) ]]
            re=("${BASH_REMATCH[@]}")
            out+="${re[1]}$(guf ${re[2]})${re[3]} "
        done
        printf -- "%s \n" "$out"
        ;;
    g|google)
        printf -- "%s: http://www.lmgtfy.com/?q=%s\n" "${nick}" "${extra// /+}"
        ;;
    w|wiki)
        [[ -z "${extra}" ]] && extra="$(rwiki)"
        wiki=$(pedia "${extra// /_}")
        if [[ "$(jq '.[2][0]' <<< "$wiki")" =~ '"'(.+)'"' ]] ; then
            page="$(jq '.[3][0]' <<< "$wiki")"
            printf -- "%s\n%s\n" "${BASH_REMATCH[1]}" "${page//\"/}"
        else
            printf -- "No results found for %s.\n" "${extra}"
        fi
         ;;
    u|unicode)
        unicode ${extra}
        ;;
    cp|codepoint)
        codepoint ${extra}
        ;;
esac
