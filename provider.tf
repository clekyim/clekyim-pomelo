provider "aws" {
  region  = var.region
  profile = "default"
}


// Uncomment if you need to keep state on s3

// terraform {
//   backend "s3" {
//     bucket         = "pomelo-challenge"
//     dynamodb_table = "pomelo-challenge"
//     key            = "pomelo-challenge.tfstate"
//     region         = "us-west-2"
//     profile        = "default"
//   }
// }
