# Task - 02:- Previous Task Enhancement: Account Categorization Update

Update the previously completed **Account Categorization** solution with the following new business requirements.

---

## Enhancement Requirements

1. **Missing Revenue Handling**
   - If `AnnualRevenue` is blank, categorize the Account as `Unclassified`.
2. **Industry-Based Priority Rule**
   - If:
     - `Industry = Technology`
     - `AnnualRevenue >= 5,000,000`
   - Categorize the Account as `Priority`.
   - Also update the Account `Rating` to `Hot`.
3. **Existing Revenue-Based Categories**
   - `AnnualRevenue >= 10,000,000` → `Enterprise`
   - `AnnualRevenue >= 1,000,000` → `Medium`
   - `AnnualRevenue < 1,000,000` → `Small`
4. **Processing Summary**
   - At the end of processing, display:
     - Total Accounts checked
     - Total Accounts updated
     - Number of Priority Accounts
     - Number of Unclassified Accounts
     - Number of Enterprise Accounts
     - Number of Medium Accounts
     - Number of Small Accounts

---

## Expected Submission

**10 September 2026**

---

## Deliverables

- Updated Apex class
- Updated categorization logic
- Updated Account `Rating` handling
- Processing summary output (debug log)
- A short explanation of how the new requirements were implemented

---

## Submission Details

| | |
| --- | --- |
| **File Type** | Zip |
| **File Format** | TraineeId_TraineeName_Task_02 |
| **Location** | Shared privately within the training program (link not published here) |
