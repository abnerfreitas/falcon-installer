#!/bin/bash
<< LEMBRAR
Fedora
Linux Mint
Ubuntu 23 > Testar/
Colocar validador de Distro não suportada
Verificar a varíavel OS e ver onde ela ta sendo usada
LEMBRAR

# Link pra todos os repos (parar de ter dor de cabeça com isso): https://support.security.cimpress.io/hc/en-us/articles/360011513860-Sensors-Latest-CrowdStrike-Sensor-Downloads-Hosted-In-S3

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
	     ██████████████PRINTI - SECURITY TEAM██████████████
	     █████████Instalador CrowdStrike Falcon 1.2████████"

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
maq_hostname=$(cat /proc/sys/kernel/hostname)

# Distros Compatíveis
#Ubuntu 16/18/20/22/23
#Amazon Linux 1
#Amazon Linux

# Corzinha :)
RED="\e[31m"
BLUE="\e[34m"
GREEN="\e[32m"
YELLOW="\e[33m"
DEFAULT="\e[0m"

DISTRO=$(grep '^NAME' /etc/os-release | cut -c 6-100)
VERSION=$(grep '^VERSION=' /etc/os-release | cut -c 10-11)
PRETTY=$(grep '^PRETTY_NAME' /etc/os-release | cut -c 13-100)

case "$DISTRO" in
	"\"Ubuntu"\")
		if [[ "$VERSION" =~ ^(16|18|20|22|23)$ ]]; then 	# =~ ta testando por pattern as versões do OS
			echo -e "${GREEN}[SUCCESS]${DEFAULT} | $PRETTY é compatível"
			OS="Ubuntu"
			REPO="https://crowdstrike-installer-newest.s3-eu-west-1.amazonaws.com/latest/falcon-sensor_ubuntu_latest.deb"
			FALCON="falcon-sensor_ubuntu_latest.deb"
		else
			echo -e "\n${RED}[ERROR]${DEFAULT}   | Versão $PRETTY não é compatível"
			exit
		fi	
	;;
	"\"Amazon Linux"\")
		echo -e "${GREEN}[SUCCESS]${DEFAULT} | $PRETTY é compatível"
		OS="RHEL"
		REPO="https://crowdstrike-installer-newest.s3-eu-west-1.amazonaws.com/latest/falcon-sensor-amzn2_latest.rpm"
		FALCON="falcon-sensor-amzn2_latest.rpm"
	;;
	"\"Linux Mint"\")
		echo -e "${GREEN}[SUCCESS]${DEFAULT} | $PRETTY é compatível"
		OS="Ubuntu"
		REPO="https://crowdstrike-installer-newest.s3-eu-west-1.amazonaws.com/latest/falcon-sensor_ubuntu_latest.deb"
		FALCON="falcon-sensor_ubuntu_latest.deb"
	;;
	"\"Fedora Linux"\")
		echo -e "${GREEN}[SUCCESS]${DEFAULT} | $PRETTY é compatível"
		OS="RHEL"
		REPO="https://crowdstrike-installer-newest.s3.eu-west-1.amazonaws.com/latest/falcon-sensor-el9_latest.rpm"
		FALCON="falcon-sensor-el9_latest.rpm"
	;;
esac

# Validando se o CrowdStrike já tá instalado
echo -e "${BLUE}[Running]${DEFAULT} | Verificando se o Falcon-Service já está instalado..."
sleep 2
if [ -f "$ctl" ] || [ -f "$falcaoservice" ]; then
	while [ -f "$ctl" ] || [ -f "$falcaoservice" ]; do
		echo -e "\n"
		read -p $'\e[33m[Warning]\e[0m | CrowdStrike já está instalado. Quer reinstalar ele? [s/N]: ' input
		if [[ "$input" = "s" || "$input" = "S" ]]; then
			echo -e "${YELLOW}[Warning]${DEFAULT} | Removendo instalação antiga...\n"
			case "$OS" in
				"Ubuntu")
					sudo apt purge falcon-sensor -y 2> erros.log
				;;
				"RHEL")
					sudo yum remove falcon-sensor -y 2> erros.log
					sleep 5
				;;
			esac
			
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

# Baixando "falcon"
echo -e "${BLUE}[Running]${DEFAULT} | Baixando CrowdStrike. Aguarde por favor...\n"
wget -c "$REPO" -P /tmp/Repo
if [ ! "$?" == "0" ]; then
	echo -e "\n${RED}[ERROR]${DEFAULT}   | Falha no download"
	sleep 1
	echo -e "\n${RED}[ERROR]${DEFAULT}   | Resolva o problema antes de executar novamente o script"
	echo -e "Instalação Abortada"
	exit 1
fi

# Verificando se o falcon.* ta baixado e iniciando instalação
if ! [ -f /tmp/Repo/"$FALCON" ]; then
	echo -e "\n${RED}[ERROR]${DEFAULT}   | Instalador não encontrado"
	echo -e "${YELLOW}[Warning]${DEFAULT} | Entre em contato com o time de Segurança: csirt@printi.com.br"
	echo -e "\n${RED}[ERROR]${DEFAULT}   | Instalação Abortada"
	exit 1
else
	echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | Download concluído"
	echo -e ""
	read -p $'\e[32m[OK]\e[0m      | Tudo certo, vamos instalar? [s/N]: ' input
	echo -e "\n"
	if ! [[ "$input" = "s" || "$input" = "S" ]]; then
		echo -e "${GREEN}[OK]${DEFAULT}      | Instalação Abortada"
		exit 1
	else
		case $OS in
			"Ubuntu")
				apt install /tmp/Repo/"$FALCON" -y 2> erros.log
			;;
			"RHEL")
				yum install /tmp/Repo/"$FALCON" -y 2> erros.log
			;;
		esac
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
case "$OS" in
	"Ubuntu")
		service falcon-sensor start 2> erros.log
	;;
	"RHEL")
		sudo /bin/systemctl start falcon-sensor.service 2> erros.log
	;;
esac
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
echo -e "${BLUE}[Running]${DEFAULT} | Aguardando 5s para confirmar comunicação com o servidor"
sleep 5

# Validando status

case "$OS" in # Independente do resultado, ele cria uma entrada no erros.log
	"Ubuntu")
		SENSOR=$(sudo service falcon-sensor status | grep "active (running)" | cut -c 6-29)
		SERVICE=$(sudo service falcon-sensor status > erros.log)
	;;
	"RHEL")
		SENSOR=$(sudo /bin/systemctl status falcon-sensor.service | grep "active (running)" | cut -c 4-27)
		SERVICE=$(sudo /bin/systemctl status falcon-sensor.service > erros.log)
	;;
esac
case "$SENSOR" in
	"Active: active (running)")
		echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | Serviço do Falcon-Sensor iniciou com sucesso"
	;;
	*)
		eval $SERVICE
		read -p $'\e[31m[ERROR]\e[0m   | Alguma coisa deu errado, quer checar o erros.log? [s/N]: ' input
		case "$input" in
			[sS])
				cat erros.log
		;;
		esac
		echo -e "\n${RED}[ERROR]${DEFAULT}   | Resolva o problema antes de executar novamente o script"
    	echo -e "${RED}[ERROR]${DEFAULT}   | Instalação Abortada"
		exit 1
	;;
esac

#echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | Serviço do Falcon-Sensor iniciou com sucesso"
echo -e "\n${YELLOW}[Warning]${DEFAULT} | Verifique o hostname ($maq_hostname) no CrowdStrike"
sleep 2

# Limpando a casa e finalizando
echo -e "${GREEN}[OK]${DEFAULT}      | Limpando arquivos de instalação..."
rm erros.log 2> /dev/null
rm -rf /tmp/Repo 2> /dev/null
sleep 2
echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | CrowdStrike Falcon-Sensor instalado com sucesso =)"