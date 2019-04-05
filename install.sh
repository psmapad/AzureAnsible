#!/bin/bash
## Script to deploy Ansible on Azure
## Centos 7.5
## Tested on Azure MSFT
## Developer: Manuel Alejandro Peña Sánchez
## Ansible on Azure

source ./conf/setup.sh
source ./include/functions.sh

ANSIBLE="true"
LPIP=$INTERNET

if [ "$SUBSCRIPTIONID" != "" ]; then
    az account set -s $SUBSCRIPTIONID
fi

>~/bAnsi.log

case $1 in
deploy)

    CHECK=$(sshpass -V)
    if [ "$?" -ne 0 ]; then
        if [ -f /etc/debian[-,_]version ]; then
            OS="debian"
        fi
        if [ -f /etc/centos[-,_]version ]; then
            OS="centos"
        fi
        case $OS in
        debian)
            apt-get -y install sshpass
            ;;

        centos)
            yum -y install sshpass
            ;;
        *)
            echo "Not SSHPass Installed"
            exit
            ;;
        esac
    fi

    if [ "$ANSIBLE" == "true" ]; then
        source ./main/ansible.sh
    else
        echo "Ambiente Ansible en $ANSIBLE"
    #fi >> ~/bAnsi.log 2>&1
    fi
    echo "Ansible Access to $AZIPVMB with $AZVMUser through SSH with $AZVMPass"

    ;;

remove)

    if [ "$ANSIBLE" == "true" ]; then
        f_title "Remove Ansible"
        az group delete -n $(echo $AZCSUFF | awk '{ print toupper($0) }')RGANSI -y
    else
        echo "Ambiente Ansible en $ANSIBLE"
    fi

    az group delete -n $(echo $AZCSUFF | awk '{ print toupper($0) }')RGVNET -y

    ;;
*)
    echo "Uso: $0 {deploy AZPREFIX AZZONE AZUSER AZPASS | remove AZPREFIX}"
    exit 2
    ;;
esac
