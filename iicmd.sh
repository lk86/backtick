nick="$1"
mesg="$2"
netw="$3"
chan="$4"

read -r cmd extra <<< "$mesg"

. ./config.sh

commands=( man bc echo fortune convo dont nn me mcguf say *gram \
            ping google wiki paste )

colorize() {
    echo $(for w in ${*}; do echo -n "$(($RANDOM % 15))${w} "; done)
}

cook() { # Takes in a fortune query as $1, returns the first result
    out="$(timeout 3 fortune -ia -m "${1}" 2> /dev/null)"
    out=$(echo $out | ./1line -i '%')
    echo "${out:=Fortune cookie not found.}"
}

guf() { # Takes either a part of speech or any word
    case $1 in
      adj|adv|noun|verb|word) # If PoS, return a random one, else return $1
        out="$(./1line -f "$botdir/dict/prince.${1}")"
        echo "${out//_/ }";;
      "a adj"|"a adv"|"a noun"|"a verb"|"a word")
        out="$(./1line -f "$botdir/dict/prince.${1##* }")"
        [[ $out =~ ^[aeiox] ]] || [[ $out =~ ^u.[^aeiou] ]] && an="n"
        echo "a${an} ${out//_/ }";;
      adj:*|adv:*|noun:*|verb:*|word:*)
        out="$(./1line -r "^(${1##*:})$" -f "$botdir/dict/prince.${1%%:*}")"
        echo "${out//_/ }";;
      *)
        echo "$1" ;;
    esac
}

rwiki() { # Takes no args, returns a random wiki page name
      url="https://en.wikipedia.org/w/api.php?format=json&action=query&list=random&rnnamespace=0&fnfilterredir=all&rnlimit=1"
      curl -s "${url}" | jq '.query.random[0].title' # http://xkcd.com/234/
}

pedia() { # Takes a wiki query as $1, returns the json search output
    url="https://en.wikipedia.org/w/api.php?format=json&action=opensearch&redirects=resolve&limit=1&search=${1}"
    curl -s "${url}"
}

[[ "${cmd}" == "me" ]] && cmd="${nick}"

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
    echo|print)
        [[ "${extra}" =~ ^[@/!] ]] && extra="${extra}"
        printf -- "%s\n" "${extra}"
        ;;
    # Begin Personal Commands
    '`')
        [[ "${extra}" == "irl" ]] && \
        echo "http://xkcd.com/1513/" ;;        
    anachrome|ana|"[Awark")
        [[ "${extra}" == "irl" ]] && \
        #echo 'http://static.zerochan.net/Hachikuji.Mayoi.full.61988.jpg' ;;
        echo 'https://sushigirl.tokyo/lewd/src/1450435125974-0.jpg #NSFW' ;;
    lhk|'`lhk`'|'`QaosWug`'|\`*\`)
        [[ "${extra}" == "irl" ]] && \
        echo 'https://animereviewers.files.wordpress.com/2010/05/bakemonogatari-screenshot-episode-7_5.jpg' ;;
    snut|Snut|george|andovan|sngruj)
        case "${extra}" in
            scroll|"") echo "@snut";;
            fascism) echo "@george";;
            irl) echo 'http://img.bato.to/comics/2011/09/11/e/read4e6c54d5e8c84/Elektel_Delusion_ch7_pg00f.jpg #NSFW' ;;
        esac ;;    
    # 4chan returns offensive fortunes.
    4chan|fortune)
        cookie=($([[ $cmd == '4chan' ]] && fortune -seo || fortune -se))
        [[ -n "${extra}" ]] && cookie=($(cook "${extra}"))
        echo `printf -- "%s " "${cookie[*]//	/  }"`
        ;;
    convo|convolve|convolut*)
        if [[ -n "$extra" ]]; then
            out="$(./1line -r "$extra" -f ./convo.db)"
            echo "${out:=No matching convo found.}"
        else
            echo "$(./1line -f ./convo.db)"
        fi ;;
    convo*)
        convo=$(./1line -f ./convo.db)
        [[ -n "$extra" ]] &&  convo=$(./1line -r "$extra" -f ./convo.db)
        colorize $convo
        ;;
    dont)
        echo -n "`< dont.db`|$extra" > dont.db 
        echo "$extra will be redacted from this point forward.";;
    nn*)
        if [[ -n "$extra" ]]; then
            out=$(./1line -r "$extra" -f ./nn.txt) && out="${out:=No matching line found}"
            echo "${out//`< dont.db`/REDACTED}" | iconv -c -t UTF-8
        else
            out=$(./1line -f ./nn.txt)
            echo "${out//`< dont.db`/REDACTED}" | iconv -c -t UTF-8
        fi ;;
    # McGuf Aliases:
    what*) [[ $cmd == 'what'* ]] && extra=${extra:='love'}' is $a adj$ $noun$' 
        extra="${extra^}." ;&
    mcguf|*gram) extra=${extra:='$adj$ $noun$'} ;&
    say)
        IFS=$'$' extra=("$extra") # Split input on $'s
        out="$(for w in $extra; do echo -n "$(guf $w)"; done)"
        if [[ $cmd =~ .*gram ]]; then
            spaces="${out//[^ ]/}"' ' spaces="${#spaces}"
            gram=' | '"$(timeout 8 anagram -w "${spaces}" -l 3 -d "/usr/share/dict/words" "${out}" | ./1line -n 20)"
        fi
        [[ "${out}" =~ ^[@/!] ]] && out="${out}"
        printf -- "%s%s\n" "${out}" "${gram}"
        ;;
    ping)
        if [[ -n "$extra" ]]; then
            IFS=$'\n' out=($(ping -c 4 -q "$extra" 2>&1))
            printf -- "%s\n %s\n" "${out[0]}" "${out[2]}"
        else
            printf -- "%s: pong!\n" "${nick}"
        fi ;;
    paste)
        exec 3<>/dev/tcp/lpaste.net/80
        echo -ne "GET /browse HTTP/1.1\r\nHost: lpaste.net\r\nAccept: */*\r\nConnection: close\r\n\r\n" >&3
        sed -nE 's/^.*a href="(\/[0-9]{6})".*$/\1/p' <&3
        exec 3>&-
        echo "http://lpaste.net$guy" ;;
    g|google)
        printf -- "%s: http://www.lmgtfy.com/?q=%s\n" "${nick}" "${extra// /+}"
        ;;
    w|wiki)
        [[ -z "${extra}" ]] && extra="$(rwiki)" extra="${extra//\"/}"
        wiki=$(pedia "${extra// /_}")
        if [[ "$(jq '.[2][0]' <<< "$wiki")" =~ '"'(.+)'"' ]] ; then
            page="$(jq '.[3][0]' <<< "$wiki")"
            printf -- "%s\n%s\n" "${BASH_REMATCH[1]}" "${page//\"/}"
        else
            printf -- "No results found for %s.\n" "${extra}"
        fi ;;
esac
