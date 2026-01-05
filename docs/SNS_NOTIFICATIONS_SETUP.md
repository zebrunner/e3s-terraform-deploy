# SNS Notifications Setup

This guide explains how to configure SNS notifications for automatic updates in E3S.

## Prerequisites

Before running `terraform apply` with `automatic_update_enabled = true`, complete the following steps.

---

## Step 1: Create AWS Secrets Manager Secret

Create a secret in AWS Secrets Manager to store SNS topic ARNs:

```bash
aws secretsmanager create-secret \
  --name "esg/automatic-update/sns-topics" \
  --description "SNS Topic ARNs for CodeBuild success and failure notifications" \
  --region <your-region>
```

> **Note:** The secret name must match the value you set for `notification_sns_topic_secret_name` in your `terraform.tfvars`.

---

## Step 2: Configure terraform.tfvars

Add the following variables to your `terraform.tfvars` file:

```hcl
# Enable automatic updates
automatic_update_enabled = true

# AWS Secrets Manager secret name for SNS topic ARNs
notification_sns_topic_secret_name = "esg/automatic-update/sns-topics"

# SNS Topic names
notification_sns_topic_success = "build-success"
notification_sns_topic_failure = "build-failure"

# Email subscriptions for success notifications
notification_email_success = [
  "your-email@example.com"
]

# Email subscriptions for failure notifications
notification_email_failure = [
  "your-email@example.com"
]
```

---

## Troubleshooting: IAM Policy for CodeBuild

If you encounter permission errors during deployment, you may need to manually attach the SNS management policy to your CodeBuild/Terraform IAM role.

### 1. Edit the Policy File

Open [policies/sns-management-policy.json](../policies/sns-management-policy.json) and replace the following placeholders with your values:

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `${region}` | Your AWS region | `us-east-1` |
| `${account}` | Your AWS account ID | `123456789012` |
| `${notification_sns_topic_secret_name}` | Secret name | `esg/automatic-update/sns-topics` |
| `${notification_sns_topic_success}` | Success topic name | `build-success` |
| `${notification_sns_topic_failure}` | Failure topic name | `build-failure` |

### 2. Create the IAM Policy

```bash
aws iam create-policy \
  --policy-name codebuild-sns-management \
  --policy-document file://policies/sns-management-policy.json
```

### 3. Attach the Policy to CodeBuild Role

```bash
aws iam attach-role-policy \
  --role-name <your-codebuild-role-name> \
  --policy-arn arn:aws:iam::<account-id>:policy/codebuild-sns-management
```

---

## Verification

After running `terraform apply`, verify the setup:

1. Check that SNS topics were created:
   ```bash
   aws sns list-topics --region <your-region>
   ```

2. Check that the secret was updated with topic ARNs:
   ```bash
   aws secretsmanager get-secret-value \
     --secret-id "esg/automatic-update/sns-topics" \
     --region <your-region>
   ```

3. Confirm email subscriptions (check your inbox for confirmation emails from AWS SNS)
