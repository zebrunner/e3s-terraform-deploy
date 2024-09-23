<powershell>
    Import-Module ECSTools
    [Environment]::SetEnvironmentVariable("ECS_LOGLEVEL", "info", "Machine")
    [Environment]::SetEnvironmentVariable("ECS_LOGLEVEL_ON_INSTANCE", "info", "Machine")
    [Environment]::SetEnvironmentVariable("ECS_CONTAINER_STOP_TIMEOUT", "15s", "Machine")
    [Environment]::SetEnvironmentVariable("ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION", "5m", "Machine")
    [Environment]::SetEnvironmentVariable("ECS_ENABLE_SPOT_INSTANCE_DRAINING", $TRUE, "Machine")
    [Environment]::SetEnvironmentVariable("ECS_PULL_DEPENDENT_CONTAINERS_UPFRONT", $TRUE, "Machine")
    [Environment]::SetEnvironmentVariable("ECS_ENABLE_CONTAINER_METADATA", "$TRUE", "Machine")
    [Environment]::SetEnvironmentVariable("ECS_IMAGE_PULL_BEHAVIOR", "prefer-cached", "Machine")
    
    Initialize-ECSAgent -Cluster '${cluster_name}' -EnableTaskIAMRole -AwsvpcBlockIMDS -LoggingDrivers '["json-file","awslogs"]' -EnableTaskENI -AwsvpcAdditionalLocalRoutes '["${cidr_block}"]'

    Set-TimeZone -Name "Pacific Standard Time"

    if (${instance_metrics}){
        New-NetFirewallRule -DisplayName 'Exporter' `
                    -LocalPort 9182 -Action Allow `
                    -Profile 'Public' `
                    -Protocol TCP `
                    -Direction Inbound

                    Start-Process "C:\Program Files\Exporter\windows_exporter.exe" -ArgumentList '--web.listen-address=:9183', '--collectors.enabled "[defaults],process,container"' -RedirectStandardError "C:\Program Files\Exporter\exporter.logs" -WindowStyle Hidden
    }
</powershell>
<persist>true</persist>
--web.listen-address=:9182