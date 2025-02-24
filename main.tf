# VPC creation and cidr_block is define in .tfvar.
resource "aws_vpc" "myvpc" {
  cidr_block = var.vpc_cidr
}
# Creating subnet 1 in vpc.
resource "aws_subnet" "mysubnet1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.subnet_cider1
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}
# Creating subnet 2 in vpc. 
resource "aws_subnet" "mysubnet2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.subnet_cider2
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}
# creation of internet gateway and attaching it with vpc.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}
# Route Table Creation.
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
# attaching route table to subnet 1.
resource "aws_route_table_association" "mysubnet1" {
  subnet_id      = aws_subnet.mysubnet1.id
  route_table_id = aws_route_table.rt.id
}
# attaching route table to subnet 2.
resource "aws_route_table_association" "mysubnet2" {
  subnet_id      = aws_subnet.mysubnet2.id
  route_table_id = aws_route_table.rt.id
}

# security group creation for ec2 instance or servers and for load balancer.
resource "aws_security_group" "sg" {
  name   = "webserver_security_group"
  vpc_id = aws_vpc.myvpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "ssh"
  }
  ingress {
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    description = "HTTP"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "anyone anywhere any port"
  }
  tags = {
    Name = "webserver_security_group"
  }
}

# IAM role creation for ec2 instance to access s3 bucket
resource "aws_iam_role" "ec2_s3_access" {
  name = "ec2_s3_access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Create an S3 bucket
resource "aws_s3_bucket" "website_bucket" {
  bucket = "my-website-backup-bucket-2025-demo" # Replace with a unique bucket name
  # acl    = "private" # Set to "private" since we don't want public access

  tags = {
    Name = "Website Backup Bucket"
  }
}

# Upload individual files to the S3 bucket
resource "aws_s3_object" "website_files" {
  for_each = fileset("<path to folder of static website>", "**") # Recursively find all files in the specified directory

  bucket = aws_s3_bucket.website_bucket.bucket
  key    = each.value # The path of the file in the S3 bucket
  source = "<path to folder of static website>/${each.value}" # The local file path
  etag   = filemd5("<path to folder of static website>${each.value}") # Track changes to files
}

# Output of the S3 bucket name
output "bucket_name" {
  value = aws_s3_bucket.website_bucket.bucket
}
# attaching Policy to IAM role to access s3 buckets 
resource "aws_iam_role_policy_attachment" "s3_read_only" {
  role       = aws_iam_role.ec2_s3_access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
# instance profile IAM Role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_s3_access.name
}

# ec2 instance creation
resource "aws_instance" "webserver1" {
  ami                    = "ami-04b4f1a9cf54c11d0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = aws_subnet.mysubnet1.id
  key_name               = "vpc2"
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  # running command on ec2 instance as it is script it will be runnned on ec2 instance on creation
  user_data = <<-EOF
            #!/bin/bash
            # Update package list
            sudo apt update -y

            # Install Apache web server
            sudo apt install -y apache2

            # Check if Apache was installed successfully
            if ! dpkg -l | grep -q apache2; then
              echo "Apache installation failed. Exiting."
              exit 1
            fi

            # Start and enable Apache service
            sudo systemctl start apache2
            sudo systemctl enable apache2
            # Remove Default Apache2 File 
            sudo rm -rf /var/www/html/*

            # Install AWS CLI
            Install AWS CLI
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            sudo apt install -y unzip
            unzip awscliv2.zip
            sudo ./aws/install

            # Copy website files from S3 bucket
            sudo aws s3 cp s3://<your bucket name>/ /var/www/html/ --recursive

            # Restart Apache to serve the new files
            sudo systemctl restart apache2
            EOF
}
resource "aws_instance" "webserver2" {
  ami                    = "ami-04b4f1a9cf54c11d0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = aws_subnet.mysubnet2.id
  key_name               = "vpc2"
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  user_data = <<-EOF
            #!/bin/bash
            # Update package list
            sudo apt update -y

            # Install Apache web server
            sudo apt install -y apache2

            # Check if Apache was installed successfully
            if ! dpkg -l | grep -q apache2; then
              echo "Apache installation failed. Exiting."
              exit 1
            fi

            # Start and enable Apache service
            sudo systemctl start apache2
            sudo systemctl enable apache2

            # Remove Default Apache File
            sudo rm -rf /var/www/html/*

            # Install AWS CLI
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            sudo apt install -y unzip
            unzip awscliv2.zip
            sudo ./aws/install



            # # Install AWS CLI
            # sudo apt install -y awscli

            # mkdir website

            # Copy website files from S3 bucket
            sudo aws s3 cp s3://<your bucket name>/ /var/www/html/ --recursive

            # Restart Apache to serve the new files
            sudo systemctl restart apache2
            EOF
}

# load balancer creation
resource "aws_lb" "mylb" {
  name               = "mylb"
  internal           = false
  load_balancer_type = "application"
  # attaching above security group to lb
  security_groups    = [aws_security_group.sg.id]
  # attaching above subnets to lb for lb listeners, traffic routing,health check ad cross-zone load balancing
  subnets            = [aws_subnet.mysubnet1.id, aws_subnet.mysubnet2.id]
  tags = {
    Name = "mylb"
  }

}
# target group creation for load balancer
resource "aws_lb_target_group" "mytg" {
  name     = "mytg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id
  health_check {
    path = "/"
    port = "traffic-port"
  }
}
resource "aws_lb_target_group_attachment" "mytgattachment1" {
  target_group_arn = aws_lb_target_group.mytg.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "mytgattachment2" {
  target_group_arn = aws_lb_target_group.mytg.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}
resource "aws_lb_listener" "mylistener" {
  load_balancer_arn = aws_lb.mylb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mytg.arn
  }
}
output "load_balancer_dnsname" {
  value = aws_lb.mylb.dns_name
}
