# Terraform

- Website: https://www.terraform.io
- Forums: [HashiCorp Discuss](https://discuss.hashicorp.com/c/terraform-core)
- Documentation: [https://www.terraform.io/docs/](https://www.terraform.io/docs/)
- Tutorials: [HashiCorp's Learn Platform](https://learn.hashicorp.com/terraform)
- Certification Exam: [HashiCorp Certified: Terraform Associate](https://www.hashicorp.com/certification/#hashicorp-certified-terraform-associate)

<img alt="Terraform" src="https://www.datocms-assets.com/2885/1629941242-logo-terraform-main.svg" width="600px">

Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. Terraform can manage existing and popular service providers as well as custom in-house solutions.

The key features of Terraform are:

- **Infrastructure as Code**: Infrastructure is described using a high-level configuration syntax. This allows a blueprint of your datacenter to be versioned and treated as you would any other code. Additionally, infrastructure can be shared and re-used.

- **Execution Plans**: Terraform has a "planning" step where it generates an execution plan. The execution plan shows what Terraform will do when you call to apply. This lets you avoid any surprises when Terraform manipulates infrastructure.

- **Resource Graph**: Terraform builds a graph of all your resources, and parallelizes the creation and modification of any non-dependent resources. Because of this, Terraform builds infrastructure as efficiently as possible, and operators get insight into dependencies in their infrastructure.

- **Change Automation**: Complex changesets can be applied to your infrastructure with minimal human interaction. With the previously mentioned execution plan and resource graph, you know exactly what Terraform will change and in what order, avoiding many possible human errors.

For more information, refer to the [What is Terraform?](https://www.terraform.io/intro) page on the Terraform website.

# Three-Tier Web Application with Terraform on AWS

This repository contains Terraform configuration files for deploying a scalable and resilient three-tier web application architecture on Amazon Web Services (AWS). The architecture includes a web tier, an application tier, and a database tier, following best practices for security, availability, and scalability.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Diagram](#diagram)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Configuration](#configuration)
- [Components](#components)
- [Contributing](#contributing)
- [License](#license)

## Architecture Overview

The three-tier architecture consists of the following layers:

1. **Web Tier**: Serves static content and forwards requests to the application tier. Deployed in public subnets.
2. **Application Tier**: Hosts the application logic and processes business transactions. Deployed in private subnets.
3. **Database Tier**: Manages data storage using Amazon RDS. Deployed in private subnets.

## Diagram
<img alt="AWS Three Tier Web App" src="https://github.com/ThawThuHan/three-tier-web-app-terraform/assets/42668854/4c641122-bce5-463d-a6bb-b55d81550a51" width="400px">

## Features

- **Terraform Configuration**: Infrastructure as Code (IaC) using Terraform.
- **AWS Components**: EC2 instances, ELB, RDS, Auto Scaling Groups, VPC, subnets, and security groups.
- **Scalability**: Auto Scaling Groups for the application tier to handle varying loads.
- **Security**: Separation of resources into public and private subnets, security groups to control access.

## Prerequisites

Before you begin, ensure you have the following installed:

- [Terraform](https://www.terraform.io/downloads.html) (v0.12 or later)
- AWS CLI configured with appropriate credentials
- An AWS account with necessary permissions

## Usage

1. **Clone the Repository**:
   ```sh
   git clone https://github.com/ThawThuHan/three-tier-web-app-terraform.git
   cd three-tier-web-app-terraform
   ```
2. **Initialize Terraform**:
    ```sh
    terraform init
    ```
3. **Configure Variables**: Edit the variables.tf file or create a terraform.tfvars file to customize the configuration (see [Configuration](#Configuration) section).
4. **Plan the Deployment**:
   ```sh
   terraform plan
   ```
5. **Apply the configuration**:
   ```sh
   terraform apply
   ```
6. **Destroy the infrastructure**(if needed):
   ```sh
   terraform destroy
   ```

## Configuration
You can customize the deployment by modifying the following variables in the variables.tf file:

- instance_type: The type of EC2 instance (default: t2.micro).
- instance_count: Number of instances for the application tier.
- ami_id: The Amazon Machine Image (AMI) ID for the EC2 instances.
- db_instance_class: The instance class for the RDS database (default: db.t2.micro).
- db_name: The name of the database.
- db_user: The database username.
- db_password: The database password.
Example **terraform.tfvars**:
```hcl
instance_type = "t3.medium"
instance_count = 2
ami_id = "ami-0abcdef1234567890"
db_instance_class = "db.t3.medium"
db_name = "mydatabase"
db_user = "admin"
db_password = "securepassword123"
```
## Components
### AWS Resources
- **VPC**: Virtual Private Cloud with public and private subnets.
- **EC2 Instances**: For web and application tiers.
- **Elastic Load Balancer (ELB)**: To distribute traffic across the web tier.
- **Auto Scaling Groups (ASG)**: For the application tier to ensure scalability.
- **RDS Instance**: Managed relational database for the database tier.
- **Security Groups**: To control inbound and outbound traffic.

### Terraform Features
- **For Loop**: Utilized for_each and count to dynamically create resources.
- **Data Block**: Used to fetch existing resource information.
- **Variables**: Parameterized configuration for reusability and flexibility.

## Contributing
Contributions are welcome! Please fork this repository and submit a pull request for any enhancements, bug fixes, or documentation updates.

## License
This project is licensed under the MIT License. See the [LICENSE] file for details.
