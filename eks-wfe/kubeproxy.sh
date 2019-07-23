#!/bin/bash

CLUSTER_NAME=${1:-stacklynx-v2}


source cluster/output/${CLUSTER_NAME}-auth-keys.sh  

echo "Open the link in the browser http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login"
echo use Token `cat cluster/output/${CLUSTER_NAME}.token`

kubectl proxy --address 0.0.0.0




