## Terrraform backend configuration module

This module will create and configure the s3 bucket to store the tfstate files and the dynamo DB table for terraform lock files.

## Getting Started

The tfstate created by this module will be uploaded to git repository. After the s3 bucket and the dynamo DB table creation all projects will be able to track tfstate files (using a proper configuration detailed below) remotely.

### Prerequisites 

* [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) >= 0.12.x
* [AWS cli](https://docs.aws.amazon.com/pt_br/cli/latest/userguide/cli-chap-welcome.html) 

### Initialization

#### Get the module
```
terraform init
```
#### Plan the resources creation
```
terraform plan 
```
#### Start the creation and confirm 
```
terraform apply
```
### Configure project to use the s3 bucket and the dynamoDB table

#### Use this block on the project main.tf
```
terraform {
  backend "s3" {
    # The key values from this block are defined on ../inventories/{env}/s3backend
    acl            = "private"
    dynamodb_table = "tf-state-lock-dynamo"
  }
}
```
#### Create a file to configure the backend properties on your project
**e.g.:** s3_backend file
```
bucket = "claro-terraform-tfstate-storage"
region = "us-east-1"
key = "jenkins/prd/prd.tfstate"
profile = "net-ongoing"
dynamodb_table = "terraform-state-lock"
```

**bucket:** The name of the bucket created earlier with this module

**region:** The region where the bucket was created

**key:** The path and the terraform.tfstate name

**profile:** The local profile from ~/.aws/credentials which terraform will use 

**dynamodb_table:** The name of the table created earlier with this module

### Destroying the resources
#### Run the command to destroy and confirm destruction
```
terraform destroy
```