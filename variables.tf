variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "us-west-1"
}

variable "aws_availability_zone" {
  description = "The AWS availability zone."
  default     = "us-west-1a"
}

# You generally want the Ubuntu Server 22.04 LTS 64-bit (x86) AMI ID
# on us-east-1, you want ami-007855ac798b5175e
# on us-west-1, you want ami-014d05e6b24240371
variable "aws_ec2_ami_id" {
  description = "AMI ID for the desired instance"
  default = "ami-014d05e6b24240371"
}

variable "key_name" {
  description = "The key pair name to login to your EC2 instance"
  default     = "samplekey" # Set to your keyname
}