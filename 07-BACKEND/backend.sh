#!/bin/bash
component=$1
environment=$2
sudo dnf install ansible -y
pip3.9 install botocore boto3
rm -rf /tmp/localhelp-ansible-roles

ansible-pull \
  -d /tmp/localhelp-ansible-roles \
  -U https://github.com/BhavyaPriyanka/localhelp-ansible-roles \
  -i localhost, \
  main.yaml \
  -e component=$component \
  -e env=$environment
