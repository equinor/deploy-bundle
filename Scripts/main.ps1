[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Action,

    [Parameter()]
    [string] $ResourceGroupName,

    [Parameter()]
    [string] $Subscription,

    [Parameter()]
    [string] $ManagementGroupID,

    [Parameter()]
    [string] $Location,

    [Parameter()]
    [string] $ModulesPath,

    [Parameter(Mandatory)]
    [string] $ModuleName,

    [Parameter(Mandatory)]
    [string] $ModuleVersion,

    [Parameter()]
    [string] $ParameterFilePath,

    [Parameter()]
    [string] $ParameterFolderPath,

    [Parameter()]
    [short] $Retries = 1,

    [Parameter()]
    [short] $RetryInterval = 1,

    [Parameter()]
    [string] $ParameterOverrides,

    [Parameter(ValueFromRemainingArguments)]
    $RemainingArguments
)
$Task = ($MyInvocation.MyCommand.Name).split('.')[0]
New-GitHubLogGroup -Title "$Task-$Action-$ModuleName-$ModuleVersion"

$Output = $null

if ($ModulesPath | IsNullOrEmpty ) {
    $ModulePath = "$env:GITHUB_ACTION_PATH/Modules/$ModuleName/$ModuleVersion"
    Write-Output "$Task-$Action-$ModuleName-$ModuleVersion - Using built-in Module Library - $ModulePath"
} else {
    $ModulePath = "$env:GITHUB_WORKSPACE/$ModulesPath/$ModuleName/$ModuleVersion"
    Write-Output "$Task-$Action-$ModuleName-$ModuleVersion - Using custom Module Library - $ModulePath"
}
Write-Output "$Task-$Action-$ModuleName-$ModuleVersion - Find module folder - $ModulePath"
if (! (Test-Path -Path $ModulePath)) {
    throw "$Task-$Action-$ModuleName-$ModuleVersion - Find module folder - $ModulePath - Failed"
}
Write-Output "$Task-$Action-$ModuleName-$ModuleVersion - Find module folder - $ModulePath - Succeeded"
$ModuleFolder = Get-Item -Path $ModulePath
$DeployFile = Get-Item -Path "$ModuleFolder/deploy.*"
Write-Output "$Task-$Action-$ModuleName-$ModuleVersion - Find module folder - $ModulePath - $DeployFile"

Write-Output "$Task-$Action-$ModuleName-$ModuleVersion - Find parameters"
$ParameterFiles = @()
if ($ParameterFilePath | IsNotNullOrEmpty) {
    Write-Output "$Task-$Action-$ModuleName-$ModuleVersion - Find parameters - Single file"

    if (Test-Path -Path "$env:GITHUB_WORKSPACE/$ParameterFilePath") {
        $ParameterFilePath = "$env:GITHUB_WORKSPACE/$ParameterFilePath"
    }

    Write-Output "$Task-$Action-$ModuleName-$ModuleVersion - Find parameters - Single file - Find '$ParameterFilePath'"
    if (! (Test-Path -Path $ParameterFilePath)) {
        throw "$Task-$Action-$ModuleName-$ModuleVersion - Find parameters - Single file - Find '$ParameterFilePath' - Failed"
    }

    Write-Output "$Task-$Action-$ModuleName-$ModuleVersion - Find parameters - Single file - Find '$ParameterFilePath' - Succeeded"

    $ParameterFile = Get-Item -Path $ParameterFilePath
    $ParameterFiles += $ParameterFile

} elseif ($ParameterFolderPath | IsNotNullOrEmpty) {
    Write-Output "$Task-$Action-$ModuleName-$ModuleVersion - Find parameters - Folder of files"

    if (Test-Path -Path "$env:GITHUB_WORKSPACE/$ParameterFolderPath") {
        $ParameterFolderPath = "$env:GITHUB_WORKSPACE/$ParameterFolderPath"
    }

    Write-Output "$Task-$Action-$ModuleName-$ModuleVersion - Find parameters - Folder of files - Find '$ParameterFolderPath'"
    if (! (Test-Path -Path $ParameterFolderPath)) {
        throw "$Task-$Action-$ModuleName-$ModuleVersion - Find parameters - Folder of files - Find '$ParameterFolderPath' - Failed"
    }
    Write-Output "$Task-$Action-$ModuleName-$ModuleVersion - Find parameters - Folder of files - Find '$ParameterFolderPath' - Succeeded"

    $ParameterFileObjects = Get-ChildItem -Path $ParameterFolderPath | Get-Item

    foreach ($ParameterFile in $ParameterFileObjects) {
        Write-Output "$Task-$Action-$ModuleName-$ModuleVersion - Find parameters - Folder of files - $($ParameterFile.FullName)"
        $ParameterFiles += $ParameterFile
    }

} else {
    throw "$Task-$Action-$ModuleName-$ModuleVersion - Find parameters - No parameter file/folder is provided."
}

$DeploymentOutputObjects = @()
foreach ($ParameterFile in $ParameterFiles) {
    New-GitHubLogGroup -Title "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name)"
    switch ($DeployFile.Extension) {
        '.ps1' {
            Write-Output "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - PowerShell module"

            Write-Output "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - Test parameter file"
            if (! (Test-JSONParameters -ParameterFilePath $ParameterFile.FullName)) {
                throw "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - Test parameter file - Failed"
            }
            Write-Output "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - Test parameter file - Successfull"

            $DeploymentParameters = @{
                ParameterFilePath = $ParameterFile
                Action            = $Action
                Verbose           = $true
                ErrorAction       = 'Stop'
            }

            Write-Output "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - Deploy using:"
            $DeploymentParameters

            $DeploymentOutputObject = . $DeployFile @DeploymentParameters
        }
        { $_ -in '.json', '.bicep' } {
            Write-Output "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - ARM ($_) module"
            switch ($Action) {
                'Validate' {
                    $Operation = 'validate'
                }
                'Deploy' {
                    $Operation = 'create'
                }
                'Remove' {
                    $Operation = 'delete'
                }
                default {
                    throw "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - Action not supported"
                }
            }

            # Dont really need to double check the JSON in this case i think
            #Write-Output "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - Test parameter file"
            #if (! (Test-JSONParameters -ParameterFilePath $ParameterFile.FullName)) {
            #    throw "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - Test parameter file - Failed"
            #}
            #Write-Output "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - Test parameter file - Successfull"

            $Schema = (Get-Content -Raw -Path $ParameterFile | ConvertFrom-Json).'$schema'
            if ($Schema -notmatch '\/deploymentParameters.json#$') {
                Write-Warning "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - Not a valid ARM parameter file"
                continue
            }

            $Scope = ''
            $LocationParam = ''
            $Target = ''
            $Template = "--template-file '$($DeployFile.FullName)'"
            $Parameters = "--parameters '$($ParameterFile.FullName)'"

            switch ($_) {
                '.json' {
                    $deploymentScope = $deploymentScope = (Get-Content -Raw -Path $DeployFile | ConvertFrom-Json).'$schema'
                }
                '.bicep' {
                    $Scope = Select-String -Pattern 'targetScope' -Raw -Path $DeployFile
                    if (-not $Scope) {
                        $Scope = 'resourceGroup'
                    }
                    $deploymentScope = $Scope
                }
            }
            switch ($deploymentScope) {
                { $_ -match '/deploymentTemplate.json#' -or $_ -match 'resourceGroup' } {
                    $Scope = 'group'
                    $Target = "--resource-group $ResourceGroupName"
                }
                { $_ -match '/subscriptionDeploymentTemplate.json#' -or $_ -match 'subscription' } {
                    $Scope = 'sub'
                    $LocationParam = "--location $Location"
                }
                { $_ -match '/managementGroupDeploymentTemplate.json#' -or $_ -match 'managementGroup' } {
                    $Scope = 'mg'
                    $Target = "--management-group-id $ManagementGroupID"
                    $LocationParam = "--location $Location"
                }
                { $_ -match '/tenantDeploymentTemplate.json#' -or $_ -match 'tenant' } {
                    $Scope = 'tenant'
                    $LocationParam = "--location $Location"
                }
                default {
                    throw "[$deploymentScope] is a non-supported ARM/Bicep template scope."
                }
            }

            $DeploymentName = "$ModuleName-$ModuleVersion-$( -join (Get-Date -Format yyyyMMddTHHMMssffffZ)[0..63])"
            $DeploymentNameParameter = "--name $DeploymentName"


            if ($ParameterOverrides | IsNotNullOrEmpty ) {
                Write-Output "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - Adding ParameterOverrides:"
                Write-Output "    >$ParameterOverrides<"
                $Parameters += " $ParameterOverrides"
            }

            $cmd = "az deployment $Scope $Operation $Target $DeploymentNameParameter $Template $LocationParam $Parameters --output json | ConvertFrom-Json"

            Write-Output "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - using:"
            $cmd

            for ($Retry = 1; $Retry -le $Retries; $Retry++) {
                New-GitHubLogGroup -Title "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - Attempt $Retry/$Retries"

                $Failed = $false
                try {
                    $DeploymentOutput = Invoke-Expression -Command $cmd -ErrorAction Stop
                } catch {
                    Write-Warning "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - Attempt $Retry/$Retries - Failiure cought"
                    $Failed = $true
                }
                $DeploymentExecutionStatus = $LASTEXITCODE

                if ($Failed -or ($DeploymentExecutionStatus -ne 0)) {
                    Write-Warning "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - Attempt $Retry/$Retries - Failiure."
                    Write-Warning "    Command execution status: $DeploymentExecutionStatus"
                    Write-Output '    Retreiving deployment information.'
                    $DeploymentResult = Invoke-Expression -Command "az deployment $Scope list $Target --output json" | ConvertFrom-Json | Where-Object name -EQ $DeploymentName
                    Write-Output '    Showing DeploymentResult.properties:'
                    $DeploymentResult.properties #| Select-Object provisioningState,timestamp
                    Write-Output '    Showing DeploymentResult.properties.parameters:'
                    $DeploymentResult.properties | Select-Object -ExpandProperty parameters
                    Write-Output '    Showing DeploymentResult.properties.error:'
                    $DeploymentResult.properties.error | Select-Object -ExcludeProperty details
                    Write-Output '    Showing DeploymentResult.properties.error.details:'
                    $DeploymentResult.properties.error | Select-Object -ExpandProperty details

                    if ($Retry -eq $Retries) {
                        throw $_
                    }

                    Write-Output "    Retrying in $RetryInterval seconds."
                    Start-Sleep -Seconds $RetryInterval
                    continue
                }
                break
            }

            Write-Output '    Showing DeploymentOutput:'
            $DeploymentOutput | Select-Object -ExcludeProperty properties
            Write-Output '    Showing DeploymentOutput.properties:'
            $DeploymentOutput | Select-Object -ExpandProperty properties
            Write-Output '    Showing DeploymentOutput.properties.parameters:'
            $DeploymentOutput.properties | Select-Object -ExpandProperty parameters

            $DeploymentOutputObject = New-Object -TypeName PSCustomObject
            foreach ($Output in $DeploymentOutput.properties.outputs.PSObject.Properties) {
                $Name = $Output.Name
                $Value = $Output.Value.Value
                $DeploymentOutputObject | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
            }
            $DeploymentOutputObjects += $DeploymentOutputObject

            <#
            $RemoveFilePath = "$ModuleFolder/Scripts/Remove-Module.ps1"
            if (Test-Path -Path $RemoveFilePath) {
                $RemoveFilePath
            } else {
                'Remove based on tags'
            }#>
        }
        '.yml' {
            Write-Output "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - Ansiable module"
        }
        '.tf' {
            Write-Output "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - Terraform module"
        }

        default {
            throw "$Task-$Action-$ModuleName-$ModuleVersion-$($ParameterFile.name) - $($DeployFile.Name) is not supported"
        }
    }
}

Write-Output '::endgroup::'

Write-Output "::set-output name=Output::$($DeploymentOutputObjects | ConvertTo-Json -Compress -Depth 100)"

New-GitHubLogGroup -Title "$Task-$Action-$ModuleName-$ModuleVersion-Output"
return $DeploymentOutputObjects
