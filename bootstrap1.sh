#!/usr/bin/env bash
######################################################################################################
# Script Name: bootstrap.sh 
# Author: IBM
# Description: Bootstrap procedure to run software config on the host
#
# Options:
# 
#######################################################################################################

CONFIG_URL="https://ec2-18-224-32-194.us-east-2.compute.amazonaws.com:443"
CONFIG_KEY="0df114828b39ed1e1a765dc45d710ad2"
CONFIG_TEMPLATE=13
CONFIG_EXTRAVARS="{}"

function log {
    echo "INFO: bootstrap.sh --> $*"
}

function usage {
    log "INFO: Usage: None"
}

function validate_parameters {
    log "INFO: Validation of parameters..."
}

function check_OS()
{
    OS=`uname`
    KERNEL=`uname -r`
    MACH=`uname -m`

    if [ -f /etc/redhat-release ] ; then
        DistroBasedOn='RedHat'
        DIST=`cat /etc/redhat-release |sed s/\ release.*//`
        PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
        REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
    elif [ -f /etc/SuSE-release ] ; then
        DistroBasedOn='SuSe'
        PSUEDONAME=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
        REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
    elif [ -f /etc/debian_version ] ; then
        DistroBasedOn='Debian'
        if [ -f /etc/lsb-release ] ; then
            DIST=`cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }'`
            PSUEDONAME=`cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }'`
            REV=`cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }'`
        fi
    fi

    OS=$OS
    DistroBasedOn=$DistroBasedOn
    readonly OS
    readonly DIST
    readonly DistroBasedOn
    readonly PSUEDONAME
    readonly REV
    readonly KERNEL
    readonly MACH

    log "INFO: Detected OS : ${OS}  Distribution: ${DIST}-${DistroBasedOn}-${PSUEDONAME} Revision: ${REV} Kernel: ${KERNEL}-${MACH}"
}

function download_artifacts {
    log "INFO: Downloading bootstrap artifacts..."
    wget -q -O bootstrap_artifacts.zip https://github.com/invhariharan77/myapp/raw/master/bootstrap_artifacts.zip
    if [[ $? -ne 0 ]]
    then
        log "ERROR: Failed to download the bootstrap artifacts"
    fi
    unzip -q -o bootstrap_artifacts.zip
    chmod +x *.sh
}

function create_admin_user {
    log "INFO: Creating user for initial config..."
    useradd -G wheel icdsadmin
    echo "icdsadmin:8fvxRsZxbR9HnOSJ" | chpasswd
}

function run_config {
    log "INFO: Running initial config..."
    if [[ ${jumpbox} ]]; then
      log "INFO: Setting config vars for jumpbox"
      CONFIG_EXTRAVARS="{ansible_ssh_common_args: '-o ProxyCommand=\"ssh -W %h:%p -q icdsadmin@${jumpbox}\"', ansible_become: true}"
    fi
    ./request_tower_configuration.sh -k -s ${CONFIG_URL} -c ${CONFIG_KEY} -t ${CONFIG_TEMPLATE} -e ${CONFIG_EXTRAVARS}
}

jumpbox=''
host_type=''
user=''
public_key_file=''
private_key_file=''
playbooks_file=''

log "INFO: $# options and arguments were passed."

while getopts j:u:t:k:p:f: opt; do
    case $opt in
        j)
            jumpbox=${OPTARG}
            log "jumpbox --> $jumpbox"
            ;;
        u)
            user=${OPTARG}
            log "user --> $user" 
            ;;
        t) 
            host_type=${OPTARG}
            log "host_type --> $host_type"
            ;;
        k)
            public_key_file=${OPTARG}
            log "public_key_file --> $public_key_file"
            ;;
        p) 
            private_key_file=${OPTARG}
            log "private_key_file --> $private_key_file"
            ;;
        f)
            playbooks_file=${OPTARG}
            log "playbooks_file --> $playbooks_file"
            ;;
        \?) #invalid option
            log "${OPTARG} is not a valid option"
            usage
            exit 1
            ;;
    esac 
done

validate_parameters
check_OS
download_artifacts
create_admin_user
run_config

log "INFO: Completed execution of $0"
