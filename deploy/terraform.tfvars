profile = "terraform"

environment = "prod"
region = "us-east-1"

e3s_server_instance_type = "m5n.large"
e3s_key_pair_name = "e3s-prod-key-pair"

# agent_key_pair = {
#     generate = true
#     save_private_key_in_file = true
#     save_public_key_in_file = false
#     private_key_file_path = ""
#     public_key_file_path = ""
# }

bucket = {
    exists = false
    name = "e3s-prod-assets"
    region = "us-east-1"
}

enable_cloudwatch = false
nat = true
max_az_number = 3

data_layer_remote = true
remote_db = {
    username = "postgres"
    pass = "uI6LPNC54K3LnP4E7y4u9ihi"
}

instance_types = [
    {
        weight = 1
        instance_type = "c5a.4xlarge"
    },
    {
        weight = 2
        instance_type = "c5a.8xlarge"
    }
]

spot_price = {
    linux   = "1"
    windows = "1"
}

zebrunner = {
    host = "https://zebruner.com"
    user = "user"
    pass = "pass"
}
