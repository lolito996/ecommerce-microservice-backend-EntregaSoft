# Guía de Despliegue en AWS

Esta guía te llevará paso a paso para desplegar la infraestructura de microservicios en AWS.

## 📋 Prerrequisitos

### 1. Instalar AWS CLI
```powershell
# Descargar e instalar AWS CLI desde:
# https://aws.amazon.com/cli/

# Verificar instalación
aws --version
```

### 2. Instalar Terraform
```powershell
# Descargar desde: https://www.terraform.io/downloads
# O con Chocolatey:
choco install terraform

# Verificar instalación
terraform --version
```

### 3. Instalar kubectl
```powershell
# Con Chocolatey:
choco install kubernetes-cli

# Verificar instalación
kubectl version --client
```

## 🔑 Paso 1: Configurar Credenciales AWS

```powershell
# Configurar tus credenciales AWS
aws configure

# Te pedirá:
# AWS Access Key ID: [Tu Access Key]
# AWS Secret Access Key: [Tu Secret Key]
# Default region name: us-east-1
# Default output format: json
```

**¿Cómo obtener credenciales?**
1. Accede a AWS Console → IAM
2. Users → Tu usuario → Security credentials
3. Create access key → CLI
4. Guarda el Access Key ID y Secret Access Key

**Permisos necesarios:**
- EC2 (VPC, Subnets, Security Groups)
- EKS (Cluster, Node Groups)
- IAM (Roles, Policies)
- S3 (Buckets)
- DynamoDB (Tables)

## 🪣 Paso 2: Crear Backend Remoto (S3 + DynamoDB)

Este paso crea el bucket S3 y la tabla DynamoDB para almacenar el estado de Terraform.

```powershell
# Navegar al directorio bootstrap
cd infra\terraform\bootstrap

# Inicializar Terraform
terraform init

# Revisar qué se va a crear
terraform plan

# Crear recursos (S3 bucket + DynamoDB table)
terraform apply
# Escribe 'yes' para confirmar
```

**Resultado esperado:**
- ✅ S3 bucket: `ecom-terraform-state`
- ✅ DynamoDB table: `ecom-terraform-state-lock`
- ✅ Outputs con la configuración del backend

**Verificar:**
```powershell
# Listar buckets S3
aws s3 ls

# Ver tabla DynamoDB
aws dynamodb list-tables
```

## 🧪 Paso 3: Desplegar Ambiente STAGING

```powershell
# Navegar al directorio staging
cd ..\environments\staging

# Inicializar con el backend S3
terraform init -backend-config=backend.tfvars

# Revisar el plan de infraestructura
terraform plan

# Aplicar configuración
terraform apply
# Escribe 'yes' para confirmar
```

**Esto creará:**
- ✅ VPC con subnets públicas y privadas
- ✅ EKS Cluster: `ecom-staging-eks`
- ✅ Node Group con 2 nodos (t3.medium)
- ✅ SonarQube desplegado via Helm
- ✅ Namespace para microservicios

**Tiempo estimado:** 15-20 minutos

## 🔌 Paso 4: Conectar a tu Cluster EKS

```powershell
# Configurar kubectl para staging
aws eks update-kubeconfig --region us-east-1 --name ecom-staging-eks

# Verificar conexión
kubectl get nodes
kubectl get namespaces

# Ver pods de SonarQube
kubectl get pods -n sonarqube

# Ver servicios (LoadBalancers)
kubectl get svc -n sonarqube
```

**Obtener URL de SonarQube:**
```powershell
# Obtener External IP del LoadBalancer
kubectl get svc -n sonarqube sonarqube -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Acceder en el navegador a esa URL en el puerto 9000
# Usuario por defecto: admin / admin
```

## 🚀 Paso 5: Desplegar tus Microservicios

Una vez que el cluster esté listo, puedes desplegar tus microservicios:

```powershell
# Opción 1: Con Helm (recomendado)
# Navega a tu directorio de charts Helm
helm install ecommerce-services ./charts/ecommerce `
  --namespace ecommerce `
  --create-namespace `
  --set environment=staging

# Opción 2: Con kubectl y manifiestos K8s
kubectl apply -f k8s/ -n ecommerce

# Verificar despliegue
kubectl get pods -n ecommerce
kubectl get svc -n ecommerce
```

## 🏭 Paso 6 (Opcional): Desplegar Ambiente PRODUCTION

```powershell
# Navegar al directorio prod
cd ..\prod

# Inicializar con backend S3
terraform init -backend-config=backend.tfvars

# Revisar plan
terraform plan

# Aplicar (3 nodos t3.large)
terraform apply
```

## 📊 Comandos Útiles

### Terraform
```powershell
# Ver estado actual
terraform show

# Ver outputs
terraform output

# Destruir infraestructura (¡CUIDADO!)
terraform destroy

# Formatear archivos
terraform fmt -recursive
```

### Kubernetes
```powershell
# Ver todos los recursos
kubectl get all -A

# Logs de un pod
kubectl logs <pod-name> -n <namespace>

# Describir un recurso
kubectl describe pod <pod-name> -n <namespace>

# Port forward para acceder localmente
kubectl port-forward svc/sonarqube 9000:9000 -n sonarqube
```

### AWS
```powershell
# Ver clusters EKS
aws eks list-clusters

# Describir cluster
aws eks describe-cluster --name ecom-staging-eks

# Ver node groups
aws eks list-nodegroups --cluster-name ecom-staging-eks
```

## 🔧 Solución de Problemas

### Error: "AccessDenied"
```powershell
# Verificar credenciales
aws sts get-caller-identity

# Verificar permisos IAM necesarios
```

### Error: "Bucket already exists"
```powershell
# Cambiar el nombre del bucket en bootstrap/terraform.tfvars
# Los nombres de S3 deben ser únicos globalmente
s3_bucket_name = "ecom-terraform-state-TU-NOMBRE"
```

### Cluster no responde
```powershell
# Reconfigurar kubectl
aws eks update-kubeconfig --region us-east-1 --name ecom-staging-eks --force

# Verificar nodos
kubectl get nodes
```

### Pods en estado Pending
```powershell
# Ver eventos
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Describir pod
kubectl describe pod <pod-name> -n <namespace>

# Posibles causas:
# - Recursos insuficientes (escalar node group)
# - ImagePullBackOff (verificar imagen)
# - PVC sin provisionar (verificar storage class)
```

## 📈 Monitoreo de Costos

```powershell
# Ver costos estimados de recursos
# Staging: ~$150-200/mes (2 nodos t3.medium + NAT Gateways)
# Production: ~$300-400/mes (3 nodos t3.large + NAT Gateways)

# Reducir costos:
# 1. Usar solo 1 NAT Gateway (menos disponibilidad)
# 2. Cambiar a instancias t3.small (menos recursos)
# 3. Apagar staging cuando no se use:
terraform destroy # en staging
```

## 🧹 Limpieza

Para eliminar toda la infraestructura:

```powershell
# 1. Destruir ambientes (en orden)
cd infra\terraform\environments\prod
terraform destroy

cd ..\staging
terraform destroy

# 2. Destruir bootstrap (al final)
cd ..\..\bootstrap
terraform destroy

# 3. Eliminar configuración kubectl
kubectl config delete-context <context-name>
```

## ✅ Checklist de Despliegue

- [ ] AWS CLI instalado y configurado
- [ ] Terraform instalado
- [ ] kubectl instalado
- [ ] Credenciales AWS configuradas (`aws configure`)
- [ ] Bootstrap aplicado (S3 + DynamoDB)
- [ ] Staging desplegado (EKS + SonarQube)
- [ ] kubectl conectado al cluster
- [ ] Microservicios desplegados
- [ ] SonarQube accesible
- [ ] (Opcional) Production desplegado

## 📚 Recursos Adicionales

- [Documentación AWS EKS](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Helm Charts](https://helm.sh/docs/)
- [Kubernetes Docs](https://kubernetes.io/docs/)
