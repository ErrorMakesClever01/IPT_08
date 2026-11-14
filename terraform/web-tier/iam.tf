data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "web" {
  name               = "food-web-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "web" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", # pull images from ECR
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",        # send metrics
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",       # Session Manager access
  ])

  role       = aws_iam_role.web.name
  policy_arn = each.value
}

# Lets a web server read its settings from Parameter Store at boot
resource "aws_iam_role_policy" "web_parameters" {
  name = "read-food-parameters"
  role = aws_iam_role.web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ssm:GetParameter"
      Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/food/*"
    }]
  })
}

resource "aws_iam_instance_profile" "web" {
  name = "food-web-role"
  role = aws_iam_role.web.name
}
