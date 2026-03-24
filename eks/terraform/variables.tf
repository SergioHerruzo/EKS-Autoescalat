variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "karpenter-challenge-35"
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  lab_role_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  voclabs_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/voclabs"
}
