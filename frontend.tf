resource "aws_s3_bucket" "frontend" {
  bucket = "bbad86bf-e69b-49ba-b02f-54911cb672ab-frontend"
  # As a static website bucket, this is world-readable and unencrypted by
  # design.  Looks like I could suppress the alerts with `--skip-check`, but I
  # like the visibility.
  acl = "public-read"
  website { index_document = "index.html" }
  versioning {
    enabled = true
    # Terraform must be integrated w/ MFA in order to be able to apply this
    # setting.  That integration seems to be a PITA, so calling it out of
    # scope for this exercise.

    # mfa_delete = true
  }
  # server_side_encryption_configuration {
  #   rule {
  #     apply_server_side_encryption_by_default {
  #       kms_master_key_id = aws_kms_key.mykey.arn
  #       sse_algorithm     = "aws:kms"
  #     }
  #   }
  # }
  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "log/"
  }
}

resource "aws_s3_bucket_object" "frontend_upload" {
  bucket       = aws_s3_bucket.frontend.id
  acl          = "public-read"
  key          = "index.html"
  content_type = "text/html"
  content      = data.template_file.frontend_source.rendered
  etag         = md5(file("frontend/index.html"))
}

data "template_file" "frontend_source" {
  template = file("frontend/index.html")
  vars = {
    invoke_url = aws_api_gateway_deployment.hello_terraform.invoke_url
  }
}
