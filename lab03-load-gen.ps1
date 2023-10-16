$ehNameSpace = "<update>"

$scoresEhName = "game-scores"
$durationEhName = "game-durations"

$keyname = "<update>"
$key = "<update>"

# Make no changes beyond this point

Function Send-To-EventHub($ehNameSpace, $ehName, $keyname, $key, $body) {
    $URI = "{0}.servicebus.windows.net/{1}" -f @($ehNameSpace, $ehName)
    $encodedURI = [System.Web.HttpUtility]::UrlEncode($URI)

    $expiry = [string](([DateTimeOffset]::Now.ToUnixTimeSeconds())+3600)
    $stringToSign = [System.Web.HttpUtility]::UrlEncode($URI) + "`n" + $expiry

    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Text.Encoding]::ASCII.GetBytes($key)

    $signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($stringToSign))
    $signature = [System.Web.HttpUtility]::UrlEncode([Convert]::ToBase64String($signature))
     
    Write-Output("$body to $URI")

    $headers = @{
                "Authorization"="SharedAccessSignature sr=" + $encodedURI + "&sig=" + $signature + "&se=" + $expiry + "&skn=" + $keyname;
                "Content-Type"="application/atom+xml;type=entry;charset=utf-8"; # must be this
                }

    $method = "POST"
    $dest = 'https://' +$URI  +'/messages?timeout=60&api-version=2014-01'

    Invoke-RestMethod -Uri $dest -Method $method -Headers $headers -Body $body -Verbose
}

[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null

while ($true)
{

    $playerName = @('Henry', 'Gerja', 'Niels', 'Erwin', 'Eduard', 'Hugo', 'Wendy') | Get-Random
    $gameName = @('Racer', 'Shooter', 'Puzzle', 'Strategy') | Get-Random
    $score = Get-Random -Minimum 1 -Maximum 100
    $duration = Get-Random -Minimum 1 -Maximum 3600
    $timestamp = Get-Date -Format "o"

    $scoreBody = "{'Player':'$playerName', 'Game':'$gameName', 'Score': $score, 'Timestamp': '$timestamp'}"
    
    Send-To-EventHub $ehNameSpace $scoresEhName $keyname $key $scoreBody

    $durationBody = "{'Player':'$playerName', 'Game':'$gameName', 'duration': $duration, 'Timestamp': '$timestamp'}"
    
    Send-To-EventHub $ehNameSpace $durationEhName $keyname $key $durationBody

    $delay = Get-Random -Minimum 250 -Maximum 900

    Start-Sleep -Milliseconds $delay
}
