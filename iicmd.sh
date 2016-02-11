
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
            | jq -j .na)"
}

help() {
    case "$1" in
        man|help)
            txt='Description: Display help text. Usage: `man <command>` - prints help text for <command>. | `man` - prints command list and github link.' ;;
        bc|calc)
            txt='Description: Perform calculations with GNU bc, the basic calculator. Usage: `bc <bc expression>` - prints one line of bc -lsq output, if calculation completes in <30 seconds' ;;
        qdb)
            txt='Description: Adds quotes to the quote database. Usage: `qdb <start regex> <end regex>` - adds messages sent between a message matching <start regex> and one matching <end message> inclusive to qdb' ;;
        echo|print)
            txt='Description: Echoes back its input. Usage: `echo <string>` - prints <string>, sanitized to not trigger averybot, lurker, or ii' ;;
        grep)
            txt='Description: Searches for qdb entry matching a given pattern. Usage: `qdb <pattern>` - prints the last 10 lines of the first matching qdb entry found' ;;
        fortune)
            txt='Description: Fortune cookie database interface. Usage: `fortune` - prints a random fortune from the database. | `fortune <pattern>` - prints the first 10 lines of matching fortune cookies' ;;
        ping)
            txt='Description: Test function to verify bot functionality. Usage: `ping` - replies "pong!"' ;;
        g|google)
            txt='Description: Prints link to desired google query. Usage: `g <query>` - replies with search link' ;;
        w|wiki)
            txt='Description: Queries en.wikipedia.org for a page, and returns a summary of the topic. Usage: `w <page>` - prints either the first 4 sentences or first graph (whichever is shorter) of wiki entry <page> | `w` - prints that summary information for a random wiki page' ;;
        *)
            txt='Command not found. This functionality is either not availible or not stable' ;;
esac

printf -- "%s\n" "${txt}"
}

case "$cmd" in
    man|help)
        if [[ -z "${extra}" ]]; then
            printf -- "Commands: %s | Source: https://github.com/lk86/backtick\n" "${commands[*]}"
        else
            help ${extra#/}
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
    fortune)
        if [[ -n "$extra" ]]; then
            cookie="$(timeout 3 fortune -ia -m "${extra#/}" 2> /dev/null)"
            cookie="${cookie%%\%*}"
            cookie="${cookie//	/  }"
            printf -- "%s\n" "${cookie:=Fortune cookie not found.}"
        else
            cookie="$(fortune -sea)"
            printf -- "%s\n" "${cookie//	/  }"
        fi ;;
    ping)
        printf -- "%s: pong!\n" "${nick}"
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
            printf -- "No results found for %s, got: %s\n" "${extra}" "${wiki}"
        fi
         ;;
    u|unicode)
        unicode ${extra}
        ;;
    cp|codepoint)
        codepoint ${extra}
        ;;
esac
