terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

data "template_file" "lambda_source" {
  template = file("backend/main.js")
  vars = {
    origin = aws_s3_bucket.frontend.website_endpoint
  }
}

data "archive_file" "lambda_package" {
  type = "zip"
  #  source_file = "backend/main.js"
  source {
    content  = data.template_file.lambda_source.rendered
    filename = "main.js"
  }
  output_path = "backend/main.zip"
}

resource "aws_lambda_function" "hello_terraform" {
  function_name = "HelloTerraform"

  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256

  handler = "main.handler"
  runtime = "nodejs12.x"

  role = aws_iam_role.lambda_exec.arn

  tracing_config { mode = "Active" }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "helloterraform_lambda"
  assume_role_policy = file("lambda_exec_policy.json")
}

resource "aws_iam_role_policy_attachment" "aws_xray_write_only_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_terraform.function_name
  principal     = "apigateway.amazonaws.com"
  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.hello_terraform.execution_arn}/*/*"
}

output "base_url" {
  value = aws_api_gateway_deployment.hello_terraform.invoke_url
}
