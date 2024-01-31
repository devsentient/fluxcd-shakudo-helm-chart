# SSH Portal

This chart installs SSH Portal, as well as a REST API proxy to control it. It also installs the appropriate services, secrets and stateful set.

## First time install
These steps need to be performed on first install of this helm chart

### Keys
a new ED25519 SSH key will need to be generated:
```ssh-keygen -o -a 100 -t ed25519 -f ./id_ed25519```
SSHPortal does not support RSA keys due to security concerns.

You will need the following files, which should be found in the folder you ran the command above in:

id_ed25519
id_ed25519.pub

### Helm

DO NOT put public and private key into any values.yaml files or CI pipelines/GitHub Actions!

```
helm install <app-name> ssh_portal --set publicKey="<public-key-file>",privateKey="<private-key-file>"
```

If you want to see what it will do first, add the --dry-run argument.

### To reset ssh proxy (just the subchart)
delete these resources: 
- deployment
- statefulset
- secret
- pvc