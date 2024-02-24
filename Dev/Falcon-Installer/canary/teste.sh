#!/bin/bash

if [[ $EUID -ne 0 ]]; then
	exit 1
fi

# Limpando diretório de instalação anterior e criando log
rm -rf /tmp/Repo
mkdir /tmp/Repo
rm erros.log 2> /dev/null
touch erros.log

# Variáveis
ctl=/opt/CrowdStrike/falconctl
falcaoservice=/lib/systemd/system/falcon-sensor.service
maq_hostname=$(cat /proc/sys/kernel/hostname)
DISTRO=$(grep '^NAME' /etc/os-release | cut -c 6-100)
VERSION=$(grep '^VERSION=' /etc/os-release | cut -c 10-11)
PRETTY=$(grep '^PRETTY_NAME' /etc/os-release | cut -c 13-100)

<<distros
Distros Compatíveis
	Ubuntu 16/18/20/22
	Amazon Linux 2
distros



case "$DISTRO" in
	"\"Ubuntu"\")
		if [[ "$VERSION" =~ ^(16|18|20|22)$ ]]; then 	# =~ ta testando por pattern as versões do OS
			OS="Ubuntu"
			REPO="https://crowdstrike-installer-newest.s3-eu-west-1.amazonaws.com/latest/falcon-sensor_ubuntu_latest.deb"
			FALCON="falcon-sensor_ubuntu_latest.deb"
		else
			exit 1
		fi	
	;;
	"\"Amazon Linux"\") # não coloquei validador pra caso não seja Amazon Linux 2 pq só vamos rodar em 1 das 2 opções
		echo -e "${GREEN}[SUCCESS]${DEFAULT} | $PRETTY é compatível"
		OS="Amazon Linux"
		REPO="https://crowdstrike-installer-newest.s3-eu-west-1.amazonaws.com/latest/falcon-sensor-amzn2_latest.rpm"
		FALCON="falcon-sensor-amzn2_latest.rpm"
	;;
esac

# Validando se o CrowdStrike já tá instalado
if [ -f "$ctl" ] || [ -f "$falcaoservice" ]; then
	while [ -f "$ctl" ] || [ -f "$falcaoservice" ]; do
		case "$OS" in
			"Ubuntu")
				sudo apt purge falcon-sensor -y 2> erros.log
			;;
			"Fedora")
				echo "Testar Fedora"
			;;
			"Amazon Linux")
				sudo yum remove falcon-sensor -y 2> erros.log
			;;
		esac
		if [ -s erros.log ]; then
			exit 1
		fi
	done
fi

# Baixando "falcon"
wget -c "$REPO" -P /tmp/Repo
if [ ! "$?" == "0" ]; then
	exit 1
	
fi

# Verificando se o falcon.* ta baixado e iniciando instalação
if ! [ -f /tmp/Repo/"$FALCON" ]; then
	exit 1
else
	case $OS in
		"Ubuntu")
			apt install /tmp/Repo/"$FALCON" -y 2> erros.log
		;;
		"Amazon Linux")
			yum install /tmp/Repo/"$FALCON" -y 2> erros.log
		;;
	esac
	if [ -s erros.log ]; then
		exit 1
	fi
fi

# Configurando Falcon-Sensor e subindo serviço
/opt/CrowdStrike/falconctl -s -f --cid=441023A549B648B39FDA947FE5A34803-8B

# Validando comunicação com o servidor
case "$OS" in
	"Ubuntu")
		service falcon-sensor start 2> erros.log
	;;
	"Amazon Linux")
		sudo /bin/systemctl start falcon-sensor.service 2> erros.log
	;;
esac
if [ -s erros.log ]; then
    exit 1
fi

sleep 5 # Alguns testes tão demorando pra subir comunicação com a console, aumenta aqui se o problema for validação muito rápida

# Validando status
case "$OS" in # Independente do resultado, ele cria uma entrada no erros.log | Obrigado tio Linus >:(
	"Ubuntu")
		SENSOR=$(sudo service falcon-sensor status | grep "active (running)" | cut -c 6-29)
		SERVICE=$(sudo service falcon-sensor status > erros.log)
	;;
	"Amazon Linux")
		SENSOR=$(sudo /bin/systemctl status falcon-sensor.service | grep "active (running)" | cut -c 4-27)
		SERVICE=$(sudo /bin/systemctl status falcon-sensor.service > erros.log)
	;;
esac
case "$SENSOR" in
	"Active: active (running)")
		echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | Serviço do Falcon-Sensor iniciou com sucesso"
	;;
	*)
		exit 1
	;;
esac

# Limpando a casa e finalizando
rm erros.log 2> /dev/null
rm -rf /tmp/Repo 2> /dev/null