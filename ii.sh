trap "echo 'QUIT Exiting...' >&3 && exit" SIGTERM SIGINT

. config.sh

exec 3>/dev/tcp/irc.foonetic.net/6667
echo "NICK ${self:=bashtick}" >&3
echo "USER ${user:=bashtick} 8 *  : ${user}" >&3

while read -eu 3 -a line ; do line="${line:1}"
    (case "${line[*]:0:2}" in
        
        # On first ping, join channels, else just pong
        ING*) echo "PONG ${line[*]:1}" 
            [[ ${line[*]:1} != *.*.* ]] && \
                for c in $@ ; do echo "JOIN #$c"; done 
                echo "PRIVMSG NickServ :IDENTIFY ${ident}" ;;
        
        *'!'*' 'PRIVMSG) # Reply to any PRIVMSG that is a command
            if [[ "${line[*]:3}" =~ ^.?'`'(.*)'`' \
                || "${line[*]:3}" =~ ^.?'$('(.*)')' ]]
            then # Call out for cmd reply, send to user if chan/target=self
                reply=$'\n'$(./iicmd.sh ${line[0]%%!*} "${BASH_REMATCH[1]}")
                [[ ${chan:=${line[2]}} == $self ]] && chan=${line[0]%%!*}
                echo -E "${reply//$'\n'/$'\n'PRIVMSG $chan }"
            elif [[ ${msg:=${line[*]:3}} =~ ^.?'!' \
                || ${line[0]%%!*} == "lurker" ]]
            then
                echo "<${line[0]%%!*}> ${msg:1}" >> ./lurks.db
                ( ./reload.sh )
            fi ;;

    esac >&3 )
done
