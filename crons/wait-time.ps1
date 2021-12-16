#!/usr/bin/env pwsh

$token = $Env:PAT
$bytes = [System.Text.Encoding]::UTF8.GetBytes(":$($token)")
$base64bytes = [System.Convert]::ToBase64String($bytes)
$headers = @{ "Authorization" = "Basic $base64bytes"}
$uri = $Env:URI
$r = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ContentType "application/json"
$count = 0

$client = New-Object Microsoft.ApplicationInsights.TelemetryClient  
$client.InstrumentationKey = $env:applicationinsightskey

$waittime= $r.value `
| Select-Object requestId, poolId, result,`
  @{Label="name"; Expression={$_.definition.name}},`
  @{Label="agent"; Expression={$_.reservedAgent.name}},`
  @{Label="queued"; Expression={(get-date $_.queueTime).ToUniversalTime()}},` 
  @{Label="assigned"; Expression={(get-date $_.assignTime).ToUniversalTime()}},` 
  @{Label="received"; Expression={(get-date $_.receiveTime).ToUniversalTime()}},` 
  @{Label="finished"; Expression={(get-date $_.finishTime).ToUniversalTime()}}`
| Where-Object {$_.name -ne 'PoolMaintenance' `
  -and $_.queued -gt (Get-Date).AddMinutes(-10).ToUniversalTime()}`
| Select-Object `
  @{Label="wait"; Expression={$_.assigned-$_.queued}}`
  
echo $waittime

$waittime | ForEach {

	$waitTimeString = $waittime[$count].wait.toString()

	if ($waitTimeString.StartsWith("-"))
	{
		echo "Starts with '-'-sign"
		
	}else {

		$anotherWaitTime=[datetime]$waitTimeString
		$dime=$waittime[$count].wait
		
		$seconds = ($dime | Measure-Object -Property TotalSeconds -Sum).Sum
		echo "Seconds:"
		echo $seconds
		
		$dictProperties = New-Object 'system.collections.generic.dictionary[[string],[string]]'
		$dictMetrics = New-Object 'system.collections.generic.dictionary[[string],[double]]'
		
		$dictProperties.Add('waittime', $seconds)
		$dictMetrics.Add('waittime', $seconds)
		$client.TrackEvent('Azure waittime', $dictProperties, $dictMetrics)
		$client.Flush()
	}
	$count++
} 

