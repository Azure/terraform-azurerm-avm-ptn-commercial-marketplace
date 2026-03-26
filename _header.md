# Commercial Marketplace SaaS Accelerator — Infrastructure Module

This Terraform module deploys the complete Azure infrastructure required by the
[Commercial Marketplace SaaS Accelerator](https://github.com/Azure/Commercial-Marketplace-SaaS-Accelerator).

## Features

- **Azure App Service** — Linux Web Apps for Admin Portal and Customer Portal
- **Azure SQL Database** — Managed SQL Server and database with Managed Identity authentication
- **Azure Key Vault** — Secrets management with optional RBAC or access-policy model
- **Virtual Network** — VNet with subnets for web apps and private endpoints
- **Private Endpoints** — Optional private connectivity for SQL and Key Vault
- **Azure AD App Registrations** — Automatic creation or bring-your-own (BYO)
- **Application Deployment** — Optional .NET build & deploy via `local-exec`

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Resource Group                           │
│                                                                 │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐       │
│  │  Admin Portal │   │Customer Portal│   │  App Service │       │
│  │  (Web App)    │   │  (Web App)    │   │    Plan      │       │
│  └──────┬───────┘   └──────┬───────┘   └──────────────┘       │
│         │                   │                                   │
│  ┌──────┴───────────────────┴──────┐                           │
│  │        Virtual Network          │                           │
│  │  ┌──────────┐  ┌──────────────┐ │                           │
│  │  │ Web Subnet│  │  PE Subnet   │ │                           │
│  │  └──────────┘  └──────┬───────┘ │                           │
│  └───────────────────────┼─────────┘                           │
│                          │                                      │
│  ┌───────────────┐  ┌────┴──────────┐                          │
│  │   Key Vault   │◄─┤Private Endpts │──►┌──────────────┐      │
│  └───────────────┘  └───────────────┘   │  SQL Server   │      │
│                                          │  + Database   │      │
│                                          └──────────────┘      │
└─────────────────────────────────────────────────────────────────┘
```
