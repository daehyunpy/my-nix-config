terraform {
  backend "s3" {
    key = "github/terraform.tfstate"
  }
}
