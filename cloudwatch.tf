resource "random_pet" "this" {
  length = 2
}

//Create log group on Cloudwatch to receive message from Evenbridge

resource "aws_cloudwatch_log_group" "this" {
  name = "/aws/events/${random_pet.this.id}"

  tags = {
    Name = "${random_pet.this.id}-log-group"
  }
}