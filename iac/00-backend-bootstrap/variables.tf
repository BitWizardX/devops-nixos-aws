variable "project" {
  description = "The name of the project, used as a prefix for all resources."
  type        = string
  default     = "devops-nixos-aws"
}

variable "environment" {
  description = "The environment name, e.g., 'dev', 'staging', 'prod'."
  type        = string
  default     = "demo"
}

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-northeast-1"
}
