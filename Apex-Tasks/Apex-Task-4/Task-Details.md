# Task - 04:- Account Tier & Rating Automation

## Background

The Salesforce environment already contains approximately **100,000 Account records**.
Each Account contains information such as:

| Field | Description |
| --- | --- |
| Name | Account name |
| Phone | Account phone number |
| Website | Company website |
| Type | Account type |
| Industry | Industry of the Account |
| AnnualRevenue | Annual revenue |
| NumberOfEmployees | Number of employees |

Management wants to classify all existing Account records based on company size and keep the Account Rating synchronized with the classification.

---

## Requirement 1 – Update Account Tier for Existing Records

Create a new custom field on Account:

- **Field Label:** Account Tier
- **API Name:** `Account_Tier__c`
- **Type:** Picklist
- **Picklist values:**
  - Enterprise
  - Large
  - Medium
  - Small

The Salesforce environment already contains approximately **100,000 Account records**.
Update the Account Tier for all existing Account records based on the following rules:

| Account Tier | Criteria |
| --- | --- |
| Enterprise | Annual Revenue ≥ 1,000,000,000 **OR** Number of Employees ≥ 10,000 |
| Large | Annual Revenue ≥ 100,000,000 **OR** Number of Employees ≥ 1,000 |
| Medium | Annual Revenue ≥ 10,000,000 **OR** Number of Employees ≥ 100 |
| Small | All other Accounts |

**Expected Behavior**

- All existing Account records should be evaluated.
- `Account_Tier__c` should contain the correct value after processing.
- Records that already contain the correct Account Tier should not be updated unnecessarily.
- The solution should be able to process the full Account dataset successfully.
- The implementation should work efficiently with a large number of records.

---

## Requirement 2 – Automatically Update Account Rating

Whenever the value of `Account_Tier__c` is changed, update the standard Account `Rating` field automatically.

Use the following mapping:

| Account Tier | Account Rating |
| --- | --- |
| Enterprise | Hot |
| Large | Hot |
| Medium | Warm |
| Small | Cold |

**Expected Behavior**

The Rating should be updated whenever:

- A new Account is created with an Account Tier.
- An existing Account Tier is changed.
- Account Tier changes from one classification to another.

---

## Requirement 3 – Verify Existing Account Processing

After processing the existing Account records, verify that the Account Tier values have been populated correctly.
The verification should show at least:

- Account Name
- Annual Revenue
- Number of Employees
- Account Tier
- Rating

You should also verify the total number of Accounts belonging to each Account Tier.
Example expected summary:

| Account Tier | Number of Accounts |
| --- | --- |
| Enterprise | X |
| Large | X |
| Medium | X |
| Small | X |

---

## Requirement 4 – Apex Unit Testing

Prepare appropriate **Apex test classes** for all implemented Apex classes and triggers.
The test classes should provide sufficient coverage for the developed functionality and verify that the implementation behaves correctly in different scenarios.
The tests should cover, at minimum: **85% Test coverage**

---

## Deliverables

Submit the following:

1. All Apex code developed for the assignment.
2. Apex test classes.
3. Code used to process the existing Account records.
4. Result showing that the existing Account records were processed successfully.
5. Account Tier-wise record count.
6. Sample processed Account records showing:
   - Annual Revenue
   - Number of Employees
   - Account Tier
   - Rating
7. Test execution result and code coverage.
8. A short explanation describing:
   - How the existing 100,000 Account records were processed.
   - How Account Tier is calculated.
   - How Rating is synchronized with Account Tier.
   - How the implementation handles multiple records efficiently.
   - How unnecessary record updates are avoided.

---

## Submission Details

| | |
| --- | --- |
| **File Type** | Zip |
| **File Format** | TraineeId_TraineeName_Task_04 |
| **Location** | Shared privately within the training program (link not published here) |
| **Due Date** | 15th September 04 PM BST |
