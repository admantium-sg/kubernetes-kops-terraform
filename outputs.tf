output "kops_iam_key" {
  value = aws_iam_access_key.kops.id
}

output "kops_iam_secret" {
  value     = aws_iam_access_key.kops.secret
  sensitive = true
}

output "kops_name_servers" {
  value = tolist(aws_route53_zone.sub_domain.name_servers)
}

output "kops_bucket_name" {
  value = aws_s3_bucket.kops_state.bucket
}
