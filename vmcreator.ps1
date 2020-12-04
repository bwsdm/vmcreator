[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Get sessionID and server path
$vars = Get-Content .\env.json | ConvertFrom-Json

function Get-SessionID {
  $creds = Get-Credential
  $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes( `
    $creds.UserName+':'+$creds.GetNetworkCredential().Password))

  $params = @{
    Uri         = "$($vars.uriStart)/com/vmware/cis/session"
    Headers     = @{ 
      'Authorization' = "Basic $encoded" 
      }
    Method      = 'POST'
    ContentType = 'application/json'
  }
  $sID = Invoke-RestMethod @params -SkipCertificateCheck

  return $sID.Value
}


$params2 = @{
  Uri = "$($vars.uriStart)/vcenter/vm"
  Headers = @{
    'vmware-api-session-id' = "$($vars.sessionID)"
  }
  Method = 'GET'
  ContentType = 'application/json'
}

# Need to loop back and try again if failed
# This naively assumes the only error will be due to session ID issues
do {
  
  $err = $null

  Invoke-RestMethod @params2 -SkipCertificateCheck `
    -ErrorAction SilentlyContinue -ErrorVariable err

  if($err) {
    Write-Output "Getting a new session ID"
    $sessionID = Get-SessionID
    $vars.SessionID = $sessionID
    $params2.Headers.Add('vmware-api-session-id', $sessionID)
    $vars | ConvertTo-Json | Out-File .\env.json

  }
}
while($err)
