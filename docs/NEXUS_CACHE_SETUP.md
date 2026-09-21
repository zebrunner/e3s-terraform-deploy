# Nexus Maven Cache Setup

This guide tells how to deploy the internal Nexus Maven cache in E3S.

The cache proxies Maven Central and stores artifacts in S3. Test runs then get artifacts from the cache. This prevents rate-limit ("too many requests") errors from public repositories.

The endpoint is private. Only resources inside the VPC can reach it. The ALB uses HTTP and has no internet access.

## Prerequisites

Before you run `terraform apply` with `nexus_enabled = true`, complete the steps below.

---

## Step 1: Configure terraform.tfvars

Add these variables to your `terraform.tfvars` file:

```hcl
# Enable the internal Nexus Maven cache
nexus_enabled = true

# S3 bucket for the Nexus blob store.
# Set exists = false to create the bucket, or exists = true to reuse one.
nexus_s3_bucket = {
  exists = false
  name   = "e3s-test-nexus-blobs"
}

# Admin password for the Nexus UI/API.
# Empty keeps the random password that Nexus generates on first boot.
# Read the random password through SSM if you keep it empty.
nexus_admin_password = ""
```

Optional variables have safe defaults:

| Variable | Default | Description |
|----------|---------|-------------|
| `nexus_instance_type` | `m5.large` | EC2 instance type for the Nexus host |
| `nexus_root_volume_size` | `40` | Root EBS volume size in GB (blobs live in S3) |
| `nexus_image` | `sonatype/nexus3:latest` | Nexus container image |
| `nexus_maven_central_url` | `https://repo1.maven.apache.org/maven2/` | Upstream repository that the proxy caches |

> **Note:** `nexus_s3_bucket.name` must not be empty when `nexus_enabled = true`.

---

## Step 2: Edit the Policy File

Open [policies/nexus-deploy-policy.json](../policies/nexus-deploy-policy.json). Replace these placeholders with your values:

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{resource_prefix}` | Prefix for E3S AWS resources | `e3s-test` |
| `{region}` | Your AWS region | `us-west-2` |
| `{account}` | Your AWS account ID | `123456789012` |
| `{nexus_bucket_name}` | Nexus blob store bucket name | `e3s-test-nexus-blobs` |

This policy grants the deployer permission to create the Nexus S3 bucket, the IAM role, and the internal ALB.

---

## Step 3: Attach IAM Policy to the Terraform Role

Create the policy and attach it to your Terraform IAM role.

### 3.1. Create the IAM Policy

```bash
aws iam create-policy \
  --policy-name nexus-deploy-policy \
  --policy-document file://policies/nexus-deploy-policy.json
```

### 3.2. Attach the Policy to the Terraform Role

```bash
aws iam attach-role-policy \
  --role-name <your-terraform-iam-role> \
  --policy-arn arn:aws:iam::<account-id>:policy/nexus-deploy-policy
```

---

## Automatic Updates: CodeBuild Permissions

When `automatic_update_enabled = true`, Terraform runs again inside CodeBuild. The CodeBuild role must hold the Nexus permissions before that build runs.

Terraform attaches the CodeBuild grant through `aws_iam_role_policy.codebuild_nexus_management`. Terraform creates this grant when both `automatic_update_enabled` and `nexus_enabled` are true.

The grant lands during a normal `terraform apply`. A later CodeBuild build runs on infrastructure that already exists, so the role already holds the permission.

### Bootstrap note

The first apply that turns Nexus on must run under an identity that already has the Nexus permissions. Use one of these identities:

- The human deployer, with `nexus-deploy-policy.json` attached (Step 3), or
- A CodeBuild role that received the grant in a previous apply.

If you can run only through CodeBuild, attach the policy to the CodeBuild role by hand before the build:

```bash
aws iam attach-role-policy \
  --role-name <your-codebuild-role-name> \
  --policy-arn arn:aws:iam::<account-id>:policy/nexus-deploy-policy
```

Terraform does not remove this manual attachment. The CodeBuild role has no exclusive policy management. A manual grant and the Terraform-managed grant can both exist. IAM permissions are additive, so this causes no conflict.

---

## Verification

After `terraform apply` completes, verify the setup.

1. Read the internal cache URL:
   ```bash
   terraform output nexus_url
   ```
   The URL has this form: `http://<internal-alb-dns>/repository/maven-public/`.

2. Check the Nexus status from a host inside the VPC:
   ```bash
   curl -s http://<internal-alb-dns>/service/rest/v1/status
   ```
   A healthy Nexus returns HTTP 200.

3. Confirm that the target is healthy:
   ```bash
   aws elbv2 describe-target-health \
     --target-group-arn <nexus-target-group-arn> \
     --region <your-region>
   ```

> **Note:** The ALB is internal. You must run the checks from a host inside the VPC, such as an E3S agent instance.
