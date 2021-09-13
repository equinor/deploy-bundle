<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		Set-AkvSecrets.ps1

		Purpose:	Set Log Analytics Key Secrets

		Version: 	3.0.0.0 - 1st November 2020
		==============================================================================================

		DISCLAIMER
		==============================================================================================
		This script is not supported under any Microsoft standard support program or service.

		This script is provided AS IS without warranty of any kind.
		Microsoft further disclaims all implied warranties including, without limitation, any
		implied warranties of merchantability or of fitness for a particular purpose.

		The entire risk arising out of the use or performance of the script
		and documentation remains with you. In no event shall Microsoft, its authors,
		or anyone else involved in the creation, production, or delivery of the
		script be liable for any damages whatsoever (including, without limitation,
		damages for loss of business profits, business interruption, loss of business
		information, or other pecuniary loss) arising out of the use of or inability
		to use the sample scripts or documentation, even if Microsoft has been
		advised of the possibility of such damages.

		IMPORTANT
		==============================================================================================
		This script uses or is used to either create or sets passwords and secrets.
		All coded passwords or secrests supplied from input files must be created and provided by the customer.
		Ensure all passwords used by any script are generated and provided by the customer
		==============================================================================================

	.SYNOPSIS
		Set Log Analytics Key Secrets.

	.DESCRIPTION
		Set Log Analytics Key Secrets.

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters
		2) Set Log Analytics Parameters
		3) Create Azure KeyVault Secret

	.PARAMETER keyVaultName
		Specify the Azure KeyVault Name parameter.

	.PARAMETER logAnalyticsName
		Specify the Log Analytics Workspace Name Id output parameter.

	.PARAMETER logAnalyticsResourceId
		Specify the Log Analytics Resource Id output parameter.

	.PARAMETER logAnalyticsResourceGroup
		Specify the Log Analytics Workspace Resource Group output parameter.

	.PARAMETER logAnalyticsWorkspaceId
		Specify the Log Analytics Workspace Id output parameter.

	.PARAMETER logAnalyticsPrimarySharedKey
		Specify the Log Analytics Primary Shared Key output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\LogAnalytics.akv.set.secrets.ps1
			-keyVaultName "$(keyVaultName)"
			-logAnalyticsName "$(logAnalyticsName)"
			-logAnalyticsResourceId "$(logAnalyticsResourceId)"
			-logAnalyticsResourceGroup "$(logAnalyticsResourceGroup)"
			-logAnalyticsWorkspaceId "$(logAnalyticsWorkspaceId)"
			-logAnalyticsPrimarySharedKey "$(logAnalyticsPrimarySharedKey)"
#>

#Requires -Module Az.KeyVault

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $false)]
    [string]$keyVaultName,

    [parameter(Mandatory = $false)]
    [string]$logAnalyticsName,

    [parameter(Mandatory = $false)]
    [string]$logAnalyticsResourceId,

    [parameter(Mandatory = $false)]
    [string]$logAnalyticsResourceGroup,

    [parameter(Mandatory = $false)]
    [string]$logAnalyticsWorkspaceId,

    [parameter(Mandatory = $false)]
    [string]$logAnalyticsPrimarySharedKey
)

#region - KeyVault Parameters
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['keyVaultName'])) {
    Write-Output "KeyVault Name: $keyVaultName"
    $kvSecretParameters = @{ }

    #region - Log Analytics Parameters
    if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['logAnalyticsName'])) {
        Write-Output "Log Analytics Workspace Name: $logAnalyticsName"
        $kvSecretParameters.Add("LogAnalytics--Name--$($logAnalyticsName)", $($logAnalyticsName))
    } else {
        Write-Output 'Log Analytics Workspace Name: []'
    }

    if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['logAnalyticsResourceId'])) {
        Write-Output "Log Analytics ResourceId: $logAnalyticsResourceId"
        $kvSecretParameters.Add("LogAnalytics--ResourceId--$($logAnalyticsName)", $($logAnalyticsResourceId))
    } else {
        Write-Output 'Log Analytics ResourceId: []'
    }

    if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['logAnalyticsResourceGroup'])) {
        Write-Output "LogAnalytics ResourceGroup: $logAnalyticsResourceGroup"
        $kvSecretParameters.Add("LogAnalytics--ResourceGroup--$($logAnalyticsName)", $($logAnalyticsResourceGroup))
    } else {
        Write-Output 'LogAnalytics ResourceGroup: []'
    }

    if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['logAnalyticsWorkspaceId'])) {
        Write-Output "Log Analytics WorkspaceId: $logAnalyticsWorkspaceId"
        $kvSecretParameters.Add("LogAnalytics--WorkspaceId--$($logAnalyticsName)", $($logAnalyticsWorkspaceId))
    } else {
        Write-Output 'LogAnalytics WorkspaceId: []'
    }

    if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['logAnalyticsPrimarySharedKey'])) {
        Write-Output "Log Analytics Primary Shared Key: $logAnalyticsPrimarySharedKey"
        $kvSecretParameters.Add("LogAnalytics--PrimarySharedKey--$($logAnalyticsName)", $($logAnalyticsPrimarySharedKey))
    } else {
        Write-Output 'Log Analytics Primary Shared Key: []'
    }
    #endregion

    #region - Set Azure KeyVault Secret
    $kvSecretParameters.Keys | ForEach-Object {
        $key = $psitem
        $value = $kvSecretParameters.Item($psitem)

        if (-not [string]::IsNullOrWhiteSpace($value)) {
            Write-Output "KeyVault Secret: $key : $value"
            $value = $kvSecretParameters.Item($psitem)
            $paramSetAzKeyVaultSecret = @{
                VaultName   = $keyVaultName
                Name        = $key
                SecretValue = (ConvertTo-SecureString $value -AsPlainText -Force)
                Verbose     = $true
                ErrorAction = 'SilentlyContinue'
            }
            Set-AzKeyVaultSecret @paramSetAzKeyVaultSecret
        } else {
            Write-Output "KeyVault Secret: $key - []"
        }
    }
    #endregion
} else {
    Write-Output 'KeyVault Name: []'
}
#endregion
