#!/bin/sh
# An idempotent update script for all configurations in keycloak

readonly REALM_NAME=Hyperplane
readonly NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
readonly KEYCLOAK_SERVER="http://keycloak.${NAMESPACE}.svc.cluster.local:8080/auth/"

function auth() {
  kcadm.sh config credentials --server "${KEYCLOAK_SERVER}" --realm master --user admin --password $(cat /kc-creds/password)
}

function create_realm() {
  local realm=$(kcadm.sh get realms --fields realm | jq -r '.[] | select(.realm == "Hyperplane") | .realm' | tr -d '\n')
  if [ "$realm" != "Hyperplane" ]; then
    # 2592000 seconds = 30 days
    kcadm.sh create realms -s realm="${REALM_NAME}" \
      -s enabled=true -o \
      -s ssoSessionIdleTimeout=2592000 \
      -s ssoSessionMaxLifespan=2592000 \
      -s loginTheme=devsentient \
      -s "verifyEmail=true"
  fi 
}

function update_csp() {
    local csp="default-src 'self'; img-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; object-src 'none'; frame-ancestors 'self';"
    kcadm.sh update realms/master -s browserSecurityHeaders.contentSecurityPolicy="${csp}"

    local hyperplane_csp=$csp
    if [ "${SNOWPLOW_ENABLED}" = 'true' ]; then
      local tracker_csp="default-src 'self'; img-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net/gh/devsentient/cdn@main/sp.js; style-src 'self' 'unsafe-inline'; object-src 'none'; frame-ancestors 'self'; connect-src https://*.hyperplane.dev 'self'"
      hyperplane_csp=$tracker_csp
    fi
    kcadm.sh update realms/${REALM_NAME} -s browserSecurityHeaders.contentSecurityPolicy="${hyperplane_csp}"
}

function create_istio_client() {
  local clientId=$(kcadm.sh get clients -r "${REALM_NAME}" | jq -r '.[] | select(.clientId == "istio") | .clientId')
  if [ "$clientId" != "istio" ]; then
    local redirect_uris=$(echo "[\"
      "https://$DOMAIN_NAME",
      "https://$DOMAIN_NAME/*",
      "https://k9s.$DOMAIN_NAME",
      "https://k9s.$DOMAIN_NAME/*",
      "https://grafana.$DOMAIN_NAME",
      "https://grafana.$DOMAIN_NAME/*"
    \"]" | tr -d '[:space:]' | jq -crR '. | gsub(","; "\",\"")')

    kcadm.sh create clients -r "${REALM_NAME}" \
      -s name=istio \
      -s protocol=openid-connect \
      -s clientId=istio \
      -s "redirectUris=${redirect_uris}" \
      -s attributes."login_theme"=devsentient \
      -s 'webOrigins=["*"]' \
      -s publicClient=true \
      -s implicitFlowEnabled=true \
      -s standardFlowEnabled=true \
      -s directAccessGrantsEnabled=true
  fi
  ISTIO_CLIENT_JSON=$(kcadm.sh get clients -r "${REALM_NAME}" | jq '.[] | select(.clientId == "istio")')
  ISTIO_CLIENT_ID=$(echo ${ISTIO_CLIENT_JSON} | jq -r '.id')
}

function update_istio_client_roles() {
  kcadm.sh create "clients/${ISTIO_CLIENT_ID}/roles" -r "${REALM_NAME}" -s name=k9s-admin -s "description=Can access https://k9s.${DOMAIN_NAME}/admin to use the k9s terminal as a cluster admin" || true
  kcadm.sh create "clients/${ISTIO_CLIENT_ID}/roles" -r "${REALM_NAME}" -s name=k9s-maintainer -s "description=Can access https://k9s.${DOMAIN_NAME}/maintainer to use the k9s terminal as a maintainer(read all resources, exec into pods, delete pods)" || true
  kcadm.sh create "clients/${ISTIO_CLIENT_ID}/roles" -r "${REALM_NAME}" -s name=k9s-reader -s "description=Can access https://k9s.${DOMAIN_NAME}/reader to use the k9s terminal as a reader(read all resources except secrets)" || true
  kcadm.sh create "clients/${ISTIO_CLIENT_ID}/roles" -r "${REALM_NAME}" -s name=dashboard-admin -s "description=Can manage/see all resources of other users on the Shakudo dashboard" || true
  kcadm.sh create "clients/${ISTIO_CLIENT_ID}/roles" -r "${REALM_NAME}" -s name=keycloak-admin -s "description=Can see all Shakudo users, roles, and groups" || true
}

function create_istio_protocol_mappers() {
  kcadm.sh create "clients/${ISTIO_CLIENT_ID}/protocol-mappers/models" -r "${REALM_NAME}" \
    -s 'name=istio' \
    -s 'protocolMapper=oidc-audience-mapper' \
    -s 'consentRequired=false' \
    -s 'protocol=openid-connect' \
    -s 'config."id.token.claim"=true' \
    -s 'config."access.token.claim"=true' \
    -s 'config."clientAudience.label"=true' \
    -s 'config."included.client.audience"=istio' || true

  kcadm.sh create "clients/${ISTIO_CLIENT_ID}/protocol-mappers/models" -r "${REALM_NAME}" \
    -s 'name=client-roles' \
    -s 'protocolMapper=oidc-usermodel-client-role-mapper' \
    -s 'protocol=openid-connect' \
    -s 'config."claim.name"="resource_access.${client_id}.roles"' \
    -s 'config."claim_name"="resource_access.\${client_id}.roles"' \
    -s 'config."token_claim_name"="resource_access.${client_id}.roles"' \
    -s 'config."usermodel.clientRoleMapping.clientId"=istio' \
    -s 'config."jsonType.label"=String' \
    -s 'config."id.token.claim"=true' \
    -s 'config."access.token.claim"=true' \
    -s 'config."userinfo.token.claim"=false' \
    -s 'config.multivalued=true' || true
}

function create_istio_client_mappers() {
  kcadm.sh create "client-scopes" -r "${REALM_NAME}" -s "name=groups" -s "protocol=openid-connect" -s "description=OpenID Connect custom scope: groups" || true

  local client_scopes=$(echo $ISTIO_CLIENT_JSON | jq -r '.defaultClientScopes += ["groups"] | .defaultClientScopes' | tr -d '[:space:]' | jq -crR '.')
  local groups_client_scope_id=$(kcadm.sh get client-scopes -r Hyperplane | jq -r '.[] | select(.name == "groups") | .id')
  kcadm.sh update "clients/${ISTIO_CLIENT_ID}/default-client-scopes/${groups_client_scope_id}" -r "Hyperplane"
}

function main() {
    auth
    create_realm 
    update_csp
    create_istio_client
    create_istio_protocol_mappers
    create_istio_client_mappers
    update_istio_client_roles
}

# Disallow expansion of unset variables
set -o nounset

main "$@"
