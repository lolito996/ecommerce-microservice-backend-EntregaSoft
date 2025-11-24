# 🌐 URLs de Acceso a Microservicios en AWS EKS

## Base URL
$BASE_URL = "http://a684a944311054f8faa8c6af7a851ba0-24347457.us-east-1.elb.amazonaws.com"

## ✅ Endpoints Funcionando

### Products (FUNCIONANDO ✓)
GET $BASE_URL/product-service/api/products

### Users
GET $BASE_URL/user-service/api/users

### Orders
GET $BASE_URL/order-service/api/orders

### Shipping
GET $BASE_URL/shipping-service/api/shippings

### Favourites (aún iniciándose)
GET $BASE_URL/favourite-service/api/favourites

### Payments (aún iniciándose)
GET $BASE_URL/payment-service/api/payments

## 📊 Monitoreo

### Zipkin (Distributed Tracing)
http://a69e0aa1986e6457fae681e617ae4ffc-2007257503.us-east-1.elb.amazonaws.com

### Grafana (Dashboards)
http://aa3ba54dfc32343379121c24a557823a-703263735.us-east-1.elb.amazonaws.com

### Eureka (Service Discovery)
$BASE_URL/eureka

## 🧪 Pruebas con curl

# Products
curl $BASE_URL/product-service/api/products

# Users
curl $BASE_URL/user-service/api/users

# Orders  
curl $BASE_URL/order-service/api/orders

# Shipping
curl $BASE_URL/shipping-service/api/shippings

