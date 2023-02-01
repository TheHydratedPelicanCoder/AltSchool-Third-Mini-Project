resource "aws_vpc" "Project_vpc" {
    cidr_block                       = "10.0.0.0/16"
    instance_tenancy                 = "default"
    enable_dns_hostnames             = true
    tags        = {
        Name    = "Project_vpc"
    }
}

resource "aws_internet_gateway" "internet-gateway" {
    vpc_id     = aws_vpc.Project_vpc.id

    tags       = {
        Name   = "TerraformIGW"
    }
}

resource "aws_subnet" "public-subnet1" {
    vpc_id                  = aws_vpc.Project_vpc.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "us-east-1a"
    map_public_ip_on_launch = true

    tags   = {
        Name = "TerraformPublicSubnet1"
    }
}

resource "aws_subnet" "public-subnet2" {
    vpc_id                  = aws_vpc.Project_vpc.id
    cidr_block              = "10.0.2.0/24"
    availability_zone       = "us-east-1b"
    map_public_ip_on_launch = true

    tags   = {
        Name = "TerraformPublicSubnet2"
    }
}

resource "aws_route_table" "public-route-table" {
    vpc_id = aws_vpc.Project_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.internet-gateway.id
    }

    tags     = {
        Name = "TerraformPublicRT"
    }
}

resource "aws_route_table_association" "public-subnet1-route-table-association" {
    subnet_id      = aws_subnet.public-subnet1.id
    route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "public-subnet2-route-table-association" {
    subnet_id      = aws_subnet.public-subnet2.id
    route_table_id = aws_route_table.public-route-table.id
}

resource "aws_network_acl" "network-acl" {
    vpc_id     = aws_vpc.Project_vpc.id
    subnet_ids = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]

    ingress {
        rule_no     = 100
        protocol    = "-1"
        action      = "allow"
        cidr_block  = "0.0.0.0/0"
        from_port   = 0
        to_port     = 0
    }

    egress {
        rule_no    = 100
        protocol   = "-1"
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0 
    }
}

resource "aws_security_group" "load_balancer_sg" {
  name        = "load-balancer-sg"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.Project_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "security-group-rule" {
  name        = "allow_ssh_http_https"
  description = "Allow SSH, HTTP and HTTPS inbound traffic for private instances"
  vpc_id      = aws_vpc.Project_vpc.id

 ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.load_balancer_sg.id]
  }

 ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.load_balancer_sg.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "security-group-rule"
  }
}

resource "aws_lb" "load-balancer" {
    name                       = "load-balancer"
    internal                   = false
    load_balancer_type         = "application"
    security_groups            = [aws_security_group.load_balancer_sg.id]
    subnets                    = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]
    enable_deletion_protection = false
    depends_on                 = [aws_instance.Altschool1, aws_instance.Altschool2, aws_instance.Altschool3]
}

resource "aws_lb_target_group" "target-group" {
  name     = "target-group"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.Project_vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.load-balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}
# Create the listener rule
resource "aws_lb_listener_rule" "listener-rule" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_lb_target_group_attachment" "target-group-attachment1" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.Altschool1.id
  port             = 80
}
 
resource "aws_lb_target_group_attachment" "target-group-attachment2" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.Altschool2.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "target-group-attachment3" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.Altschool3.id
  port             = 80 
  
  }