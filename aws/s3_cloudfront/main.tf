# Create bucket for static content
resource "aws_s3_bucket" "static_content_bucket" {
  bucket = var.static_content_bucket_name
  acl    = "private"

  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}-static-content"
    },
    var.tags,
  )
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.static_content_bucket.id

  block_public_acls   = true
  block_public_policy = true
}

# Create CF origin access identity
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "tf-access-identity-${aws_s3_bucket.static_content_bucket.id}"
}

# Create bucket policy
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_content_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.static_content_bucket.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
  # statement {
  #   actions   = ["s3:PutObject"]
  #   resources = ["${aws_s3_bucket.static_content_bucket.arn}"]

  #   principals {
  #     type        = "AWS"
  #     identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
  #   }
  # }
}

# Attach bucket policy
resource "aws_s3_bucket_policy" "attach_policy" {
  bucket = aws_s3_bucket.static_content_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# Create Cloudfront distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.default_root_object

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_page_path    = "/${var.default_root_object}"
    response_code         = 200
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "allow-all"
    target_origin_id       = "${var.env}-${var.project_name}-${var.static_content_bucket_name}"

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"
  }

  origin {
    domain_name = aws_s3_bucket.static_content_bucket.bucket_regional_domain_name
    origin_id   = "${var.env}-${var.project_name}-${var.static_content_bucket_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}-static-content"
    },
    var.tags,
  )
}

