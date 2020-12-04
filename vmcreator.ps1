[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Have to encode the username and password
$vars = Get-Content .\env.json | ConvertFrom-Json

function Get-SessionID {
  $creds = Get-Credential
  $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($creds.UserName+':'+$creds.GetNetworkCredential().Password))

  $params = @{
    Uri         = "$($vars.uriStart)/com/vmware/cis/session"
    Headers     = @{ 
      'Authorization' = "Basic $encoded" 
      }
    Method      = 'POST'
    #Body        = $jsonSample
    ContentType = 'application/json'
  }

  return Invoke-RestMethod @params -SkipCertificateCheck

}

#$sessionID = Get-SessionID

$params2 = @{
  Uri = "$($vars.uriStart)/vcenter/vm"
  Headers = @{
    'vmware-api-session-id' = "$($vars.sessionID)"
  }
  Method = 'GET'
  ContentType = 'application/json'
}

Write-Output $params2.Headers

Invoke-RestMethod @params2 -SkipCertificateCheck
