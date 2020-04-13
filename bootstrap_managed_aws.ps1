<# Custom Script for Windows #>

# Bootstrap script for Windows
#
$ip = Invoke-WebRequest -Uri ifconfig.me -Method Get -UseBasicParsing | select -Expand Content
echo $ip

# Create user for initial config
$pw = ConvertTo-SecureString "8fvxRsZxbR9HnOSJ" -AsPlainText -Force
New-LocalUser "icdsadmin" -Password $pw -FullName "ICDS Administrator" -Description "ICDS account for initial config."
Add-LocalGroupMember -Group "Administrators" -Member "icdsadmin"

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

Start-Sleep -s 30

$configURL = "https://ec2-18-224-32-194.us-east-2.compute.amazonaws.com:443"
$configKey = "5dc068b241b38597bd3f62395e998256"
$configTemplate = "22"
# $extraVars = "{extra_vars: {}}"
# .\request_tower_configuration.ps1 $configURL $configKey $configTemplate
$data = @{
    host_config_key=$configKey
}
echo $ip
echo "Invoking web request"
Invoke-WebRequest -UseBasicParsing -Headers @{'X-Forwarded-For'=$ip} -ContentType application/json -Method POST -Body (ConvertTo-Json $data) -Uri $configURL/api/v2/job_templates/$configTemplate/callback/


# End
