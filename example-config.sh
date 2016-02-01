botdir="$HOME/backtick"
ircdir="$botdir/ii-fifos"
qdbdir="$botdir/qdb"
nickname="ima-bot"
ident="identification-password"

declare -A networks=(
    [irc.freenode.net]="#linux"
    [irc.myprivateirc.net]="#linux"
)

declare -A networks=(
    [irc.freenode.net]="ii -i $ircdir -n $nickname -f BotName "
)

#relay="yes please"
#pm="yep"
