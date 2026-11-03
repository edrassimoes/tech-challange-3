#!/bin/bash
set -euo pipefail

tf_output() {
  terraform -chdir=terraform output "$@"
}

create_secret() {
  local name=$1 namespace=$2
  shift 2
  kubectl create secret generic "$name" --namespace "$namespace" "$@" --dry-run=client -o yaml | kubectl apply -f -
}

init_db() {
  kubectl run "db-init-$1" --rm -i --restart=Never --pod-running-timeout=5m --image=postgres:16-alpine \
    -- psql "$2" -v ON_ERROR_STOP=1 -c "${3//\$\$/\$\$\$\$}"
}

aws eks update-kubeconfig --name "$(tf_output -raw cluster_name)" --region us-east-1

auth_db=$(tf_output -json database_urls | jq -r .auth)
flags_db=$(tf_output -json database_urls | jq -r .flags)
targeting_db=$(tf_output -json database_urls | jq -r .targeting)
redis_url=$(tf_output -raw redis_url)
master_key=$(openssl rand -hex 32)
service_key="tm_key_$(openssl rand -hex 32)"

for service in auth flag targeting evaluation analytics; do
  kubectl apply -f "gitops/$service-service/namespace.yaml"
done

create_secret auth-service-secret auth --from-literal=DATABASE_URL="$auth_db" --from-literal=MASTER_KEY="$master_key"
create_secret flag-service-secret flags --from-literal=DATABASE_URL="$flags_db"
create_secret targeting-service-secret targeting --from-literal=DATABASE_URL="$targeting_db"
create_secret evaluation-service-secret evaluation --from-literal=REDIS_URL="$redis_url" --from-literal=SERVICE_API_KEY="$service_key"

init_db auth "$auth_db" "$(cat auth-service-main/db/init.sql)
INSERT INTO api_keys (name, key_hash)
VALUES ('evaluation-service', encode(sha256(convert_to('$service_key', 'UTF8')), 'hex'));"
init_db flags "$flags_db" "$(cat flag-service-main/db/init.sql)"
init_db targeting "$targeting_db" "$(cat targeting-service-main/db/init.sql)"

kubectl apply -f gitops/argocd/applications.yaml
