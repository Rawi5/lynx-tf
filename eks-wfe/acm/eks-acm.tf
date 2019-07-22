# Variables
variable "cluster-name" {}



resource "aws_acm_certificate" "stacklynx-cert" {
  domain_name               = "stacklynx.com"
  subject_alternative_names = ["*.corp.stacklynx.com", "*.cloud.stacklynx.com", "*.stackaero.com", "*.demo.stacklynx.com"]
  validation_method         = "DNS"

  tags = {
    Environment = "prod"
  }

  lifecycle {
    create_before_destroy = true
  }
}
