#!/bin/bash

curl -o ./tools/heptio-authenticator-aws https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/bin/linux/amd64/heptio-authenticator-aws
chmod +x ./tools/heptio-authenticator-aws \
 && mv ./tools/heptio-authenticator-aws /usr/local/bin/heptio-authenticator-aws

curl -o ./tools/kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/bin/linux/amd64/kubectl
chmod +x ./tools/kubectl \
 && mv ./tools/kubectl /usr/local/bin/kubectl

curl -o ./tools/helm-v2.11.0-linux-amd64.tar.gz https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-linux-amd64.tar.gz  \
    && tar -zxvf ./tools/helm-v2.11.0-linux-amd64.tar.gz  -C /tmp \
    && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
    && mv /tmp/linux-amd64/tiller /usr/local/bin/tiller \
    && chmod +x /usr/local/bin/tiller \
    && chmod +x /usr/local/bin/helm \
    && rm -f ./tools/helm-v2.11.0-linux-amd64.tar.gz

apt=`command -v apt-get`
yum=`command -v yum`

if [ -n "$apt" ]; then
    apt-get update
    apt-get -y install unzip
elif [ -n "$yum" ]; then
    yum -y install unzip
else
    echo "Err: no path to apt-get or yum" >&2;
    exit 1;
fi

curl -O https://bootstrap.pypa.io/get-pip.py
python get-pip.py --user
export PATH=~/.local/bin:$PATH
pip install awscli --upgrade --user
aws --version

curl -o /tmp/terraform_linux_amd64.zip  https://releases.hashicorp.com/terraform/0.12.5/terraform_0.12.5_linux_amd64.zip && \
    unzip /tmp/terraform_linux_amd64.zip -d /usr/local/bin \
    && rm /tmp/terraform_linux_amd64.zip


terraform -v

kubectl version

helm version

