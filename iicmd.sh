
nick="$1"
mesg="$2"
netw="$3"
chan="$4"

read -r cmd extra <<< "$mesg"

. ./config.sh

commands=(
    man
    bc
    cp
    echo
    fortune
    grep
    ping
    qdb
    g
    u
    w
)

qdb() {
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

guf() {
  case ${1#\$} in
    adj|adv|noun|verb)
      shuf -n1 "$botdir/dict/index.${1#\$}" | head -1 | cut -f1 -d" ";;
    *)
      echo "$1" ;;
  esac
}

case "$cmd" in
    man|help)
        if [[ -z "${extra}" ]]; then
            printf -- "Commands: %s | Source: https://github.com/lk86/backtick\n" "${commands[*]}"
        else
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
    4chan|fortune)
        if [[ -n "$extra" ]]; then
            cookie="$(timeout 3 fortune -ia -m "${extra#/}" 2> /dev/null)"
            cookie="${cookie%%\%*}"
            cookie="${cookie//	/  }"
            printf -- "%s\n" "${cookie:=Fortune cookie not found.}"
        else
            cookie="$([[ $cmd == '4chan' ]] && fortune -seo || fortune -se)"
            printf -- "%s\n" "${cookie//	/  }"
        fi ;;
    ping)
        printf -- "%s: pong!\n" "${nick}"
        ;;
    mcguf) extra='$adj$ $noun$' ;&
    say)
        out=""
        for w in $extra; do
            [[ $w =~ (.*)'$'(.*)'$'(.*) ]] && \
                w=${BASH_REMATCH[1]}$(guf ${BASH_REMATCH[2]})${BASH_REMATCH[3]}
            out+="$w "
        done
        printf -- "%s \n" "$out"
        ;;
    g|google)
        printf -- "%s: http://www.lmgtfy.com/?q=%s\n" "${nick}" "${extra// /+}"
        ;;
    w|wiki)
        if [[ -z "${extra}" ]]; then
            url="https://en.wikipedia.org/w/api.php?format=json&action=query&list=random&rnnamespace=0&fnfilterredir=all&rnlimit=1"
            extra="$(curl -s "${url}" | jq '.query.random[0].title')"
            # http://xkcd.com/234/
            extra="${extra//\"/}"
        fi
        url="https://en.wikipedia.org/w/api.php?format=json&action=opensearch&redirects=resolve&limit=1&search=${extra// /_}"
        wiki="$(curl -s "${url}")"
        page="$(jq '.[3][0]' <<< "$wiki")"
        wiki="$(jq '.[2][0]' <<< "$wiki")"
        if [[ "${wiki}" =~ '"'(.+)'"' ]] ; then
            printf -- "%s\n" "${BASH_REMATCH[1]}"
            printf -- "%s\n" "${page//\"/}"
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
