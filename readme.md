<h1> Pomelo DevOps (AWS Serverless) Challenge </h1>

<h3> My name is Chayakorn Lekyim </h3>

## Terraform

To run the terraform scripts, please make sure you have aws cli installed and have your credentail saved as a default profile. Then simple run with:

`terraform init`

`terraform plan`

This will show up all the list of changes that will build on the AWS. Checking and if it looks fine, then run:

`terraform apply`

The terraform will setup everything that are mentioned in the terraform file for the first run.


## Notes
- You can update the provider.tf to save your state file on s3.
- You may need to update the variable.tf, line 2 for your AWS account ID, and line 6 to match your current region.

