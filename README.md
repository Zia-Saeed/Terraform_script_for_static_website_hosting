Terraform Script: Deploying a Highly Available Web Application on AWS
This Terraform script automates the deployment of a scalable and highly available web application infrastructure on AWS. It provisions a complete environment, including a VPC, subnets, EC2 instances, an S3 bucket, IAM roles, and an Application Load Balancer (ALB). Below is a summary of the key components:

VPC and Subnets :
Creates a Virtual Private Cloud (VPC) with two public subnets spread across multiple Availability Zones (AZs) for fault tolerance.
Automatically assigns public IPs to instances in the subnets for internet access.
Internet Gateway and Route Table :
Sets up an Internet Gateway and configures a Route Table to enable internet connectivity for the subnets.
Security Groups :
Defines a security group to allow SSH (port 22) and HTTP (port 80) traffic, ensuring secure access to the EC2 instances and load balancer.
IAM Role and S3 Bucket :
Creates an IAM role with read-only access to an S3 bucket, allowing EC2 instances to fetch website files.
Provisions an S3 bucket to store static website files and uploads them using the aws_s3_object resource.
EC2 Instances :
Launches two EC2 instances in separate subnets, installs Apache web server, and configures it to serve the static website files from the S3 bucket.
Application Load Balancer (ALB) :
Deploys an ALB to distribute incoming HTTP traffic across the EC2 instances.
Configures a target group and health checks to ensure only healthy instances receive traffic.
High Availability :
Ensures high availability by distributing resources across multiple AZs and leveraging the ALB for traffic routing.
This script is ideal for deploying a static website or web application in AWS with scalability, fault tolerance, and automated provisioning. It adheres to best practices such as using variables for configurability, enabling cross-zone load balancing, and securing resources with IAM roles and security groups.

How to Use
Update the .tfvars file with your desired CIDR blocks, instance types, and other configurations.
Run terraform init to initialize the working directory.
Run terraform apply to provision the infrastructure.
