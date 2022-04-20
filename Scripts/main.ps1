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

    [Parameter()]
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
$ModuleIdentifier = (@($Task, $Action, $ModuleName, $ModuleVersion) | Where-Object {$_}) -join "-"

New-GitHubLogGroup -Title "$ModuleIdentifier"

$Output = $null

$ModulePath = (@($env:GITHUB_WORKSPACE, $ModulesPath, $ModuleName, $ModuleVersion) | Where-Object {$_}) -join "/"

Write-Output "$ModuleIdentifier - Using custom Module Library - $ModulePath"

Write-Output "$ModuleIdentifier - Find module folder - $ModulePath"
if (! (Test-Path -Path $ModulePath)) {
    throw "$ModuleIdentifier - Find module folder - $ModulePath - Failed"
}
Write-Output "$ModuleIdentifier - Find module folder - $ModulePath - Succeeded"
$ModuleFolder = Get-Item -Path $ModulePath
$DeployFile = Get-Item -Path "$ModuleFolder/deploy.*"
Write-Output "$ModuleIdentifier - Find module folder - $ModulePath - $DeployFile"

Write-Output "$ModuleIdentifier - Find parameters"
$ParameterFiles = @()
if ($ParameterFilePath | IsNotNullOrEmpty) {
    Write-Output "$ModuleIdentifier - Find parameters - Single file"

    if (Test-Path -Path "$env:GITHUB_WORKSPACE/$ParameterFilePath") {
        $ParameterFilePath = "$env:GITHUB_WORKSPACE/$ParameterFilePath"
    }

    Write-Output "$ModuleIdentifier - Find parameters - Single file - Find '$ParameterFilePath'"
    if (! (Test-Path -Path $ParameterFilePath)) {
        throw "$ModuleIdentifier - Find parameters - Single file - Find '$ParameterFilePath' - Failed"
    }

    Write-Output "$ModuleIdentifier - Find parameters - Single file - Find '$ParameterFilePath' - Succeeded"

    $ParameterFile = Get-Item -Path $ParameterFilePath
    $ParameterFiles += $ParameterFile

} elseif ($ParameterFolderPath | IsNotNullOrEmpty) {
    Write-Output "$ModuleIdentifier - Find parameters - Folder of files"

    if (Test-Path -Path "$env:GITHUB_WORKSPACE/$ParameterFolderPath") {
        $ParameterFolderPath = "$env:GITHUB_WORKSPACE/$ParameterFolderPath"
    }

    Write-Output "$ModuleIdentifier - Find parameters - Folder of files - Find '$ParameterFolderPath'"
    if (! (Test-Path -Path $ParameterFolderPath)) {
        throw "$ModuleIdentifier - Find parameters - Folder of files - Find '$ParameterFolderPath' - Failed"
    }
    Write-Output "$ModuleIdentifier - Find parameters - Folder of files - Find '$ParameterFolderPath' - Succeeded"

    $ParameterFileObjects = Get-ChildItem -Path $ParameterFolderPath | Get-Item

    foreach ($ParameterFile in $ParameterFileObjects) {
        Write-Output "$ModuleIdentifier - Find parameters - Folder of files - $($ParameterFile.FullName)"
        $ParameterFiles += $ParameterFile
    }

} else {
    throw "$ModuleIdentifier - Find parameters - No parameter file/folder is provided."
}

$DeploymentOutputObjects = @()
foreach ($ParameterFile in $ParameterFiles) {
    New-GitHubLogGroup -Title "$ModuleIdentifier-$($ParameterFile.name)"
    switch ($DeployFile.Extension) {
        '.ps1' {
            Write-Output "$ModuleIdentifier-$($ParameterFile.name) - PowerShell module"

            Write-Output "$ModuleIdentifier-$($ParameterFile.name) - Test parameter file"
            if (! (Test-JSONParameters -ParameterFilePath $ParameterFile.FullName)) {
                throw "$ModuleIdentifier-$($ParameterFile.name) - Test parameter file - Failed"
            }
            Write-Output "$ModuleIdentifier-$($ParameterFile.name) - Test parameter file - Successfull"

            $DeploymentParameters = @{
                ParameterFilePath = $ParameterFile
                Action            = $Action
                Verbose           = $true
                ErrorAction       = 'Stop'
            }

            Write-Output "$ModuleIdentifier-$($ParameterFile.name) - Deploy using:"
            $DeploymentParameters

            $DeploymentOutputObject = . $DeployFile @DeploymentParameters
        }
        { $_ -in '.json', '.bicep' } {
            Write-Output "$ModuleIdentifier-$($ParameterFile.name) - ARM ($_) module"
            switch ($Action) {
                'WhatIf' {
                    $Operation = 'what-if'
                }
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
                    throw "$ModuleIdentifier-$($ParameterFile.name) - Action not supported"
                }
            }

            $Schema = (Get-Content -Raw -Path $ParameterFile | ConvertFrom-Json).'$schema'
            if ($Schema -notmatch '\/deploymentParameters.json#$') {
                Write-Warning "$ModuleIdentifier-$($ParameterFile.name) - Not a valid ARM parameter file"
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

            $DeploymentName = "$ModuleName-$(if($ModuleVersion){"$ModuleVersion-"})$( -join (Get-Date -Format yyyyMMddTHHMMssffffZ)[0..63])"
            $DeploymentNameParameter = "--name $DeploymentName"


            if ($ParameterOverrides | IsNotNullOrEmpty ) {
                Write-Output "$ModuleIdentifier-$($ParameterFile.name) - Adding ParameterOverrides:"
                Write-Output "    >$ParameterOverrides<"
                $Parameters += " $ParameterOverrides"
            }

            if ($Action -eq 'WhatIf') {
                $cmd = "az deployment $Scope $Operation $Target $DeploymentNameParameter $Template $LocationParam $Parameters --exclude-change-types Ignore"
            } else {
                $cmd = "az deployment $Scope $Operation $Target $DeploymentNameParameter $Template $LocationParam $Parameters --output json | ConvertFrom-Json"
            }

            Write-Output "$ModuleIdentifier-$($ParameterFile.name) - using:"
            $cmd

            for ($Retry = 1; $Retry -le $Retries; $Retry++) {
                New-GitHubLogGroup -Title "$ModuleIdentifier-$($ParameterFile.name) - Attempt $Retry/$Retries"
                $errorFromDeployment = $null
                $Failed = $false
                try {
                    $DeploymentOutput = Invoke-Expression -Command $cmd -ErrorAction Stop
                } catch {
                    Write-Warning "$ModuleIdentifier-$($ParameterFile.name) - Attempt $Retry/$Retries - Failure caught"
                    $Failed = $true
                    $errorFromDeployment = $_
                }
                $DeploymentExecutionStatus = $LASTEXITCODE

                if ($Failed -or ($DeploymentExecutionStatus -ne 0)) {
                    Write-Warning "$ModuleIdentifier-$($ParameterFile.name) - Attempt $Retry/$Retries - Failure."
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
                        throw $errorFromDeployment
                    }

                    Write-Output "    Retrying in $RetryInterval seconds."
                    Start-Sleep -Seconds $RetryInterval
                    continue
                }
                break
            }

            if ($Action -eq 'WhatIf') {
                Write-Output '    Showing WhatIfOutput:'
                $DeploymentOutput
                "## $DeploymentName" | Out-File -Path /tmp/OUTPUT.md -Append
                '```' | Out-File -Path /tmp/OUTPUT.md -Append
                $DeploymentOutput | Out-File -Path /tmp/OUTPUT.md -Append
                '```' | Out-File -Path /tmp/OUTPUT.md -Append
                Write-Output "::set-output name=Output::$DeploymentOutput"
            } else {
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
                Write-Output "::set-output name=Output::$($DeploymentOutputObjects | ConvertTo-Json -Compress -Depth 100)"
            }

        }
        '.yml' {
            Write-Output "$ModuleIdentifier-$($ParameterFile.name) - Ansible module"
        }
        '.tf' {
            Write-Output "$ModuleIdentifier-$($ParameterFile.name) - Terraform module"
        }

        default {
            throw "$ModuleIdentifier-$($ParameterFile.name) - $($DeployFile.Name) is not supported"
        }
    }
}

Write-Output '::endgroup::'

New-GitHubLogGroup -Title "$ModuleIdentifier-Output"
return $DeploymentOutputObjects
