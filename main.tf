locals {
  producer_lambda_name = "${var.prefix}-${terraform.workspace}-producer_lambda"
  consumer_lambda_name = "${var.prefix}-${terraform.workspace}-consumer_lambda"
  alb_name             = "${var.prefix}-${terraform.workspace}-alb-test2"
  tg_name              = "${var.prefix}-${terraform.workspace}-tg"
  lamda1_role_name     = "${var.prefix}-${terraform.workspace}-lambda1-role"
  lamda2_role_name     = "${var.prefix}-${terraform.workspace}-lambda2-role"
  sg_alb_name          = "${var.prefix}-${terraform.workspace}-sg_alb"
  sg_lambdas_name      = "${var.prefix}-${terraform.workspace}-sg_lambdas"
}

######
# ALB
######

resource "aws_security_group" "alb" {
  name   = local.sg_alb_name
  vpc_id = "vpc-087b4e0167a2591a9"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["195.56.119.209/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "this" {
  name               = local.alb_name
  load_balancer_type = "application"
  subnets            = var.alb_subnets
  security_groups    = ["${aws_security_group.alb.id}"]
}

resource "aws_lb_target_group" "this" {
  name        = local.tg_name
  target_type = "lambda"
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_alb.this.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

##############
# Lambdas IAM
##############

resource "aws_iam_role" "lambda1" {
  name = local.lamda1_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_sendmessage" {
  name   = "${var.prefix}-${terraform.workspace}-sendmessage"
  path   = "/"
  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sqs:SendMessage",
            "Resource": "${aws_sqs_queue.this.arn}"
        }
    ]
}
EOT
}

resource "aws_iam_policy" "lambda_recievemessage" {
  name   = "${var.prefix}-${terraform.workspace}-recievemessage"
  path   = "/"
  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "sqs:DeleteMessage",
                "sqs:ReceiveMessage",
                "sqs:GetQueueAttributes",
                "sqs:ListQueueTags",
                "sqs:ListDeadLetterSourceQueues"
            ],
            "Resource": "${aws_sqs_queue.this.arn}"
        }
    ]
}
EOT
}

resource "aws_iam_role_policy_attachment" "lambda_sendmessage" {
  role       = aws_iam_role.lambda1.name
  policy_arn = aws_iam_policy.lambda_sendmessage.arn
}

resource "aws_iam_role_policy_attachment" "lambda1_basicexecutionrole" {
  role       = aws_iam_role.lambda1.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "lambda2" {
  name = local.lamda2_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda2_sqs_consumer" {
  role       = aws_iam_role.lambda2.name
  policy_arn = aws_iam_policy.lambda_recievemessage.arn
}

resource "aws_iam_role_policy_attachment" "lambda2_basicexecutionrole" {
  role       = aws_iam_role.lambda2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

######
# SQS
######

resource "aws_sqs_queue" "this" {
  name                      = "${var.prefix}-${terraform.workspace}-sqs"
  delay_seconds             = 60
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 5
}

##########
# Lambdas
##########

data "archive_file" "lambda1" {
  type        = "zip"
  output_path = "lambda1.zip"
  source {
    content  = file("lambdas/lambda1.py")
    filename = "lambda1.py"
  }
}

resource "aws_lambda_function" "lambda1" {
  function_name = local.producer_lambda_name
  runtime       = "python3.9"
  handler       = "lambda1.lambda_handler"
  role          = aws_iam_role.lambda1.arn

  filename         = data.archive_file.lambda1.output_path
  source_code_hash = data.archive_file.lambda1.output_base64sha256

  environment {
    variables = {
      MY_CONSTANT = "PIZZAAAA"
      QUEUE_URL   = aws_sqs_queue.this.url
    }
  }
}

resource "aws_lambda_permission" "lambda1" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda1.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.this.arn
}

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = aws_lambda_function.lambda1.arn
  depends_on       = [aws_lambda_permission.lambda1]
}

data "archive_file" "lambda2" {
  type        = "zip"
  output_path = "lambda2.zip"
  source {
    content  = file("lambdas/lambda2.py")
    filename = "lambda2.py"
  }
}

resource "aws_lambda_function" "lambda2" {
  function_name = local.consumer_lambda_name
  runtime       = "python3.9"
  handler       = "lambda2.lambda_handler"
  role          = aws_iam_role.lambda2.arn

  filename         = data.archive_file.lambda2.output_path
  source_code_hash = data.archive_file.lambda2.output_base64sha256
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.this.arn
  function_name    = aws_lambda_function.lambda2.arn
}