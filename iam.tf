
//--------------------------------------------------------------------
// Data Sources

data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }

}

data "aws_iam_policy_document" "execute" {
  statement {
    sid    = "VaultAWSAuthMethod"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "iam:GetInstanceProfile",
      "iam:GetUser",
      "iam:GetRole",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "VaultKMSUnseal"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = ["*"]
  }

}

## Vault Server IAM Config
resource "aws_iam_instance_profile" "main" {
  name = "${random_pet.env.id}-vault-server-instance-profile"
  role = module.vault_cluster.iam_role_name

}

resource "aws_iam_role_policy" "execute" {
  name   = "execute"
  role   = module.vault_cluster.iam_role_name
  policy = data.aws_iam_policy_document.execute.json

}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role       = module.vault_cluster.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

}

resource "aws_iam_instance_profile" "vault-server" {
  name = module.vault_cluster.iam_role_name
  role = module.vault_cluster.iam_role_name

}