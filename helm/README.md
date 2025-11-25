# Helm Charts para Ecommerce Microservices

Este directorio contiene los charts de Helm para desplegar la aplicación de microservicios de ecommerce.

## Estructura

```
helm/
├── ecommerce-microservices/    # Chart principal (umbrella chart)
│   ├── Chart.yaml
│   ├── values.yaml              # Valores por defecto
│   ├── values-dev.yaml         # Valores para desarrollo
│   ├── values-staging.yaml     # Valores para staging
│   ├── values-prod.yaml        # Valores para producción
│   └── templates/              # Templates de Kubernetes
│       ├── configmap.yaml
│       ├── service-discovery.yaml
│       ├── cloud-config.yaml
│       ├── api-gateway.yaml
│       ├── user-service.yaml
│       ├── product-service.yaml
│       ├── order-service.yaml
│       ├── payment-service.yaml
│       ├── shipping-service.yaml
│       ├── favourite-service.yaml
│       ├── proxy-client.yaml
│       ├── prometheus.yaml
│       ├── grafana.yaml
│       └── zipkin.yaml
└── microservice/                # Chart genérico reutilizable
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        ├── deployment.yaml
        ├── service.yaml
        └── _helpers.tpl
```

## Prerrequisitos

- Kubernetes cluster configurado
- Helm 3.x instalado
- kubectl configurado para acceder al cluster
- Namespace creado (o se creará automáticamente)

## Instalación

### Desarrollo

```bash
# Instalar en namespace dev
helm install ecommerce-microservices ./helm/ecommerce-microservices \
  --namespace dev \
  --create-namespace \
  --values ./helm/ecommerce-microservices/values-dev.yaml \
  --set global.registry=your-registry \
  --set global.imageTag=latest
```

### Staging

```bash
# Instalar en namespace staging
helm install ecommerce-microservices ./helm/ecommerce-microservices \
  --namespace staging \
  --create-namespace \
  --values ./helm/ecommerce-microservices/values-staging.yaml \
  --set global.registry=your-registry \
  --set global.imageTag=staging
```

### Producción

```bash
# Instalar en namespace production
helm install ecommerce-microservices ./helm/ecommerce-microservices \
  --namespace production \
  --create-namespace \
  --values ./helm/ecommerce-microservices/values-prod.yaml \
  --set global.registry=your-registry \
  --set global.imageTag=prod \
  --set grafana.adminPassword=your-secure-password
```

## Actualización

```bash
# Actualizar el release
helm upgrade ecommerce-microservices ./helm/ecommerce-microservices \
  --namespace <namespace> \
  --values ./helm/ecommerce-microservices/values-<env>.yaml \
  --set global.registry=your-registry \
  --set global.imageTag=new-tag
```

## Desinstalación

```bash
# Desinstalar el release
helm uninstall ecommerce-microservices --namespace <namespace>
```

## Configuración

### Variables Globales

- `global.namespace`: Namespace donde se desplegarán los servicios
- `global.registry`: Registro de imágenes Docker
- `global.imageTag`: Tag de las imágenes
- `global.imagePullPolicy`: Política de pull de imágenes
- `global.springProfile`: Perfil de Spring Boot (dev, stage, prod)

### Habilitar/Deshabilitar Servicios

Puedes habilitar o deshabilitar servicios individuales:

```bash
# Deshabilitar un servicio
helm install ecommerce-microservices ./helm/ecommerce-microservices \
  --set favourite-service.enabled=false
```

### Escalar Servicios

```bash
# Escalar un servicio específico
helm upgrade ecommerce-microservices ./helm/ecommerce-microservices \
  --set user-service.replicas=5
```

### Cambiar Recursos

```bash
# Cambiar recursos de un servicio
helm upgrade ecommerce-microservices ./helm/ecommerce-microservices \
  --set user-service.resources.requests.memory=1Gi \
  --set user-service.resources.limits.memory=2Gi
```

## Verificación

```bash
# Ver el estado del release
helm status ecommerce-microservices --namespace <namespace>

# Ver los recursos desplegados
kubectl get all -n <namespace>

# Ver logs de un servicio
kubectl logs -f deployment/user-service -n <namespace>
```

## Troubleshooting

### Verificar templates generados

```bash
# Renderizar templates sin instalar
helm template ecommerce-microservices ./helm/ecommerce-microservices \
  --values ./helm/ecommerce-microservices/values-dev.yaml \
  --set global.registry=your-registry
```

### Validar el chart

```bash
# Validar sintaxis
helm lint ./helm/ecommerce-microservices
```

### Ver valores finales

```bash
# Ver valores combinados
helm get values ecommerce-microservices --namespace <namespace>
```

## Servicios Incluidos

- **service-discovery**: Eureka Service Discovery
- **cloud-config**: Spring Cloud Config Server
- **api-gateway**: API Gateway (Spring Cloud Gateway)
- **user-service**: Servicio de usuarios
- **product-service**: Servicio de productos
- **order-service**: Servicio de órdenes
- **payment-service**: Servicio de pagos
- **shipping-service**: Servicio de envíos
- **favourite-service**: Servicio de favoritos
- **proxy-client**: Cliente proxy
- **prometheus**: Métricas y monitoreo
- **grafana**: Dashboards de visualización
- **zipkin**: Distributed tracing

## Puertos

### NodePort (Desarrollo/Staging)
- API Gateway: 30000
- Service Discovery: 30001
- Prometheus: 30090
- Grafana: 30300
- Zipkin: 30411

### ClusterIP (Producción)
En producción, se recomienda usar Ingress o LoadBalancer en lugar de NodePort.

## Notas

- Asegúrate de actualizar `global.registry` con tu registro de imágenes
- En producción, usa secrets para contraseñas sensibles (Grafana, etc.)
- Considera usar PersistentVolumes para Prometheus y Grafana en producción
- Ajusta los recursos según las necesidades de tu cluster



