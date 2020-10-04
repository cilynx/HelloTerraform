resource "aws_kms_key" "mykey" {
  description             = "Used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "c3d64c05-3c3e-43e1-813e-5035bec7ada8-logs"
  acl    = "log-delivery-write"
  versioning {
    enabled = true
    # Terraform must be integrated w/ MFA in order to be able to apply this
    # setting.  That integration seems to be a PITA, so calling it out of
    # scope for this exercise.

    # mfa_delete = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.mykey.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
  # I didn't find a way to manage logging for the logging bucket itself in
  # Terraform without running into either cyclic or self-reference issues.
  # Curious to know if there is a best practice to solve this problem or if the
  # best bet is just to manually define and lock down the logging bucket first.

  # logging {
  #   target_bucket = aws_s3_bucket.meta_log_bucket.id
  #   target_prefix = "log/"
  # }
}
