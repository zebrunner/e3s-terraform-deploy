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

### Permissions

Configured aws profile with the following policies:

1. In [terraform-policy.json](policies/terraform-policy.json) should be replaced the next placeholders:
* `{env}` - Prefix for almost all e3s aws resources
* `{region}` - Aws region in which all e3s resources will be deployed
* `{account}` - Aws account id
* `{bucket_name}` - Name of a bucket that would be used by e3s
* `{state_bucket_name}` - Bucket to save current state of terraform
* `{state_bucket_key}` - State file path in bucket
* `{dynamodb_table}` - Dynamodb table name, which will support terraform's lock mechanism
* `{dynamodb_region}` - Region of dynamodb table

2. In [terraform-view-policy.json](policies/terraform-view-policy.json) should be replaced the next placeholders:
* `{env}` - Prefix for almost all e3s aws resources
* `{region}` - Aws region in which all e3s resources will be deployed
* `{account}` - Aws account id

3. In [terraform-ec2-deploy-policy.json](policies/terraform-ec2-deploy-policy.json) should be replaced the next placeholders:
* `{env}` - Prefix for almost all e3s aws resources
* `{region}` - Aws region in which all e3s resources will be deployed
* `{account}` - Aws account id
* `{e3s-key-name}` - Key name to attach to e3s-server instance

## Deploy steps

1. Clone repository and get to deploy folder

```
git clone https://github.com/zebrunner/e3s-terraform-deploy.git && cd ./e3s-terraform-deploy/deploy
```

2. Create and configure `terraform.tfvars` file

> #### Mandatory vars:

* `environment` - Value type: string. Default value: `None`. Determines prefix in name for all e3s aws resources.
* `region` - Values type: string. Default value: `None`. Aws region in which all e3s resources will be created.
* `e3s_key_name` - Value type: string. Default value: `None`. Aws key name, that will be attached to e3s-server instance.
* `bucket` - Value type: object. Default value: `None`. Describes whether to create a new s3 bucket, or use an existing one. Fields:
* * `exists` - Value type: boolean.
* * `name` - Value type: string. 
* * `region`- Value type: string. 

> #### Optional vars:

* `cert` - Value type: string. Default value: `None`. Certificate arn to attach to listener. If none provided, load balancer will support only http protocol.
* `e3s_server_instance_type` - Value type: string. Default value: `m5n.large`. Instance type for e3s-server.
* `allow_agent_ssh` - Value type: boolean. Default value: `false`. Allows ssh connection to agent instances by newly created key name only from e3s-server instance.
* `enable_cloudwatch` - Value type: boolean. Default value: `false`. Enables tasks logs display at aws ecs console.
* `data_layer_remote` - Value type: boolean. Default value: `true`. Determines whether to create rds and elasticache services in aws cloud or use local ones instead.
* `asg_instance_metrics` - Value type: boolean. Default value: `false`. Determines whether to create service for collecting metrics for prometheus from autoscaling instaces.
* `nat` - Value type: boolean. Default value: `false`. Determines whether to create private subnets and provide internet connection by nat gateways.
* `max_az_number` - Value type: number. Default value: `3`. Determines number of availability zones to use in current region
* `profile` - Value type: string. Default value: `None`. Aws profile to use in terraform provider.
* `remote_db` - Value type: object. Default value: 
```
{
    username = "postgres"
    pass     = "postgres"
}
```
RDS service credentials configuration. Ignored if data_layer_remote is set to false. Fields:
* * username - Value type: string.
* * pass - Value type: string.
* `instance_types` =  Value type: object array. Default value:
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
Determines autoscaling group instance types and corresponding weights. Fields:
* * `weight` - Value type: number.
* * `instance_type` - Value type: string.
* `spot_price` - Value type: object. Default value: `None`. Determines spot price per 1 weight in autoscaling group. If none is specified on-demand instances are used instead. Fields:
* * `linux` - Value type: string.
* * `windows` - Value type: string.
* `zebrunner` - Value type: object. Default value: `None`. Zebrunner reporting integration configuration. Fields:
* * `host` - Value type: string.
* * `user` - Value type: string.
* * `pass` - Value type: string.

3. Create and configure config.{service}.tfbackend file.

Example of s3 backend state configure (config.s3.tfbackend file):

```
bucket         = "{state_bucket_name}"
key            = "{state_bucket_key}"
region         = "{state_bucket_region}"
dynamodb_table = "{state_dynamodb_table}"
encrypt        = true
```

4. Init terraform providers

```
terraform init -backend-config=config.{service}.tfbackend
```

5. Deploy

```
terraform apply
```

6. [Optional] User policices.

For user's use could be created [e3s-manage](policices/e3s-manage-policy.json) and [e3s-monitor](policices/e3s-monitor-policy.json) policies.
