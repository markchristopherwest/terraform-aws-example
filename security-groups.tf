resource "aws_security_group" "testing" {
  name        = "${random_pet.env.id}-testing-sg"
  description = "${random_pet.env.id} Internal Traffic & SSH"
  vpc_id      = module.vault_demo_vpc.vpc_id

  tags = {
    Name = random_pet.env.id
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress for api_address
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress for cluster_address 
  ingress {
    from_port   = 8201
    to_port     = 8201
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress other
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "api_egress" {
  description       = "${random_pet.env.id} Allow Vault API Access"
  type              = "egress"
  protocol          = "tcp"
  from_port         = 8200
  to_port           = 8200
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testing.id
}
