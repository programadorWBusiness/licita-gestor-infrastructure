variable "engine" {
  type    = string
  default = "postgres"
}

variable "engine_version" {
  type    = string
  default = "13.4"
}

variable "instance_class" {
  type    = string
  default = "db.t2.micro"  # Free-tier eligible in many regions
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "username" {
  type    = string
  default = "admin"
}

variable "password" {
  type      = string
  sensitive = true
}

variable "subnets" {
  type = list(string)
}

variable "security_groups" {
  type    = list(string)
  default = []
}
