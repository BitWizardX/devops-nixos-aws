resource "aws_iam_role" "gitlab_role" {
  name               = "devops-nixos-demo-gitlab-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "gitlab_ssm_policy" {
  role       = aws_iam_role.gitlab_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "gitlab_profile" {
  name = "devops-nixos-demo-gitlab-profile"
  role = aws_iam_role.gitlab_role.name
}

resource "aws_security_group" "gitlab_sg" {
  name        = "devops-nixos-demo-gitlab-sg"
  description = "Security group for the GitLab server"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "devops-nixos-demo-gitlab-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "gitlab_sg_allow_http" {
  security_group_id            = aws_security_group.gitlab_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  description                  = "Allow HTTP from ALB"
}

resource "aws_vpc_security_group_egress_rule" "gitlab_sg_allow_all_outbound" {
  security_group_id = aws_security_group.gitlab_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}

data "aws_ami" "nixos" {
  most_recent = true
  owners      = ["427812963091"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["nixos/25.05.*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "gitlab_server" {
  ami                    = data.aws_ami.nixos.id
  instance_type          = "c7i-flex.large"
  subnet_id              = aws_subnet.private_a.id
  vpc_security_group_ids = [aws_security_group.gitlab_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.gitlab_profile.name

  root_block_device {
    volume_size = 64
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "devops-nixos-demo-gitlab-server"
  }
}
