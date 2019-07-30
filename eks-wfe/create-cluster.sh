#!/bin/bash
start_time="$(date -u +%s)"

echo "Using Terraform version `terraform -v`"
CLUSTER_NAME=stacklynx-`openssl rand -base64 32 | base64 | head -c 4`
VPC_PREFIX=10.11
EKS_TYPE=
CLUSTER_REGION=us-east-1
AWS_KEY=
AWS_SECRET=
CORP_IPS=`curl -s https://ifconfig.co`/32
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

cat <<EOF > ./output/eks-vars-${CLUSTER_NAME}.tfvars
aws_access_key = "${AWS_KEY}"
aws_secret_key = "${AWS_SECRET}"
aws_region = "${CLUSTER_REGION}"
cluster-name = "${CLUSTER_NAME}"
vpcnet_prefix ="${VPC_PREFIX}"
corporate_cidr_list=["${CORP_IPS}"]
EOF



echo "Creating Cluster: $CLUSTER_NAME  `date`"

if [ -z "${EKS_TYPE}" ] ; then # if type is not set then create the cluster and nodes
  terraform  init  cluster
  terraform  apply -var-file=./output/eks-vars-${CLUSTER_NAME}.tfvars -state=./output/$CLUSTER_NAME-cluster.state  -auto-approve  cluster
  RET=$?
  if [[ RET -ne 0 ]]; then # then retry cluster creation
  echo "Retrying cluster creation. last exit code: $RET"
    terraform  apply -var-file=./output/eks-vars-${CLUSTER_NAME}.tfvars -state=./output/$CLUSTER_NAME-cluster.state  -auto-approve  cluster
  fi

  terraform  init  nodes
  terraform  apply -var-file=./output/eks-vars-${CLUSTER_NAME}.tfvars -state=./output/$CLUSTER_NAME-nodes.state  -auto-approve nodes
else 
  terraform  init  $EKS_TYPE
  terraform  apply -var-file=./output/eks-vars-${CLUSTER_NAME}.tfvars -state=./output/$CLUSTER_NAME-$EKS_TYPE.state   $EKS_TYPE

  RET=$?
  if [[ RET -ne 0 ]]; then # then retry cluster creation
  echo "Retrying operation. last exit code: $RET"
  terraform  apply -var-file=./output/eks-vars-${CLUSTER_NAME}.tfvars -state=./output/$CLUSTER_NAME-$EKS_TYPE.state   $EKS_TYPE
  fi

fi


end_time="$(date -u +%s)"
elapsed="$(($end_time-$start_time))"
echo "Total time taken for cluster creation: $elapsed sec"

echo "set Env variables execute this: source cluster/output/${CLUSTER_NAME}-auth-keys.sh"

AUTH_FILE=cluster/output/${CLUSTER_NAME}-auth-keys.sh
if [ -f "$AUTH_FILE" ]; then
source cluster/output/${CLUSTER_NAME}-auth-keys.sh 
echo Waiting 30s for the nodes to be initialized
sleep 30
kubectl apply -f ./k8s-apps/echoserver.yaml
kubectl get nodes -o wide
kubectl get svc -n echoserver -o wide
kubectl get svc -n ingress-nginx -o wide

echo Load Balancer DNS: $(kubectl get  svc nginx-ingress-controller -n ingress-nginx -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

echo "Cluster Setup Completed: $CLUSTER_NAME  `date`"

echo "Test the setup using the proxy Run ./kubeproxy and http://localhost:8001/api/v1/namespaces/echoserver/services/http:echoserver:/proxy/"
else
  echo "Auth file:$AUTH_FILE does not exist: Cluster creation probably failed"
fi