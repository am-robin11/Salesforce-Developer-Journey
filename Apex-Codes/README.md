# 🧠 Apex Codes

Practice code for learning Apex, from the first `System.debug` to data structures and database operations.

## What goes here

| Topic | Examples |
|---|---|
| **Apex Basics** | Variables, data types, operators, loops, conditionals, methods |
| **Collections** | `List`, `Set`, `Map` exercises |
| **OOP** | Classes, constructors, inheritance, interfaces, abstract/virtual classes, polymorphism |
| **DSA** | Sorting, searching, recursion, stacks, queues, and other algorithm practice |
| **SOQL** | Filtering, relationships, subqueries, aggregates |
| **SOSL** | Text search across multiple objects |
| **DML** | `insert`, `update`, `upsert`, `delete`, `undelete`, and the `Database` class |

> Database work (SOQL, SOSL, DML) lives right here alongside the rest of the Apex code, because in Apex they are part of the same language.

## File types

- `.cls` + `.cls-meta.xml` — Apex classes (always keep the two files together)
- `.apex` — Anonymous Apex scripts you can paste into the Developer Console or run with `sf apex run --file <path>`

## Running the code

- **Quick experiments:** paste the code into the Developer Console's *Execute Anonymous Apex* window (see the main [README](../README.md#devconsole)).
- **Classes:** deploy them to your org from VS Code, then call them from an anonymous Apex script.
