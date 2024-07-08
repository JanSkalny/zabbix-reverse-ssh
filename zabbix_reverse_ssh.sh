#!/bin/bash

fail() {
    echo "$*" 1>&2
    exit 1
}

usage() {
    fail "usage: $0 (discover|count|connected CLIENT|test CLIENT)"
    exit 1
}

[ $# -lt 1 ] && usage

case "$1" in
discover)
    [ $# -ne 1 ] && usage

    # list authorized_keys for cat user
    cat ~cat/.ssh/authorized_keys | awk '{print $4}' | sed 's/^cat@//' | jq -Rs 'split("\n")[:-1] | map({"{#REVERSE_SSH_CLIENT}": .}) | {data: .}'
    ;;

connected)
    [ $# -ne 2 ] && usage
    CLIENT="$2"

    # identify client based on permit_open
    PERMITOPEN=$( grep "cat@$CLIENT$" ~cat/.ssh/authorized_keys | awk '{print $1}' | tr ',' '\n' | grep permitopen | cut -d '=' -f 2 | tr -d '"' )
    [ "x" == "x$PERMITOPEN" ] && fail "invalid reverse ssh client"

    # find pid listening for permitopen
    ss -tnlp | grep " $PERMITOPEN " | wc -l

    ;;

test)
    [ $# -ne 2 ] && usage
    CLIENT="$2"

    # identify client based on permit_open
    PERMITOPEN=$( grep "cat@$CLIENT$" ~cat/.ssh/authorized_keys | awk '{print $1}' | tr ',' '\n' | grep permitopen | cut -d '=' -f 2 | tr -d '"' )
    [ "x" == "x$PERMITOPEN" ] && fail "invalid reverse ssh client"

	PORT=$( echo $PERMITOPEN | cut -d ':' -f 2 )

    # test ssh connectivity using netcat
	nc 127.0.0.1 $PORT -w 1 | grep SSH | wc -l
    ;;


count)
    [ $# -ne 1 ] && usage

    # count users sshd processes
    ps aux | grep '^cat' | grep sshd | awk '{print $2}' | wc -l
    ;;

*)
    usage
    ;;
esac
