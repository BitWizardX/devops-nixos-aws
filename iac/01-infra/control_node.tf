data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "control_node_role" {
  name               = "devops-nixos-demo-control-node-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "control_node_ssm_policy" {
  role       = aws_iam_role.control_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "control_node_admin_policy" {
  role       = aws_iam_role.control_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "control_node_profile" {
  name = "devops-nixos-demo-control-node-profile"
  role = aws_iam_role.control_node_role.name
}

resource "aws_security_group" "control_node_sg" {
  name        = "devops-nixos-demo-control-node-sg"
  description = "Security group for the Control Node"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "devops-nixos-demo-control-node-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "control_node_sg_allow_all_outbound" {
  security_group_id = aws_security_group.control_node_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic for package updates and AWS API calls"
}

data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["debian-13-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "cloudinit_config" "control_node_init" {
  part {
    filename     = "init.yaml"
    content_type = "text/cloud-config"

    content = file("${path.module}/scripts/control_node/init.yaml")
  }

  part {
    filename     = "init.sh"
    content_type = "text/x-shellscript"

    content = file("${path.module}/scripts/control_node/init.sh")
  }
}

resource "aws_instance" "control_node" {
  ami                    = data.aws_ami.debian.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_a.id
  vpc_security_group_ids = [aws_security_group.control_node_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.control_node_profile.name
  user_data_base64       = data.cloudinit_config.control_node_init.rendered

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "devops-nixos-demo-control-node"
  }
}
