resource "aws_security_group" "alb_sg" {
  name        = "devops-nixos-demo-alb-sg"
  description = "Allow HTTP/HTTPS traffic to ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "devops-nixos-demo-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_allow_http" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = "80"
  to_port           = "80"
  ip_protocol       = "tcp"
  description       = "Allow HTTP from anywhere"
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_allow_https" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = "443"
  to_port           = "443"
  ip_protocol       = "tcp"
  description       = "Allow HTTPS from anywhere"
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_allow_quic" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = "443"
  to_port           = "443"
  ip_protocol       = "udp"
  description       = "Allow QUIC from anywhere"
}

resource "aws_vpc_security_group_egress_rule" "alb_sg_allow_all_outbound" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}

resource "aws_lb" "gitlab" {
  name                       = "devops-nixos-demo-gitlab-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = [aws_subnet.public_a.id]
  enable_deletion_protection = true

  tags = {
    Name = "devops-nixos-demo-gitlab-alb"
  }
}

resource "aws_lb_target_group" "gitlab" {
  name              = "gitlab-tg"
  port              = 80
  protocol          = "HTTP"
  vpc_id            = aws_vpc.main.id
  target_type       = "instance"
  proxy_protocol_v2 = true

  health_check {
    path     = "/users/sign_in"
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group_attachment" "gitlab" {
  target_group_arn = aws_lb_target_group.gitlab.arn
  target_id        = aws_instance.gitlab_server.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.gitlab.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gitlab.arn
  }
}
