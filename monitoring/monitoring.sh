


helm install --name fluentd --namespace logging stable/fluentd-elasticsearch --set elasticsearch.host=elasticsearch-ingest.es-farm.svc.cluster.local,elasticsearch.port=9200

#helm install stable/prometheus-operator --name prometheus-operator --namespace monitoring
kubectl apply -f ./kube-prometheus


#kubectl port-forward -n monitoring alertmanager-prometheus-operator-alertmanager-0 9093