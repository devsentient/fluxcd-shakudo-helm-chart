#!/bin/sh

SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)
TOKEN=$(cat ${SERVICEACCOUNT}/token)
CACERT=${SERVICEACCOUNT}/ca.crt

ssh-keygen -t ed25519 -N "" -f /tmp/id_ed25519
# The k8s secret keys need to be id_rsa and id_rsa.pub even though a id_ed25519 key is generated is because these values are hardcoded in the backend apps
# The secret name is "github-deploy-key-ancrht4u" cause it's hardcoded in our helm chart
echo $(
	jq -n \
		--arg namespace "$NAMESPACE" \
		--arg privateKey "$(cat /tmp/id_ed25519 | base64 | tr -d '[:space:]')" \
		--arg publicKey "$(cat /tmp/id_ed25519.pub | base64)" \
		--arg knownHosts "${KNOWN_HOSTS}" \
		'{
    "apiVersion":"v1",
    "kind" :"Secret",
    "metadata" :{
      "namespace" : $namespace,
      "name": "github-deploy-key-ancrht4u"
    },
    "type": "Opaque",
    "data": {
      "id_rsa": $privateKey,
      "id_rsa.pub": $publicKey,
      "known_hosts": $knownHosts
    }
  }'
) >secret.json

curl -X 'POST' "https://kubernetes.default.svc/api/v1/namespaces/${NAMESPACE}/secrets" \
	--cacert "${CACERT}" \
	-H "Authorization: Bearer ${TOKEN}" \
	-H 'accept: application/json' \
	-H 'Content-Type: application/json' \
	-d @secret.json

# TODO: get rid of this after refactoring apiserver and dashboard to not use that one env
echo $(
	jq -n \
		--arg namespace "$NAMESPACE" \
		--arg privateKey "$(cat /tmp/id_ed25519 | base64 | tr -d '[:space:]')" \
		--arg publicKey "$(cat /tmp/id_ed25519.pub | base64)" \
		--arg knownHosts "${KNOWN_HOSTS}" \
		'{
    "apiVersion":"v1",
    "kind" :"Secret",
    "metadata" :{
      "namespace" : "hyperplane-core", 
      "name": "github-deploy-key-ancrht4u" 
    },
    "type": "Opaque",
    "data": {
      "id_rsa": $privateKey,
      "id_rsa.pub": $publicKey,
      "known_hosts": $knownHosts 
    }
  }'
) >secret.json

curl -i -X 'POST' "https://kubernetes.default.svc/api/v1/namespaces/hyperplane-core/secrets" \
	--cacert "${CACERT}" \
	-H "Authorization: Bearer ${TOKEN}" \
	-H 'accept: application/json' \
	-H 'Content-Type: application/json' \
	-d @secret.json
