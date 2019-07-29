#!/bin/bash

CLUSTER_NAME=${1:-stacklynx-v2}

source cluster/output/$CLUSTER_NAME-auth-keys.sh

# List the nodes. make sure all the nodes are in ready state
echo -e "\n===> Listing nodes"
 kubectl get nodes -o wide

#list all the services in the nginx namespace.. make sure EXTERNAL-IP is listed for load balancer
echo -e "\n===> Listing Services for Nginx"
kubectl get svc -n ingress-nginx -o wide

ELB_EXTERNAL_IP=$(kubectl get  svc nginx-ingress-controller -n ingress-nginx -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")




#check if the the test pod and service is running
echo -e "\n===>Listing Pods for echoserver"
kubectl get pods -n echoserver -o wide

echo -e "\n===> Listing Services for echoserver"
kubectl get svc -n echoserver -o wide

#check if you are able to access the nginx controller through the load balancer. if successful you will see the response default backend - 404
echo -e "\n===> Checking if the load balancer is routing traffic to the nginx controller LB:$ELB_EXTERNAL_IP"
curl -k  $ELB_EXTERNAL_IP

echo -e "\nPlease check default backend - 404 is the output"





