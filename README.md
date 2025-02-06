# E3S deploy by terraform

Feel free to support the development with a [**donation**](https://www.paypal.com/donate/?hosted_button_id=MNHYYCYHAKUVA) for the next improvements.

<p align="center">
  <a href="https://zebrunner.com/"><img alt="Zebrunner" src="https://github.com/zebrunner/zebrunner/raw/master/docs/img/zebrunner_intro.png"></a>
</p>

## Prerequisites

### AWS Marketplace subscriptions

#### [Zebrunner Selenium Grid Agent](https://aws.amazon.com/marketplace/pp/prodview-qykvcpnstrlzi?sr=0-2&ref_=beagle&applicationId=AWSMPContessa)

Linux based ECS optimized instance with embedded Zebrunner tuning for scalable and reliable browser images usage

#### [Zebrunner Selenium Grid Agent - Windows](https://aws.amazon.com/marketplace/pp/prodview-wmwdyq54i36jy?sr=0-4&ref_=beagle&applicationId=AWSMPContessa)

Windows based ECS optimized instance with embedded Zebrunner tuning for scalable and reliable browser images usage

### Software

* Installed git
* Installed terraform
* Installed aws cli

### AWS resources

* Dynamodb table that will store terraform lock. The table should contain only partition key with name `LockID`.

### Permissions

Configured aws profile with the following policies:

1. In [terraform-policy.json](policies/terraform-policy.json) should be replaced the next placeholders:
    * `{env}` - Prefix for almost all e3s aws resources
    * `{region}` - Aws region in which all e3s resources will be deployed
    * `{account}` - Aws account id
    * `{bucket_name}` - Name of a bucket that will store assets (videos, logs, etc.) created by e3s
    * `{state_bucket_name}` - Bucket to save terraform state
    * `{state_bucket_key}` - Key of the state file stored in `{state_bucket_name}`
    * `{dynamodb_table}` - Dynamodb table name, which will support terraform lock mechanism
    * `{dynamodb_region}` - Region of the `{dynamodb_table}`

2. In [terraform-ec2-view-policy.json](policies/terraform-ec2-view-policy.json) should be replaced the next
   placeholders:
    * `{env}` - Prefix for almost all e3s aws resources
    * `{region}` - Aws region in which all e3s resources will be deployed
    * `{account}` - Aws account id

3. In [terraform-ec2-deploy-policy.json](policies/terraform-ec2-deploy-policy.json) should be replaced the next
   placeholders:
    * `{env}` - Prefix for almost all e3s aws resources
    * `{region}` - Aws region in which all e3s resources will be deployed
    * `{account}` - Aws account id
    * `{e3s-key-name}` - Key pair name to attach to e3s-server instance

## Deploy steps

### 1. Clone repository and navigate to deploy folder

```
git clone https://github.com/zebrunner/e3s-terraform-deploy.git && cd ./e3s-terraform-deploy/deploy
```

### 2. Adjust values in `terraform.tfvars` file

> #### Mandatory vars:

* `environment` - part of the name of all e3s resources. Most of the resources will have name like `e3s-{environment}-<resource-name>`.
* `region` - AWS region in which all e3s resources will be deployed.
* `e3s_key_pair_name` - AWS key pair name, that will be attached to e3s-server instance.
* `bucket` - (object) Definition of the bucket where all e3s assets are stored. Contains the following fields:
    * `exists` - (boolean) determines whether a new bucket should be created or not.
    * `name`
    * `region`

> #### Optional vars:

* `cert` - TLS certificate arn to attach to ELB listener. If none provided, load balancer will only support http protocol.
* `e3s_server_instance_type` - Instance type of the e3s-server. Default value: `m5n.large`.
* `allow_agent_ssh` - Value type: boolean. Default value: `false`. Allows ssh connection to agent instances by newly
  created key name only from e3s-server instance.
* `enable_cloudwatch` - (boolean) Specifies if task logs should be stored in cloudwatch. Default value: `false`.
* `data_layer_remote` - (boolean) Determines whether to create rds and elasticache services or use local ones instead. Default value: `true`.
* `nat` - (boolean) Determines whether to create private subnets and provide internet connections via nat gateways. Default value: `false`.
* `max_az_number` - (number) Determines number of availability zones to use in the specified region. Default value: `3`.
* `profile` - AWS profile to be used by terraform. Default value: `default`.
* `remote_db` - (object) Configuration of RDS service credentials. Ignored if `data_layer_remote` is `false`. Fields: `username` and `pass`. Default value:
    ```
    {
        username = "postgres"
        pass     = "postgres"
    }
    ```
* `instance_types` = (list of objects) Determines autoscaling group instance types and corresponding weights.
    Fields:
        * `weight` - (number)
        * `instance_type`
    Default value:
    ```
    [
        {
            weight        = 1
            instance_type = "c5a.4xlarge"
        },
        {
            weight        = 2
            instance_type = "c5a.8xlarge"
        }
    ]
    ```
* `spot_price` - (object) spot price per 1 weight in autoscaling group. If not specified, on-demand instances are used instead. Fields: `linux` and `windows`
* `zebrunner` - (object) Configuration of Zebrunner integration. Fields: `host`, `user`, and `pass`.

### 3. Create and configure config.{service}.tfbackend file.

Example of s3 backend state configuration exists in `deploy` folder (config.s3.tfbackend file).

### 4. Init terraform providers

```
terraform init -backend-config=config.{service}.tfbackend
```
For example
```
terraform init -backend-config=config.s3.tfbackend
```

### 5. Deploy

```
terraform apply
```

### 6. [Optional] User policices.

For user's use could be created [e3s-manage](policices/e3s-manage-policy.json)
and [e3s-monitor](policices/e3s-monitor-policy.json) policies.
