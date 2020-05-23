#!/usr/bin/env bash

git clone https://github.com/OpenVPN/easy-rsa.git
cd easy-rsa/easyrsa3
./easyrsa init-pki
export EASYRSA_BATCH=1
./easyrsa build-ca nopass
./easyrsa build-server-full server.$2 nopass
./easyrsa build-client-full client.$2 nopass
pwd
echo PWD: $1
test ! -d $1/certs && mkdir -p $1/certs
mv pki/ca.crt $1/certs/
mv pki/issued/server.$2.crt $1/certs/
mv pki/private/server.$2.key $1/certs/
mv pki/issued/client.$2.crt $1/certs/
mv pki/private/client.$2.key $1/certs/
cd ../..
rm -rf easy-rsa
