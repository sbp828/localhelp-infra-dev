#!/bin/bash
component=$1
environment=$2
sudo dnf install ansible -y
pip3.9 install botocore boto3
sudo ansible-pull -i localhost, -U https://github.com/sbp828/localhelp-ansible-roles main.yaml -e component=$component -e env=$environment