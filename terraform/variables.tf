variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "dotnet-cicd"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
