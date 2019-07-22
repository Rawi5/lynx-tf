# This data source is included for ease of sample architecture deployment
# and can be swapped out as necessary.
variable "vpcnet_prefix" {
 
}

variable "network-name" {
 
}

data "aws_availability_zones" "available" {}
resource "aws_vpc" "eks-vpc" {
  cidr_block           = "${var.vpcnet_prefix}.0.0/16"
  enable_dns_hostnames = true

 
}

resource "aws_subnet" "eks-subnets" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "${var.vpcnet_prefix}.${count.index}.0/24"
  vpc_id            = "${aws_vpc.eks-vpc.id}"

  tags = "${
    map(
     "Name", "${var.network-name}-subnet"
  
    )
  }"
}

resource "aws_subnet" "eks-subnet-private" {
  cidr_block        = "${var.vpcnet_prefix}.5.0/24"
  vpc_id            = "${aws_vpc.eks-vpc.id}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags = "${
    map(
     "Name", "${var.network-name}-private"
    )
  }"
}

resource "aws_internet_gateway" "eks-igw" {
  vpc_id = "${aws_vpc.eks-vpc.id}"

  tags {
    Name = "${var.network-name}"
  }
}

resource "aws_route_table" "eks-rt" {
  vpc_id = "${aws_vpc.eks-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.eks-igw.id}"
  }
}

resource "aws_route_table" "eks-rt-private" {
  vpc_id = "${aws_vpc.eks-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.eks-igw.id}"
  }
}

resource "aws_route_table_association" "eks-rta" {
  count = 2

  subnet_id      = "${aws_subnet.eks-subnets.*.id[count.index]}"
  route_table_id = "${aws_route_table.eks-rt.id}"
}

resource "aws_route_table_association" "eks-rta-private" {
  subnet_id      = "${aws_subnet.eks-subnet-private.id}"
  route_table_id = "${aws_route_table.eks-rt-private.id}"
}