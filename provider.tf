provider "aws" {
  profile = "default"
  region  = var.region
  default_tags {
    tags = {
      Environment = "${terraform.workspace}"
      Name        = "${var.personal_tag}"
    }
  }
}