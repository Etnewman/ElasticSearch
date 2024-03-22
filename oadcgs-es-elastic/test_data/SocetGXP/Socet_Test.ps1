####Pre-Requisites:
#      - filebeat-<version>-x86_64.zip extracted into C:\temp
#      - oadcgs-es-elastic-arts-SocetGXP-TestLogs-<version>.zip extracted into C:\temp
#      - cachain.pem copied to C:\temp
if (!(Test-Path -Path C:\temp\filebeat-*\filebeat.exe ))
{
    Write-Host "Extract Filebeat .zip into C:\temp"
}
elseif (!(Test-Path -Path C:\temp\socet_test.yml ))
{
    Write-Host "Extract Socet TestFiles .zip into C:\temp"
}
elseif (!(Test-Path -Path C:\temp\cachain.pem ))
{
    Write-Host "Copy cachain.pem to C:\temp"
}
else
{
    ####Set up Logstash output
    Write-Host "Updating socet_test.yml"
    $fullName = [System.Net.Dns]::GetHostByName(($env:COMPUTERNAME)).HostName
    $rootName = $fullName.Substring(0,$fullName.IndexOf('.'))
    $logstash = "logstash-" + $rootName.subString(0,3)
    $destString = "output.logstash: `n  hosts: [""" + $logstash + ":5044""]`n  ssl.certificate_authorities: ['C:\temp\cachain.pem'] "
    Add-Content -Path "C:\temp\socet_test.yml" -Value $destString -Encoding Ascii

    ### Create log files
    New-Item -Path C:\temp\logs -ItemType Directory -Force | out-null
    ((Get-Content -path C:/temp/SocetGxp.log-test -Raw) -replace 'yyyy-mm-dd',(Get-Date -Format "yyyy-MM-dd") -replace 'yyyy/mm/dd',(Get-Date -Format "yyyy/MM/dd")) | Out-File -Encoding ASCII -NoNewLine -Append C:/temp/logs/SocetGxp.log-test
    ((Get-Content -path C:/temp/SocetGxp.log-govcloud -Raw) -replace 'yyyy-mm-dd',(Get-Date -Format "yyyy-MM-dd") -replace 'yyyy/mm/dd',(Get-Date -Format "yyyy/MM/dd")) | Out-File -Encoding ASCII -NoNewLine -Append C:/temp/logs/SocetGxp.log-unclass-govcloud
    ((Get-Content -path C:/temp/AFPluginLog0.txt -Raw) -replace 'yyyy-mm-dd',(Get-Date -Format "yyyy-MM-dd") -replace 'yyyy/mm/dd',(Get-Date -Format "yyyy/MM/dd")) | Out-File -Encoding ASCII -NoNewLine -Append C:/temp/logs/AFPluginLog0.txt

    ####Run Filebeat
    Write-Host "Running Filebeat -c C:\temp\socet_test.yml"
    $filebeat=(Get-ChildItem -Path C:\temp -Name -include filebeat-* -attributes Directory)
    cd $filebeat
    ./filebeat.exe -c C:\temp\socet_test.yml --once
    cd ..

    Write-Host "Please clean up C:\temp when testing is complete."
}#end if
