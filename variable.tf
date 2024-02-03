variable "availability_zone_map" {
    description = "Availability zone for instance"
    type = list(string)
    default = [ "us-east-1a" ]
    }
variable "environment" {
  description = "The environment in which the infrastructure is being deployed"
  type        = string
  default     = "dev"
}
variable "region" {
  description = "The AWS region in which resources are created"
  type        = string
  default     = "us-east-1"
}
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
variable "public_subnets_cidr" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}
variable "private_subnets_cidr" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.4.0/24"]
}