#!/bin/bash
CREDS=$(aws sts assume-role \
  --role-arn arn:aws:iam::659932254483:role/vs-terraform-code-build \
  --role-session-name codebuild-terraform \
  --output json)

export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.Credentials.SessionToken')

aws sts get-caller-identity