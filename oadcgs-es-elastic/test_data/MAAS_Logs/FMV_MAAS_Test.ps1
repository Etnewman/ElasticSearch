#!Powershell
#   Set up FMV MAAS test logs
#   If Filebeat is not automatically picking up logs, set it up and run manually

####Pre-Requisites:
#   - oadcgs-es-elastic-arts-FMV-MAAS-TestLogs-<version>.zip extracted into C:\temp
#   And Either:
#      - FMV MAAS installed
#      - Filebeat installed and running
#   Or:
#      - filebeat-<version>-x86_64.zip extracted into C:\temp
#      - cachain.pem copied to C:\temp

### If FMV MAAS is not installed, set up temporary ingest in C:\Temp
if ( "$MAAS_HOME" -eq "" )
{
    Set-Variable -Name MAAS_HOME -Value "C:\temp\logs"
    New-Item -Path $MAAS_HOME\config\default\temp\logs -ItemType Directory -Force | out-null

    if ( "$JBOSS_HOME" -eq "" )
    {
        $JBOSS_HOME="C:\temp\logs"
        New-Item -Path $JBOSS_HOME\standalone\log -ItemType Directory -Force | out-null
    }

    if (!(Test-Path -Path C:\temp\filebeat-*\filebeat.exe ))
    {
        Write-Host "ERROR: Extract Filebeat .zip into C:\temp before running"
        return
    }
    elseif (!(Test-Path -Path C:\temp\fmv_maas-test.yml ))
    {
        Write-Host "ERROR: Extract FMV MAAS TestFiles .zip into C:\temp before running"
        return
    }
    elseif (!(Test-Path -Path C:\temp\cachain.pem ))
    {
        Write-Host "ERROR: Copy cachain.pem to C:\temp before running"
        return
    }
}
if (!(Test-Path -Path C:\temp\MAAS_Test_Data.log ) -or !(Test-Path -Path C:\temp\Wildfly_Test_Data.log ))
{
    Write-Host "ERROR: Extract FMV MAAS TestFiles .zip into C:\temp before running"
    return
}

### Copy log files to ingest directories (date change is not needed because ingest time is used)
copy C:\temp\MAAS_Test_Data.log $MAAS_HOME\config\default\temp\logs
copy C:\temp\Wildfly_Test_Data.log $JBOSS_HOME\standalone\log

### If temporary ingest, set up and run Filebeat
if ($MAAS_HOME -eq "C:\temp\logs")
{
    if (!(Select-String -quiet -pattern 'output.logstash:' -path C:\temp\fmv_maas-test.yml))
    {
        ####Set up Logstash output
        Write-Host "Updating fmv_maas-test.yml"
        $fullName = [System.Net.Dns]::GetHostByName(($env:COMPUTERNAME)).HostName
        $rootName = $fullName.Substring(0,$fullName.IndexOf('.'))
        $logstash = "logstash-" + $rootName.subString(0,3)
        $destString = "output.logstash: `n  hosts: [""" + $logstash + ":5044""]`n  ssl.certificate_authorities: ['C:\temp\cachain.pem'] "
        Add-Content -Path "C:\temp\fmv_maas-test.yml" -Value $destString -Encoding Ascii
    }

    ####Run Filebeat
    Write-Host "Running Filebeat -e -c C:\temp\fmv_maas-test.yml --once"
    C:\temp\filebeat-*\filebeat.exe -e -c C:\temp\fmv_maas-test.yml --once
}
Write-Host "Please clean up C:\temp when testing is complete."
