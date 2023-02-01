resource "aws_instance" "Altschool1" {
  ami             = "ami-00874d747dde814fa"
  instance_type   = "t2.micro"
  key_name        = "testkeypair"
  security_groups = [aws_security_group.security-group-rule.id]
  subnet_id       = aws_subnet.public-subnet1.id
  availability_zone = "us-east-1a"

  tags = {
    Name   = "Altschool-1"
    source = "terraform"
  }
}

# creating instance 2
 resource "aws_instance" "Altschool2" {
  ami             = "ami-00874d747dde814fa"
  instance_type   = "t2.micro"
  key_name        = "testkeypair"
  security_groups = [aws_security_group.security-group-rule.id]
  subnet_id       = aws_subnet.public-subnet2.id
  availability_zone = "us-east-1b"
  tags = {
    Name   = "Altschool-2"
    source = "terraform"
  }
}

# creating instance 3
resource "aws_instance" "Altschool3" {
  ami             = "ami-00874d747dde814fa"
  instance_type   = "t2.micro"
  key_name        = "testkeypair"
  security_groups = [aws_security_group.security-group-rule.id]
  subnet_id       = aws_subnet.public-subnet1.id
  availability_zone = "us-east-1a"
  tags = {
    Name   = "Altschool-3"
    source = "terraform"
  }
}

resource "local_file" "IP_address" {
    filename = "\\wsl.localhost/Ubuntu/etc/ansible/host-inventory.txt"
    content  = <<EOT
${aws_instance.Altschool1.public_ip}
${aws_instance.Altschool2.public_ip}
${aws_instance.Altschool3.public_ip}
    EOT
}