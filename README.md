# E3S deploy by terraform

1. Clone repository

```
git clone https://github.com/zebrunner/e3s-terraform-deploy.git && cd ./e3s-terraform-deploy
```

2. Create and configure `terraform.tfvars` file

> #### Mandatory vars:

* `environment` - Value type: string. Default value: `None`. Determines prefix in name for all e3s aws resources.
* `region` - Values type: string. Default value: `None`. Aws region in which all e3s resources will be deployed.
* `e3s_key_name` - Value type: string. Default value: `None`. Aws key name, that will be attached to e3s-server instance.
* `bucket` - Value type: object. Default value: `None`. Describes whether to create a new s3 bucket, or use an existing one. Fields:
* * `exists` - Value type: boolean.
* * `name` - Value type: string. 
* * `region`- Value type: string. 

> #### Optional vars:

- Value type: . Default value: .

* `allow_agent_ssh` - Value type: boolean. Default value: `false`. Allows ssh connection to agent instances by newly created key name only from e3s-server instance.
* `cert` - Value type: string. Default value: `None`. Certificate arn to attach to listener. If none provided, load balancer will support only http protocol.
* `enable_cloudwatch` - Value type: boolean. Default value: `false`. Enables tasks logs display at aws ecs console.
* `e3s_server_instance_type` - Value type: string. Default value: `m5n.large`. Instance type for e3s-server.
* `data_layer_remote` - Value type: boolean. Default value: `true`. Determines whether to create rds and elasticache services in aws cloud or use local ones instead.
* `profile` - Value type: string. Default value: `None`. Aws profile to use in terraform provider.
* `remote_db` - Value type: object. Default value: 
`{
    username = "postgres"
    pass     = "postgres"
}`. RDS service credentials configuration. Ignored if data_layer_remote is set to false. Fields:
* * username - Value type: string.
* * pass - Value type: string.
* `instance_types` =  Value type: object array. Default value: 
`[
    {
        weight        = 1
        instance_type = "c5a.4xlarge"
    },
    {
        weight        = 2
        instance_type = "c5a.8xlarge"
    }
]`. Determines autoscaling group instance types and their wheights. Fields:
* * `weight` - Value type: number.
* * `instance_type` - Value type: string.
* `spot_price` - Value type: object. Default value: `None`. Determines spot price per 1 weight in autoscaling group. If none specified on-demand instances will be used. Fields:
* * `linux` - Value type: string.
* * `windows` - Value type: string.
* `zebrunner` - Value type: object. Default value: `None`. Zebrunner reporting integration configuration. Fieds:
* * `host` - Value type: string.
* * `user` - Value type: string.
* * `pass` - Value type: string.

3. Init terraform providers

```
terraform init
```

4. Deploy

```
terraform apply
```