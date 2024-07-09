terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
      backend "s3" {
      bucket = "demo-statefile-s3"
      key    = "terraform-state.tfstate"
      region = "us-east-2"
    }
   
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
  #profile = "Neethu"
}


#creating the vpc

resource "aws_vpc" "demo-vpc" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "${var.name}-vpc" 
  }
}

 #creating the subnets

resource "aws_subnet" "demo-subnet-public-2a" {
  vpc_id                  = aws_vpc.demo-vpc.id
  cidr_block              = "10.10.0.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-subnet-public-2a"
  }
}

resource "aws_subnet" "demo-subnet-public-2b" {
  vpc_id                  = aws_vpc.demo-vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-subnet-public-2b"
  }
}

resource "aws_subnet" "demo-subnet-private-2a" {
  vpc_id            = aws_vpc.demo-vpc.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "${var.name}-subnet-private-2a"
  }
}

resource "aws_subnet" "demo-subnet-private-2b" {
  vpc_id            = aws_vpc.demo-vpc.id
  cidr_block        = "10.10.3.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "${var.name}-subnet-private-2b"
  }
}

#create IGW

resource "aws_internet_gateway" "demo-IGW" {
  vpc_id = aws_vpc.demo-vpc.id

  tags = {
    Name = "${var.name}-internet-GW"
  }
}

#create RT

resource "aws_route_table" "demo-public-RT" {
  vpc_id = aws_vpc.demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo-IGW.id
  }

  tags = {
    Name = "${var.name}-public-RT"
  }
}


resource "aws_route_table" "demo-private-RT" {
  vpc_id = aws_vpc.demo-vpc.id

  tags = {
    Name = "${var.name}-private-RT"
  }
}

resource "aws_route_table_association" "RT_asso_subnet_1_public" {
  subnet_id      = aws_subnet.demo-subnet-public-2a.id
  route_table_id = aws_route_table.demo-public-RT.id
}

resource "aws_route_table_association" "RT_asso_subnet_2_public" {
  subnet_id      = aws_subnet.demo-subnet-public-2b.id
  route_table_id = aws_route_table.demo-public-RT.id
}

resource "aws_route_table_association" "RT_asso_subnet_3_private" {
  subnet_id      = aws_subnet.demo-subnet-private-2a.id
  route_table_id = aws_route_table.demo-private-RT.id
}
resource "aws_route_table_association" "RT_asso_subnet_4_private" {
  subnet_id      = aws_subnet.demo-subnet-private-2b.id
  route_table_id = aws_route_table.demo-private-RT.id
}


#create Security Group for ASG & ALB

resource "aws_security_group" "allow_22" {
  name        = "allow_22"
  description = "Allow TLS inbound traffic to port 22"
  vpc_id      = aws_vpc.demo-vpc.id

  tags = {
    Name = "allow_22"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_22" {
  security_group_id = aws_security_group.allow_22.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound" {
  security_group_id = aws_security_group.allow_22.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound_traffic_ipv6" {
  security_group_id = aws_security_group.allow_22.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_security_group" "allow_80" {
  name        = "allow_80"
  description = "Allow TLS inbound traffic to port 80"
  vpc_id      = aws_vpc.demo-vpc.id

  tags = {
    Name = "allow_80"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_80" {
  security_group_id = aws_security_group.allow_80.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound_1" {
  security_group_id = aws_security_group.allow_80.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound_traffic_ipv6_1" {
  security_group_id = aws_security_group.allow_80.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# key pair

resource "aws_key_pair" "demo-key" {
  key_name   = "demo-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCnWfXdWECxjE2in1OnLRPMT2CHRk/Z1LQlrPTMl3EdoxeowRwA3jlmVEWjkg1+Q0DShqMUNR2uFP4J64Il2R6/cJk8cDCIXmAoiI0f6klxAM3XkwRirhr4Qd8N0Ujqc+NxABUo7CK6lEuQ9UIFBXeaWl9VzSLPoxFIU1DY8xnjAjqAFrIkTmZ6aG+827h5CiB9NwoV345C7d3LWlQPiur2NtkT0aglwSxzIeyIEx3p9C/msYTvBijBojxnbpeUfGVi8q4B1BbUZHCRWynNvkMDNH01UlUJFUuxAMk3nF/ClP3VqBx7fHWr6d9MzhCWv2jAq9/lyRMpRVh3euNWwKrNl1Ld5XsT6nB8fHCbjB++0mFUNoZN2OrbJNvNJBe2TzS8/YO067gq5TdUrxPGqB42GTxKoSNEiDmAcZD6ogPhj3pr3u5V6cpb0/0yd7L2xTd8VYBx5jFp9deHrCY+GMqcp5Y/ln4JnARyCdWeRbvTvSI5esoYhokMkQ/ok77llHM= ssankar1@ussd-ofcmc6821.lan"
}


# ASG

#create the lauch template
resource "aws_launch_template" "demo_launch_template" {
  name = "${var.name}_launch_template"
  image_id = "ami-0862be96e41dcbf74"
  instance_type = var.instance_type
  key_name = aws_key_pair.demo-key.id
  vpc_security_group_ids = [aws_security_group.allow_22.id, aws_security_group.allow_80.id]
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.name}-instance-asg"
    }
  }

  user_data = filebase64("userdata.sh")
}

# asg
resource "aws_autoscaling_group" "demo-asg" {
  name_prefix = "${var.name}-asg-"
  vpc_zone_identifier = [aws_subnet.demo-subnet-public-2a.id, aws_subnet.demo-subnet-public-2b.id]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2
  target_group_arns = [aws_lb_target_group.demo-target-group.arn]

  launch_template {
    id      = aws_launch_template.demo_launch_template.id
    version = "$Latest"
  }
}

# ALB

# target group
resource "aws_lb_target_group" "demo-target-group" {
  name     = "${var.name}-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo-vpc.id
}


# alb
resource "aws_lb" "demo-alb" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_80.id]
  subnets            = [aws_subnet.demo-subnet-public-2a.id, aws_subnet.demo-subnet-public-2b.id]


  tags = {
    Environment = "production"
  }
}

# listener
resource "aws_lb_listener" "demo_listener" {
  load_balancer_arn = aws_lb.demo-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo-target-group.arn
  }
}