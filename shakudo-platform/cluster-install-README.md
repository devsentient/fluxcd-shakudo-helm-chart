## Example install
Install all crds before the rest of the helm chart (as recommended by in helm docs)
```
kubectx [your-cluster-context]
kubectl apply -f crds/
```

Install the non-client-specific Prometheus resources
```
kubectx [your-cluster-context]
kubectl apply -f static/prometheus-0
kubectl apply -f static/prometheus-1
kubectl apply -f static/prometheus-2
```

### Helm install on a cluster

Consider a dry run:
```
helm install shakudo-hyperplane . --kube-context deploymentname --values values_deploymentname.yaml --debug
```

## Install
E.g.
```
helm install shakudo-hyperplane . --kube-context deploymentname --values values_deploymentname.yaml --set publicKeyGit=keys/id_rsa_deploymentname.pub,privateKeyGit=keys/id_rsa_deploymentname,ociServiceAccount.privateKey=keys/deploymentname_oci_sa.pem
```
optionally wait until finished, e.g.
```
helm install shakudo-hyperplane . --kube-context deploymentname --values values_deploymentname.yaml --wait --timeout 30m
```


## Upgrade

E.g.
```
helm upgrade shakudo-hyperplane . --kube-context deploymentname --values values_deploymentname.yaml
```

## Other commands

Generate a key, e.g.
```
ssh-keygen -t rsa -f keys/id_rsa_deploymentname
```

Use the following to get the open ssh public key string:
```ssh-keygen -y```

# Setup DNS
```
gcloud dns --project=hyperplane-test record-sets create deploymentname.hyperplane.dev. --type="A" --zone="hyperplane-main" --rrdatas="12.34.56.78" --ttl="300"
```