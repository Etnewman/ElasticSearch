Function removeBeat($beat) {
    If (Get-Service $beat -ErrorAction SilentlyContinue) {
        $service = Get-WmiObject -Class Win32_Service -Filter "name='$beat'"
        $service.StopService()
        Start-Sleep -s 1
        $service.delete()
    }
}
Function main {
removeBeat metricbeat
removeBeat winlogbeat
removeBeat filebeat
Remove-Item  'C:\Program Files\ELAC' -Recurse -Force
}
main
