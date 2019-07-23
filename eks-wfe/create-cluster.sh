#!/bin/bash

CLUSTER_NAME=stacklynx-v2
VPC_PREFIX=10.11
EKS_TYPE=cluster
CLUSTER_REGION=us-east-1
AWS_KEY=AKIAX7U7VQOSX4UAA4HE
AWS_SECRET=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
CORP_IPS=`curl https://ifconfig.co`
mkdir -p ./output

while getopts c:n:t:r:k:s:i: option
do
        case $option in
                c) CLUSTER_NAME=${OPTARG} ;;
	            n) VPC_PREFIX=${OPTARG} ;;
	            t) EKS_TYPE=${OPTARG} ;;
	            r) CLUSTER_REGION=${OPTARG} ;;
				k) AWS_KEY=${OPTARG} ;;
				s) AWS_SECRET=${OPTARG} ;;
				i) CORP_IPS=${OPTARG} ;;
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

terraform init  $EKS_TYPE
terraform apply -var-file=./output/eks-vars-${CLUSTER_NAME}.tfvars -state=./output/$CLUSTER_NAME-$EKS_TYPE.state   $EKS_TYPE