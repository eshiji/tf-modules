# Terrraform modules
Repo with Terraform modules to setup AWS applications configurations.

# Prerequisites
- Terraform version >= [0.12](https://releases.hashicorp.com/terraform/0.12.29/) ([tfswitch](https://tfswitch.warrensbox.com/) is a good option to manage terraform versions)

# Getting started
* The modules will upload de tfstate to a S3 bucket and use DynamoDB to storage lock files to manage concurrency.
* The states are also used to data from a module and use it as input to another (remote_state).  
* First, use the tf-backend module to get the environment prepared **(S3 tfstate storage and DynamoDB table)**.

Learn more about s3 backend type [here](https://www.terraform.io/docs/backends/types/s3.html).

Learn more about remote_state [here](https://www.terraform.io/docs/providers/terraform/d/remote_state.html)
