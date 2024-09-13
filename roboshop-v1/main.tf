module "instances" {
  for_each = var.instances
  source   = "./ec2"
  name     = module.aws_instance.name
}

variable "instances" {
  default = {

    frontend  = {}
    mongodb   = {}
    catalogue = {}
    redis     = {}
    user      = {}
    cart      = {}
    mysql     = {}
    shipping  = {}
    rabbitmq  = {}
    payment   = {}

  }
}
