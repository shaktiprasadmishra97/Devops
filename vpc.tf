#Sample terraform script for VPC Peering
#VPC1 CREATION- 192.168.0.0/26
resource "aws_vpc" "vpc1"{
	cidr_block = "192.168.0.0/26"
	
	tags = {
		Name = "vpc1"
		}
	}
	
#VPC2 CREATION - 10.0.0.0/26
resource "aws_vpc" "vpc2"{
	cidr_block = "10.10.0.0/26"
	
	tags = {
		Name = "vpc2"
		}
	}
	
#VPC PEERING
resource "aws_vpc_peering_connection" "peer" {
	peer_vpc_id   = aws_vpc.vpc2.id #10.0.0.0/26
	vpc_id        = aws_vpc.vpc1.id #192.168.0.0/26
	auto_accept   = true
}

#Internet Gateway cration for vpc1  with name "igw_vpc1"
resource "aws_internet_gateway" "igw_vpc1" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "igw_vpc1"
  }
}

#Creation of Public subnet for VPC1(192.168.0.0/26)
#Public subnet name - "pub_sub_vpc1"
resource "aws_subnet" "pub_sub_vpc1" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "192.168.0.0/27"

  tags = {
    Name = "pub_sub_vpc1"
  }
}

#Creation of Route Table for Public subnet of VPC1(192.168.0.0/26)
#Route Table name - "pub_route_vpc1"
resource "aws_route_table" "pub_route_vpc1" {
  vpc_id = aws_vpc.vpc1.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_vpc1.id
  }
  
  route {
    cidr_block = "10.0.0.0/26"
    vpc_peering_connection_id  = aws_vpc_peering_connection.peer.id
  }
}

#Public Subnet association (pub_sub_vpc1) with route table (pub_route_vpc1)
#route table asociation name - "pubroute_association"
resource "aws_route_table_association" "pubroute_association_vpc1" {
  subnet_id      = aws_subnet.pub_sub_vpc1.id
  route_table_id = aws_route_table.pub_route_vpc1.id
}

#Elastic IP creation name - "eip_vpc1"
resource "aws_eip" "eip_vpc1" {
  vpc      = true
}

#Create NAT Gateway in public subnet with Elastic IP. Name - "natgw_vpc1"
resource "aws_nat_gateway" "natgw_vpc1" {
  allocation_id = aws_eip.eip_vpc1.id
  subnet_id     = aws_subnet.pub_sub_vpc1.id

  tags = {
    Name = "natgw_vpc1"
  }
} 

#Creation of Private subnet for VPC1(192.168.0.0/26)
#Private subnet name - "pvt_sub_vpc1"
resource "aws_subnet" "pvt_sub_vpc1" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "192.168.0.32/27"

  tags = {
    Name = "pvt_sub_vpc1"
  }
}

#Creation of Route Table for Private subnet of VPC1(192.168.0.0/26)
#Route Table name - "pvt_route_vpc1"
resource "aws_route_table" "pvt_route_vpc1" {
  vpc_id = aws_vpc.vpc1.id
  
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw_vpc1.id
  }
  
  route {
    cidr_block = "10.0.0.0/26"
    vpc_peering_connection_id  = aws_vpc_peering_connection.peer.id
  }
}

#Private Subnet association (pvt_sub_vpc1) with route table (pvt_route_vpc1)
#route table asociation name - "pvtroute_association"
resource "aws_route_table_association" "pvtroute_association_vpc1" {
  subnet_id      = aws_subnet.pvt_sub_vpc1.id
  route_table_id = aws_route_table.pvt_route_vpc1.id
}
