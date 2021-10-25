variable "prefix" {
  type        = string
  default     = "task19-imozymov"
  description = "Prefix for name of resources"
}

variable "region" {
  type        = string
  default     = "eu-central-1"
  description = "AWS region"
}

variable "personal_tag" {
  type        = string
  default     = "Task19-IMozymov"
  description = "Additional Name tag to resources"
}

variable "lambda_subnets" {
  type        = list(string)
  default     = []
  description = "Subnets for Lambda"
}

variable "lambda_sg" {
  type        = list(string)
  default     = []
  description = "Sg for lambda"
}

variable "lambda_sqs_role" {
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  description = "sqs role for lambda"
}

variable "alb_subnets" {
  type        = list(string)
  default     = ["subnet-0ad4947b529ea6577", "subnet-0056cb89cd49ab2e4"]
  description = "Subnets for ALB"
}