provider "aws" {
  region  = "eu-west-3"
  profile = "finstack"
}

terraform {
  required_version = "~> 0.12.0"
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "gregbkr"
    workspaces {
      name = "eth2-staking-testnet"
    }
  }
}

# Fist get the default VPC and subnet IDs
data "aws_vpc" "default" {
  default = true
}
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
variable "env" {
  default = "dev"
}