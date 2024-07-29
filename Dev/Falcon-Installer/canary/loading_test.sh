#!/bin/bash
echo "1"
echo "2"
echo "3"
function loading_icon() {
    #local load_interval="${1}"
    local loading_message="${1}"
    local elapsed=0
    local loading_animation=( '—' "\\" '|' '/' )


    # This part is to make the cursor not blink
    # on top of the animation while it lasts
    tput civis
    trap "tput cnorm" EXIT
        for frame in "${loading_animation[@]}" ; do
            printf "%s\b" "Loading " "${frame}"
            sleep 0.1
        done
    #printf "\033[A \b\n"
    #printf " \b\n"
}

while true; do
    if (grep -q "rekt" lol.txt); then
        echo "Sim"
        break
    else
       loading_icon
    fi
done