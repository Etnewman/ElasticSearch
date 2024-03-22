##########################################################################
#
# Author:  Steve Truxal
# Initial: May the 4th be with you 2017
# Purpose: To install beats agents on Windows clients silently.
#
##########################################################################
# Allow for version request
param ([switch]$version = $false)

# Global Variable Declarations

# Installation Source Directory - Currently set to directory where script is executed
$global:installSourceDir = $PSScriptRoot
$global:vernum="3.0.0"

#
# This function removes old scheduled tasks that contain "beats"
# Will be removed in a later release
#
# Returns:
#    Nothing
Function RemoveScheduledTask
{
    $ScheduledTasks = Get-ScheduledTask
    foreach ($Task in $ScheduledTasks)
    {
        if ($Task.TaskName.ToLower() -like "*beats*")
        {
            Unregister-ScheduledTask -TaskName $Task.TaskName -TaskPath '\*' -Confirm:$false
            $outstr = "Task " + $Task.TaskName + " removed successfully."
            Write-Output $outstr
        }
    }
}

#
# This function is used to verify this script is executed by a user with Administrator
# privliges.
#
# Returns:
#    True - If user has administrator privileges
#    False - If user does NOT have administrator privileges
Function IsAdmin
{
    $identity=[Security.Principal.WindowsIdentity]::GetCurrent()
    $priciple = New-Object Security.Principal.WindowsPrincipal -ArgumentList $identity
    return $priciple.isInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )
}

#
# This function is used to determine the lastest version of a beat in the zipfiles
# directory.
#
# Parameters:
#    $beat - Name beat to get latest version for
#
# Returns:
#    latest - lastest version of beat in zipfiles directory
#
Function getLatestVersion($beat, $zipdir) {
    $zips=(Get-ChildItem -Path $zipdir -Name -include $beat-*)
    $latest = $null
    $major=$minor=$patch=[int]0
    $changever=$false
    foreach ($zip in $zips) {
        $verstr=$zip.Split('-')[1]
        $verarray=$verstr.Split('.')
        $curmajor=[int]$verarray[0]
        $curminor=[int]$verarray[1]
        $curpatch=[int]$verarray[2]

        if ($curmajor -gt $major)
        {
            $changever = $true
        }
        elseif($curmajor -eq $major)
        {
            if($curminor -gt $minor)
            {
                $changever = $true
            }
            elseif($curpatch -gt $patch)
            {
                $changever = $true
            }
        }

        if($changever)
        {
            $latest = $verstr
            $curmajor = $major
            $curminor = $minor
            $curpatch = $patch
        }
    }
    # Write-Host "Newest=""$newest"""
    return $latest
}


#
# This is a utility function to unzip a file
#
# Parameters:
#    $source - Name of archive to unzip including path
#    $dest - destination of where to unzip archive
#
function unzip($source, $dest)
{
    if ($PSVersionTable.PSVersion.Major -ge 5)
    {
        try {
            $global:ProgressPreference="SilentlyContinue"
            Expand-Archive -Path $source -DestinationPath $dest -Force
        }
        catch {
            Write-Host "Unable to unzip archive"
        }
    }
    else
    {
        Add-Type -assembly "system.io.compression.filesystem"
        [io.compression.zipfile]::ExtractToDirectory($source, $dest)
    }
    Start-Sleep -Seconds 20
}

#
# This function updates the "Path to executable" value for the beat Service
#
# Parameters:
#    $beatPath - Path where beat is located on host
#    $beat - Name of beat being configured
#
function update_service_path($beatPath, $beat)
{
    $val = "`"$beatPath\$beat.exe`" -c `"$beatPath\$beat.yml`" -path.home `"$beatPath`" -path.data `"C:\ProgramData\$beat`""
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$beat" -Name ImagePath -Value $val

    # Allow service to restart on failure
    sc.exe failure $beat reset=120 actions=restart/60000/restart/60000/restart/60000
}

#
# This function where check the current version of the installed beat
# against the passed in $newver value
#
# Parameters:
#    $newver - version to check against
#    $beat - name of beat to check version on
#
# Returns:
#   True - If version is the same
#   False - If version is different
#
function check_version($newver, $beat)
{
    $output = & "C:\Program Files\ELAC\$beat\$beat.exe" version
    $ver = $output.Split(' ')[2]

    if($ver -eq $newver)
    {
        return $true
    }
    else
    {
        return $false
    }
}


#
# This function will delete any old versions of a beat that
# is in the ELAC directory
#
# Parameters:
#    $beat - name of beat to check for old versions
#
function cleanup_old_versions($beat)
{
    Get-ChildItem "C:\Program Files\ELAC" -Filter $beat-* |
    ForEach-Object {
        # Write-Host "Found old directory:" $_.FullName " Deleting..."
        Remove-Item $_.FullName -Force -Recurse
    }
}

#
# The function copies over any modules needed for the beat
# being installed
#
# Parameters:
#    $moduleLoc - Directory where to look for modules
#    $dest - Directory where beat is installed
#    $prefix - Module prefix for this host
#    $defaultModules = Any default modules to add on to list being copied
#
function get_modules($moduleLoc, $dest, $prefix, $defaultModules=@())
{
    Write-Host "defmods: $defaultModules"
    $modules=(Get-ChildItem -Path $moduleLoc -Filter "$prefix.module.*").BaseName
    $modules = $modules + $defaultModules

    foreach ($module in $modules)
    {
        Write-Host "mod: $module"
        $destname=$module.split(".")[2]
        Copy-Item $moduleLoc\$module.yml $dest\modules.d\$destname.yml
        Remove-Item $dest\modules.d\$destname.yml.disabled -Force -ErrorAction SilentlyContinue
    }
}

#
# The function copies over any inputs needed for the beat
# being installed
#
# Parameters:
#    $inputLoc - Directory where to look for inputs directory
#    $dest - Directory where beat is installed
#    $inputs - Log inputs to copy
#
function get_inputs($configLoc, $dest, $inputs)
{
    $inputsDir = $dest + "\inputs.d"
    # Ensure inputs.d directory exists
    if (!(Test-Path -Path $inputsDir ))
    {
        New-Item -ItemType directory -Path $inputsDir
    }
    else
    {
        # Clean up all configs in case a program
        # has been removed from the host
        Remove-Item -Path "$inputsDir/*.yml"
    }

    # Copy over configs for all inputs
    $source = "$configLoc\inputs.d"
    foreach ($inputFile in $inputs)
    {
        Write-Host "Copying $inputFile"
        Copy-Item "$source\$inputFile" $inputsDir
    }
}

#
# This function updates the yaml configuration file needed for the beat
# being installed.  The get_modules function is also called to copy over
# any needed modules for the host being configured.
#
# Parameters:
#    $name - The name that discribes the host being configured
#    $installLoc - Location where installation file are found
#    $dest - Directory where beat is installed
#    $logstash_dest - Logstash destination to send data to
#    $beat - Name of beat being installed
#    $beatyml - yaml filename to copy over for beat
#    $inputs - Any input configurations
#
function update_yaml($name, $installLoc, $dest, $logstash_dest, $beat, $beatyml, $inputs)
{
    $configLoc = "$installLoc\configs\$beat"
    # Check for single worker being specified via ":SW" on end of yml specification
    for ($i=0; $i -lt $inputs.Count; $i++)
    {
        $hassw=$inputs[$i].Split(':')[1]
        $inputs[$i]=$inputs[$i].Split(':')[0]

        # If single worker found, don't overwrite and lose it
        if (!($sw))
        {
            $sw = $hassw
        }
        # Compile all metricbeat input.d/* files
        if($beat -eq "metricbeat")
        {
            $input=$inputs[$i]
            Write-Host "Adding $input to metricbeat.yml"
            $FileContent+=(Get-Content $inputs[$i] -raw)
        }
    }

    # If single worker config not found yet, check to see if specified via filebeat config file with "-SW"
    if(!($sw))
    {
        $sw=$beatyml.Split('-')[1]
    }

    if($beat -eq "metricbeat")
    {
        $lsport = "5048"
		get_modules $configLoc $dest $name @("all.module.system", "all.module.windows")
        # Add input.d/* files into mericbeat.yml as it's copied
        $Comment="#----------------------------- Logstash output --------------------------------"
        (Get-Content $configLoc\$beatyml.yml -raw) -replace "(?s)},`n          }`n$Comment","},`n$FileContent`n          }`n$Comment" > $dest\$beat.yml
        Copy-Item $configLoc\appmonitor_win.js $dest\appmonitor_win.js
    }
    elseif($beat -eq "filebeat")
    {
        if ($sw)
        {
            $lsport = "5043"
        }
        else
        {
            $lsport = "5044"
        }
        get_modules $configLoc $dest $name
        get_inputs $configLoc $dest $inputs
        Copy-Item $configLoc\$beatyml.yml $dest\$beat.yml
    }
    elseif($beat -eq "winlogbeat")
    {
        $lsport = "5045"
        Copy-Item $configLoc\$beatyml.yml $dest\$beat.yml
    }

    # Update beat yml file
    $destString = "output.logstash: `n  hosts: [""" + $logstash_dest + ":$lsport""]`n  ssl.certificate_authorities: ['$dest\cachain.pem'] "
    $ymlfile = $dest + "\$beat.yml"
    Add-Content -Path $ymlfile -Value $destString -Encoding Ascii

    Copy-Item $installLoc\cachain.pem $dest\cachain.pem

}

#
# This function checks to see if there is a configuration
# file for the host(name) passed.
#
# Parameters:
#    $name - The name that describes the host being configured
#    $SourceDir - Source Directory where installation configs are located
#    $beat - The name of the beat being installed
#    $sw - the single worker flag in case of filebeat-sw.yml file
#
function check_beat_config($name, $SourceDir, $beat, $sw=$null)
{

    $filename = "$SourceDir\configs\$beat\$name.$beat.yml"
    if ($sw -eq "-SW")
    {
        $filename = "$SourceDir\configs\$beat\$name.$beat$sw.yml"
    }
    Write-Host "Checking for: $filename"
    Test-Path $filename
}

#
# This function checks to see if there are programs on the
# machine being installed that have beat configuration files.
#
# Parameters:
#    $SourceDir - Source Directory where installation configs are located
#    $beat - The name of the beat being installed
#
# Returns:
#   $inputs_to_config - ArrayList of beat configurations that need copied over for this host
#
function get_beat_inputs($SourceDir, $beat)
{
    # Create Array for inputs to Configure
    $inputs_to_config = New-Object -TypeName System.Collections.ArrayList

    # Check if inputs.txt exists and is not empty
    if (Test-Path $SourceDir\configs\$beat\inputs.txt)
    {
        if ([String]::IsNullOrWhiteSpace((Get-content $SourceDir\configs\$beat\inputs.txt)))
        {
            Write-Host "WARN - $SourceDir\configs\$beat\inputs.txt IS EMPTY"
        }

        $available_program_inputs = Get-Content -Raw $SourceDir\configs\$beat\inputs.txt | ConvertFrom-StringData
    }
    else
    {
        Write-Host "ERROR - $SourceDir\configs\$beat\inputs.txt DOES NOT EXIST"
    }

    # Check if inputsByService.txt exists and is not empty
    if (Test-Path $SourceDir\configs\$beat\inputsByService.txt)
    {
        if ([String]::IsNullOrWhiteSpace((Get-content $SourceDir\configs\$beat\inputsByService.txt)))
        {
            Write-Host "WARN - $SourceDir\configs\$beat\inputsByService.txt IS EMPTY"
        }

        $available_service_inputs = Get-Content -Raw $SourceDir\configs\$beat\inputsByService.txt | ConvertFrom-StringData
    }
    elseif ($beat -eq "filebeat")
    {
        Write-Host "ERROR - $SourceDir\configs\$beat\inputsByService.txt DOES NOT EXIST"
    }

    # Get List of Programs
    $progs = reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall /reg:64 /s /v DisplayName | Select-String DisplayName
    $progs += reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall /reg:32 /s /v DisplayName | Select-String DisplayName

    $installed_programs=@()
    foreach ($prog in $progs)
    {
        $installed_programs += ($prog -split '\s+',4)[3]
    }

    # Get List of Services
    $installed_services = Get-Service

    # Sort Programs and Services
    $installed_programs = $installed_programs | Sort-Object -Unique
    $installed_services = $installed_services | Sort-Object -Unique


    # Match Program and Service to Available Programs and Services then add those to config array
    foreach ($program in $available_program_inputs.Keys)
    {
        if (($installed_programs -match $program).Length -gt 0)
        {
            Write-Host "Program:", $program, " is installed"
            $inputs_to_config.Add($available_program_inputs[$program]) | Out-Null
        }

    }

    foreach ($service in $available_service_inputs.Keys)
    {
        if (($installed_services -match $service).Length -gt 0)
        {
            Write-Host "Service:", $service, " is installed"
            $inputs_to_config.Add($available_service_inputs[$service]) | Out-Null
        }

    }
    ,$inputs_to_config # Return the Config Array
}

#
# This is a generic function to install a beat collector
#
# Parameters:
#    $beat - The name of the beat being installed
#    $name - The name that describes the host being configured
#    $beatyml - If a custom configuration for this beat is needed the name
#               of the custom yaml file is specified here.  If the default
#               yaml file is used then this parameter can be left blank
#    $inputs_to_config - ArrayList of beat configurations that need to be
#               copied over for this host
#
function install_beat($beat, $name, $beatyml=$beat, $inputs_to_config=$null)
{
    $fullName = [System.Net.Dns]::GetHostByName(($env:COMPUTERNAME)).HostName
    $installRoot = $fullName.Substring($fullName.IndexOf('.')+1)
    $rootName = $fullName.Substring(0,$fullName.IndexOf('.'))

    $logstash = "logstash"

    # Installation files located in installation script directory
    $zipsharePath = $global:installSourceDir

    $installPath = "C:\Program Files\ELAC"
    $beatPath = "$installPath\$beat"

    $curVersion = getLatestVersion $beat "$global:installSourceDir\zipfiles"

    $installZip="$beat-$curVersion-windows-x86_64.zip"


    #check if already installed, if so lets stop it for update
    if (Get-Service $beat -ErrorAction SilentlyContinue){
        #but am I running?
        $service = Get-Service -Name $beat
        if($service.Status -eq "Running")
        {
            $service.Stop()
        }

        #Ensure path to executable is correct for existing service
        update_service_path $beatPath $beat
    }
    else
    {
        # create new service
        New-Service -name $beat `
            -displayName $beat `
            -binaryPathName "`"$beatPath\\$beat.exe`" -c `"$beatPath\\$beat.yml`" -path.home `"$beatPath`" -path.data `"C:\\ProgramData\\$beat`""
    }

    # Ensure Startup type is Delayed for service
    $startType=(sc.exe qc $beat | Select-String "START_TYPE" | ForEach-Object { ($_ -replace '\s+', ' ').trim().Split(" ") } | Select-Object -Last 1 )
    $startType=$startType -replace '[()]',""

    if (!($startType -eq "DELAYED")) {
        $myArgs = 'config "{0}" start=delayed-auto' -f $beat
        Start-Process -FilePath sc.exe -ArgumentList $myArgs
    }

    #check if install path exists & create, this coud be initial install
    if (!(Test-Path -Path $installPath))
    {
        New-Item -ItemType directory -Path $installPath
    }


    # Check to see if already installed, if so ensure latest version.
    # If not latest then remove and upgrade
    $zipDir = $installZip.Substring(0, $installZip.Length-4)
    $installit = $false
    if((Test-Path -Path $beatPath))
    {
        #if not current version then need to upgrade
        if(!(check_version $curVersion $beat ))
        {
            Remove-Item $beatPath -Force -Recurse
            $installit = $true
        }
    }
    else
    {
        $installit = $true
    }

    if($installit)
    {
        #unzip beat package
        unzip "$zipSharePath\zipfiles\$installZip" $installPath
        Rename-Item -Path $installPath\$zipDir -NewName $beatPath
    }

    # If zip was extracted but never renamed... (unlikely)
    if(Test-Path -Path $installPath\$zipDir)
    {
        Rename-Item -Path $installPath\$zipDir -NewName $beatPath
    }


    # make sure yaml files are up to date
    update_yaml $name $zipSharePath $beatPath $logstash $beat $beatyml $inputs_to_config

    Start-Sleep -Seconds 2

    #enable services
    Start-Service $beat

    cleanup_old_versions $beat
}

#
# This is the main function for installing beats collectors.
#
function main
{
    # If version requested print and exit program
    # install_beats_windows.ps1 -version
    if ($version)
    {
        Write-Host "Install_beats_windows version: $global:vernum"
        exit
    }

    $fullName = [System.Net.Dns]::GetHostByName(($env:COMPUTERNAME)).HostName
    $rootName = $fullName.Substring(0,$fullName.IndexOf('.'))

    #check if admin
    if (-Not (IsAdmin))
    {
        exit
    }

    # Get the root name of this host
    # Strip off the first 7 characters of hostname
    $name = $rootName.Substring(7,$rootName.Length-7)

    #
    # Install Metricbeat on all hosts.  If a specific configuration exists
    # for this host then use it, otherwise use the generic configuration.
    # Add app configurations based on installed programs.
    #

    # Get list of any app configs that metricbeat should have
    # configured for this host based on installed programs
    $inputs = get_beat_inputs $global:installSourceDir "metricbeat"

    if (check_beat_config $name "$global:installSourceDir" "metricbeat")
    {
        install_beat "metricbeat" $name "$name.metricbeat" $inputs
    }
    else
    {
        install_beat "metricbeat" $name "metricbeat" $inputs
    }

    #
    # Check to see if Filebeat should be installed on this host
    #
    #
    # Check for specific filebeat configuration for this host
    if(check_beat_config $name "$global:installSourceDir" "filebeat")
    {
        $specific_config = $true
        $beatyml = "$name.filebeat"
    }
    # Check for single working configuration for this host
    elseif (check_beat_config $name "$global:installSourceDir" "filebeat" "-SW")
    {
        $specific_config = $true
        $beatyml = "$name.filebeat-SW"
    }
    else
    {
        $beatyml = "filebeat"
    }

    # Get list of any log inputs that filebeat should have
    # configured for this host based on installed programs
    $inputs = get_beat_inputs $global:installSourceDir "filebeat"

    # If there is a specific filebeat config for this host
    # or a program running on the host with a config
    # install filebeat and configure.
    if ($specific_config -Or ($inputs.Count -gt 0))
    {
        Write-Host "Installing filebeat on host: $rootName"
        install_beat "filebeat" $name $beatyml $inputs
    }

    #
    # Install Winlogbeat on the Event collector
    #
    if ($name -eq "ec01")
    {
        install_beat "winlogbeat" $name "$name.winlogbeat"
    }

    RemoveScheduledTask
}

main
