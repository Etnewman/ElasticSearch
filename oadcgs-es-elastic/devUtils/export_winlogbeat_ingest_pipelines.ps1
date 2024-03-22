﻿##########################################################################
#
# Author:  Robert Williamson
# Initial: 02/16/2023
# Purpose: To load winlogbeat pipelines into elastic
#
##########################################################################


Write-Output "This script loads winlogbeat pipelines into Logstash."

$user = $env:USERNAME
$securedValue = Read-Host -Prompt "Enter password for $user to be able to communicate with Elastic" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securedValue)
$passwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

$winlogbeatDir = 'C:\Program Files\ELAC\winlogbeat'
if (Test-Path -Path $winlogbeatDir) {
    Set-Location $winlogbeatDir
    .\winlogbeat.exe setup --pipelines -E output.logstash.enabled=false -E output.elasticsearch.hosts=["https://elastic-node-1:9200"] -E output.elasticsearch.username=$user -E output.elasticsearch.password=$passwd -E output.elasticsearch.ssl.certificate_authorities="C:\Program Files\ELAC\winlogbeat\cachain.pem"
    Write-Output "Winlogbeat ingest pipelines loaded successfully."
}
else {
    Write-Output "ERROR: This script should only be run on a machine where winlogbeat is installed."
}
