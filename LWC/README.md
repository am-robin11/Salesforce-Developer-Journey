# ⚡ Lightning Web Components

Daily Lightning Web Component practice and tasks.

## What goes here

Each component is its own folder containing:

| File | Purpose |
|---|---|
| `componentName.html` | Template |
| `componentName.js` | JavaScript logic |
| `componentName.css` | Styles (optional) |
| `componentName.js-meta.xml` | Metadata (API version, exposure, targets) |

> Folder and file names must be **camelCase** (for example `accountList`), and the folder name must match the file names inside it.

If a component calls Apex, commit the Apex controller (with its `-meta.xml`) in [`Apex-Tasks`](../Apex-Tasks) so the component can be deployed and run end to end.

## Deploying a component

Copy the component folder into a Salesforce DX project's `force-app/main/default/lwc` directory and deploy it:

```bash
sf project deploy start --source-dir force-app/main/default/lwc/componentName
```

Then add it to a Lightning page with **App Builder** (make sure `<isExposed>true</isExposed>` and the right `<targets>` are set in the meta file).

See the main [README](../README.md#vscode) for the full setup.
