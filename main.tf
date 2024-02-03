# Define your VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }

}

# Define your public and private subnets

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  count                   = length(var.public_subnets_cidr)
  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zone_map, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-${element(var.availability_zone_map, count.index)}-public-subnet"
    Environment = var.environment

  }

}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main.id
  count                   = length(var.private_subnets_cidr)
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zone_map, count.index)
  map_public_ip_on_launch = false  # Corrected to false for private subnet

  tags = {
    Name        = "${var.environment}-${element(var.availability_zone_map, count.index)}-private-subnet"
    Environment = var.environment
  }

}

# Define your internet gateway

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }

}

# Define Elastic IP for NAT gateway

resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.ig]

}

# Define NAT gateway

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)

  tags = {
    Name        = "nat"
    Environment = var.environment
  }

}

# Define public route table and associate with public subnet

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-public-route-table"
    Environment = var.environment
  }

}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

# Define private route table and associate with private subnet

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  depends_on = [aws_security_group_rule.ssh_system]

  tags = {
    Name        = "${var.environment}-private-route-table"
    Environment = var.environment

  }

}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id

}

# Define your EC2 instance

resource "aws_instance" "web" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  subnet_id     = element(aws_subnet.private_subnet.*.id, 0)

  tags = {
    Name = "Project-arch"

  }

}

resource "aws_security_group_rule" "ssh_system" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["182.72.246.252/32"]
  security_group_id = "sg-0cd6d9dd5a4d7bc77"
}