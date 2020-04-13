#!/usr/bin/env bash
######################################################################################################
# Script Name: bootstrap.sh 
# Author: IBM
# Description: Bootstrap procedure to run software config on the host
#
# Options:
# 
#######################################################################################################

# Default values
ANSIBLE_TOWER_URL="https://ec2-18-224-32-194.us-east-2.compute.amazonaws.com:443"
ANSIBLE_TOWER_JOB_CONFIGKEY="0df114828b39ed1e1a765dc45d710ad2"
ANSIBLE_TOWER_JOB_TEMPLATE=13
ANSIBLE_TOWER_JOB_EXTRAVARS="{}"

JQ_DOWNLOAD_URL="https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
BOOTSTRAP_SUPPORT_DOWNLOAD_URL="https://github.com/invhariharan77/myapp/raw/master/bootstrap_artifacts.zip"

# log to output
function log {
    echo "INFO: bootstrap.sh --> $*"
}

# Handle fatal failures
fatal() {
  if [ -n "${2}" ]; then
    echo -e "ERROR: ${2}"
  fi
  exit ${1}
}

function usage {
cat << EOF
Usage: $0 <options>

Bootstrap the server by invoke Ansible playbook

OPTIONS:
   -h      Show this message
   -s      Tower server
   -c      Host config key
   -t      Job template ID
   -e      Extra variables
EOF
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

    log "Detected OS : ${OS}  Distribution: ${DIST}-${DistroBasedOn}-${PSUEDONAME} Revision: ${REV} Kernel: ${KERNEL}-${MACH}"
}

function download_artifacts {
    log "Downloading bootstrap additional artifacts..."
    wget -q -O bootstrap_artifacts.zip ${BOOTSTRAP_SUPPORT_DOWNLOAD_URL}
    if [[ $? -ne 0 ]]; then
        fatal 1 "ERROR: Failed to download the bootstrap artifacts"
    fi
    unzip -q -o bootstrap_artifacts.zip
    chmod +x *.sh

    wget -q -O /usr/local/bin/jq ${JQ_DOWNLOAD_URL}
    chmod +x /usr/local/bin/jq
}

function create_admin_user {
    log "Creating user for initial config..."
    user_exists=`id -u icdsadmin 2> /dev/null`
    if [[ $? -ne 0 ]]; then
        useradd -G wheel icdsadmin
        echo "icdsadmin:8fvxRsZxbR9HnOSJ" | chpasswd
    else
        log "User icdsadmin already exists. Skipping."
    fi
}

function run_ansible_play {
    log "Invoke ansible playbook..."
    retry_count=3

    while [[ ${retry_count} -gt 0 ]]
    do
      ./request_tower_configuration.sh -k \
          -s ${ANSIBLE_TOWER_URL} \
          -c ${ANSIBLE_TOWER_JOB_CONFIGKEY} \
          -t ${ANSIBLE_TOWER_JOB_TEMPLATE} \
          -e ${ANSIBLE_TOWER_JOB_EXTRAVARS}
      install_status=$?
      if [[ ${install_status} -eq 0 ]]; then
        break
      elif [[ ${install_status} -eq 909 ]]; then
        echo "Sync inventory failed. trying again after 120 seconds..."
        sleep 120
        retry_count=$((retry_count - 1))
      else
        log "Invoke ansible playbook procedure failed with exit code ${install_status}"
        fatal 2 "failed to run ansible play"
      fi
    done
}

while getopts hs:c:t:e: OPTION; 
do
    case ${OPTION} in
        s)
            ANSIBLE_TOWER_SRV_URL=${OPTARG}
            ;;
        c) 
            ANSIBLE_TOWER_JOB_CONFIGKEY=${OPTARG}
            ;;
        t)
            ANSIBLE_TOWER_JOB_TEMPLATE=${OPTARG}
            ;;
        e) 
            ANSIBLE_TOWER_JOB_EXTRAVARS=${OPTARG}
            ;;
        h)
            usage
            exit 1
            ;;
        \?) #invalid option
            log "${OPTARG} is not a valid option"
            usage
            exit 1
            ;;
    esac 
done

log "ANSIBLE_TOWER_URL = ${ANSIBLE_TOWER_URL}"
log "ANSIBLE_TOWER_JOB_CONFIGKEY = ${ANSIBLE_TOWER_JOB_CONFIGKEY}"
log "ANSIBLE_TOWER_JOB_TEMPLATE = ${ANSIBLE_TOWER_JOB_TEMPLATE}"
log "ANSIBLE_TOWER_JOB_EXTRAVARS = ${ANSIBLE_TOWER_JOB_EXTRAVARS}"

check_OS
download_artifacts
create_admin_user
run_ansible_play

log "Successfully completed execution of $0"

# End
