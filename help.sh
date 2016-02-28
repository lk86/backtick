case "$1" in
    man|help)
        txt='Description: Display help text. Usage: `man <command>` - prints help text for <command>. | `man` - prints command list and github link.' ;;
    bc|calc)
        txt='Description: Perform calculations with GNU bc, the basic calculator. Usage: `bc <bc expression>` - prints one line of bc -lsq output, if calculation completes in <30 seconds'
;;
    q|qdb)
        txt='Description: Adds quotes to the quote database. Usage: `qdb <start regex> <end regex>` - adds messages sent between a message matching <start regex> and one matching <end message> inclusive to qdb' ;;
    echo|print)
        txt='Description: Echoes back its input. Usage: `echo <string>` - prints <string>, sanitized to not trigger averybot, lurker, or ii' ;;
    grep)
        txt='Description: Searches for qdb entry matching a given pattern. Usage: `qdb <pattern>` - prints the last 10 lines of the first matching qdb entry found' ;;
    fortune)
        txt='Description: Fortune cookie database interface. Usage: `fortune` - prints a random fortune from the database. | `fortune <pattern>` - prints the first 10 lines of matching fortune cookies' ;;
    ping)
        txt='Description: Test function to verify bot functionality. Usage: `ping` - replies "pong!"' ;;
    say)
        txt='Description: Generates sentences based on input format. Usage: `say <format>` where <format> is any string. $adj$, $adv$, $noun$, $verb$ in format will replace $_$ with with a random word of type _' ;;
    g|google)
        txt='Description: Prints link to desired google query. Usage: `g <query>` - replies with search link' ;;
    w|wiki)
        txt='Description: Queries en.wikipedia.org for a page, and returns a summary of the topic. Usage: `w <page>` - prints either the first 4 sentences or first graph (whichever is shorter) of wiki entry <page> | `w` - prints that summary information for a random wiki page' ;;
    *)
        txt='Command not found. This functionality is either not availible or not stable' ;;
esac

printf -- "%s\n" "${txt}"
