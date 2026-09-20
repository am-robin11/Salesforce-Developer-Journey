# Task - 03:- Opportunity Closure Validation & Audit Processing

Your company wants to introduce a new business rule for **Opportunity** records.
When an Opportunity moves to **Closed Won**, Salesforce must validate the record, protect sensitive data, and automatically create an audit record.

---

## Business Scenario

Sales representatives work with Opportunities. Management has requested the following controls:

1. A user should not be able to mark an Opportunity as `Closed Won` if:
   - `Amount` is empty or zero.
   - `CloseDate` is empty.
   - Implement this requirement using a **Salesforce Validation Rule**.
2. When an Opportunity is successfully changed to `Closed Won`:
   - Create a related audit record to track the change.
   - The audit record should store:
     - Opportunity
     - Previous Stage
     - New Stage
     - Changed Date
     - Changed By
3. The implementation must respect Salesforce security.
   - Users should not be able to access or update records beyond the access they are supposed to have.
   - The solution should not assume that every user has access to every field used by the logic.
4. The trigger must work correctly when:
   - One Opportunity is updated.
   - Multiple Opportunities are updated together.
   - An Opportunity is edited without changing the Stage.
5. If the audit record creation fails for one Opportunity:
   - The failure should be handled properly.
   - The developer should decide whether the Opportunity update should continue or fail, and explain the reason for that decision.

---

## Additional Requirement

The trainee should identify **where this logic executes in Salesforce Order of Execution** and explain:

- When the Validation Rule executes.
- When the trigger runs.
- When the Opportunity is actually saved.
- What happens if the Validation Rule fails.
- What happens if an exception is thrown during the transaction.

---

## Expected Submission

**14 September 2026, 10 AM BST**

---

## Deliverables

- The Salesforce Validation Rule
- The Apex Trigger
- Any supporting Apex class used
- The audit object/field design if a custom object is required
- Exception-handling logic
- A short explanation covering:
  - Validation Rule behavior
  - Security handling
  - Trigger context used
  - Bulk processing
  - Order of Execution
  - What happens when an error occurs during the transaction

---

## Submission Details

| | |
| --- | --- |
| **File Type** | Zip |
| **File Format** | TraineeId_TraineeName_Task_03 |
| **Location** | Shared privately within the training program (link not published here) |
