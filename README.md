# 🍅 Tomato Food Delivery Platform — End-to-End AWS ECS, Terraform & DevOps Architecture

A full-stack, three-tier food delivery web application (**Customer Storefront**, **Restaurant Admin Portal**, and **Node.js/Express REST API** backed by **MongoDB**) re-architected from a single-server setup into a high-availability, auto-scaling **Amazon ECS** production environment in **AWS Mumbai (`ap-south-1`)**, with **Terraform** provisioning the Application Load Balancer and Auto Scaling infrastructure, and **AWS SSM Parameter Store** securing all runtime credentials.

---

## 🏗️ System Architecture

```text
                        [ Users & Restaurant Admins ]
                                      │
                     (DuckDNS: tomato-foods.duckdns.org)
                     (DuckDNS: admin.tomato-foods.duckdns.org)
                                      ▼
                    ┌───────────────────────────────────┐
                    │  AWS Application Load Balancer    │
                    │     (food-alb :80 — Terraform)    │
                    └──────┬──────────┬──────────┬──────┘
                           │          │          │
              /api/* &     │          │ Host:    │ Default
              /images/*    │          │ admin.*  │ (/*)
                           ▼          ▼          ▼
        ┌──────────────────────────────────────────────────────┐
        │         AWS ECS Cluster (food-cluster)               │
        │  2 × t3.small EC2 Nodes (ASG via Terraform)         │
        │                                                      │
        │  ┌────────────────┐ ┌───────────────┐ ┌───────────┐  │
        │  │  food-backend  │ │  food-admin   │ │ food-web  │  │
        │  │ Node.js (:4000)│ │ Nginx (:80)   │ │Nginx (:80)│  │
        │  │  (2–4 Tasks)   │ │  (1 Task)     │ │(2–4 Tasks)│  │
        │  └───────┬────────┘ └───────┬───────┘ └───────────┘  │
        └──────────┼──────────────────┼────────────────────────┘
                   │                  │
                   │  Runtime Secrets │ (SSM Parameter Store)
                   │◄─────────────────┘
                   │
                   │ Private VPC (TCP :27017)
                   ▼
        ┌──────────────────────────────────────────────────────┐
        │   Decoupled Stateful Database Tier (Private VPC)     │
        │       EC2 (food-app) — MongoDB (food_app DB)         │
        └──────────────────────────────────────────────────────┘
```

### Core Architectural Highlights
* ### Infrastructure Evolution: Terraform Backbone Reused for Amazon ECS
* **Phase 1 — Terraform Foundation (`food-app` EC2):** Provisioned the core **Application Load Balancer (`food-alb`)**, initial **Target Group**, and **EC2 Auto Scaling Group** via **Terraform** to add load-balanced horizontal scaling on top of the existing standalone `food-app` EC2 server (without ECS).
* **Phase 2 — Reusing Infrastructure for Amazon ECS (`food-cluster`):** Migrated the application tiers (`food-backend`, `food-frontend`, `food-admin`) onto **Amazon ECS** by **reusing the existing Terraform-provisioned `food-alb` and EC2 Auto Scaling Group** (attached as the ECS Capacity Provider), adding microservice-specific Target Groups (`food-tg-backend`, `food-tg-web`, `food-tg-admin`) and Layer-7 routing rules while repurposing the original `food-app` EC2 instance (`172.31.6.81`) as the decoupled private VPC MongoDB tier , Layer-7 listener rules, Security Groups, and **Auto Scaling** policies (both EC2 Auto Scaling Group capacity and ECS Service CPU target-tracking auto-scaling from `2` to `4` tasks at `70%` CPU).
* **Stateless Auto-Scaling Compute (`Amazon ECS`):** Runs containerized microservices across **2 × `t3.small` EC2 worker instances** using **100% min / 200% max zero-downtime rolling deployments**.
* **Layer-7 Traffic Routing (`food-alb`):** Routes incoming traffic based on URL paths (`/api/*`, `/images/*` → backend) and host headers (`admin.tomato-foods.duckdns.org` → admin portal), with cookie-based stickiness enabled on `food-tg-backend` for multi-replica image uploads.
* **Zero-Hardcoded Secrets (`AWS SSM Parameter Store`):** All sensitive credentials (`MONGO_URI`, `JWT_SECRET`, `ADMIN_USER`, and `ADMIN_PASS`) are stored encrypted at rest as **`SecureString`** parameters under `/tomato/prod/*` in AWS Systems Manager Parameter Store and injected dynamically into ECS tasks at runtime via `ValueFrom` (and `docker-entrypoint.sh` for Nginx `.htpasswd`).
* **Decoupled Stateful Database Tier:** Isolates MongoDB (`food_app`) onto a dedicated private VPC EC2 instance (`172.31.6.81`) restricted strictly to internal VPC traffic on TCP port `27017`, protecting user and order data across container replacements and scaling events.
* **Admin Portal Hardening:** Secures `food-admin` at the reverse-proxy layer using **Nginx HTTP Basic Authentication** generated at container startup, with a `map $http_user_agent` exemption for `ELB-HealthChecker` so ALB health checks pass with `HTTP 200 OK` while blocking unauthenticated users (`HTTP 401`).
* **Automated CI/CD (`Jenkins` + `Amazon ECR`):** Distributed **Jenkins Controller + Build Agent (`food-agent`)** builds multi-stage Docker images, pushes `:latest` tags to Amazon ECR, and triggers `aws ecs update-service --force-new-deployment`.
* **Full-Stack Observability (`Prometheus`, `Grafana` & `CloudWatch`):**
  * **EC2 Launch Template User Data** automatically provisions `node-exporter` (`:9100`) and `cAdvisor` (`:8080`) on every ECS worker node on boot.
  * **Prometheus** uses dynamic AWS EC2 service discovery (`ec2_sd_configs` with read-only IAM role) to auto-discover scaling ECS nodes and visualize metrics in **Grafana** (Overview, Server Health, and Container Resource dashboards).
  * **Amazon CloudWatch** tracks request counts across Availability Zones (`ap-south-1a/b/c`) and triggers **SNS email alarms** when backend `5XX` errors exceed 5 per minute.

---

## 🛠️ Tech Stack

| Layer | Technologies Used |
| :--- | :--- |
| **Frontend & Admin** | React.js, Vite, CSS3, Nginx (`1.27-alpine`) |
| **Backend & Database** | Node.js, Express.js, Mongoose, Multer, JWT, MongoDB |
| **Infrastructure as Code** | Terraform (ALB, Target Groups, Security Groups, EC2 & ECS Auto Scaling) |
| **Secrets Management** | AWS Systems Manager (SSM) Parameter Store (`SecureString`), IAM (`ecsTaskExecutionRole`) |
| **Containerization & Cloud** | Docker (Multi-Stage Builds), Amazon ECR, Amazon ECS (EC2 Launch Type), VPC, DuckDNS |
| **CI/CD Automation** | Jenkins (Distributed Controller & Agent), AWS CLI |
| **Monitoring & Alerting** | Prometheus (`ec2_sd_configs`), Grafana, Node Exporter, cAdvisor, AWS CloudWatch & SNS |

---

## 📂 Repository Structure

```text
├── terraform/                # Infrastructure as Code (ALB, Target Groups, ASG & ECS Auto Scaling)
│   ├── main.tf               # Core AWS resources (ALB, Listeners, Target Groups, Auto Scaling)
│   ├── variables.tf          # Input variables (VPC, subnets, cluster & service parameters)
│   └── outputs.tf            # ALB DNS name and Target Group ARN outputs
│
├── backend/                  # Node.js + Express REST API
│   ├── config/               # MongoDB connection setup
│   ├── controllers/          # Food, User, Cart, and Order business logic
│   ├── middleware/           # JWT authentication middleware
│   ├── models/               # Mongoose schemas (food, user, order)
│   ├── routes/               # API routes (/api/food, /api/user, /api/cart, /api/order)
│   ├── uploads/              # Uploaded menu item images (/images/*)
│   ├── Dockerfile            # Backend container build definition
│   └── server.js             # Express entry point (Port 4000)
│
├── frontend/                 # Customer-facing React Storefront
│   ├── src/                  # Components, pages, and StoreContext
│   ├── Dockerfile            # Multi-stage React build -> Nginx (:80)
│   └── nginx.conf            # SPA routing configuration
│
├── admin/                    # Protected Restaurant Admin Portal
│   ├── src/                  # Add Items, List Items, and Order Status management
│   ├── docker-entrypoint.sh  # Generates /etc/nginx/.htpasswd at runtime from SSM secrets
│   ├── Dockerfile            # Multi-stage build + apache2-utils (zero hardcoded credentials)
│   └── nginx.conf            # HTTP Basic Auth + ELB-HealthChecker exemption
│
└── Jenkinsfile               # Automated build, ECR push, and ECS rolling deployment pipeline
```

---

## 🔐 Secrets & Configuration Management (AWS SSM Parameter Store)

No passwords, database URIs, or JWT signing keys are stored in Git or baked into Docker image layers. Instead, secrets are stored in **AWS SSM Parameter Store (`ap-south-1`)** as `SecureString` entries and injected at container startup via `ecsTaskExecutionRole`:

| SSM Parameter Name | Target Service | Purpose |
| :--- | :--- | :--- |
| `/tomato/prod/MONGO_URI` | `food-backend-task` | Authenticated MongoDB connection string (`172.31.6.81:27017/food_app`) |
| `/tomato/prod/JWT_SECRET` | `food-backend-task` | Secret key for signing and verifying customer JWT tokens |
| `/tomato/prod/ADMIN_USER` | `food-admin-task` | Admin portal HTTP Basic Auth username |
| `/tomato/prod/ADMIN_PASS` | `food-admin-task` | Admin portal HTTP Basic Auth password |

---

## 🚀 Infrastructure Provisioning & CI/CD Workflow

### 1. Provisioning Load Balancer & Auto Scaling (Terraform)
```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

### 2. Automated Application Deployment (Jenkins)
1. **Code Commit:** Developer pushes changes to GitHub (`main` branch).
2. **Distributed Build:** Jenkins Controller delegates `Master-pipeline` execution to the dedicated build agent (`food-agent`).
3. **Container Build & Push:** Jenkins builds updated Docker images for `food-backend`, `food-frontend`, and `food-admin`, tagging and pushing `:latest` to **Amazon ECR**.
4. **Zero-Downtime Rollout:** Jenkins executes `aws ecs update-service --force-new-deployment` across all three ECS services. ECS pulls the latest images, injects SSM `SecureString` secrets, passes `food-alb` health checks (`HTTP 200 OK`), and drains old containers.

---

## 🧪 Smoke Testing & Verification

Before releasing updates, run an automated HTTP smoke test to verify ALB routing, API database connectivity, and Admin Panel access controls:


```bash
# 1. Verify Customer Frontend (Expected: 200)
curl -s -o /dev/null -w "Customer Frontend: %{http_code}\n" http://duckdns.org/

# 2. Verify Backend API + MongoDB Read (Expected: 200)
curl -s -o /dev/null -w "Backend Food API:  %{http_code}\n" http://duckdns.org/api/food/list

# 3. Verify Unauthenticated Admin Block (Expected: 401)
curl -s -o /dev/null -w "Admin Unauth Check: %{http_code}\n" http://duckdns.org

# 4. Verify Authenticated Admin Access (Expected: 200)
curl -s -o /dev/null -w "Admin Auth Check:   %{http_code}\n" -u admin:<ADMIN_PASSWORD> http://duckdns.org
```

---

## 🔮 Future Enhancements

* **End-to-End HTTPS (`ACM` + `Route 53`):** Attach an AWS Certificate Manager SSL/TLS certificate to `food-alb` on port `443` with automatic `HTTP -> HTTPS` redirection.
* **Shared Persistent Media Storage (`Amazon S3`):** Migrate uploaded dish images (`/images/*`) from container storage to an **Amazon S3 bucket + CloudFront CDN** for stateless multi-replica persistence.
* **Full-Stack `Terraform` Coverage:** Expand the existing Terraform configuration (ALB & Auto Scaling) to also manage the VPC, ECS Cluster, Task Definitions, and SSM Parameter Store resources.

