#!/bin/bash
function loading_icon() {
    local load_interval="${1}"
    local loading_message="${2}"
    local elapsed=0
    local loading_animation=( '—' "\\" '|' '/' )

    echo -n "${loading_message} "
    
    # This part is to make the cursor not blink
    # on top of the animation while it lasts
    tput civis
    trap "tput cnorm" EXIT
    while [ "${load_interval}" -ne "${elapsed}" ]; do
        for frame in "${loading_animation[@]}" ; do
            printf "%s\b" "${frame}"
            sleep 0.25
        done
        elapsed=$(( elapsed + 1 ))
    done
    printf " \b\n"
}

touch erros2.log
# Set the timeout
timeout=240

# Start the timer
start=$(date +%s)

# Loop until the timeout is reached or the word is found
while true; do
  # Check if the timeout has been reached
  now=$(date +%s)
  elapsed=$((now - start))
  if [[ $elapsed -ge $timeout ]]; then
    echo "Nao Funfou"
    exit 1
  fi

  # Check for the word in the file
  sudo /bin/systemctl status falcon-sensor.service > "erros2.log"
  if (grep -q "ConnectToCloud successful" erros2.log); then
    echo "Funfou"
    exit 0
  fi
  
  loading_icon 10 "Validando comunicação..."
done


Descobrir uma forma de manualmente retornar um exit code pro $?
