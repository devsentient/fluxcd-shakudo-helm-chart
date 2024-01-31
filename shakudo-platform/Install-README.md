# Shakudo helm chart installation instructions

1. Git pull our helm chart repo: `monorepo`
2. cd into ./charts/shakudo-platform
3. If you haven’t already, move your values yaml to this folder (./charts/shakudo-platform/)
4. Ensure you are in the correct kubecontext (check `kubectx`)
5. Generate two sets of keys in the following locations:
   in `charts/shakudo-platform/charts/sshportal/keys`

```
ssh-keygen -o -a 100 -t ed25519 -f ./id_ed25519
```

in `charts/shakudo-platform/keys`

```
ssh-keygen -t rsa -f ./id_rsa
```

ensure your "privateKeyGit" and "publicKeyGit" in your values.yaml are set to "keys/id_rsa" and "keys/id_rsa.pub" respectively

6. Modify Shakudo chart. Update values in `values*.yaml` depending on the cloud provider of the k8s cluster. For example, for AWS EKS, update the following values in `valuesEks.yaml`,

- `domain`
- `clientName`
- `domainName`
- `clusterName`
- `sshportal.domain`
- `components.airflow.gitURL`
- `buckets.aws`
- `gitServer.repo`
- `gitServer.repoUrl`

Note that for Oracle OKE, the auto-discovery feature (`--node-group-auto-discovery`) of [cluster-autoscaler](https://github.com/kubernetes/autoscaler) is disabled (for details, see [Oracle Docs](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengusingclusterautoscaler.htm) under "Supported Kubernetes Cluster Autoscaler Parameters
"). Therefore, we need to specify node group OCIDs. If you deployed your OKE cluster with terraform scripts under `hyperplane-oci/`, then the OCIDs are included in the terraform output. You can find them by running

```
terraform output | grep pool-OCID
```

Add your node groups and their OCIDs under `autoscaler.nodepools` in `valuesOke.yaml`. For example,

```yaml
autoscaler:
  nodepools:
    - type: main
      min: "1"
      max: "10"
      ocid: <YOUR_MAIN_POOL_NODE_GROUP_OCID>
    - type: jhub
      min: "1"
      max: "10"
      ocid: <YOUR_JHUB_POOL_NODE_GROUP_OCID>
```

Optionally, you can update the following values,

- `nodeSelectorExpressions.key`: custom cluster-wide node selector key
- `session.defaultAllocatableRam`: default root allocatable CPU for reconciler and dashboard
- `session.defaultAllocatableCpu`: default root allocatable RAM for reconciler and dashboard

If you wish to use images from other private registries (maybe on another cloud provider), we currently support GCR, ECR, ACR, OCIR, Docker Hub. Follow the example in `values.yaml` to setup docker authentication for your private registry in `customImagePullSecrets`.

For Oracle OKE, update the `OCI_REGION` value.

For clusters where the client has added permissions to the service account for `cert-manager` to alter DNS records, set,

```
certManager.useServiceAccountSecretRef: false
```

7. Install Shakudo chart. From within the `charts/shakudo-platform/` directory

`kubectl apply -f crds/`
`kubectl apply -f static/prometheus-0`
`kubectl apply -f static/prometheus-1`
`kubectl apply -f static/prometheus-2`
`helm install shakudo-hyperplane . --values your-values-file.yaml --debug`

8. Check if there is an "istiod" pod running in the "istio-system" namespace
9. Send the Shakudo team your istio ingress-gateway LoadBalancer `svc` external IP — we will use this to create a DNS recordset

- Note that this is an IP address if on Oracle OKE but a URL if on AWS EKS or GCP GKE.

10. Check if the `certificate` resources are "up to date and has not expired"
11. Follow `charts/shakudo-platform/shakudo-platform-docs/cluster-setup.README.md` to setup KeyCloak and Applications on your cluster.
