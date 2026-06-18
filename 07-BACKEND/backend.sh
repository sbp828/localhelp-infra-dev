#!/bin/bash
set -euxo pipefail


exec > >(sudo tee /var/log/backend-user-data.log) 2>&1

environment=$2

echo "Starting backend bootstrap..."

# ---------------------------
# Install dependencies
# ---------------------------
sudo dnf clean all
sudo dnf update -y

sudo dnf install -y jq awscli python3 python3-pip ansible-core
echo "Skipping pip upgrade (RPM-managed pip)"

sudo python3 -m pip install --ignore-installed PyMySQL cryptography boto3 botocore

REPO_DIR=/tmp/localhelp-ansible

rm -rf $REPO_DIR
git clone https://github.com/sbp828/localhelp-ansible-roles $REPO_DIR

sudo ansible-galaxy collection install -r $REPO_DIR/collections/requirements.yml

sudo ansible-pull -U $REPO_DIR main.yaml \
  -i localhost, -c local \
  -e component=backend \
  -e env="$environment"