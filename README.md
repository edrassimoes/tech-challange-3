# ToggleMaster

Plataforma de feature flags com 5 microsserviços: `auth`, `flag`, `targeting`, `evaluation` e `analytics`.

## Estrutura

- `terraform/`: infraestrutura na AWS
- `gitops/`: manifestos Kubernetes monitorados pelo ArgoCD
- `scripts/bootstrap.sh`: instala os componentes do cluster, cria os Secrets e inicializa os bancos
- `docker-compose.yml`: ambiente local

## Subir o ambiente

Crie o bucket do state uma única vez:

```bash
aws s3api create-bucket --bucket toggle-master-tfstate-579097996347 --region us-east-1
```

Crie a infraestrutura:

```bash
terraform -chdir=terraform init
terraform -chdir=terraform apply
```

Configure o cluster:

```bash
./scripts/bootstrap.sh
```

## Acessar o ArgoCD

O usuário é `admin`. Para obter a senha:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

A interface fica em `https://localhost:8080`.

## Destruir o ambiente

Remova o Load Balancer antes do `destroy`, pois ele não é gerenciado pelo Terraform:

```bash
kubectl delete -f gitops/argocd/applications.yaml
```

```bash
helm uninstall ingress-nginx --namespace ingress-nginx --wait
```

```bash
terraform -chdir=terraform destroy
```
