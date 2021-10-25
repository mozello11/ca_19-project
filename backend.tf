
terraform {
  backend "s3" {
    bucket = "cloudacademy-state"
    key    = "imozymov_task19/terraform.tfstate"
    region = "eu-central-1"
  }
}
