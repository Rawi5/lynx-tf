#!/bin/bash

CLUSTER_NAME=stacklynx-`openssl rand -base64 32 | base64 | head -c 4`
VPC_PREFIX=10.11
EKS_TYPE=cluster
CLUSTER_REGION=us-east-1
AWS_KEY=
AWS_SECRET=
CORP_IPS=`curl -s https://ifconfig.co`/32
mkdir -p ./output

while getopts c:n:t:r:k:s: option
do
        case $option in
                c) CLUSTER_NAME=${OPTARG} ;;
	            n) VPC_PREFIX=${OPTARG} ;;
	            t) EKS_TYPE=${OPTARG} ;;
	            r) CLUSTER_REGION=${OPTARG} ;;
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

cat ./eks-vars.tfvars.tmpl   \
  | sed "s|{{CLUSTER_NAME}}|${CLUSTER_NAME}|g"  \
  | sed "s|{{VPC_PREFIX}}|${VPC_PREFIX}|g"  \
  | sed "s|{{CLUSTER_REGION}}|${CLUSTER_REGION}|g"  \
  | sed "s|{{AWS_KEY}}|${AWS_KEY}|g"  \
  | sed "s|{{AWS_SECRET}}|${AWS_SECRET}|g"  \
  | sed "s|{{CORP_IPS}}|${CORP_IPS}|g"  \
> ./output/eks-vars-${CLUSTER_NAME}.tfvars

source cluster/output/${CLUSTER_NAME}-auth-keys.sh  
helm del --purge nginx-ingress

if [ -z "${EKS_TYPE}" ] ; then # if type is not set then create the cluster and nodes
  terraform  init  cluster
  terraform  destroy -var-file=./output/eks-vars-${CLUSTER_NAME}.tfvars -state=./output/$CLUSTER_NAME-cluster.state   cluster
  terraform  init  nodes
  terraform  destroy -var-file=./output/eks-vars-${CLUSTER_NAME}.tfvars -state=./output/$CLUSTER_NAME-nodes.state   nodes
else 
  terraform  init  $EKS_TYPE
  terraform  destroy -var-file=./output/eks-vars-${CLUSTER_NAME}.tfvars -state=./output/$CLUSTER_NAME-$EKS_TYPE.state  $EKS_TYPE
fi

