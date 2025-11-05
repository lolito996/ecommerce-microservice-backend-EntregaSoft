# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [1.0.0] - 2025-11-03

### ✨ Añadido
- Implementación completa de arquitectura de microservicios
- 11 microservicios operativos:
  - Service Discovery (Eureka)
  - API Gateway (Spring Cloud Gateway)
  - Cloud Config Server
  - User Service
  - Product Service
  - Order Service
  - Shipping Service
  - Payment Service
  - Favourite Service
  - Proxy Client
  - Zipkin (Distributed Tracing)
- Pipeline CI/CD completo con Jenkins
- GitHub Actions workflows para unit tests, E2E tests y performance tests
- Distributed tracing con Zipkin
- Métricas con Prometheus
- Circuit breaker con Resilience4j
- Health checks configurados
- Documentación completa del proyecto
- Presentación para exposición

### 🔧 Cambiado
- Actualizado Dockerfiles de `openjdk:11` (deprecated) a `eclipse-temurin:11-jdk`
- Mejorada la configuración de CI/CD
- Optimizado el proceso de build y despliegue

### 🐛 Corregido
- Error de build en Dockerfiles (imagen openjdk:11 no disponible)
- Problemas de conexión en performance tests (port-forward)
- Manejo de errores en tests E2E y performance

### 📊 Métricas
- Performance tests: 7,202 requests, 0% error rate
- Latencia promedio: 26.52 ms
- P95: 51 ms
- P99: 330 ms
- Throughput: 24.06 RPS

---

## [0.1.0] - 2025-10-XX

### ✨ Añadido
- Estructura inicial del proyecto
- Configuración base de Spring Boot y Spring Cloud
- Módulos de microservicios básicos

---

## Notas

- Las versiones futuras se documentarán aquí siguiendo el formato establecido.
- Para cambios detallados, ver el historial de commits en Git.

