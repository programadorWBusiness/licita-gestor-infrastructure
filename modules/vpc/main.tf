resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 8, 0)
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
}
