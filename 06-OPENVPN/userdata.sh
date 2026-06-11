#!/bin/bash
set -eux

apt-get update -y
apt-get install -y ca-certificates wget gnupg

wget -qO - https://as-repository.openvpn.net/as-repo-public.gpg | \
gpg --dearmor > /etc/apt/trusted.gpg.d/openvpn-as.gpg

echo "deb http://as-repository.openvpn.net/as/debian jammy main" > \
/etc/apt/sources.list.d/openvpn-as.list

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y openvpn-as

# Wait for Access Server to start
until systemctl is-active --quiet openvpnas; do
  sleep 5
done

sleep 20

cd /usr/local/openvpn_as

./scripts/sacli \
  --user ubuntu \
  --new_pass 'Openvpn@123' \
  SetLocalPassword

./scripts/sacli \
  --user ubuntu \
  --key prop_superuser \
  --value true \
  UserPropPut

systemctl restart openvpnas