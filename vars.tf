variable "ami_id" {
  default = ""
}

variable "vpc_cidr" {
  default = "0.0.0.0/16"
}

varibale "pub_subnet1_CIDR" {
  default = "0.0.2.0/24"
}
  
variable "pub_subnet2_CIDR" {
  default = "0.0.3.0/24"
}

variable "app_subnet1" {
  default = "0.0.10.0/24"
}

variable "app_subnet2" {
  default = "0.0.12.0/24"
}

varibale "db_subnet1_CIDR" {
  default = "0.0.20.0/24"
}

variable "db_subnet2_CIDR" {
  default = "0.0.21.0/24"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "az_a" {
  default = "us-east-1a"
}

variable "az_b" {
  default = "us-east-1b"
}

variable "username" {
  default = "admin"
}

variable "pwd" {
  default = ""
}
