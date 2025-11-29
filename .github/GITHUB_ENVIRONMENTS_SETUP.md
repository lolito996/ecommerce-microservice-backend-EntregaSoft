# 🌍 Configuración de GitHub Environments

## 📋 Resumen

Esta guía te ayudará a configurar **GitHub Environments** para gestionar los despliegues de Development, Staging y Production desde GitHub.

---

## 🎯 ¿Qué son GitHub Environments?

Los **GitHub Environments** te permiten:

- ✅ Definir entornos específicos (dev, staging, prod)
- ✅ Configurar secrets y variables por entorno
- ✅ Establecer reglas de protección y aprobaciones
- ✅ Limitar qué branches pueden desplegar a cada entorno
- ✅ Ver historial de deployments por entorno

---

## 🚀 Paso 1: Crear Environments en GitHub

### Acceder a la Configuración

1. Ve a tu repositorio en GitHub
2. Click en **"Settings"**
3. En el menú lateral, click en **"Environments"**
4. Click en **"New environment"**

### Crear Environment: Development

**Nombre:** `development`

#### Configuration:

**Deployment branches:**
- ✅ Selected branches
- Branches permitidas: `develop`, `feature/*`

**Environment secrets** (Click "Add secret"):
```
AWS_ACCESS_KEY_ID=<tu-access-key>
AWS_SECRET_ACCESS_KEY=<tu-secret-key>
AWS_REGION=us-east-1
ECS_CLUSTER=dev-ecommerce-cluster
DOCKER_USERNAME=alejomunoz
DOCKER_PASSWORD=<tu-docker-hub-token>
```

**Environment variables** (Click "Add variable"):
```
ALB_URL=http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com
VPC_ID=vpc-0b2c9353eedba8701
EUREKA_URL=http://10.0.10.18:8761
ENVIRONMENT=dev
```

**Deployment protection rules:**
- ❌ Required reviewers: No (para dev)
- ❌ Wait timer: 0 minutes

**Save environment**

---

### Crear Environment: Staging

**Nombre:** `staging`

#### Configuration:

**Deployment branches:**
- ✅ Selected branches
- Branches permitidas: `stage`, `release/*`

**Environment secrets:**
```
AWS_ACCESS_KEY_ID=<tu-access-key>
AWS_SECRET_ACCESS_KEY=<tu-secret-key>
AWS_REGION=us-east-1
ECS_CLUSTER=stage-ecommerce-cluster
DOCKER_USERNAME=alejomunoz
DOCKER_PASSWORD=<tu-docker-hub-token>
```

**Environment variables:**
```
ALB_URL=http://stage-ecommerce-alb-xxxxx.us-east-1.elb.amazonaws.com
VPC_ID=vpc-xxxxx
EUREKA_URL=http://10.1.10.18:8761
ENVIRONMENT=stage
```

**Deployment protection rules:**
- ✅ Required reviewers: 1 reviewer
- ⏰ Wait timer: 5 minutes (opcional)

**Save environment**

---

### Crear Environment: Production

**Nombre:** `production`

#### Configuration:

**Deployment branches:**
- ✅ Selected branches
- Branches permitidas: `main`, `master`

**Environment secrets:**
```
AWS_ACCESS_KEY_ID=<tu-access-key>
AWS_SECRET_ACCESS_KEY=<tu-secret-key>
AWS_REGION=us-east-1
ECS_CLUSTER=prod-ecommerce-cluster
DOCKER_USERNAME=alejomunoz
DOCKER_PASSWORD=<tu-docker-hub-token>
```

**Environment variables:**
```
ALB_URL=https://api.ecommerce.com
VPC_ID=vpc-xxxxx
EUREKA_URL=http://10.2.10.18:8761
ENVIRONMENT=prod
```

**Deployment protection rules:**
- ✅ Required reviewers: 2 reviewers (Tech Lead + DevOps)
- ⏰ Wait timer: 10 minutes
- ✅ Prevent self-review

**Save environment**

---

## 🔧 Paso 2: Actualizar GitHub Actions Workflows

### Crear Workflow de Deployment

Crea el archivo: `.github/workflows/deploy-to-aws.yml`

```yaml
name: Deploy to AWS ECS

on:
  push:
    branches:
      - develop   # Despliega a development
      - stage     # Despliega a staging
      - main      # Despliega a production
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options:
          - development
          - staging
          - production

jobs:
  determine-environment:
    runs-on: ubuntu-latest
    outputs:
      environment: ${{ steps.set-env.outputs.environment }}
    steps:
      - name: Determine environment
        id: set-env
        run: |
          if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
            echo "environment=${{ github.event.inputs.environment }}" >> $GITHUB_OUTPUT
          elif [[ "${{ github.ref }}" == "refs/heads/develop" ]]; then
            echo "environment=development" >> $GITHUB_OUTPUT
          elif [[ "${{ github.ref }}" == "refs/heads/stage" ]]; then
            echo "environment=staging" >> $GITHUB_OUTPUT
          elif [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            echo "environment=production" >> $GITHUB_OUTPUT
          else
            echo "environment=development" >> $GITHUB_OUTPUT
          fi

  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up JDK 11
        uses: actions/setup-java@v3
        with:
          java-version: '11'
          distribution: 'temurin'
          cache: maven
      
      - name: Build with Maven
        run: mvn clean package -DskipTests
      
      - name: Run Unit Tests
        run: mvn test
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: jar-files
          path: '**/target/*.jar'

  build-docker-images:
    needs: build-and-test
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service:
          - api-gateway
          - cloud-config
          - service-discovery
          - user-service
          - product-service
          - order-service
          - payment-service
          - shipping-service
          - favourite-service
          - proxy-client
    steps:
      - uses: actions/checkout@v3
      
      - name: Download artifacts
        uses: actions/download-artifact@v3
        with:
          name: jar-files
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ${{ matrix.service }}/Dockerfile
          push: true
          tags: |
            alejomunoz/${{ matrix.service }}:${{ github.sha }}
            alejomunoz/${{ matrix.service }}:latest
          cache-from: type=registry,ref=alejomunoz/${{ matrix.service }}:latest
          cache-to: type=inline

  deploy-to-aws:
    needs: [determine-environment, build-docker-images]
    runs-on: ubuntu-latest
    environment: ${{ needs.determine-environment.outputs.environment }}
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}
      
      - name: Deploy to ECS
        run: |
          SERVICES=(
            "api-gateway"
            "cloud-config"
            "service-discovery"
            "user-service"
            "product-service"
            "order-service"
            "payment-service"
            "shipping-service"
            "favourite-service"
            "proxy-client"
          )
          
          for service in "${SERVICES[@]}"; do
            echo "Deploying $service to ${{ vars.ENVIRONMENT }}..."
            
            # Update task definition with new image
            aws ecs describe-task-definition \
              --task-definition ${{ vars.ENVIRONMENT }}-$service \
              --query 'taskDefinition' > task-def.json
            
            # Update image tag in task definition
            jq --arg IMAGE "alejomunoz/$service:${{ github.sha }}" \
              '.containerDefinitions[0].image = $IMAGE' \
              task-def.json > new-task-def.json
            
            # Register new task definition
            aws ecs register-task-definition \
              --cli-input-json file://new-task-def.json
            
            # Update service to use new task definition
            aws ecs update-service \
              --cluster ${{ secrets.ECS_CLUSTER }} \
              --service ${{ vars.ENVIRONMENT }}-$service \
              --force-new-deployment \
              --task-definition ${{ vars.ENVIRONMENT }}-$service
          done
      
      - name: Wait for deployment to complete
        run: |
          echo "Waiting for services to stabilize..."
          aws ecs wait services-stable \
            --cluster ${{ secrets.ECS_CLUSTER }} \
            --services ${{ vars.ENVIRONMENT }}-product-service
      
      - name: Verify deployment
        run: |
          echo "Verifying deployment at ${{ vars.ALB_URL }}"
          curl -f "${{ vars.ALB_URL }}/product-service/api/products" || exit 1
          echo "✅ Deployment successful!"

  notify:
    needs: deploy-to-aws
    runs-on: ubuntu-latest
    if: always()
    steps:
      - name: Notify deployment status
        run: |
          if [[ "${{ needs.deploy-to-aws.result }}" == "success" ]]; then
            echo "✅ Deployment to ${{ needs.determine-environment.outputs.environment }} succeeded!"
          else
            echo "❌ Deployment to ${{ needs.determine-environment.outputs.environment }} failed!"
            exit 1
          fi
```

---

## 📊 Paso 3: Ver Deployments en GitHub

Una vez configurado:

1. Ve a tu repositorio
2. Click en **"Actions"**
3. Verás los workflows en ejecución

Para ver deployments por entorno:

1. Ve a tu repositorio
2. Click en **"Environments"** (en la barra lateral derecha)
3. Selecciona un entorno (development, staging, production)
4. Verás:
   - ✅ Historial de deployments
   - 🕐 Deployments en progreso
   - 📊 Métricas de deployment
   - 🔗 URLs del entorno

---

## 🔐 Paso 4: Secrets vs Variables

### Secrets (Datos sensibles)
- ✅ AWS credentials
- ✅ Docker Hub password
- ✅ Database passwords
- ✅ API keys

**Características:**
- 🔒 Encriptados
- ❌ No visibles en logs
- ❌ No se pueden leer después de crearlos

### Variables (Datos no sensibles)
- ✅ URLs
- ✅ Nombres de recursos
- ✅ Configuraciones públicas
- ✅ Feature flags

**Características:**
- 👁️ Visibles en logs
- ✅ Se pueden editar
- ✅ Más fáciles de debuggear

---

## 🔄 Flujo de Deployment

```
Developer Push to develop
         │
         ├─► GitHub Actions Trigger
         │
         ├─► Build & Test
         │    └─► Unit Tests
         │    └─► Build JARs
         │
         ├─► Build Docker Images
         │    └─► Tag with commit SHA
         │    └─► Push to Docker Hub
         │
         ├─► Deploy to Development
         │    └─► Use 'development' environment
         │    └─► Automatic deployment
         │    └─► No approval required
         │
         └─► Verify Deployment
              └─► Health checks
              └─► Smoke tests
```

```
Pull Request merge to stage
         │
         ├─► GitHub Actions Trigger
         │
         ├─► Build & Test
         │
         ├─► Build Docker Images
         │
         ├─► Deploy to Staging
         │    └─► Use 'staging' environment
         │    └─► Requires 1 approval
         │    └─► Wait 5 minutes
         │
         └─► Integration Tests
```

```
Release to main
         │
         ├─► GitHub Actions Trigger
         │
         ├─► Build & Test
         │
         ├─► Build Docker Images
         │
         ├─► Deploy to Production
         │    └─► Use 'production' environment
         │    └─► Requires 2 approvals
         │    └─► Wait 10 minutes
         │    └─► Tech Lead + DevOps approval
         │
         └─► Smoke Tests + Monitoring
```

---

## 🎯 Mejores Prácticas

### 1. Branch Protection Rules

Configura reglas para cada branch:

**develop:**
- ✅ Require pull request reviews: 1
- ✅ Require status checks to pass
- ❌ No direct pushes

**stage:**
- ✅ Require pull request reviews: 1
- ✅ Require status checks to pass
- ✅ Require merge from develop

**main:**
- ✅ Require pull request reviews: 2
- ✅ Require status checks to pass
- ✅ Require merge from stage
- ✅ Require approval from code owners

### 2. Deployment Strategy

**Development:**
- 🚀 Auto-deploy en cada push
- ✅ Tests automáticos
- ❌ No requiere aprobación

**Staging:**
- ⏸️ Requiere 1 aprobación
- ✅ Tests E2E completos
- ⏰ Wait timer de 5 minutos

**Production:**
- ⏸️ Requiere 2 aprobaciones
- ✅ Smoke tests + monitoring
- ⏰ Wait timer de 10 minutos
- 🔐 Solo desde branch `main`

### 3. Rollback Strategy

Si algo sale mal:

```bash
# Opción 1: Revert en GitHub
# 1. Ve al commit problemático
# 2. Click "Revert"
# 3. Create PR
# 4. Merge para desplegar versión anterior

# Opción 2: Manual rollback en AWS
aws ecs update-service \
  --cluster prod-ecommerce-cluster \
  --service prod-product-service \
  --task-definition prod-product-service:PREVIOUS_VERSION
```

---

## 🧪 Testing Local del Workflow

Puedes probar localmente con `act`:

```bash
# Instalar act
choco install act  # Windows

# Ejecutar workflow localmente
act -j build-and-test

# Con secrets
act -j deploy-to-aws --secret-file .secrets
```

---

## 📊 Monitoreo de Deployments

### Ver estado en tiempo real:

```bash
# Ver servicios en ECS
aws ecs list-services --cluster dev-ecommerce-cluster

# Ver deployments
aws ecs describe-services \
  --cluster dev-ecommerce-cluster \
  --services dev-product-service \
  --query 'services[0].deployments'

# Ver logs
aws logs tail /ecs/dev-ecommerce --follow
```

### Dashboard en GitHub:

1. Ve a **Actions** → **Workflows** → **Deploy to AWS ECS**
2. Selecciona un run
3. Verás:
   - ✅ Jobs ejecutados
   - 📊 Tiempo de ejecución
   - 📝 Logs detallados
   - 🔗 Links a los recursos

---

## 🆘 Troubleshooting

### Error: Environment not found

**Problema:** El workflow no encuentra el environment.

**Solución:**
```yaml
# Asegúrate de usar el nombre exacto:
environment: development  # No "dev" ni "Development"
```

### Error: Secrets not available

**Problema:** Los secrets no están disponibles en el job.

**Solución:**
```yaml
# Usa la sintaxis correcta:
${{ secrets.AWS_ACCESS_KEY_ID }}  # ✅ Correcto
${{ env.AWS_ACCESS_KEY_ID }}      # ❌ Incorrecto
```

### Error: Deployment pending approval

**Problema:** El deployment está esperando aprobación.

**Solución:**
1. Ve a **Actions** → Workflow run
2. Click en **"Review deployments"**
3. Selecciona el environment
4. Click **"Approve and deploy"**

---

## 📚 Referencias

- [GitHub Environments Documentation](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS ECS Deployment Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html)

---

**Última actualización:** 28 de noviembre de 2025  
**Versión:** 1.0.0
