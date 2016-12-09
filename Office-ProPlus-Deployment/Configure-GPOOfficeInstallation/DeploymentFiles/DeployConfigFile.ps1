  param(
    [Parameter(Mandatory=$true)]
    [string]$OfficeDeploymentPath,

	[Parameter(Mandatory=$true)]
	[String]$ConfigFileName = $NULL,

    [Parameter()]
    [string]$Channel = "Current",

    [Parameter()]
    [string]$Bitness = "32",
    
    [Parameter()]
    [bool]$WaitForInstallToFinish = $true,

    [Parameter()]
    [bool]$InstallProofingTools = $false,

    [Parameter()]
    [bool]$InstallLanguagePack = $false
  )

Begin {
    Set-Location $OfficeDeploymentPath
}

Process {
    $scriptPath = "."

      #Importing all required functions
    . $scriptPath\Edit-OfficeConfigurationFile.ps1
    . $scriptPath\Install-OfficeClickToRun.ps1
    . $scriptPath\SharedFunctions.ps1
    
    [string]$configFilePath = "$scriptPath\$ConfigFileName"
    [string]$targetFilePath = "$env:temp\configuration.xml"
    
    if (!(Test-Path -Path $configFilePath)) {
        throw "Cannot find Configuration Xml File: $ConfigFileName"
    }
    
    Copy-Item -Path $configFilePath -Destination $targetFilePath -Force
    
    [string]$UpdateSource = (Get-ODTAdd -TargetFilePath $targetFilePath | select SourcePath).SourcePath
    [string]$Bitness = (Get-ODTAdd -TargetFilePath $targetFilePath | select OfficeClientEdition).OfficeClientEdition
    [string]$Channel = (Get-ODTAdd -TargetFilePath $targetFilePath | select Channel).Channel
    if($Bitness -eq '64'){
       $Bitness = "x64"
    } else {
       $Bitness = "x32"
    }
    
    if ($UpdateSource) {
        if ($UpdateSource.StartsWith(".\")) {
           $UpdateSource = $UpdateSource -replace "^\.", "$scriptPath"
        }
    }
    
    $UpdateURLPath = $NULL
    if ($UpdateSource) {
      if (Test-ItemPathUNC -Path "$UpdateSource") {
         $UpdateURLPath = "$UpdateURLPath\$SourceFileFolder"
      }
    }
    
    $languages = Get-XMLLanguages -Path $targetFilePath
    
    if ($UpdateSource) {
        $ValidUpdateSource = Test-UpdateSource -UpdateSource $UpdateSource -OfficeLanguages $languages -Bitness $Bitness
        if ($ValidUpdateSource) {
           if ($InstallLanguagePack) {
               Set-ODTAdd -TargetFilePath $targetFilePath -SourcePath $UpdateSource -Channel $Channel | Out-Null
           } else {
               Set-ODTAdd -TargetFilePath $targetFilePath -SourcePath $UpdateSource -Channel $Channel | Set-ODTUpdates -Channel $Channel -UpdatePath $UpdateURLPath | Out-Null
           }
        } else {
           throw "Invalid Update Source: $UpdateSource"
        }
    }
       
    Install-OfficeClickToRun -TargetFilePath $targetFilePath -WaitForInstallToFinish $WaitForInstallToFinish -InstallProofingTools $InstallProofingTools

}