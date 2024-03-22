#!Powershell
#   Create GXP Xplorer test logs with today's date
#   If Filebeat is not automatically picking up logs, set it up and run manually

####Pre-Requisites:
#   - oadcgs-es-elastic-arts-SocetGXP-TestLogs-<version>.zip extracted into C:\temp
#   And Either:
#      - GXP Xplorer installed
#      - Filebeat installed and running
#   Or:
#      - filebeat-<version>-x86_64.zip extracted into C:\temp
#      - cachain.pem copied to C:\temp

### If GXP Xplorer is not installed, set up temporary ingest in C:\Temp
if ( "$GXP_XPLORER_DATA" -eq "" )
{
    Set-Variable -Name GXP_XPLORER_DATA -Value "C:\temp"
    New-Item -Path $GXP_XPLORER_DATA\logs\filebeat -ItemType Directory -Force | out-null

    if (!(Test-Path -Path C:\temp\filebeat-*\filebeat.exe ))
    {
        Write-Host "ERROR: Extract Filebeat .zip into C:\temp before running"
        return
    }
    elseif (!(Test-Path -Path C:\temp\gxp_xplorer-test.yml ))
    {
        Write-Host "ERROR: Extract Socet TestFiles .zip into C:\temp before running"
        return
    }
    elseif (!(Test-Path -Path C:\temp\cachain.pem ))
    {
        Write-Host "ERROR: Copy cachain.pem to C:\temp before running"
        return
    }
}
if (!(Test-Path -Path C:\temp\ecs.log ) -or !(Test-Path -Path C:\temp\event.log ))
{
    Write-Host "ERROR: Extract Socet TestFiles .zip into C:\temp before running"
    return
}

### Create log files
((Get-Content -path C:/temp/ecs.log -Raw) -replace 'YYYY-MM-DD',(Get-Date -Format "yyyy-MM-dd")) | Out-File -Encoding ASCII -NoNewLine -Append $GXP_XPLORER_DATA/logs/ecs.log
((Get-Content -path C:/temp/event.log -Raw) -replace 'YYYY-MM-DD',(Get-Date -Format "yyyy-MM-dd") -replace 'Month D YYYY',(Get-Date -Format "MMMM d yyyy")) | Out-File -Encoding ASCII -NoNewLine -Append $GXP_XPLORER_DATA/logs/event.log

### If temporary ingest, set up and run Filebeat
if ($GXP_XPLORER_DATA -eq "C:\temp")
{
    if (!(Select-String -quiet -pattern 'output.logstash:' -path C:\temp\gxp_xplorer-test.yml))
    {
        ####Set up Logstash output
        Write-Host "Updating gxp_xplorer-test.yml"
        $fullName = [System.Net.Dns]::GetHostByName(($env:COMPUTERNAME)).HostName
        $rootName = $fullName.Substring(0,$fullName.IndexOf('.'))
        $logstash = "logstash-" + $rootName.subString(0,3)
        $destString = "output.logstash: `n  hosts: [""" + $logstash + ":5044""]`n  ssl.certificate_authorities: ['C:\temp\cachain.pem'] "
        Add-Content -Path "C:\temp\gxp_xplorer-test.yml" -Value $destString -Encoding Ascii
    }

    ####Run Filebeat
    Write-Host "Running Filebeat -c C:\temp\gxp_xplorer-test.yml"
    $filebeat=(Get-ChildItem -Path C:\temp -Name -include filebeat-* -attributes Directory)
    cd C:\temp\$filebeat
    ./filebeat.exe -e -c C:\temp\gxp_xplorer-test.yml --once --E GXP_XPLORER_DATA=${GXP_XPLORER_DATA}
    cd ..
}
Write-Host "Please clean up C:\temp when testing is complete."
