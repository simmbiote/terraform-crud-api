# terraform-crud-api

A terraform set up for provisioning an AWS API Gateway, Lambda function, DynamoDB table and associated CloudWatch logs.

## Requirements

### AWS profile

If not done already, an AWS profile needs to be configured on your device. You can do this via the AWS CLI (v2) - https://aws.amazon.com/cli/
Run `aws configure`
You will be prompted for your for your AWS Access Key and Secret Key.

### Terraform cli

You'll need the terraform cli to provision the infrastructure.
See https://www.terraform.io/ for installation details.

## Overview

This terraform set will provision:

- A DynamoDB table named ProductCollections. This can be easily changed in the code.
- A Lambda function
- An AWS HTTP API Gateway
- CloudWatch log groups for API Gateway and Lambda.
- AWS role policies for invoking the lambda function and creating logs.

## Provisioning AWS Infrastructure

1. cd into terraform/
2. Zip the lambda function file - `zip -r lambda.zip index.js `
3. Run `terraform init` the first time.
4. Run `terraform plan` to do a dry run.
5. If satisfied, run `terraform apply` and follow the prompts.

Once complete you will be given the API URL in the command output.

## API Routes

### GET /items

Get all your items.

### GET /items/{id}

Get details of an item with the given id.

### PUT /items

Create or Update items. To update an item, include {"id": "someId"} in the body.
ID's are not assigned to items by default in DynamoDB. The lambda function will assign a timestamp by default, so supplying an id is not required.

### DELETE /items/{id}

Delete an item with the given ID.
