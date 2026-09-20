# 📝 Apex Tasks

Task-based Apex work: complete solutions with classes, triggers, and test classes.

## What goes here

- **Apex classes** — `TaskName.cls` and `TaskName.cls-meta.xml`
- **Apex triggers** — `TaskNameTrigger.trigger` and `TaskNameTrigger.trigger-meta.xml`
- **Test classes** — `TaskNameTest.cls` and `TaskNameTest.cls-meta.xml`

> Always commit the `-meta.xml` file together with its source file. Salesforce cannot deploy a class or trigger without it.

## Conventions

- Keep each task's class, trigger, and test class together.
- Name test classes `<ClassName>Test`.
- Write bulk-safe code (no SOQL or DML inside loops) and aim for **75%+ coverage** on every task.

## Deploying a task

Copy the files into a Salesforce DX project (`force-app/main/default/classes` and `triggers`) and deploy them:

```bash
sf project deploy start --source-dir force-app/main/default/classes
sf project deploy start --source-dir force-app/main/default/triggers
```

See the main [README](../README.md#vscode) for the full VS Code and CLI setup.
