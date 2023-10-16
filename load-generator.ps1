$ehNameSpace = "<enter-event-hub-namespace-name>"
$ehName = "<enter-event-hub-name>"
$keyname = "<enter-sender-policy-name>"
$key = "<key>"

# Make no changes beyond this point

while ($true)
{

    $playerName = @('Henry', 'Gerja', 'Niels', 'Erwin', 'Eduard', 'Hugo', 'Wendy') | Get-Random
    $gameName = @('Racer', 'Shooter', 'Puzzle', 'Strategy') | Get-Random
    $score = Get-Random -Minimum 1 -Maximum 100
    $timestamp = Get-Date -Format "o"

    [Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null

    $URI = "{0}.servicebus.windows.net/{1}" -f @($ehNameSpace,$ehName)
    $encodedURI = [System.Web.HttpUtility]::UrlEncode($URI)

    $expiry = [string](([DateTimeOffset]::Now.ToUnixTimeSeconds())+3600)
    $stringToSign = [System.Web.HttpUtility]::UrlEncode($URI) + "`n" + $expiry

    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Text.Encoding]::ASCII.GetBytes($key)

    $signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($stringToSign))
    $signature = [System.Web.HttpUtility]::UrlEncode([Convert]::ToBase64String($signature))

    $body = "{'Player':'$playerName', 'Game':'$gameName', 'Score': $score, 'Timestamp': '$timestamp'}"

    Write-Output($body)

    $headers = @{
                "Authorization"="SharedAccessSignature sr=" + $encodedURI + "&sig=" + $signature + "&se=" + $expiry + "&skn=" + $keyname;
                "Content-Type"="application/atom+xml;type=entry;charset=utf-8"; # must be this
                }

    $method = "POST"
    $dest = 'https://' +$URI  +'/messages?timeout=60&api-version=2014-01'

    Invoke-RestMethod -Uri $dest -Method $method -Headers $headers -Body $body -Verbose

    $delay = Get-Random -Minimum 250 -Maximum 900

    Start-Sleep -Milliseconds $delay
}
