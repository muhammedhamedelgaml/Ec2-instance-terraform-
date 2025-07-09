provider "aws" {
  region = "us-east-1" 
}



resource "aws_vpc" "vpc-1" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "vpc-1"  
    }
}


# create a public subnet in the VPC
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc-1.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
    }     
}


# create an internet gateway and attach it to the VPC
resource "aws_internet_gateway" "igw-1" {
  vpc_id = aws_vpc.vpc-1.id
  tags = {
    Name = "igw-1"
  }
}




# create a route table and associate it with the public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc-1.id
  tags = {
    Name = "public-route-table"
  }
}
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw-1.id
}
resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}




#create security group for the instance
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP "
  vpc_id      = aws_vpc.vpc-1.id    
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow HTTP traffic"
    }

    egress {    
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]  
        description = "Allow all outbound traffic"
    }
    tags = {
        Name = "web_sg"
    }
}



# create ec2 instance
resource "aws_instance" "Appache" {
  ami           = "ami-05ffe3c48a9991133" 
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "web-server"
  } 
  vpc_security_group_ids = [aws_security_group.web_sg.id]
    user_data = <<-EOF
                #!/bin/bash
                sudo yum install -y httpd
                sudo systemctl start httpd
                sudo systemctl enable httpd
                echo "Hello, World!" | sudo tee /var/www/html/index.html
                EOF

}


