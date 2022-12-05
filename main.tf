provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr
  tags = {
    Name = "My VPC"
  }
}

# Create Public Subnets
resource "aws_subnet" "public-subnet-1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.pub_subnet1_CIDR
  availability_zone       = var.az_a
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.pub_subnet2_CIDR
  availability_zone       = var.az_b
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet-2"
  }
}

# Create Application Subnets
resource "aws_subnet" "app-subnet-1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.app_subnet1
  availability_zone       = var.az_a
  map_public_ip_on_launch = false

  tags = {
    Name = "App Subnet-1"
  }
}

resource "aws_subnet" "app-subnet-2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.app_subnet2
  availability_zone       = var.az_b
  map_public_ip_on_launch = false

  tags = {
    Name = "App Subnet-2"
  }
}

# Create Database Private Subnet
resource "aws_subnet" "db-subnet-1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.db_subnet1_CIDR
  availability_zone = var.az_a

  tags = {
    Name = "Database Subnet-1"
  }
}

resource "aws_subnet" "db-subnet-2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.db_subnet2_CIDR
  availability_zone = var.az_b

  tags = {
    Name = "Database Subnet-2"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Internet Gateway"
  }
}

# route table
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = var.vpc_cidr
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Route Table"
  }
}

resource "aws_route_table_association" "pub1" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "pub2" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.route_table.id
}


# Create LB Security Group
resource "aws_security_group" "lb-sg" {
  name        = "LB-SG"
  description = "Allow HTTP inbound traffic to ALB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "LB-SG"
  }
}

# Create ec2 Security Group
resource "aws_security_group" "ec2-sg" {
  name        = "Webserver-SG"
  description = "Allow traffics from ALB to instance"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Webserver-SG"
  }
}

# Create Database Security Group
resource "aws_security_group" "db-sg" {
  name        = "Database-SG"
  description = "Allow inbound traffic to database"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2-sg.id]
  }

  egress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database-SG"
  }
}

# Create EC2 Instances
resource "aws_instance" "web1" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  availability_zone      = var.az_a
  vpc_security_group_ids = [aws_security_group.ec2-sg.id]
  subnet_id              = aws_subnet.public-subnet-1.id
  tags = {
    Name = "We server-1"
  }

}

resource "aws_instance" "web2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  availability_zone      = var.az_b
  vpc_security_group_ids = [aws_security_group.ec2-sg.id]
  subnet_id              = aws_subnet.public-subnet-2.id
  tags = {
    Name = "Web Server-2"
  }

}

# Create Load Balancer
resource "aws_lb" "alb" {
  name               = "ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb-sg.id]
  subnets            = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]
}

resource "aws_lb_target_group" "target-alb" {
  name     = "ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_lb_target_group_attachment" "alb1" {
  target_group_arn = aws_lb_target_group.target-alb.arn
  target_id        = aws_instance.web1.id
  port             = 80
  depends_on       = [aws_instance.web1]
}

resource "aws_lb_target_group_attachment" "alb2" {
  target_group_arn = aws_lb_target_group.target-alb.arn
  target_id        = aws_instance.web2.id
  port             = 80
  depends_on       = [aws_instance.web2]
}

resource "aws_lb_listener" "alb" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-alb.arn
  }
}

# Create database
resource "aws_db_instance" "database" {
  allocated_storage      = 10
  db_subnet_group_name   = aws_db_subnet_group.default.id
  engine                 = "mysql"
  engine_version         = "8.0.20"
  instance_class         = "db.t2.micro"
  multi_az               = true
  name                   = "mydb"
  username               = var.username
  password               = var.pwd
  vpc_security_group_ids = [aws_security_group.db-sg.id]
}

resource "aws_db_subnet_group" "default" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.db-subnet-1.id, aws_subnet.db-subnet-2.id]

  tags = {
    Name = "My DB subnet group"
  }
}
