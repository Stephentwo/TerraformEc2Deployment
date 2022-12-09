// This block creates the VPC

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "Name" = "dev"
  }
}


// Thic block creates the subnet

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "public"
  }
}


// This block creates the internet gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "internetGW"
  }
}


// This block creates the route table

resource "aws_route_table" "routemain" {
    vpc_id = aws_vpc.main.id


    tags = {
      "Name" = "mainpublicRT"
    }
}

// This block adds route to the route table

resource "aws_route" "default_route" {
    route_table_id = aws_route_table.routemain.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
}

// This block associates the subnet with the route table

resource "aws_route_table_association" "RTassociation" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.routemain.id
}

// This block creates the security group

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [aws_vpc.main.cidr_block, "41.84.151.154/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

//This block creates the keypair

resource "aws_key_pair" "ec2keypair" {
  key_name   = "ec2key"
  public_key = file("~/.ssh/ec2keypair.pub")
}

// This block creates the AWS instance

resource "aws_instance" "dev" {
  instance_type = "t2.micro"
  ami = data.aws_ami.getami.id
  key_name = aws_key_pair.ec2keypair.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id = aws_subnet.main.id
  user_data = file("userdata.tpl")

  tags = {
    "Name" = "Dev"
  }

}