# ---------- Load balancer security group ----------
resource "aws_security_group" "alb" {
  name        = "food-alb-sg"
  description = "Load balancer: HTTP from the internet"
  vpc_id      = var.vpc_id

  tags = { Name = "food-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from anywhere"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

# Terraform removes the default "allow all out" rule, so we add it back
resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ---------- Web server security group ----------
resource "aws_security_group" "web" {
  name        = "food-web-sg"
  description = "Web servers: HTTP only from the load balancer"
  vpc_id      = var.vpc_id

  tags = { Name = "food-web-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "web_from_alb" {
  security_group_id            = aws_security_group.web.id
  description                  = "HTTP from the load balancer only"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound (ECR, Parameter Store, MongoDB, package downloads)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ---------- One new rule on the EXISTING food-app group ----------
# Lets the web servers (and nothing else) reach MongoDB on food-app.
resource "aws_vpc_security_group_ingress_rule" "mongo_from_web" {
  security_group_id            = var.app_security_group_id
  description                  = "MongoDB from the web servers"
  ip_protocol                  = "tcp"
  from_port                    = 27017
  to_port                      = 27017
  referenced_security_group_id = aws_security_group.web.id
}
