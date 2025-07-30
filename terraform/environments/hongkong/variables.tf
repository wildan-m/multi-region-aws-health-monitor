variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "sleek-health-monitor"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "hongkong"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.2.10.0/24", "10.2.20.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "monitoring_enabled" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    Country = "Hong Kong"
    Office  = "Hong Kong Branch"
  }
}