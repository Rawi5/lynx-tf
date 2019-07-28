#!/bin/bash

git clone https://github.com/stacklynx/lynx-tf.git

cd lynx-tf

# install ubuntu desktop coponenets for rdp
sudo ./ubuntu-rd.sh

cd weks-wfe

#install tools
sudo ./tools/install-tools-linux.sh


./create-cluster.sh -k <aws_key> -s <aws_key> -t cluster -c stacklynx-v4

#wait for 1 min for the cluster to be initialzed

./cluster-setup.sh stacklynx-v4

#wait for 1 min for the ingress setup
./create-cluster.sh -k <aws_key> -s <aws_key> -t nodes -c stacklynx-v4

source cluster/output/stacklynx-v4-auth-keys.sh

#create the test app
./k8s-apps/nginx-test.sh





#### DELETING THE CLUSTER******



kubectl delete ns ingress-nginx
./delete-cluster.sh -k <aws_key> -s <aws_key> -t nodes -c stacklynx-v4
./delete-cluster.sh -k <aws_key> -s <aws_key> -t cluster -c stacklynx-v4






