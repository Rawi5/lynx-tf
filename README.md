# tf-templates
Repository  for managing sample terraform templates and scripts

## Clone the Repo
```
git clone https://github.com/stacklynx/lynx-tf.git

cd lynx-tf
```

### ONLY required if you need to remote desktop into the ubutu desktop for accessing the prroxy
#### install ubuntu desktop coponenets 
```
sudo ./ubuntu-rd.sh
```



### install tools required for the instalation. This will install terraform, kubectl, awscli and other components
```
cd eks-wfe
sudo ./tools/install-tools-linux.sh
```

### Create an AWS Accoount with the following policy and create a Security. click here how to create keys (https://aws.amazon.com/premiumsupport/knowledge-center/create-access-key)
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "iam:*",
                "ec2:*",
                "autoscaling:*",
                "eks:*"
            ],
            "Resource": "*"
        }
    ]
}
```


### Create the Custer. Make sure you have the aws keys and secret before you run the steps
```
Parameters
 -t : Module to install. ddefault installs the cluster and nodes
 -c : Cluster name
 -k : aws key for admin account that has permission to create a cluster
 -s : aws secret for admin account that has permission to create a cluster

./create-cluster.sh -k <aws_key> -s <aws_key> -c <clustername>
```


### Verify if all the components are vcreated sucessfully 
```
source cluster/output/<clustername>-auth-keys.sh

# List the nodes. make sure all the nodes are in ready state
 kubectl get nodes -o wide

#list all the services in the nginx namespace.. make sure EXTERNAL-IP is listed for load balancer
kubectl get svc -n ingress-nginx -o wide

#check if you are able to access the nginx controller through the load balancer. if successful you will see the response default backend - 404
curl -k < EXTERNAL-IP>

#check if the the test pod and service is running
kubectl get pods -n echoserver -o wide
kubectl get svc -n echoserver -o wide

```

### Start Proxy to access Kubernetes Dashboard
```
./kubeproxy.sh <clustername>
```



