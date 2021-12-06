# AzModules - Deploy resources to Azure

[![Action-Test](https://github.com/equinor/AzModules/actions/workflows/Action-Test.yml/badge.svg)](https://github.com/equinor/AzModules/actions/workflows/Action-Test.yml)

[![Linter](https://github.com/equinor/AzModules/workflows/Linter/badge.svg)](https://github.com/equinor/AzModules/actions/workflows/Linter.yml)

[![GitHub](https://img.shields.io/github/license/equinor/AzModules)](LICENSE)

This action automates the validation, deployment and removal of resources in Azure using [idempotent](https://en.wikipedia.org/wiki/Idempotence#Computer_science_meaning)
[Infrastructure as Code (IaC)](https://en.wikipedia.org/wiki/Infrastructure_as_code) modules.
You can use the built-in module library that comes with this action or create and use your own module repository.

Supported IaC languages:

- Azure Resource Manager templates
  - ARM, (.json)
  - Bicep templates (.bicep)

Soon to come:

- Support for PowerShell based IaC modules. Useful when creating things which are not controlled by ARM, such as Azure AD resources, GitHub resources etc.
- Add support for using the `what-if` through a parameter, to support for showing what the deployment would do.
  - ARM templates: Will use [`What-if` commands](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-what-if?tabs=azure-powershell#what-if-commands)
  - Powershell IaC modules would need to support this too. Need to create guidelines for developing PowerShell modules using [`SupportsShouldProcess` and `WhatIf`](https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-shouldprocess?view=powershell-7.1#supportsshouldprocess)
- Additional testing when passing `Validate` as action.
  - ARM json/bicep: Today this is only using the `validate` task in AzCLI. Planning to add [ARM-TTK](https://github.com/Azure/arm-ttk).
  - Powershell IaC modules: Pester tests?
- Support for specifying deployment mode. Today this is `incremental` for ARM deployments.
- Support for overriding deployment name. Today this is automated within the framework.

Known issues:

- `Remove` action is not working as expected. Do not use `Remove` in production!

## Why use this module?

There are other public actions which have the same functions as this one, such as [azure/arm-deploy](https://github.com/azure/arm-deploy), [azure/powershell](https://github.com/azure/powershell) and [azure/cli](https://github.com/azure/cli).
However, there are some reasons why we chose to create this action:

- Uses the environment variables with same name as inputs to reduce the need of specifying same values multiple times, but still have override capability in the inputs given to the action.
  See [Input handling in AzActions](https://github.com/equinor/AzActions#input-handling) for details.
- Meant as a unified deployment framework supporting multiple the language used in the module/template to Azure.
- Supports more than the deployment action. This action can also be used to validate and remove deployments.
- Contains a library of modules and templates that are used by default.

These contributions would not make sense to contribute to [azure/arm-deploy](https://github.com/azure/login) as it will support more than ARM.

## Module library

By default the AzModules action uses the built-in module repository. This can be overridden by using the `ModulesPath` input.
The folder this is pointing to should be structured like the [`Modules`](https://github.com/equinor/AzModules/tree/main/Modules) folder in this repository.

| Module name (link to readme)                                                                                                 | IaC Language | Status                                                                                                                                                                                                                                       |
| :--------------------------------------------------------------------------------------------------------------------------- | :----------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [ActionGroup](https://github.com/equinor/AzModules/tree/main/Modules/ActionGroup/1.0#readme)                                 | ARM          | [![ActionGroup 1.0](https://github.com/equinor/AzModules/actions/workflows/Module-ActionGroup.yml/badge.svg)](https://github.com/equinor/AzModules/actions/workflows/Module-ActionGroup.yml)                                                 |
| [ActivityLog](https://github.com/equinor/AzModules/tree/main/Modules/ActivityLog/1.0#readme)                                 | ARM          | [![ActivityLog 1.0](https://github.com/equinor/AzModules/actions/workflows/Module-ActivityLog.yml/badge.svg)](https://github.com/equinor/AzModules/actions/workflows/Module-ActivityLog.yml)                                                 |
| [ActivityLogAlert](https://github.com/equinor/AzModules/tree/main/Modules/ActivityLogAlert/1.0#readme)                       | ARM          | [![ActivityLogAlert 1.0](https://github.com/equinor/AzModules/actions/workflows/Module-ActivityLogAlert.yml/badge.svg)](https://github.com/equinor/AzModules/actions/workflows/Module-ActivityLogAlert.yml)                                  |
| [AutomationAccount](https://github.com/equinor/AzModules/tree/main/Modules/AutomationAccount/1.0#readme)                     | ARM          | [![AutomationAccount 1.0](https://github.com/equinor/AzModules/actions/workflows/Module-AutomationAccount.yml/badge.svg)](https://github.com/equinor/AzModules/actions/workflows/Module-AutomationAccount.yml)                               |
| [Budgets](https://github.com/equinor/AzModules/tree/main/Modules/Budgets/1.0#readme)                                         | ARM          | [![Budgets 1.0](https://github.com/equinor/AzModules/actions/workflows/Module-Budgets.yml/badge.svg)](https://github.com/equinor/AzModules/actions/workflows/Module-Budgets.yml)                                                             |
| [LogAnalytics](https://github.com/equinor/AzModules/tree/main/Modules/LogAnalytics/1.0#readme)                               | ARM          | [![LogAnalytics 1.0](https://github.com/equinor/AzModules/actions/workflows/Module-LogAnalytics.yml/badge.svg)](https://github.com/equinor/AzModules/actions/workflows/Module-LogAnalytics.yml)                                              |
| [MetricAlert](https://github.com/equinor/AzModules/tree/main/Modules/MetricAlert/1.0#readme)                                 | ARM          | [![MetricAlert 1.0](https://github.com/equinor/AzModules/actions/workflows/Module-MetricAlert.yml/badge.svg)](https://github.com/equinor/AzModules/actions/workflows/Module-MetricAlert.yml)                                                 |
| [ResourceGroup](https://github.com/equinor/AzModules/tree/main/Modules/ResourceGroup/1.0#readme)                             | ARM          | [![ResourceGroup 1.0](https://github.com/equinor/AzModules/actions/workflows/Module-ResourceGroup.yml/badge.svg)](https://github.com/equinor/AzModules/actions/workflows/Module-ResourceGroup.yml)                                           |
| [SoftwareUpdateConfiguration](https://github.com/equinor/AzModules/tree/main/Modules/SoftwareUpdateConfiguration/1.0#readme) | ARM          | [![SoftwareUpdateConfiguration 1.0](https://github.com/equinor/AzModules/actions/workflows/Module-SoftwareUpdateConfiguration.yml/badge.svg)](https://github.com/equinor/AzModules/actions/workflows/Module-SoftwareUpdateConfiguration.yml) |

### Test and validation process for modules

This process is currently being established.

### ARM/Bicep WhatIf deployment

When doing ARM/Bicep you can use [WhatIf deployments](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-what-if?tabs=azure-cli) to see which changes will be performed by you operation. This is also possible with our framework.

See usage example [here](#using-whatif).

When a deployment with action `WhatIf` is processed, you will get an output message with the required changes to your infrastructure. You can then decide if this is should be deployed, or if you want to change the code for any reason.

What-If will always run on a Pull Request to main branch.

### PowerShell WhatIf

An action value of `what-if` will be input as a parameter to the PowerShell script. PowerShell scripts to be deployed need to support this action value, and implement their own version of What-If.

## Inputs

| Input name            | Default  | Required | Description                                                                                                            | Allowed values                                                                                                                        |
| :-------------------- | :------- | :------- | :--------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------ |
| `Action`              | `Deploy` | No       | The action to perform.                                                                                                 | WhatIf, Validate, Deploy, Remove                                                                                                      |
| `ResourceGroupName`   |          | No       | Target Resource Group to deploy resources to.                                                                          | string                                                                                                                                |
| `Subscription`        |          | No       | Subscription ID or name to deploy resources to.                                                                        | string (GUID or name of subscription)                                                                                                 |
| `ManagementGroupID`   |          | No       | Target Management Group to deploy resources to.                                                                        | string                                                                                                                                |
| `Location`            |          | No       | Azure location for where to deploy resources.                                                                          | string (valid Azure location)                                                                                                         |
| `ModulesFolderPath`   |          | No       | Path to a custom module library, structured as /\<ModuleName\>/\<ModuleVersion\>/deploy.*.                             | string                                                                                                                                |
| `ModuleName`          |          | No       | Name and version of module.                                                                                            | string                                                                                                                                |
| `ModuleVersion`       |          | No       | Version of module.                                                                                                     | string ([simver](https://simver.org/))                                                                                                |
| `ParameterFilePath`   |          | No       | Path to Parameter file. Will deploy based on single parameter file. Need to use either this or ParametersFolderPath.   | Relative or absolute path to a variables json file.                                                                                   |
| `ParameterFolderPath` |          | No       | Path to Parameter folder. Will deploy based on multiple parameter files. Need to use either this or ParameterFilePath. | Relative or absolute path to a folder containing variables json files.                                                                |
| `ParameterOverrides`  |          | No       | Parameter overrides.                                                                                                   | string [Provided as expected by AzCLI](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-cli#parameters) |
| `Retries`             | 5        | No       | Number of retries in case of failed attempts.                                                                          | integer                                                                                                                               |
| `RetryInterval`       | 10       | No       | Number of seconds between retries.                                                                                     | integer                                                                                                                               |

### Input overrides

This action uses environment variables with input overrides. For more info please read our article on [Input handling](https://github.com/equinor/AzActions#input-handling)

### Parameter precedence

1. Input Variable
2. Environment Variable
3. Values from parameter file
4. Defaults in template

As an exstension of [Bicep Parameter Precedence | Microsoft Docs](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/parameter-files#parameter-precedence)

## Outputs

| Output name | Data type                      | Description                                                                     |
| :---------- | :----------------------------- | :------------------------------------------------------------------------------ |
| `Output`    | Compressed json data structure | The object(s) which were deployed. Output properties are defined by the module. |

## Environment variables

N/A

## Usage

### Using the built-in modules

```yml
name: Test-Workflow

on: [push]

env:
  TenantID: 0229e31e-273f-49bc-befe-eb255ae83dfc
  AppID: a3825ed9-ca00-4355-9b3e-a37f12f9cf44
  Subscription: Dev-Subscription-123
  AppSecret: ${{ secrets.APP_SECRET }}
  Location: norwayeast

jobs:
  Validate:
    runs-on: ubuntu-latest
    steps:

      - name: Checkout parameter
        uses: actions/checkout@v2

      - name: Connect to Azure
        uses: equinor/AzConnect@v1

      - name: Deploy resource group
        id: DeployRG
        uses: equinor/AzModules@v1
        with:
          ModuleName: ResourceGroup
          ModuleVersion: '1.0'
          ParameterFilePath: Parameters/ResourceGroup/MyRg.json
```

### Using a custom module library

When using this action with a custom library, use the

```yml
name: Test-Workflow

on: [push]

env:
  TenantID: 0229e31e-273f-49bc-befe-eb255ae83dfc
  AppID: a3825ed9-ca00-4355-9b3e-a37f12f9cf44
  Subscription: Dev-Subscription-123
  AppSecret: ${{ secrets.APP_SECRET }}
  ModulesPath: './MyOwnModules' ## Required folder structure ./<ModuleName>/ModuleVersion/deploy.*
  Location: norwayeast
  ResourceGroupName: 'MyOwnResources-RG'

jobs:
  Validate:
    runs-on: ubuntu-latest
    steps:

      - name: Checkout parameters
        uses: actions/checkout@v2

      - name: Checkout modules
        uses: actions/checkout@v2
        with:
          clean: false # So the parameter checkout is not cleaned out
          repository: Someone/MyOwnModules
          path: ${{ env.ModulesPath}}

      - name: Connect to Azure
        uses: equinor/AzConnect@v1

      - name: Deploy resource
        id: Deploy
        uses: equinor/AzModules@v1
        with:
          ModuleName: ResourceGroup
          ModuleVersion: '1.0'
          #ModulesPath: ${{ env.ModulesPath}} # Will get env var with same name by default.
          # Assume param file does not contain ResourceGroupName parameter
          ParameterFilePath: Parameters/ResourceGroup/MyOwnResources-RG.json
          # ResourceGroupName can be passed from environment variables using ParametersOverrides.
          ParameterOverrides: resourceGroupName=${{ env.ResourceGroupName }}

```

### Using WhatIf

You can use WhatIf deployment to check which changes will be deployed.

```yml
name: Test-Workflow

on: [push]

env:
  TenantID: 0229e31e-273f-49bc-befe-eb255ae83dfc
  AppID: a3825ed9-ca00-4355-9b3e-a37f12f9cf44
  Subscription: Dev-Subscription-123
  AppSecret: ${{ secrets.APP_SECRET }}
  Location: norwayeast

jobs:
  Validate:
    runs-on: ubuntu-latest
    steps:

      - name: Checkout parameter
        uses: actions/checkout@v2

      - name: Connect to Azure
        uses: equinor/AzConnect@v1

      - name: Deploy resource group
        id: DeployRG
        uses: equinor/AzModules@v1
        with:
          ModuleName: ResourceGroup
          ModuleVersion: '1.0'
          Action: 'WhatIf'
          ParameterFilePath: Parameters/ResourceGroup/MyRg.json
```

### How to handle output

This example show how you can take output from one deployment and feed it in as input/parameter on next deployment.

```yml
name: Test-Workflow

on: [push]

env:
  TenantID: 0229e31e-273f-49bc-befe-eb255ae83dfc
  AppID: a3825ed9-ca00-4355-9b3e-a37f12f9cf44
  Subscription: Dev-Subscription-123
  AppSecret: ${{ secrets.APP_SECRET }}
  Location: norwayeast
  ResourceGroupName: 'MyOwnResources-RG'

jobs:
  Validate:
    runs-on: ubuntu-latest
    steps:

      - name: Checkout parameters
        uses: actions/checkout@v2

      - name: Connect to Azure
        uses: equinor/AzConnect@v1

      - name: Deploy resource group
        id: DeployRG
        uses: equinor/AzModules@v1
        with:
          ModuleName: ResourceGroup
          ModuleVersion: '1.0'
          # Assume param file does not contain the required 'ResourceGroupName' parameter
          ParameterFilePath: Parameters/ResourceGroup/MyOwnResources-RG.json
          # 'ResourceGroupName' can be passed from environment variables as an override.
          ParameterOverrides: resourceGroupName=${{ env.ResourceGroupName }}

      - name: Deploy ActionGroup
        id: DeployAG
        uses: equinor/AzModules@v1
        with:
          ModuleName: ActionGroup
          ModuleVersion: '1.0'
          # Outputs from a deployment can be used as an input in another deployment.
          ResourceGroupName: '${{ fromJSON(steps.DeployRG.outputs.Output).resourceGroupName }}'
          ParameterFilePath: Parameters/ActionGroup/MyActionGroup.json

```

## Dependencies

- [equinor/AzUtilities](https://www.github.com/equinor/AzUtilities)
- [action/checkout](https://github.com/actions/checkout), to check out parameters and modules.
- [equinor/AzConnect](https://github.com/equinor/AzConnect), if the resources to deploy are Azure based. Other connection steps might be needed for different solutions.

## Contributing

This project welcomes contributions and suggestions. Please review [How to contribute](https://github.com/equinor/AzActions#how-to-contibute) on our [AzActions](https://github.com/equinor/AzActions) page.
