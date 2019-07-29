#!/bin/bash

git clone https://github.com/stacklynx/lynx-tf.git

cd lynx-tf

# install ubuntu desktop coponenets for rdp
sudo ./ubuntu-rd.sh

cd eks-wfe

#install tools
sudo ./tools/install-tools-linux.sh


./create-cluster.sh -k <aws_key> -s <aws_key>  -c stacklynx-v4


source cluster/output/stacklynx-v4-auth-keys.sh




#### DELETING THE CLUSTER******


./delete-cluster.sh -k <aws_key> -s <aws_key> -c stacklynx-v4






