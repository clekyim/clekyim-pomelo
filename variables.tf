variable account_id {
  default = "0123456789012"
}

variable "region" {
    default = "us-west-2"
}

### API GW ###
variable "environment" {
  default = "dev"
}

### SQS ###
variable "allowed_arns" {
  type        = list
  default     = null
}

variable "delay_seconds" {
  type = number  
  default =  90
}
variable "max_message_size" {
  type = number
  default =  262144
}
variable "message_retention_seconds" {
  type = number
  default =  86400
}
variable "receive_wait_time_seconds" {
  type = number  
  default =  10
}
variable "visibility_timeout_seconds" {
  type = number
  default =  90
}
variable "content_based_deduplication" {
  type = bool  
  default =  false
}

