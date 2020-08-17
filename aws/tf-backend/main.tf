# Create s3 bucket to store tfstate files 
resource "aws_s3_bucket" "terraform-tfstate-storage" {
  bucket = var.tfstate_bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    {
      "Name" = "terraform-tfstate-storage"
    },
    var.tags,
  )
}

# Create s3 bucket to store artifact files
# resource "aws_s3_bucket" "artifact-storage" {
#   bucket = var.artifact_bucket_name
#   acl    = "private"
#   region = var.aws_region

#   versioning {
#     enabled = true
#   }

#   lifecycle {
#     prevent_destroy = true
#   }

#   tags = merge(
#     {
#       "Name" = "terraform-tfstate-storage"
#     },
#     var.tags,
#   )
# }

# Create Dynamo table for lock file
resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name           = var.dynamodb_lock_table
  hash_key       = "LockID"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    {
      "Name" = var.dynamodb_lock_table
    },
    var.tags,
  )
}

