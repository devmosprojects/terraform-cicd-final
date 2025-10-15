variable "public_key_path" {
  type        = string
  description = "Path to the public key file for Jenkins EC2 key pair"
}
variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "jenkins_key_name" {
  type = string
}

variable "ecr_repo_name" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "ecs_task_family" {
  type = string
}

variable "aws_region" {
  type = string
}
resource "aws_key_pair" "jenkins_key" {
  key_name   = var.jenkins_key_name
  public_key = file(var.public_key_path) # provide path or generate separately
}

resource "aws_security_group" "jenkins_sg" {
  name   = "${var.name}-jenkins-sg"
  vpc_id = var.vpc_id
  ingress = [
    { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { from_port = 8080, to_port = 8080, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
  ]
  egress = [{ from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }]
}

resource "aws_instance" "jenkins" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id     = var.public_subnet_id
  key_name      = aws_key_pair.jenkins_key.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    region = var.aws_region
    ecr_repo = var.ecr_repo_name
    ecs_cluster = var.ecs_cluster_name
    ecs_service = var.ecs_service_name
    task_family = var.ecs_task_family
  })
  tags = { Name = "${var.name}-jenkins" }
}

# IAM user for Jenkins
resource "aws_iam_user" "jenkins_user" {
  name = "${var.name}-jenkins-user"
}

resource "aws_iam_access_key" "jenkins_access_key" {
  user = aws_iam_user.jenkins_user.name
}

resource "aws_iam_policy" "jenkins_policy" {
  name = "${var.name}-jenkins-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:CreateRepository"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "iam:PassRole"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach" {
  user       = aws_iam_user.jenkins_user.name
  policy_arn = aws_iam_policy.jenkins_policy.arn
}
