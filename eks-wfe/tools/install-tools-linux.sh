
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