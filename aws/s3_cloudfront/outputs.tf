# Bucket
output "static_content_bucket_id" {
  value = aws_s3_bucket.static_content_bucket.id
}

output "static_content_bucket_domain_name" {
  value = aws_s3_bucket.static_content_bucket.bucket_domain_name
}

# Cloudfront orifin identity access
output "cf_origin_access_identity_id" {
  value = aws_cloudfront_origin_access_identity.origin_access_identity.id
}

# Cloudfront distribution
output "cf_distribution_id" {
  value = aws_cloudfront_distribution.s3_distribution.id
}

output "cf_distribution_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

