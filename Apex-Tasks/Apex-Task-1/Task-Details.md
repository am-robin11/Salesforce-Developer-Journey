# Task - 01: Account Categorization Based on Annual Revenue

Create an Apex class that processes **all available Account records in the Salesforce environment** and categorizes them based on their Annual Revenue.

---

## Requirements

1. Retrieve all available Account records from the Salesforce environment.
2. Use the Account `AnnualRevenue` value to categorize each Account:
   - Annual Revenue greater than or equal to **20,000,000** → `Enterprise`
   - Annual Revenue greater than or equal to **1,000,000** → `Medium`
   - Annual Revenue below **1,000,000** → `Small`
3. Store the calculated category for each Account.
4. If required, create a custom field on Account, for example: `Customer_Category__c`

   Suggested picklist values:
   - Enterprise
   - Medium
   - Small
5. Update the Account records with the appropriate category.
6. Handle Accounts where `AnnualRevenue` is empty or not available.
7. Print the total number of Accounts processed after completion.

---

## Expected Submission

**09/09/2026**

---

## Deliverables

- The complete Apex class
- Any custom field created for storing the category
- A short explanation of how the categorization logic works
