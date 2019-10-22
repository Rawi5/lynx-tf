#!/bin/bash
start_time="$(date -u +%s)"

CLUSTER_NAME="lynx-eks-v1"
CLUSTER_ENDPOINT=
CLUSTER_CERT=
AWS_KEY=
AWS_SECRET=
mkdir -p ./output

while getopts c:e:t:k:s: option
do
        case $option in
              c) CLUSTER_NAME=${OPTARG} ;;
	            e) CLUSTER_ENDPOINT=${OPTARG} ;;
	            t) CLUSTER_CERT=${OPTARG} ;;
				      k) AWS_KEY=${OPTARG} ;;
				      s) AWS_SECRET=${OPTARG} ;;
                \?) echo "Unknown option: -$OPTARG" >&2; phelp; exit 1;;
        		:) echo "Missing option argument for -$OPTARG" >&2; phelp; exit 1;;
        		*) echo "Unimplimented option: -$OPTARG" >&2; phelp; exit 1;;
        esac
done

if [ -z "${AWS_KEY}" ] ; then
 echo "Please set AWS_KEY using -k option to procced"
 exit 1
fi

if  [  -z "${AWS_SECRET}" ]  ; then
 echo "Please set AWS_SECRET using -s option to procced"
 exit 1
fi

if  [  -z "${CLUSTER_ENDPOINT}" ]  ; then
 echo "Please set CLUSTER_ENDPOINT using -e option to procced"
 exit 1
fi

if  [  -z "${CLUSTER_CERT}" ]  ; then
 echo "Please set CLUSTER_CERT using -t option to procced"
 exit 1
fi

if  [  -z "${CLUSTER_NAME}" ]  ; then
 echo "Please set CLUSTER_NAME using -c option to procced"
 exit 1
fi

CFG_FILE=./output/${CLUSTER_NAME}-auth-cfg.yaml

cat <<EOF >$CFG_FILE
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${CLUSTER_CERT}
    server: ${CLUSTER_ENDPOINT}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    user: ${CLUSTER_NAME}-user
  name: ${CLUSTER_NAME}
current-context: ${CLUSTER_NAME}
kind: Config
preferences: {}
users:
- name: ${CLUSTER_NAME}-user
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${CLUSTER_NAME}"
EOF

ls -ltr $CFG_FILE

export AWS_ACCESS_KEY_ID=$AWS_KEY
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET
export KUBECONFIG=$CFG_FILE

kubectl get nodes

TOKEN=$(kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | cut -f1 -d ' ') | grep -E '^token' | cut -f2 -d':' | tr -d '\t')
echo TOKEN:$TOKEN





