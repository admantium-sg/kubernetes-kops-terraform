resource "aws_iam_user" "kops" {
  name = "kops"
  path = "/"
}

resource "aws_iam_user_policy" "kops_access" {
  name = "kops_access"
  user = aws_iam_user.kops.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:*",
          "route53:*",
          "s3:*",
          "iam:*",
          "vpc:*",
          "sqs:*",
          "events:*",
          "autoscaling:*",
          "elasticloadbalancing:*"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_access_key" "kops" {
  user = aws_iam_user.kops.id
}

resource "aws_route53_zone" "domain" {
  name          = var.kops_domain
  force_destroy = true
}

resource "aws_route53_zone" "sub_domain" {
  name          = var.kops_sub_domain
  force_destroy = true
}

resource "aws_route53_record" "dns_record" {
  zone_id = aws_route53_zone.domain.zone_id
  name    = var.kops_sub_domain
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.sub_domain.name_servers
}

resource "aws_s3_bucket" "kops_state" {
  bucket        = "${random_pet.bucket_name.id}-kops-state"
  force_destroy = true
}

resource "random_pet" "bucket_name" {}

resource "tls_private_key" "generic-ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096

  provisioner "local-exec" {
    command = <<EOF
      mkdir -p .ssh/
      cat <<< "${tls_private_key.generic-ssh-key.private_key_openssh}" > .ssh/id_rsa.key
      cat <<< "${tls_private_key.generic-ssh-key.public_key_openssh}" > .ssh/id_rsa.pub
      chmod 400 .ssh/id_rsa.key
      chmod 400 .ssh/id_rsa.key
    EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
      rm -rvf .ssh/
    EOF
  }
}