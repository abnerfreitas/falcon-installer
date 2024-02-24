#!/bin/bash

if [[ $EUID -ne 0 ]]; then
	echo -e "###################################################################"
	echo -e "#            Execute o script como sudo (sudo ./cs.sh)            #" 
	echo -e "###################################################################"
	exit 1
fi
clear
echo -e "     
	     ██████████████████████░ ███ ▒█████████████████████
	     ███████████████████ ▓▓██  ░██▓▓ ██████████████████
	     ███████████████▒▒█ ▒███░   ▒███░ ▓▒▒██████████████
	     ██████████████ ▓██████       ██████▒ █████████████
	     ███████████████▒▒███▒░       ░▒███▒▒██████████████
	     ███████████▒░▒▒▓▒  ▓░         ▒▓  ▒▓▒▒ ▓██████████
	     ███████████ ▒██▒▒░ ██         ██ ░▒▓██  ██████████
	     ████████████ ▒▓▓███▓░         ░▓███▓▓░ ███████████
	     ████████████▓░         █░ ▒█         ░████████████
	     ██████████ ▒██▒▒▒▒▒▒▒░  ▒ ▒  ░▒▒▒░▒▒▓██  █████████
	     ██████████ ▓███▓▓█▓▒▒  ▒   ▒  ▒▒▓█▓▓███▒ █████████
	     ████████████▓█▓    ░ ░▓░ ░ ▒▓░      ▓█▓███████████
	     ██████████████ ▓███  ░▓ ▒█▒░▓▒ ░███▓ █████████████
	     █████████████  ██▓ ▓██  ▒█▒  ██▓ ▓██  ████████████
	     ██████████████▒▒▒▓██▓▓███████▓▓██▒▒▒▓█████████████
	     ███████████████████ ██████████▓ ██████████████████
	     ████████████████████▓   ███   ▓███████████████████
	     ███████████████████████░███▒██████████████████████
	     ███████████████PRINTI - GREYJOY TEAM██████████████
	     █████████Instalador CrowdStrike Falcon 1.0████████"

sleep 4
clear

# Limpando diretório de instalação anterior e criando log
rm -rf /tmp/Repo
mkdir /tmp/Repo
rm erros.log 2> /dev/null
touch erros.log

# Variáveis
ctl=/opt/CrowdStrike/falconctl
falcaoservice=/lib/systemd/system/falcon-sensor.service
falcaoexe=/tmp/Repo/Ubuntu/latest/falcao.deb
maq_hostname=$(cat /proc/sys/kernel/hostname)

# Corzinha :)
RED="\e[31m"
BLUE="\e[34m"
GREEN="\e[32m"
YELLOW="\e[33m"
DEFAULT="\e[0m"

# Validando se o CrowdStrike já tá instalado
echo -e "${BLUE}[Running]${DEFAULT} | Verificando se o Falcon-Service já está instalado..."
sleep 2
if [ -f "$ctl" ] || [ -f "$falcaoservice" ]; then
	while [ -f "$ctl" ] || [ -f "$falcaoservice" ]; do
		echo -e "\n"
		read -p $'\e[33m[Warning]\e[0m | CrowdStrike já está instalado. Quer reinstalar ele? [s/N]: ' input
		if [[ "$input" = "s" || "$input" = "S" ]]; then
			echo -e "${YELLOW}[Warning]${DEFAULT} | Removendo instalação antiga...\n"
			apt purge falcon-sensor -y 2> erros.log
			if [ -s erros.log ]; then
				read -p $'\e[31m[ERROR]\e[0m   | Alguma coisa deu errado, quer checar o erros.log? [s/N]: ' input
				if [[ "$input" = "s" || "$input" = "S" ]]; then
					echo -e "\n"
					cat erros.log
					echo -e "\n"
				fi
				echo -e "\n${RED}[ERROR]${DEFAULT}   | Resolva o problema antes de executar novamente o script"
				exit 1
			fi
			echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | CrowdStrike removido"
			sleep 3
		else
			echo -e "\n${GREEN}[OK]${DEFAULT}      | Instalação Abortada"
			exit 1
		fi
	done
else
	echo -e "${GREEN}[OK]${DEFAULT}      | Falcon-Sensor não instalado"
fi

# Verifica se tem Git na máquina
echo -e "${BLUE}[Running]${DEFAULT} | Verificando se o Git está instalado..."
sleep 2
if ! dpkg -s git &> /dev/null; then
	read -p $'\e[31m[ERROR]\e[0m   | Git não instalado. Deseja instalar? [s/N]' input
	if [[ "$input" = "s" || "$input" = "S" ]]; then
		echo -e "${BLUE}[Running]${DEFAULT} | Instalando Git. Aguarde por favor..."
		apt install git -y 2> erros.log
		if [ -s erros.log ]; then
			read -p $'\e[31m[ERROR]\e[0m   | Alguma coisa deu errado, quer checar o erros.log? [s/N]: ' input
			if [[ "$input" = "s" || "$input" = "S" ]]; then
				echo -e "\n"
				cat erros.log
				echo -e "\n"
			fi
			echo -e "\n${RED}[ERROR]${DEFAULT}   | Resolva o problema antes de executar novamente o script"
			exit 1
		fi
		echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | Git instalado com sucesso"
	else
		echo -e "\n${RED}[ERROR]${DEFAULT}   | O Git precisa ser instalado. Instalação Abortada"
		exit 1
	fi
else
	echo -e "\n${GREEN}[OK]${DEFAULT} | Git já está instalado"
fi

# Baixando "falcao.deb"
echo -e "${BLUE}[Running]${DEFAULT} | Clonando repositório. Aguarde por favor...\n"
git clone https://bitbucket.org/printiteam/falcon.git /tmp/Repo #2> erros.log # A porra do Git e Wget escrevem o STDOUT no STDERR
<<deprecated
if [ -s erros.log ]; then
	read -p $'\e[31m[ERROR]\e[0m   | Alguma coisa deu errado, quer checar o erros.log? [s/N]: ' input
	if [[ "$input" = "s" || "$input" = "S" ]]; then
			echo -e "\n"
			cat erros.log
			echo -e "\n"
	fi
	echo -e "\n${RED}[ERROR]${DEFAULT}   | Resolva o problema antes de executar novamente o script"
	echo -e "Instalação Abortada"
	exit 1
fi
deprecated

# Verificando se o falcao.* ta clonado e iniciando instalação
if ! [ -f "$falcaoexe" ]; then
	echo -e "\n${RED}[ERROR]${DEFAULT}   | Instalador não encontrado"
	echo -e "${YELLOW}[Warning]${DEFAULT} | Entre em contato com o time de Segurança: seguranca@printi.com.br"
	echo -e "\n${RED}[ERROR]${DEFAULT}   | Instalação Abortada"
	exit 1
else
	echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | Clonagem concluída"
	echo -e ""
	read -p $'\e[32m[OK]\e[0m      | Tudo certo, vamos instalar? [s/N]: ' input
	echo -e "\n"
	if ! [[ "$input" = "s" || "$input" = "S" ]]; then
		echo -e "${GREEN}[OK]${DEFAULT}      | Instalação Abortada"
		exit 1
	else
		apt install "$falcaoexe" -y 2> erros.log
		if [ -s erros.log ]; then
			read -p $'\e[31m[ERROR]\e[0m   | Alguma coisa deu errado, quer checar o erros.log? [s/N]: ' input
			if [[ "$input" = "s" || "$input" = "S" ]]; then
				echo -e "\n"
				cat erros.log
				echo -e "\n"
			fi
			echo -e "${RED}[ERROR]${DEFAULT}   | Resolva o problema antes de executar novamente o script"
			echo -e "\n${RED}[ERROR]${DEFAULT}   | Instalação Abortada"
			exit 1
		fi
		echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | Falcon-Sensor instalado\n"
	fi
fi

# Configurando Falcon-Sensor e subindo serviço
echo -e "${BLUE}[Running]${DEFAULT} | Configurando Falcon-Sensor..."
sleep 3
/opt/CrowdStrike/falconctl -s -f --cid=441023A549B648B39FDA947FE5A34803-8B
echo -e "${GREEN}[OK]${DEFAULT}      | Falcon-Sensor configurado"
sleep 2

# Validando comunicação com o servidor
echo -e "${BLUE}[Running]${DEFAULT} | Iniciando serviço falcon-sensor.service..."
sleep 3
service falcon-sensor start 2> erros.log
if [ -s erros.log ]; then
	read -p $'\e[31m[ERROR]\e[0m   | Alguma coisa deu errado, quer checar o erros.log? [s/N]: ' input
    if [[ "$input" = "s" || "$input" = "S" ]]; then
		echo -e "\n"
		cat erros.log
		echo -e "\n"
    fi
	echo -e "${RED}[ERROR]${DEFAULT}   | Resolva o problema antes de executar novamente o script"
    echo -e "\n${RED}[ERROR]${DEFAULT}   | Instalação Abortada"
    exit 1
fi
echo -e "${BLUE}[Running]${DEFAULT} | Aguardando 20s para confirmar comunicação com o servidor"
sleep 20

# Validando status
echo ""
status=$(service falcon-sensor status | grep "active (running)") # Tentar resolver isso com AWK e/ou Cut no futuro
echo -e "$status"
echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | Serviço do Falcon-Sensor iniciou com sucesso"
echo -e "\n${YELLOW}[Warning]${DEFAULT} | Verifique o hostname ($maq_hostname) no CrowdStrike"
sleep 2

# Limpando a casa e finalizando
echo -e "${GREEN}[OK]${DEFAULT}      | Limpando arquivos de instalaçao..."
rm erros.log 2> /dev/null
rm -rf /tmp/Repo 2> /dev/null
sleep 2
echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | CrowdStrike Falcon-Sensor instalado com sucesso =)"