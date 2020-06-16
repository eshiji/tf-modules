provider "aws" {
  #profile = var.local_profile
  region  = var.aws_region
}

resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type
}