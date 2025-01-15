#!/bin/bash
# Sizpa MF OBM Ajan Conf Tool
# Date 02.2023
# Author mesut.ozsoy@ptt.gov.tr

#export PATH=$PATH:/opt/OV/bin
#echo $PATH
#Vars
appPath="/opt/OV/bin"
ovcert="/opt/OV/bin/ovcert"
getDate=`date +"%Y-%m-%d %T"`
logFileName=sizpalog_$(date +"%d-%m-%Y").log
agentFileName="OBM_Agent_v1111.iso"
agentPackageURL="https://1.1.1.1/$agentFileName"
workDir="/tmp"

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

function rootCheck() {
	if [ "${EUID}" -ne 0 ]; then
		echo -e "${BWhite}Bu Scripti Root Yetkileri ile çalıştırmalısınız!"
		exit 1
	fi
}

function checkOS() {
	source /etc/os-release
	OS="${ID}"
	if [[ ${OS} == "debian" || ${OS} == "raspbian" ]]; then
		if [[ ${VERSION_ID} -lt 9 ]]; then
			echo "Your version of Debian (${VERSION_ID}) is not supported. Please use Debian 9 Buster or later"
			exit 1
		fi
		OS=debian 
	elif [[ ${OS} == "ubuntu" ]]; then
		RELEASE_YEAR=$(echo "${VERSION_ID}" | cut -d'.' -f1)
		if [[ ${RELEASE_YEAR} -lt 16 ]]; then
			echo "Your version of Ubuntu (${VERSION_ID}) is not supported. Please use Ubuntu 16.04 or later"
			exit 1
		fi
	elif [[ ${OS} == "fedora" ]]; then
		if [[ ${VERSION_ID} -lt 32 ]]; then
			echo "Your version of Fedora (${VERSION_ID}) is not supported. Please use Fedora 32 or later"
			exit 1
		fi
	elif [[ ${OS} == 'centos' ]] || [[ ${OS} == 'almalinux' ]] || [[ ${OS} == 'rhel' ]]; then
		if [[ ${VERSION_ID} == 5* ]]; then
			echo "Your version of CentOS-RHEL (${VERSION_ID}) is not supported. Please use CentOS - RHEL 7 or later"
			exit 1
		fi
	elif [[ -e /etc/oracle-release ]]; then
		source /etc/os-release
		OS=oracle
	elif [[ -e /etc/arch-release ]]; then
		OS=arch
	else
		echo "Looks like you aren't running this installer on a Debian, Ubuntu, Fedora, CentOS,RHEL, AlmaLinux, Oracle or Arch Linux system"
		exit 1
	fi
}

function createSedTemplate() {
cat << EOF > /tmp/sed_template
s/Certificates://g 
s/Trusted//g
s/Keystore Content (OVRG: server)//g
s/|//g
s/Keystore Content//g
s/+---------------------------------------------------------+//g
s/(\*)//g
/^[[:space:]]*$/d
s/^[ \t]*//
EOF
}

function logCreate {

    echo $getDate >> "$workDir/$logFileName"
    $ovcert -list  >> "$workDir/$logFileName"
    $ovcert -check >> "$workDir/$logFileName"
    sleep 3
	$appPath/ovc -status   >> "$workDir/$logFileName"
    echo "*****************************************" >> "$workDir/$logFileName"
}


function installAgent() {
	#cd $workDir
    #curl -o -s $agentPackageURL
	#mount -o loop $agentFileName /tmp/oa_agent_1215
}

function reinstallCertificate() {
	if [ ! -d "$appPath" ]; then
     	echo "Kurulu MicroFocus OBM Ajani Bulunamadi..." | tee -a $logFileName
	else
		createSedTemplate
		$ovcert -list > $workDir/ovcert-list
		sed -f $workDir/sed_template $workDir/ovcert-list > $workDir/cleandatalist
		while read ln; do $ovcert -remove -f "$ln"; done < /tmp/cleandatalist
		$ovcert -list
		$ovcert -certreq
		sleep 3
		$ovcert -list
		rm -rf $workDir/cleandatalist ; rm -rf $workDir/ovcert-list ; rm -rf $workDir/sed_template
		logCreate
	fi
}

function cleanRestart() {
	echo "Ajan Restart Ediliyor..."  && /opt/OV/bin/opcagt -cleanstart
	$appPath/ovc	
}

function uninstallAgent() {
	oainstall.sh -remove -agent -clean
}


function manageMenu() {
	echo " "
    echo     " - - OBM Ajan Konfigurasyon Aracı - -"
	echo     "Ajan islemlerini seciniz?"
	echo "   1) Ajan Kurulum"
	echo "   2) Ajan Sertifika Sil-Yukle"
	echo "   3) Ajan Clean Restart"
	echo "   4) Ajan Kaldirma"
	echo "   5) Cikis"
	until [[ ${MENU_OPTION} =~ ^[1-5]$ ]]; do
		read -rp "Secim Yapiniz [1-5]: " MENU_OPTION
	done
	case "${MENU_OPTION}" in
	1)
		installAgent
		;;
	2)
		reinstallCertificate
		;;
	3)
		cleanRestart
		;;
	4)
		uninstallAgent
		;;
	5)
		exit 0
		;;
	esac
}

rootCheck
checkOS
manageMenu


