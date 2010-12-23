#!/bin/bash

if ! which twidge &>/dev/null; then
    echo "Please install twidge: https://github.com/jgoerzen/twidge/wiki"
    exit 1
fi

KNOWN_TAGS=( book manga net fullgame game lyric subs news nico sentence )
KNOWN_REPEATS=( second third fourth fifth sixth seventh eighth ninth tenth )

usage() {
    cat <<EOF
Usage:
  tadoku <tag> <page count> [repeat] [message...]"
  tadoku undo [message...]

<tag>
  Known tags:
  ${KNOWN_TAGS[*]}

  The special 'undo' tag does not require a number of pages.

[repeat]
  This parameter is optional and can be any number from 2 to 10.

[message...]
  This parameter is optional and can be anything not including
  numbers.

Examples:
  $ tadoku book 5
  $ tadoku undo screwed up
  $ tadoku net 1 2 'one page of slashdot, second time'
EOF
    if [[ $# -eq 1 ]]; then
        printf '\nError: %s\n' "$1"
    fi
    exit 0
}

tweet() {
    message="@tadokubot ${1% }"
    echo "Going to tweet: '$message'"
    read -p "OK? [Yn]" ok
    if [[ ! $ok || $ok = 'y' || $ok = 'Y' ]]; then
        twidge update "$message"
    else
        echo 'Abort.'
    fi
}

check_message() {
    if printf '%s' "$1" | grep -q '[0-9]'; then
        echo "Digits in the message are not allowed."
        exit 1
    fi
}
is_number() {
    printf '%s' "$1" | grep -q '^[0-9]\+$'
}

[[ $# -gt 0 ]] || usage

tag="$1"
shift

if [[ $tag = undo ]]; then
    message="$*"
    check_message "$message"
    tweet "#undo $message"
    exit 0
fi

valid=0
for i in "${KNOWN_TAGS[@]}"; do
    if [[ $i = $tag ]]; then
        valid=1
    fi
done
[[ $valid = 1 ]] || usage "Unknown tag: '$tag'"

[[ $# -gt 0 ]] || usage "Missing argument: <page count>"

pagecount="$1"
shift

is_number "$pagecount" || usage "Not a page count: '$pagecount'"
if [[ $# -ge 1 ]]; then
    repeat="$1"
    if is_number "$repeat"; then
        [[ $repeat -ge 2 && $repeat -le 10 ]] || usage "repeat $repeat: out of range"
        shift
        repeat=" #${KNOWN_REPEATS[$(( $repeat - 2 ))]}"
    else
        repeat=
    fi
fi

message="$*"
check_message "$message"
tweet "$pagecount #$tag$repeat $message"

exit 0
