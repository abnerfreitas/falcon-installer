#!/bin/bash
rm erros.log
touch erros.log
rm -r /tmp/Repo
echo -e "${BLUE}[Running]${DEFAULT} | Baixando Falcon-Sensor. Aguarde por favor...\n"

wget -P /tmp/Repo -c https://bitbucket.org/printiteam/falcon/raw/master/Ubuntu/latest/falco.deb --show-progress -nv --show-progress --progress=bar:force 2>erros.log &
PID=$!

trap "kill $PID 2> /dev/null" EXIT 

#if kill -0 $PID; then
sleep 1

if grep -q "ERROR" erros.log 2> /dev/null; then
    read -p $'\e[31m[ERROR]\e[0m   | Alguma coisa deu errado, quer checar o erros.log? [s/N]: ' input
    case "$input" in 
    [sS])
        echo -e "\n"
	    cat erros.log
	    echo -e "\n"
        ;; 
    *)
    esac
        echo -e "${RED}[ERROR]${DEFAULT}   | Falha ao baixar o pacote"
	    echo -e "\nInstalação Abortada"
	    exit 1
else
    while kill -0 $PID 2> /dev/null; do
        echo -ne "$(tail --lines 1 erros.log)\r"
        sleep 1
    done
fi

sleep 1
echo -ne "$(tail -2 erros.log | head -1)\r"
echo -e "\n"
echo "TERMINOU"
exit 0
