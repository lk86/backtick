trap "echo 'QUIT Exiting...' >&3 && exit" SIGTERM SIGINT

exec 3>/dev/tcp/irc.foonetic.net/6667
echo "NICK ${self:=bashtick}" >&3
echo "USER bashtick 8 *  : bashtick" >&3
while read -u 3 -a line ; do line="${line:1}"
    (case "${line[*]:0:2}" in
        ING*) echo "PONG ${line[*]:1}" 
            [[ ${line[*]:1} != *.*.* ]] \
                && for c in $@ ; do echo "JOIN #$c"; done ;;
        *'!'*' 'PRIVMSG)
            if [[ "${line[*]:3}" =~ ^.?'`'(.*)'`' || \
              "${line[*]:3}" =~ ^.?'$('(.*)')' ]] ; then
                reply=$'\n'$(./iicmd.sh ${line[0]%%!*} "${BASH_REMATCH[1]}")
                [[ ${chan:=${line[2]}} == $self ]] && chan=${line[0]%%!*}
                echo "${reply//$'\n'/$'\n'PRIVMSG $chan }"
            fi ;;
    esac >&3 )
done
echo "Last Line: ${line[*]}"
