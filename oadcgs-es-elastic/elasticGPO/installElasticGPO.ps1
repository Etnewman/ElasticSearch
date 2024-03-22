####################################################################
# Create GPO for elastic metricbeat
####################################################################
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
#
# This function is used to verify this script is executed by a user with Administrator
# privliges.
#
# Returns:
#    True - If user has administrator privileges
#    False - If user does NOT have administrator privileges
function IsAdmin
{
    $identity=[Security.Principal.WindowsIdentity]::GetCurrent()
    $priciple = New-Object Security.Principal.WindowsPrincipal -ArgumentList $identity
    return $priciple.isInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )
}

#
# This is the main function for installing beats collectors.
#
function main
{
$CWD = (Get-Item .).FullName
$GpoName = "Elastic Metricbeat Install"
$GpoPath = $CWD + "\Elastic Metricbeat Install"
$baseDN = (Get-ADRootDSE).defaultNamingContext
$OUName = "OU=Domain Controllers,$baseDN"

# If the GPO exists, skip it
If(Get-GPO  -Server $env:COMPUTERNAME -Name $GpoName -ErrorAction SilentlyContinue) {
   write-output "GPO already exists skipping..."
   exit
}

# Otherwise, create it
Else {
   # Modify XML file to include path to beats directory
   modXML

   # Create GPO
   write-output "Creating $GpoName GPO"
   New-GPO  -Server $env:COMPUTERNAME -Name $GpoName | Out-Null

   # Import the settings
   write-output "IMPORTING - Settings into $GpoName"
   Import-GPO  -Server $env:COMPUTERNAME -BackupGpoName $GpoName -TargetName $GpoName -Path $GpoPath | Out-Null
   # Link the GPO
   write-output "LINKING - $GpoName to the $ADRoot domain"
   New-GPLink  -Server $env:COMPUTERNAME -Name $GpoName -target $OUName -Enforced No
   }
}

function modXML
{
	$defaultVal = '\\u00sm01sc01\c$\Source\Beats'

	$inputVal = Read-Host -Prompt "Input path to SCCM Elastic directory? [$($defaultVal)]"
	$inputVal = ($defaultVal,$inputVal)[[bool]$inputVal]
		if ($inputVal -eq '\\u00sm01sc01\c$\Source\Beats')
		{
		$inputVal = $defaultVal
		}

	$filePathToTask = $CWD + "\Elastic Metricbeat Install\{465035F7-1532-4275-9B68-047E588CD31C}\DomainSysvol\GPO\Machine\Preferences\ScheduledTasks\ScheduledTasks.xml"
	$xml = New-Object XML
	$xml.Load($filePathToTask)
	$element =  $xml.SelectSingleNode("//Arguments")
	$anyVar = "-ExecutionPolicy Bypass -file ""$inputVal\install_beats_windows.ps1"""
	$element.InnerText = $anyVar
	$xml.Save($filePathToTask)

}

if (-Not (IsAdmin))
    {
	    write-output "Must have administrative privileges to install"
        exit
    }

main
