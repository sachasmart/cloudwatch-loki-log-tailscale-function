module "vpc" {
  source = "./modules/vpc"

  name_prefix          = local.name_prefix_shipper
  vpc_cidr             = "10.0.0.0/16"
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]
  availability_zones   = ["${var.region}a", "${var.region}b"]
}
