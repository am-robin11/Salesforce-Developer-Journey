# Task Manager — Salesforce DX Project

A Salesforce Lightning application built with Lightning Web Components (LWC) and Apex. It demonstrates a source-driven Salesforce DX workflow, CRUD operations against Salesforce's **standard `Task` object**, Apex unit tests, and unlocked-package delivery.

> **Current data model:** This version uses the standard Salesforce `Task` object. It does not define a custom `Task__c` object. The app operates on tasks owned by the current user. Because it uses a standard object, there is no custom object metadata to package for `Task` itself.

## Features

- Create tasks with a subject, due date, priority, and description.
- List tasks owned by the current user.
- Edit task details and status.
- Mark tasks as completed.
- Delete tasks.
- Apex controller and Apex tests for read/create/update/delete operations.
- Lightning app and custom tab metadata.

## Technology

- Salesforce DX project structure and Salesforce CLI (`sf`)
- Apex and SOQL
- Lightning Web Components
- Salesforce Metadata API
- Optional LWC Jest, ESLint, and Prettier tooling from `package.json`

## Repository layout

```text
ToDO_App_Project/
├── config/
│   └── project-scratch-def.json
├── force-app/main/default/
│   ├── applications/       # Task Manager Lightning app
│   ├── classes/            # Apex controller and test class
│   ├── contentassets/      # App logo asset
│   ├── lwc/taskManager/    # LWC UI, metadata, and Jest test
│   └── tabs/               # Task Manager custom tab
├── package.json            # JavaScript/LWC quality and test scripts
├── sfdx-project.json       # Salesforce DX and package configuration
└── README.md
```

Local Salesforce caches and authentication files (`.sf`, `.sfdx`) should not be committed to Git. They are excluded from the clean archive prepared with this README.

## Prerequisites

1. A supported version of Salesforce CLI (`sf`). Install it from [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli).
2. Visual Studio Code and the Salesforce Extension Pack (recommended).
3. A Salesforce Developer Edition org or sandbox for development.
4. A Dev Hub-enabled org if you intend to create scratch orgs or unlocked-package versions.
5. Node.js/npm only if you intend to run the optional LWC Jest, ESLint, and Prettier tooling.
6. Git if you intend to version the project in GitHub.

Check installations:

```powershell
sf --version
node --version
npm --version
git --version
```

## 1. Get the project

Clone your repository, or place the `ToDO_App_Project` folder inside an existing repository. Open a terminal in the project folder—the directory containing `sfdx-project.json`.

```powershell
Set-Location "D:\path\to\ToDO_App_Project"
```

Do not run Salesforce project commands from the parent repository folder unless that folder itself contains this project's `sfdx-project.json`.

## 2. Authenticate to Salesforce

For a Developer Edition or production org:

```powershell
sf org login web --alias TaskManagerDev --instance-url https://login.salesforce.com --set-default
```

For a sandbox, use `https://test.salesforce.com` instead. Complete the browser login, then verify:

```powershell
sf org list
sf org display --target-org TaskManagerDev
```

Use your own org alias. Do not commit authentication tokens or local CLI state.

## 3. Create a scratch org (optional)

Scratch orgs require a Dev Hub. Authenticate the Dev Hub first:

```powershell
sf org login web --alias TaskManagerHub --instance-url https://login.salesforce.com --set-default-dev-hub
```

Create a scratch org using the supplied definition:

```powershell
sf org create scratch --definition-file config/project-scratch-def.json --alias TaskManagerScratch --duration-days 7 --set-default
```

Open it:

```powershell
sf org open --target-org TaskManagerScratch
```

If you already have a suitable development org, you can skip scratch-org creation and deploy to that org instead.

## 4. Deploy the source

From the directory containing `sfdx-project.json`:

```powershell
sf project deploy start --source-dir force-app --target-org TaskManagerDev
```

Replace `TaskManagerDev` with your target org alias. To deploy to the scratch org, use `TaskManagerScratch`.

After deployment, open the org and launch **Task Manager** from the App Launcher. If the app is not visible, check that deployment succeeded and that the current user has access to the app/tab and permission to use the relevant Task fields.

## 5. Test the Apex implementation

Run the controller test class:

```powershell
sf apex run test --target-org TaskManagerDev --tests TaskManagerControllerTest --result-format human --wait 30
```

Or run all Apex tests:

```powershell
sf apex run test --target-org TaskManagerDev --result-format human --wait 30
```

A successful test run verifies the assertions covered by the test class; it is not a substitute for testing the app manually as a non-administrator. The test class inserts its own test records and should not rely on existing org data.

## 6. Optional LWC unit tests and linting

Install the project's JavaScript development dependencies:

```powershell
npm install
```

Then run:

```powershell
npm test
npm run lint
npm run prettier:verify
```

These commands require compatible Node/npm versions and installed dependencies. Resolve any tooling/version errors before treating these checks as passing. Do not commit `node_modules/` or generated coverage output.

## 7. Package the app as an unlocked package (optional)

Packaging requires a Dev Hub and a package definition. The `sfdx-project.json` currently contains a package alias named `Task Manager` and an existing subscriber package version alias. Those IDs belong to the original packaging environment; verify them against your own Dev Hub before using them. If you are working in a different Dev Hub, create a new package instead of assuming those IDs exist there.

List packages and versions:

```powershell
sf package list --target-dev-hub TaskManagerHub
sf package version list --target-dev-hub TaskManagerHub
```

If you need to create a new unlocked package, first ensure the `packageDirectories` entry in `sfdx-project.json` points to `force-app`, then run:

```powershell
sf package create --name "Task Manager" --package-type Unlocked --path force-app --target-dev-hub TaskManagerHub --no-namespace
```

Record the new package ID and update `packageAliases` in `sfdx-project.json` if the CLI has not already done so. Do not create a duplicate package if the correct package already exists in your Dev Hub.

Create a package version after deploying and testing the source:

```powershell
sf package version create --package "Task Manager" --installation-key-bypass --code-coverage --wait 30 --target-dev-hub TaskManagerHub
```

If the version creation reports a test, coverage, dependency, or metadata error, fix that error and retry. A successful version creation returns a subscriber package version ID. Inspect the result:

```powershell
sf package version list --packages "Task Manager" --target-dev-hub TaskManagerHub
```

Install a version into a **test org first**, using the subscriber package version ID returned by your own CLI output:

```powershell
sf package install --package 04tXXXXXXXXXXXXXXX --target-org TaskManagerTest --wait 30 --publish-wait 30
```

Replace the sample ID with the real `04t...` ID and authenticate `TaskManagerTest` first. Verify the app, CRUD operations, and permissions in the receiving org before sharing the installation URL. Package installation does not automatically assign a permission set unless your installation process explicitly does so; review access requirements for the target users.

## 8. Put this project in a folder in your existing GitHub repository

The GitHub repository shown in the supplied screenshot is `Salesforce-Developer-Journey`. Clone it if it is not already on your computer:

```powershell
git clone https://github.com/<YOUR-ACCOUNT>/Salesforce-Developer-Journey.git
```

Copy the `ToDO_App_Project` directory into the cloned repository, preserving the folder name. For example, the resulting structure can be:

```text
Salesforce-Developer-Journey/
├── Apex-Codes/
├── Apex-Tasks/
├── LWC/
├── Project/
├── The Final Project/
└── ToDO_App_Project/
    ├── README.md
    ├── sfdx-project.json
    └── force-app/
```

Then, from the **root of `Salesforce-Developer-Journey`**, review and commit the folder:

```powershell
git status
git add ToDO_App_Project
git commit -m "Add Salesforce Task Manager DX project"
git push origin main
```

If you use a feature branch, create/switch to that branch before committing and push that branch instead; open a pull request to merge it into `main`. If your repository's default branch is not `main`, use the actual branch name. Avoid placing a nested `.git` directory inside `ToDO_App_Project`—the project should be a normal folder within the parent repository, not a separate Git repository.

## 9. Validate after publishing

- Open the folder in GitHub and confirm `README.md`, `sfdx-project.json`, Apex classes, LWC files, app metadata, tab metadata, and logo asset are present.
- Confirm no `.sf/`, `.sfdx/`, `.git/`, `node_modules/`, credentials, or local auth files were added.
- Clone the repository into a fresh directory and repeat the deployment/test steps to verify the documented workflow.
- Install the package into a clean test org if package distribution is required.

## Important limitations and security notes

- The app uses Salesforce's standard `Task` object, not a custom `Task__c` object. It does not need to package a definition for the standard object.
- The Apex class declares `with sharing`, which enforces record-level sharing but does **not by itself** enforce object CRUD or field-level security. Review and implement the appropriate user-mode operations or explicit CRUD/FLS checks before using the app with untrusted or restricted users.
- The current query filters by `OwnerId` for the logged-in user. Review whether that is the intended visibility model for your organization.
- Validate field permissions, task status/picklist values, and behavior in a clean target org; permissions and org configuration can differ.
- The package alias IDs in `sfdx-project.json` are environment-specific. Use your own Dev Hub and package IDs when reproducing packaging steps.
- No deployment, tests, or package-version creation are executed by this README itself; run the commands and confirm their results in your environment.

## Useful references

- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)
- [Lightning Web Components Developer Guide](https://developer.salesforce.com/docs/platform/lwc/guide)
