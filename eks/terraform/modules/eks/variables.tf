variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "lab_role_arn" {
  type = string
}

variable "voclabs_role_arn" {
  type = string
}
