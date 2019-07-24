
cat <<EOF > ./output/letsencrypt-issuer.yaml
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: 'devops@stacklynx.com'
    privateKeySecretRef:
      name: letsencrypt-staging
    http01: {}
---
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: 'devops@stacklynx.com'
    privateKeySecretRef:
      name: letsencrypt-prod
    http01: {}

EOF

helm install --name nginx-ingress stable/nginx-ingress --set rbac.create=true --namespace ingress-nginx

helm install stable/cert-manager \
    --namespace ingress-nginx  \
    --set ingressShim.defaultIssuerName=letsencrypt-prod \
    --set ingressShim.defaultIssuerKind=ClusterIssuer \
    --version v0.5.2

kubectl apply -f ./output/letsencrypt-issuer.yaml -n ingress-nginx

