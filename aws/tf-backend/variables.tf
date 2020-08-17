variable "aws_region" {
  type        = string
  description = "Region where the bucket will be created."
}

variable "tags" {
  type        = map(string)
  description = "Specific tags to be merged with resource name."
}

variable "tfstate_bucket_name" {
  type        = string
  description = "The bucket name to store terraform state files."
}

# variable "artifact_bucket_name" {
#   type        = string
#   description = "The bucket name for trraform tf state files"
# }

variable "dynamodb_lock_table" {
  type        = string
  description = "The DynamoDB table to store state lock info."
}

