output "jenkins_public_ip" {
  value = module.jenkins.public_ip
}

output "alb_dns" {
  value = module.ecs.alb_dns
}

output "ecr_repo_uri" {
  value = module.ecs.ecr_repo_uri
}

