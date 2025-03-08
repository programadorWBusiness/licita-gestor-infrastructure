variable "cluster_id" {
  type = string
}

variable "service_name" {
  type = string
}

variable "container_image" {
  type = string
}

variable "container_port" {
  type = number
}

variable "subnets" {
  type = list(string)
}

variable "security_groups" {
  type    = list(string)
  default = []
}
