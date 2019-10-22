#!/bin/bash
# enter dns for the cluster you should also have route53 defined for this
clusterdns=lynx-v8.k8s.local
# enter your bucket name to store cluster data
bucket=govcloud-kops-state-store
# enter your master instance size
masterInstanceSize=t2.medium
#enter your worker instance size
workerInstanceSize=t2.medium

awsRegion=us-gov-west-1
awsZone=${awsRegion}c

DNS_ZONE=
# install kops 
##curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
#chmod +x kops-linux-amd64
#sudo mv kops-linux-amd64 /usr/local/bin/kops
# create s3 bucket for kubernetes cluster

#export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
#export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)

#aws s3 mb s3://${bucket}

AWS_REGION=$awsRegion
export KOPS_STATE_STORE=s3://${bucket}

echo "creating  cluster : create cluster --zones=$awsZone $clusterdns --master-size $masterInstanceSize --master-count 1 --node-size $workerInstanceSize"

#kops create cluster --cloud aws --zones=$awsZone $clusterdns --master-size $masterInstanceSize --master-count 1 --node-size $workerInstanceSize --out=. --target=terraform

kops create cluster \
  --name=$clusterdns \
  --state=$KOPS_STATE_STORE \
  --master-size $masterInstanceSize \
  --master-count 1 \
  --node-size $workerInstanceSize \
  --dns-zone $DNS_ZONE \
  --zones=$awsZone \
  --image=ami-5a0c663b \
  --cloud aws 
#  --out=. \
#  --target=terraform

RESULT=$?
if [ $RESULT -eq 0 ]; then
  echo "updating cluster : update cluster --name $clusterdns --yes"
   #kops update cluster --name $clusterdns --yes
else
  echo "Create cluster FAILED"
fi




