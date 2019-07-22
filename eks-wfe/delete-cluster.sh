#!/bin/bash

CLUSTER_NAME=stacklynx-v2
VPC_PREFIX=10.11
EKS_TYPE=cluster
CLUSTER_REGION=us-west-2

mkdir -p ./output

while getopts c:n:t:r: option
do
        case $option in
                c)
		              CLUSTER_NAME=${OPTARG};
				        	;;
	              n)
               	  VPC_PREFIX=${OPTARG};
                	;;
	              t)
               	  EKS_TYPE=${OPTARG};
                	;;
	              r)
               	  CLUSTER_REGION=${OPTARG};
                	;;
                \?) echo "Unknown option: -$OPTARG" >&2; phelp; exit 1;;
        		:) echo "Missing option argument for -$OPTARG" >&2; phelp; exit 1;;
        		*) echo "Unimplimented option: -$OPTARG" >&2; phelp; exit 1;;
        esac
done

cat ./eks-vars.tfvars.tmpl   \
  | sed "s|{{CLUSTER_NAME}}|${CLUSTER_NAME}|g"  \
  | sed "s|{{VPC_PREFIX}}|${VPC_PREFIX}|g"  \
  | sed "s|{{CLUSTER_REGION}}|${CLUSTER_REGION}|g"  \
> ./output/eks-vars.tfvars

mkdir -p ./output

terraform destroy -var-file=./output/eks-vars.tfvars -state=./output/$CLUSTER_NAME-$EKS_TYPE.state   $EKS_TYPE