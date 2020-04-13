# Bootstrap script for Windows
#

# Create user for initial config
# $pw = ConvertTo-SecureString "8fvxRsZxbR9HnOSJ" -AsPlainText -Force
# New-LocalUser "icdsadmin" -Password $pw -FullName "ICDS Administrator" -Description "ICDS account for initial config."
# Add-LocalGroupMember -Group "Administrators" -Member "icdsadmin"

# $admin = [adsi]("WinNT://./mcmpadmin, user")
# $admin.PSBase.Invoke("SetPassword", "myTempPassword123!")

# Config WinRM
Invoke-Expression ((New-Object System.Net.Webclient).DownloadString('https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1'))

# Invoke Ansible for initial config
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# $url = "https://raw.githubusercontent.com/invhariharan77/myapp/master/bootstrap_artifacts.zip"
# $output = "bootstrap_artifacts.zip"
# (New-Object System.Net.WebClient).DownloadFile($url, $output)
# Expand-Archive "bootstrap_artifacts.zip" -DestinationPath "." -Force

$configURL = "https://ec2-18-224-32-194.us-east-2.compute.amazonaws.com:443"
$configKey = "0df114828b39ed1e1a765dc45d710ad2"
$configTemplate = "13"
# $extraVars = "{extra_vars: {ansible_become: false, ansible_winrm_server_cert_validation: ignore}}"
# $extraVars = "{extra_vars: {}}"
# .\request_tower_configuration.ps1 $configURL $configKey $configTemplate
# Invoke-Expression ((New-Object System.Net.Webclient).DownloadString('https://raw.githubusercontent.com/invhariharan77/myapp/master/request_tower_configuration.ps1'))
$data = @{
    host_config_key=$configKey
}
Invoke-WebRequest -UseBasicParsing -ContentType application/json -Method POST -Body (ConvertTo-Json $data) -Uri $configURL/api/v2/job_templates/$configTemplate/callback/

# [Environment]::Exit(0)

# End
