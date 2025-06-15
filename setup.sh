#!/bin/sh
set -e
log () {
    printf "\n[`date "+%Y/%m/%d %H:%M:%S"`] \033[0;38;5;214m$1\033[0m\n"
}

echo Specify the Splunk admin password to use:
read -s password

if ! docker ps | grep -w splunk/splunk; then
    log "Starting Splunk in Docker"
    [ -e terraform.tfstate ] && rm terraform.tfstate
    [ -e terraform.tfstate.backup ] && rm terraform.tfstate.backup
    docker run -d -p 8000:8000 -p 8089:8089 -p 8088:8088 -e "SPLUNK_START_ARGS=--accept-license" -e "SPLUNK_PASSWORD=$password" --name splunk splunk/splunk:latest
    log "Done"
fi

spin='-\|/'
log "Waiting for Splunk instance to come up..."

while ! curl -ks https://localhost:8089/?output_mode=json | jq -e '.updated, .generator'; do
  i=$(( (i+1) %4 ))
  printf "\r${spin:$i:1}"
  sleep 1
done

log "Splunk up and ready."

export TF_VAR_splunk_pass=$password
log "Deploying Splunk resources with Terraform"

terraform init
terraform apply -auto-approve

export HEC_TOKEN=`terraform output | cut -f2 -d\"`
log "Waiting for a healthy HEC endpoint..."

while ! curl -ks https://localhost:8088/services/collector/health | jq -r .text | grep healthy; do
  i=$(( (i+1) %4 ))
  printf "\r${spin:$i:1}"
  sleep 1
done

log "Sending synthetic test events"

virtualenv env
source env/bin/activate
python synthtest.py

log "Setup complete. Login to the Splunk UI at http://127.0.0.1:8000/"
