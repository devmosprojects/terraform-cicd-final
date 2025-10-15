module "vpc" {
  source  = "./modules/vpc"
  name    = var.project_name
  cidr    = var.vpc_cidr
}

module "ecs" {
  source        = "./modules/ecs"
  name          = var.project_name
  vpc_id        = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "jenkins" {
  source            = "./modules/jenkins"
  name              = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_id  = module.vpc.public_subnet_ids[0]
  jenkins_key_name  = "${var.project_name}-jenkins-key"
  ecr_repo_name     = module.ecs.ecr_repo_name
  ecs_cluster_name  = module.ecs.cluster_name
  ecs_service_name  = module.ecs.service_name
  ecs_task_family   = module.ecs.task_family
  aws_region        = var.aws_region
  public_key_path   = "~/.ssh/id_rsa.pub" # Update this path if your public key is elsewhere
}
