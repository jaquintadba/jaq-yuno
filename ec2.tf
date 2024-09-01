# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my_vpc"
  }
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a" # or your preferred AZ

  tags = {
    Name = "public_subnet"
  }
}

# Create a private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2a" # or your preferred AZ

  tags = {
    Name = "private_subnet"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_igw"
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

# Associate the public route table with the public subnet
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Define the EC2 instance
data "aws_ami" "amazon-linux-2" {
 most_recent = true

 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }

 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}


resource "aws_instance" "mysql_client_ec2" {
  ami            = "${data.aws_ami.amazon-linux-2.id}"
  #ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = "t2.micro"              # Free tier eligible instance type
  subnet_id     = aws_subnet.private_subnet.id
  associate_public_ip_address = false    # No public IP

  tags = {
    Name = "MyEC2Instance"
  }

 # User data to install MySQL client
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y mysql
              EOF
}

# Output the private IP of the instance
output "instance_private_ip" {
  value = aws_instance.mysql_client_ec2.private_ip
}

# Output the public IP of the instance (if needed for SSH access)
output "instance_public_ip" {
  value = aws_instance.mysql_client_ec2.public_ip
  description = "The public IP of the EC2 instance. Note: This is only available if associate_public_ip_address is true."
}
