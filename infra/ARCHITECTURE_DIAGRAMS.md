# Diagrama de Arquitectura AWS - E-Commerce Microservices

Este documento contiene diagramas de arquitectura en formato Mermaid que pueden visualizarse en GitHub o editores compatibles.

## 🏗️ Arquitectura General

```mermaid
graph TB
    subgraph Internet
        Users[👥 Users]
    end
    
    subgraph AWS["AWS Cloud - us-east-1"]
        subgraph VPC["VPC (10.x.0.0/16)"]
            subgraph PublicSubnets["Public Subnets"]
                ALB[Application Load Balancer]
                NAT[NAT Gateways]
                IGW[Internet Gateway]
            end
            
            subgraph PrivateSubnets["Private Subnets"]
                subgraph ECS["ECS Fargate Cluster"]
                    APIGateway[API Gateway :8080]
                    Eureka[Service Discovery :8761]
                    Config[Cloud Config :9296]
                    UserSvc[User Service :8700]
                    ProductSvc[Product Service :8500]
                    OrderSvc[Order Service :8300]
                    PaymentSvc[Payment Service :8400]
                    ShippingSvc[Shipping Service :8600]
                    FavouriteSvc[Favourite Service :8800]
                    ProxyClient[Proxy Client :8900]
                end
                
                subgraph Monitoring["Monitoring Stack"]
                    Prometheus[Prometheus :9090]
                    Grafana[Grafana :3000]
                    Zipkin[Zipkin :9411]
                end
                
                RDS[(RDS PostgreSQL<br/>Multi-AZ)]
            end
        end
        
        SM[Secrets Manager]
        CW[CloudWatch Logs]
        ECR[ECR<br/>Container Registry]
    end
    
    Users -->|HTTPS/HTTP| ALB
    ALB -->|Route /api/*| APIGateway
    ALB --> Prometheus
    ALB --> Grafana
    
    APIGateway --> UserSvc
    APIGateway --> ProductSvc
    APIGateway --> OrderSvc
    APIGateway --> PaymentSvc
    APIGateway --> ShippingSvc
    APIGateway --> FavouriteSvc
    
    UserSvc --> Eureka
    ProductSvc --> Eureka
    OrderSvc --> Eureka
    PaymentSvc --> Eureka
    ShippingSvc --> Eureka
    FavouriteSvc --> Eureka
    
    UserSvc -.->|Config| Config
    ProductSvc -.->|Config| Config
    OrderSvc -.->|Config| Config
    
    UserSvc --> RDS
    ProductSvc --> RDS
    OrderSvc --> RDS
    PaymentSvc --> RDS
    ShippingSvc --> RDS
    FavouriteSvc --> RDS
    
    ECS -->|Pull Images| ECR
    ECS -->|Logs| CW
    ECS -->|DB Credentials| SM
    ECS -->|Traces| Zipkin
    Prometheus -.->|Scrape| ECS
    Grafana --> Prometheus
    
    PrivateSubnets -->|Outbound| NAT
    NAT --> IGW
    IGW --> Internet

    style ALB fill:#ff9900
    style RDS fill:#2e73b8
    style ECS fill:#ff9900
    style Monitoring fill:#34a853
```

## 🌐 Arquitectura de Red

```mermaid
graph TB
    subgraph Internet["🌐 Internet"]
        Client[Client/User]
    end
    
    subgraph Region["AWS Region: us-east-1"]
        subgraph VPC["VPC: 10.x.0.0/16"]
            IGW[Internet Gateway]
            
            subgraph AZ1["AZ-1a"]
                subgraph PublicAZ1["Public Subnet<br/>10.x.1.0/24"]
                    ALB1[ALB Node]
                    NAT1[NAT Gateway]
                end
                subgraph PrivateAZ1["Private Subnet<br/>10.x.10.0/24"]
                    ECS1[ECS Tasks]
                    RDS1[(RDS Primary)]
                end
            end
            
            subgraph AZ2["AZ-1b"]
                subgraph PublicAZ2["Public Subnet<br/>10.x.2.0/24"]
                    ALB2[ALB Node]
                    NAT2[NAT Gateway]
                end
                subgraph PrivateAZ2["Private Subnet<br/>10.x.20.0/24"]
                    ECS2[ECS Tasks]
                    RDS2[(RDS Standby)]
                end
            end
            
            subgraph AZ3["AZ-1c (Prod Only)"]
                subgraph PublicAZ3["Public Subnet<br/>10.x.3.0/24"]
                    ALB3[ALB Node]
                    NAT3[NAT Gateway]
                end
                subgraph PrivateAZ3["Private Subnet<br/>10.x.30.0/24"]
                    ECS3[ECS Tasks]
                end
            end
        end
    end
    
    Client -->|HTTPS :443| IGW
    IGW --> ALB1
    IGW --> ALB2
    IGW --> ALB3
    
    ALB1 --> ECS1
    ALB2 --> ECS2
    ALB3 --> ECS3
    
    ECS1 --> RDS1
    ECS2 --> RDS2
    ECS3 --> RDS1
    
    RDS1 -.->|Replication| RDS2
    
    ECS1 -->|Outbound| NAT1
    ECS2 -->|Outbound| NAT2
    ECS3 -->|Outbound| NAT3
    
    NAT1 --> IGW
    NAT2 --> IGW
    NAT3 --> IGW

    style IGW fill:#ff9900
    style RDS1 fill:#2e73b8
    style RDS2 fill:#5294cf
    style NAT1 fill:#ff9900
    style NAT2 fill:#ff9900
    style NAT3 fill:#ff9900
```

## 🔐 Security Groups

```mermaid
graph LR
    subgraph Internet["🌐 Internet"]
        Users[Users/Clients]
    end
    
    subgraph ALBSG["ALB Security Group"]
        ALB[Load Balancer<br/>Inbound: 80, 443]
    end
    
    subgraph ECSSG["ECS Tasks Security Group"]
        ECS[ECS Tasks<br/>All ports from ALB<br/>Inter-service comm]
    end
    
    subgraph RDSSG["RDS Security Group"]
        RDS[(Database<br/>Port 5432 from ECS)]
    end
    
    Users -->|80, 443| ALBSG
    ALBSG -->|All TCP| ECSSG
    ECSSG -->|5432| RDSSG
    ECSSG -.->|Self-reference| ECSSG
    
    ECSSG -->|Outbound: All| Internet
    ALBSG -->|Outbound: All| Internet

    style ALBSG fill:#ff6b6b
    style ECSSG fill:#4ecdc4
    style RDSSG fill:#45b7d1
```

## 🔄 Traffic Flow

```mermaid
sequenceDiagram
    participant User
    participant Route53
    participant ALB
    participant APIGateway
    participant Eureka
    participant UserService
    participant RDS
    participant Secrets
    
    User->>Route53: HTTPS request
    Route53->>ALB: Resolve DNS
    ALB->>ALB: SSL Termination
    ALB->>APIGateway: Forward /api/* request
    APIGateway->>Eureka: Service Discovery
    Eureka-->>APIGateway: User Service location
    APIGateway->>UserService: Forward request
    UserService->>Secrets: Get DB credentials
    Secrets-->>UserService: Return credentials
    UserService->>RDS: Query database
    RDS-->>UserService: Return data
    UserService-->>APIGateway: Response
    APIGateway-->>ALB: Response
    ALB-->>User: HTTPS response
```

## 📊 Deployment Pipeline

```mermaid
graph LR
    subgraph Developer["👨‍💻 Developer"]
        Code[Write Code]
    end
    
    subgraph Git["Git Repository"]
        Push[Git Push]
    end
    
    subgraph CI["CI/CD Pipeline"]
        Build[Build & Test]
        Docker[Build Docker Images]
        Push2ECR[Push to ECR]
        TFPlan[Terraform Plan]
    end
    
    subgraph Environments["AWS Environments"]
        Dev[Development<br/>Auto-deploy]
        Stage[Staging<br/>Auto-deploy + Tests]
        Prod[Production<br/>Manual approval]
    end
    
    Code --> Push
    Push --> Build
    Build --> Docker
    Docker --> Push2ECR
    Push2ECR --> TFPlan
    TFPlan --> Dev
    Dev --> Stage
    Stage -->|Approval| Prod

    style Dev fill:#90EE90
    style Stage fill:#FFD700
    style Prod fill:#FF6347
```

## 🗄️ Backend State Management

```mermaid
graph TB
    subgraph Developers["Development Team"]
        Dev1[Developer 1]
        Dev2[Developer 2]
        Dev3[Developer 3]
    end
    
    subgraph TerraformBackend["Terraform Backend"]
        S3[S3 Bucket<br/>ecommerce-terraform-state<br/>Versioning Enabled<br/>Encrypted]
        DynamoDB[DynamoDB Table<br/>terraform-locks<br/>State Locking]
    end
    
    subgraph Environments["Environment States"]
        DevState[dev/terraform.tfstate]
        StageState[stage/terraform.tfstate]
        ProdState[prod/terraform.tfstate]
    end
    
    Dev1 -->|terraform apply| DynamoDB
    Dev2 -->|terraform apply| DynamoDB
    Dev3 -->|terraform apply| DynamoDB
    
    DynamoDB -->|Lock acquired| S3
    
    S3 --> DevState
    S3 --> StageState
    S3 --> ProdState
    
    DevState -.->|Version history| S3
    StageState -.->|Version history| S3
    ProdState -.->|Version history| S3

    style S3 fill:#ff9900
    style DynamoDB fill:#4053d6
```

## 💰 Cost Distribution

```mermaid
pie title Production Monthly Costs (~$700)
    "ECS Fargate" : 300
    "RDS Multi-AZ" : 140
    "NAT Gateways" : 100
    "ALB" : 20
    "Data Transfer" : 50
    "CloudWatch" : 40
    "Storage" : 30
    "Other" : 20
```

## 📈 Scaling Architecture

```mermaid
graph TB
    subgraph AutoScaling["Auto-Scaling Configuration"]
        subgraph Triggers["Scaling Triggers"]
            CPU[CPU > 70%]
            Memory[Memory > 80%]
            RequestCount[Request Count]
        end
        
        subgraph Actions["Scaling Actions"]
            ScaleOut[Scale Out<br/>Add Tasks]
            ScaleIn[Scale In<br/>Remove Tasks]
        end
        
        subgraph Limits["Limits"]
            MinTasks[Min: 2 tasks]
            MaxTasks[Max: 10 tasks]
        end
    end
    
    subgraph ECS["ECS Service"]
        Task1[Task 1]
        Task2[Task 2]
        Task3[Task 3]
        TaskN[Task N]
    end
    
    CPU --> ScaleOut
    Memory --> ScaleOut
    RequestCount --> ScaleOut
    
    ScaleOut --> MaxTasks
    ScaleIn --> MinTasks
    
    ScaleOut -.->|Create| TaskN
    ScaleIn -.->|Terminate| Task3

    style CPU fill:#ff6b6b
    style Memory fill:#ff6b6b
    style ScaleOut fill:#90EE90
    style ScaleIn fill:#FFD700
```

## 🛡️ Security Layers

```mermaid
graph TB
    subgraph Layer1["Layer 1: Network Security"]
        VPC[VPC Isolation]
        SG[Security Groups]
        NACL[Network ACLs]
        FlowLogs[VPC Flow Logs]
    end
    
    subgraph Layer2["Layer 2: Application Security"]
        ALB[ALB with SSL/TLS]
        WAF[AWS WAF Optional]
        PathRouting[Path-based Routing]
    end
    
    subgraph Layer3["Layer 3: Data Security"]
        Encryption[RDS Encryption at Rest]
        Secrets[Secrets Manager]
        S3Enc[S3 Encryption]
        Backups[Automated Backups]
    end
    
    subgraph Layer4["Layer 4: Identity & Access"]
        IAM[IAM Roles]
        Policies[Least Privilege]
        MFA[MFA for Admins]
        CloudTrail[CloudTrail Logs]
    end
    
    Layer1 --> Layer2
    Layer2 --> Layer3
    Layer3 --> Layer4

    style Layer1 fill:#ff6b6b
    style Layer2 fill:#ffa500
    style Layer3 fill:#ffd700
    style Layer4 fill:#90EE90
```

## 📝 Notas

- Todos los diagramas están en formato Mermaid
- Se pueden visualizar directamente en GitHub
- También funcionan en editores como VS Code con extensión Mermaid
- Para generar imágenes: usar [Mermaid Live Editor](https://mermaid.live/)

## 🔗 Referencias

- [Documentación completa](./AWS_INFRASTRUCTURE_GUIDE.md)
- [README principal](./README.md)
