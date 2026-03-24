module "vpc" {
  source = "./modules/vpc"

  cluster_name    = var.cluster_name
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

module "eks" {
  source = "./modules/eks"

  cluster_name     = var.cluster_name
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnets
  lab_role_arn     = local.lab_role_arn
  voclabs_role_arn = local.voclabs_role_arn
}

module "karpenter" {
  source = "./modules/karpenter"

  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  lab_role_arn     = local.lab_role_arn

  depends_on = [module.eks]
}
