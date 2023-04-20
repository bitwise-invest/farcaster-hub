variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "us-east-1"
}

variable "aws_availability_zone" {
  description = "The AWS availability zone."
  default     = "us-east-1d"
}

variable "key_name" {
  description = "The key pair name to login to your EC2 instance"
  default     = "samplekey" # Set to your keyname
}