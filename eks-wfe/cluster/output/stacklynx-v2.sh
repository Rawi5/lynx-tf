
export AWS_ACCESS_KEY_ID=AKIAX7U7VQOSX4UAA4HE
export AWS_SECRET_ACCESS_KEY=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
sleep 30
export KUBECONFIG=/Users/sureshthumma/devzone/stackzone/lynx-tf/eks-wfe/cluster/output/stacklynx-v2-cfg.yaml
kubectl apply -f /Users/sureshthumma/devzone/stackzone/lynx-tf/eks-wfe/cluster/output/stacklynx-v2-aws-auth.yaml
kubectl get componentstatus 
kubectl get nodes
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/heapster.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/influxdb.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml

#kubectl apply -f /Users/sureshthumma/devzone/stackzone/lynx-tf/eks-wfe/cluster/output/stacklynx-v2-tiller-rbac.yaml
#helm init --node-selectors "appgroup"="system" --tiller-namespace kube-system --tiller-service-account tiller

# Create service accounts
kubectl apply -f /Users/sureshthumma/devzone/stackzone/lynx-tf/eks-wfe/cluster/output/stacklynx-v2-service-account.yaml
kubectl apply -f /Users/sureshthumma/devzone/stackzone/lynx-tf/eks-wfe/cluster/output/stacklynx-v2-role-binding.yaml

#create storage class and volumes
kubectl apply -f /Users/sureshthumma/devzone/stackzone/lynx-tf/eks-wfe/cluster/output/stacklynx-v2-storage.yaml


#setup helm for the cluster
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller
sleep 30

helm install --name nginx-ingress stable/nginx-ingress --set rbac.create=true --namespace ingress-nginx

helm install stable/cert-manager \
    --namespace ingress-nginx  \
    --set ingressShim.defaultIssuerName=letsencrypt-prod \
    --set ingressShim.defaultIssuerKind=ClusterIssuer \
    --version v0.5.2

kubectl apply -f /Users/sureshthumma/devzone/stackzone/lynx-tf/eks-wfe/cluster/output/stacklynx-v2-letsencryptpolicy.yaml -n ingress-nginx


APISERVER=$(kubectl config view | grep server | cut -f 2- -d ":" | tr -d " ")
TOKEN=$(kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | cut -f1 -d ' ') | grep -E '^token' | cut -f2 -d':' | tr -d '\t')

echo TOKEN:$TOKEN
echo APISERVER:$APISERVER
echo $TOKEN > /Users/sureshthumma/devzone/stackzone/lynx-tf/eks-wfe/cluster/output/stacklynx-v2.token

