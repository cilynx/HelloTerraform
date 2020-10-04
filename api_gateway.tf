resource "aws_api_gateway_rest_api" "hello_terraform" {
  name        = "HelloTerraform"
  description = "Terraform Serverless Hello World"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.hello_terraform.id
  parent_id   = aws_api_gateway_rest_api.hello_terraform.root_resource_id
  path_part   = "{proxy+}"
}

module "cors" {
  source  = "bridgecrewio/apigateway-cors/aws"
  version = "1.1.0"

  api       = aws_api_gateway_rest_api.hello_terraform.id
  resources = [aws_api_gateway_resource.proxy.id]

  methods = ["GET"]

  origin = aws_s3_bucket.frontend.bucket_regional_domain_name
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.hello_terraform.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = "ANY"
  # In a real app, this would have a user-pool / API key(s), etc. behind it as
  # opposed to no auth.
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.hello_terraform.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello_terraform.invoke_arn
}

resource "aws_api_gateway_deployment" "hello_terraform" {
  depends_on  = [aws_api_gateway_integration.lambda]
  rest_api_id = aws_api_gateway_rest_api.hello_terraform.id
  stage_name  = "test"
}
