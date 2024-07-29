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

#sleep 4
clear

# Cleaning up...
rm -rf /tmp/Repo
mkdir /tmp/Repo
rm error.log 2> /dev/null
touch error.log

# Variables =D
ctl=/opt/CrowdStrike/falconctl
falcaoservice=/lib/systemd/system/falcon-sensor.service
maq_hostname=$(cat /proc/sys/kernel/hostname)
DISTRO=$(grep '^NAME' /etc/os-release | cut -c 6-100)
VERSION=$(grep '^VERSION=' /etc/os-release | cut -c 10-11)
PRETTY=$(grep '^PRETTY_NAME' /etc/os-release | cut -c 13-100)
ARCH=$(uname -m)
CID=""

# Pretty colors :)
RED="\e[31m"
BLUE="\e[34m"
GREEN="\e[32m"
YELLOW="\e[33m"
DEFAULT="\e[0m"

# Define a function to display the help message.
function show_param() {
  echo "Usage: sudo $0 --cid [CID] [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help      Display this help message and exit."
  echo "  -c, --cid		  Defines Falcon's CID"
  echo "  -s, --silent    Run the script with no output (Don't use with -y)"
  echo "  -y, --all-yes   Choose yes for everything (Don't use with -s)"
  echo ""
}

function service_stats() {
	sudo /bin/systemctl status falcon-sensor.service > error.log
}

error_log() {
	if [ -s error.log ]; then
		read -p $'\e[31m[ERROR]\e[0m   | Something went wrong, wanna check error.log? [y/N]: ' input
		case $input in
			[yY])
				echo -e "\n"
				cat error.log
				echo -e "\n"
			;;
		esac
		echo -e "\n${RED}[ERROR]${DEFAULT}   | Fix the issue before running this script again"
		exit 1
	fi }

function cid_validation(){
	if [[ ${CID:0:1} = "-" || ! ${CID} =~ ^[A-Z0-9-]+$ || ${CID:(-1)} = "-" || ! ${CID:(-3)} =~ -..$ ]]; then
    	echo "Error: CID only can contain Uppercase Letters, Numbers and \"-\"."
    	exit 1
	else
    	echo "CID is $CID"
	fi }

case $1 in
	-c|--cid)
	;;
	*)
		if [[ $CID == "" ]]; then
			show_param
			exit 1
		else
			cid_validation
		fi
	;;
esac

while [[ $# -ne 0 ]]; do
	param="$1"
	case "$param" in
    	-h|--help)
			show_param
			exit 0
    	;;
		-c|--cid)
            CID="$2"
            cid_validation
            shift
        ;;
		-l|--lulz)
			lulz_set=true
			echo "LOL get rekt"
		;;
		*)
			echo "Invalid argument: $1"
			show_param
			exit 1
		;;
	esac
	shift
done

########################################### Installer ########################################### 

case "$DISTRO" in
	"\"Ubuntu"\")
		if [[ "$VERSION" =~ ^(16|18|20|22|23|24)$ ]] && [[ "$ARCH" =~ ^("aarch64"|"x86_64")$ ]]; then	# =~ Not all Ubuntu versions are compatible, yikes!
			echo -e "${GREEN}[SUCCESS]${DEFAULT} | $PRETTY $ARCH is compatible"
			OS="Ubuntu"
			if [ "$ARCH" = "aarch64" ]; then
				REPO="https://crowdstrike-installer-newest.s3-eu-west-1.amazonaws.com/latest/falcon-sensor_ubuntu_arm64_latest.deb"
				FALCON="falcon-sensor_ubuntu_arm64_latest.deb"
			else
				REPO="https://crowdstrike-installer-newest.s3-eu-west-1.amazonaws.com/latest/falcon-sensor_ubuntu_latest.deb"
				FALCON="falcon-sensor_ubuntu_latest.deb"
			fi
		else
			echo -e "\n${RED}[ERROR]${DEFAULT}   | Version $PRETTY $ARCH is not compatible"
			exit
		fi
	;;
	"\"Amazon Linux"\")
		echo -e "${GREEN}[SUCCESS]${DEFAULT} | $PRETTY is compatible"
		OS="Amazon Linux"
		REPO="https://crowdstrike-installer-newest.s3-eu-west-1.amazonaws.com/latest/falcon-sensor-amzn2_latest.rpm"
		FALCON="falcon-sensor-amzn2_latest.rpm"
	;;
	"\"Linux Mint"\")
		echo -e "${GREEN}[SUCCESS]${DEFAULT} | $PRETTY is compatible"
		OS="Ubuntu"
		REPO="https://crowdstrike-installer-newest.s3-eu-west-1.amazonaws.com/latest/falcon-sensor_ubuntu_latest.deb"
		FALCON="falcon-sensor_ubuntu_latest.deb"
	;;
	"\"Fedora Linux"\")
		echo -e "${GREEN}[SUCCESS]${DEFAULT} | $PRETTY is compatible"
		OS="Fedora"
		REPO="https://crowdstrike-installer-newest.s3.eu-west-1.amazonaws.com/latest/falcon-sensor-el9_latest.rpm"
		FALCON="falcon-sensor-el9_latest.rpm"
	;;
	*)
		echo -e "\n${RED}[ERROR]${DEFAULT}   | $PRETTY is not compatible"
		exit
	;;
esac

# Previous installation validation 
echo -e "${BLUE}[Running]${DEFAULT} | Let's see if Falcon is already installed. Hold up..."
sleep 2
if [ -f "$ctl" ] || [ -f "$falcaoservice" ]; then
	while [ -f "$ctl" ] || [ -f "$falcaoservice" ]; do
		echo -e "\n"
		read -p $'\e[33m[Warning]\e[0m | Falcon is already installed. You wanna reinstall? [y/N]: ' input
		case $input in
			[yY])
				echo -e "${YELLOW}[Warning]${DEFAULT} | Removing previous install...\n"
				case "$OS" in
					"Ubuntu")
						sudo apt purge falcon-sensor -y 2> error.log
					;;
					"Amazon Linux"|"Fedora")
						sudo yum remove falcon-sensor -y 2> error.log
						sleep 5
					;;
				esac
				if [ -s error.log ]; then
					read -p $'\e[31m[ERROR]\e[0m   | Something went wrong, wanna check error.log? [y/N]: ' input
					case $input in
						[yY])
							echo -e "\n"
							cat error.log
							echo -e "\n"
						;;
					esac
					echo -e "\n${RED}[ERROR]${DEFAULT}   | Fix the issue before using this script again"
					exit 1
				fi
				echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | Falcon removed"
				sleep 3
			;;
			*)
				echo -e "\n${GREEN}[OK]${DEFAULT}      | Aborted Install"
				exit 1
			;;
		esac
	done
else
	echo -e "${GREEN}[OK]${DEFAULT}      | Falcon was not installed"
fi

# Downloading "falcon"
echo -e "${BLUE}[Running]${DEFAULT} | Downloading Falcon. Please wait...\n"
wget -c "$REPO" -P /tmp/Repo
case $? in
	"1")
		echo -e "\n${RED}[ERROR]${DEFAULT}   | Download failed"
		sleep 1
		echo -e "\n${RED}[ERROR]${DEFAULT}   | Fix the issue before using this script again"
		echo -e "Aborted Install"
		exit 1
	;;
esac

# Checking if falcon.* is downloaded and beginning install
if ! [ -f /tmp/Repo/"$FALCON" ]; then
	echo -e "\n${RED}[ERROR]${DEFAULT}   | Installer package not found"
	echo -e "${YELLOW}[Warning]${DEFAULT} | Please, reach out to your security team"
	echo -e "\n${RED}[ERROR]${DEFAULT}   | Aborted Install"
	exit 1
else
	echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | Download completed"
	echo -e ""
	read -p $'\e[32m[OK]\e[0m      | Everything seems fine, wanna install? [Y/n]: ' input
	echo -e "\n"
	case $input in
		[nN])
			echo -e "${GREEN}[OK]${DEFAULT}      | Aborted Install"
			exit 1
		;;
		*)
			case $OS in
				"Ubuntu")
					apt update && apt install /tmp/Repo/"$FALCON" -y 2> error.log
				;;
				"Amazon Linux"|"Fedora")
					yum install /tmp/Repo/"$FALCON" -y 2> error.log
				;;
			esac
			if [ -s error.log ]; then
				read -p $'\e[31m[ERROR]\e[0m   | Something went wrong, wanna check error.log? [y/N]: ' input
				case $input in
					[yY])
						echo -e "\n"
						cat error.log
						echo -e "\n"
					;;
				esac
				echo -e "${RED}[ERROR]${DEFAULT}   | Fix the issue before using this script again"
				echo -e "\n${RED}[ERROR]${DEFAULT}   | Aborted Install"
				exit 1
			fi
			echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | Falcon installed\n"
		;;
	esac
fi

# Configuring Falcon-sensor and starting the service
echo -e "${BLUE}[Running]${DEFAULT} | Configuring Falcon..."
/opt/CrowdStrike/falconctl -s -f --cid=$CID 2> error.log

error_log

echo -e "${GREEN}[OK]${DEFAULT}      | Falcon configured"
sleep 2

# Checking crowdstrike's server handshake
echo -e "${BLUE}[Running]${DEFAULT} | Starting falcon-sensor.service..."
sleep 3
case "$OS" in
	"Ubuntu")
		service falcon-sensor start 2> error.log
	;;
	"Amazon Linux"|"Fedora")
		sudo /bin/systemctl start falcon-sensor.service 2> error.log
	;;
esac
if [ -s error.log ]; then
	read -p $'\e[31m[ERROR]\e[0m   | Something went wrong, wanna check error.log? [y/N]: ' input
    case $input in
		[yY])
			echo -e "\n"
			cat error.log
			echo -e "\n"
		;;
    esac
	echo -e "${RED}[ERROR]${DEFAULT}   | Fix the issue before using this script again"
    echo -e "\n${RED}[ERROR]${DEFAULT}   | Aborted Install"
    exit 1
fi
echo -e "${BLUE}[Running]${DEFAULT} | Confirming cloud handshake. Please wait..."

# Checking status

SERVICE=$(sudo /bin/systemctl status falcon-sensor.service > error.log)
RFM=$($ctl -g --rfm-state)
timeout=60
start=$(date +%s)

# Loop until the timeout is reached or the handshake is acknowledged
while true; do
	now=$(date +%s)
	elapsed=$((now - start))
	if [[ $elapsed -ge $timeout ]]; then
		error_log
	fi
	service_stats
	if (grep -q "ConnectToCloud successful" error.log); then
		break
	fi
done
case $? in
	"0")
		case "$RFM" in
			"rfm-state=true.")
				echo -e "\n${YELLOW}[Warning]${DEFAULT} | CAREFUL! THIS SERVICE IS RUNNING AS RFM! PROCEED AT YOUR OWN RISK!"
				echo -e "\n${YELLOW}[Warning]${DEFAULT} | REINSTALLING USUALLY SOLVES THIS ISSUE, IF NOT, REACH CROWDSTRIKE'S SUPPORT"
				sleep 3
			;;
		esac
		echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | Falcon service started successfully"	
	;;
esac
echo -e "\n${YELLOW}[Warning]${DEFAULT} | Check this hostname ($maq_hostname) on CrowdStrike Console"
sleep 2

# Cleaning everything up
echo -e "${GREEN}[OK]${DEFAULT}      | Cleaning..."
rm error.log 2> /dev/null
rm -rf /tmp/Repo 2> /dev/null
sleep 2
echo -e "\n${GREEN}[SUCCESS]${DEFAULT} | CrowdStrike Falcon-Sensor installed successfully."