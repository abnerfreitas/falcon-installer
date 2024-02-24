#!/bin/bash

# CrowdStrike's Repository: https://support.security.cimpress.io/hc/en-us/articles/360011513860-Sensors-Latest-CrowdStrike-Sensor-Downloads-Hosted-In-S3

if [[ $EUID -ne 0 ]]; then
	echo -e "###################################################################"
	echo -e "#            Hey, you're not root! Use sudo or else...            #" 
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
	     ██████████████████████████████████████████████████
	     ███████████████Falcon - Installer 1.2█████████████"

sleep 4
clear

# Cleaning up...
rm -rf /tmp/Repo
mkdir /tmp/Repo
rm erros.log 2> /dev/null
touch erros.log

# Variables =D
ctl=/opt/CrowdStrike/falconctl
falcaoservice=/lib/systemd/system/falcon-sensor.service
maq_hostname=$(cat /proc/sys/kernel/hostname)
DISTRO=$(grep '^NAME' /etc/os-release | cut -c 6-100)
VERSION=$(grep '^VERSION=' /etc/os-release | cut -c 10-11)
PRETTY=$(grep '^PRETTY_NAME' /etc/os-release | cut -c 13-100)

# Pretty colors :)
RED="\e[31m"
BLUE="\e[34m"
GREEN="\e[32m"
YELLOW="\e[33m"
DEFAULT="\e[0m"

########################################### Installer ########################################### 

case "$DISTRO" in
	"\"Ubuntu"\")
		if [[ "$VERSION" =~ ^(16|18|20|22|23)$ ]]; then 	# =~ Not all Ubuntu versions are compatible, yikes!
			echo -e "${GREEN}[SUCCESS]${DEFAULT} | $PRETTY is compatible"
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
		OS="Amazon Linux"
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
		OS="Fedora"
		REPO="https://crowdstrike-installer-newest.s3.eu-west-1.amazonaws.com/latest/falcon-sensor-el9_latest.rpm"
		FALCON="falcon-sensor-el9_latest.rpm"
	;;
esac

# Previous installation validation 
echo -e "${BLUE}[Running]${DEFAULT} | Let's see if Falcon is already installed. Hold up..."
sleep 2
if [ -f "$ctl" ] || [ -f "$falcaoservice" ]; then
	while [ -f "$ctl" ] || [ -f "$falcaoservice" ]; do
		echo -e "\n"
		read -p $'\e[33m[Warning]\e[0m | Falcon is already installed. You wanna reinstall? [y/N]: ' input
		if [[ "$input" = "y" || "$input" = "Y" ]]; then
			echo -e "${YELLOW}[Warning]${DEFAULT} | Removing previous install...\n"
			case "$OS" in
				"Ubuntu")
					sudo apt purge falcon-sensor -y 2> erros.log
				;;
				"Amazon Linux"|"Fedora")
					sudo yum remove falcon-sensor -y 2> erros.log
					sleep 5
				;;
			esac
			
			if [ -s erros.log ]; then
				read -p $'\e[31m[ERROR]\e[0m   | Something went wrong, wanna check erros.log? [y/N]: ' input
				if [[ "$input" = "y" || "$input" = "Y" ]]; then
					echo -e "\n"
					cat erros.log
					echo -e "\n"
				fi
				echo -e "\n${RED}[ERROR]${DEFAULT}   | Fix the issue before using this script again"
				exit 1
			fi
			echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | Falcon removed"
			sleep 3
		else
			echo -e "\n${GREEN}[OK]${DEFAULT}      | Aborted Install"
			exit 1
		fi
	done
else
	echo -e "${GREEN}[OK]${DEFAULT}      | Falcon was not installed"
fi

# Downloading "falcon"
echo -e "${BLUE}[Running]${DEFAULT} | Downloading Falcon. Please wait...\n"
wget -c "$REPO" -P /tmp/Repo
if [ ! "$?" == "0" ]; then
	echo -e "\n${RED}[ERROR]${DEFAULT}   | Download failed"
	sleep 1
	echo -e "\n${RED}[ERROR]${DEFAULT}   | Fix the issue before using this script again"
	echo -e "Aborted Install"
	exit 1
fi

# Checking if falcon.* is downloaded and beginning install
if ! [ -f /tmp/Repo/"$FALCON" ]; then
	echo -e "\n${RED}[ERROR]${DEFAULT}   | Installer package not found"
	echo -e "${YELLOW}[Warning]${DEFAULT} | Please, reach out to your security team"
	echo -e "\n${RED}[ERROR]${DEFAULT}   | Aborted Install"
	exit 1
else
	echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | Download completed"
	echo -e ""
	read -p $'\e[32m[OK]\e[0m      | Everything seems fine, wanna install? [y/N]: ' input
	echo -e "\n"
	if ! [[ "$input" = "y" || "$input" = "Y" ]]; then
		echo -e "${GREEN}[OK]${DEFAULT}      | Aborted Install"
		exit 1
	else
		case $OS in
			"Ubuntu")
				apt install /tmp/Repo/"$FALCON" -y 2> erros.log
			;;
			"Amazon Linux"|"Fedora")
				yum install /tmp/Repo/"$FALCON" -y 2> erros.log
			;;
		esac
		if [ -s erros.log ]; then
			read -p $'\e[31m[ERROR]\e[0m   | Something went wrong, wanna check erros.log? [y/N]: ' input
			if [[ "$input" = "y" || "$input" = "Y" ]]; then
				echo -e "\n"
				cat erros.log
				echo -e "\n"
			fi
			echo -e "${RED}[ERROR]${DEFAULT}   | Fix the issue before using this script again"
			echo -e "\n${RED}[ERROR]${DEFAULT}   | Aborted Install"
			exit 1
		fi
		echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | Falcon installed\n"
	fi
fi

# Configuring Falcon-sensor and starting the service
echo -e "${BLUE}[Running]${DEFAULT} | Configuring Falcon..."
sleep 3
/opt/CrowdStrike/falconctl -s -f --cid=441023A549B648B39FDA947FE5A34803-8B
echo -e "${GREEN}[OK]${DEFAULT}      | Falcon configured"
sleep 2

# Checking crowdstrike's server handshake
echo -e "${BLUE}[Running]${DEFAULT} | Starting falcon-sensor.service..."
sleep 3
case "$OS" in
	"Ubuntu")
		service falcon-sensor start 2> erros.log
	;;
	"Amazon Linux"|"Fedora")
		sudo /bin/systemctl start falcon-sensor.service 2> erros.log
	;;
esac
if [ -s erros.log ]; then
	read -p $'\e[31m[ERROR]\e[0m   | Something went wrong, wanna check erros.log? [y/N]: ' input
    if [[ "$input" = "y" || "$input" = "Y" ]]; then
		echo -e "\n"
		cat erros.log
		echo -e "\n"
    fi
	echo -e "${RED}[ERROR]${DEFAULT}   | Fix the issue before using this script again"
    echo -e "\n${RED}[ERROR]${DEFAULT}   | Aborted Install"
    exit 1
fi
echo -e "${BLUE}[Running]${DEFAULT} | Waiting 5s to confirm server handshake..."
sleep 5 # Increase this value if you have a really slow machine or poor connection

# Checking status

case "$OS" in # Doesn't matter if its a error or not, an entry on erros.log will be added, deal with it
	"Ubuntu"|"Fedora")
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
		echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | Falcon service started successfully"
	;;
	*)
		eval $SERVICE
		read -p $'\e[31m[ERROR]\e[0m   | Something went wrong, wanna check erros.log? [y/N]: ' input
		case "$input" in
			[yY])
				cat erros.log
		;;
		esac
		echo -e "\n${RED}[ERROR]${DEFAULT}   | Fix the issue before using this script again"
    	echo -e "${RED}[ERROR]${DEFAULT}   | Aborted Install"
		exit 1
	;;
esac
echo -e "\n${YELLOW}[Warning]${DEFAULT} | Check this hostname ($maq_hostname) on CrowdStrike"
sleep 2

# Cleaning everything up
echo -e "${GREEN}[OK]${DEFAULT}      | Cleaning..."
rm erros.log 2> /dev/null
rm -rf /tmp/Repo 2> /dev/null
sleep 2
echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | CrowdStrike Falcon-Sensor installed successfully. See ya =)"