provider "aws" {
  #profile = var.local_profile
  #region = var.aws_region
  #access_key = "my-access-key"
  #secret_key = "my-secret-key"
}

terraform {
  backend "remote" {
    organization = "eshiji"
    hostname = "app.terraform.io"

    workspaces {
      name = "tf-modules"
    }
  }
}

resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type
}