// Run this AFTER the batch job (from 01_run_batch.apex) shows "Completed"
// in Setup > Apex Jobs. This is Deliverable #3's verification evidence.

// 1) Tier-wise record count summary (Requirement 3's example table)
List<AggregateResult> summary = [
    SELECT Account_Tier__c tier, COUNT(Id) total
    FROM Account
    GROUP BY Account_Tier__c
    ORDER BY Account_Tier__c
];

System.debug('=== Account Tier-wise Summary ===');
Integer grandTotal = 0;
for (AggregateResult ar : summary) {
    Integer total = (Integer) ar.get('total');
    grandTotal += total;
    System.debug((String) ar.get('tier') + ': ' + total);
}
System.debug('Grand total Accounts: ' + grandTotal);

// 2) Sample of processed records showing every field the task asks for
System.debug('=== Sample processed Accounts ===');
List<Account> sample = [
    SELECT Name, AnnualRevenue, NumberOfEmployees, Account_Tier__c, Rating
    FROM Account
    ORDER BY AnnualRevenue DESC NULLS LAST
    LIMIT 20
];
for (Account a : sample) {
    System.debug(
        a.Name +
        ' | Revenue=' + a.AnnualRevenue +
        ' | Employees=' + a.NumberOfEmployees +
        ' | Tier=' + a.Account_Tier__c +
        ' | Rating=' + a.Rating
    );
}

// 3) Sanity check: any record where Tier/Rating are out of sync with the
// business rule at all (should return 0 rows once the batch has run)
Integer mismatchCount = 0;
for (Account a : [SELECT AnnualRevenue, NumberOfEmployees, Account_Tier__c, Rating FROM Account]) {
    String expectedTier = AccountTierRatingService.calculateTier(a.AnnualRevenue, a.NumberOfEmployees);
    String expectedRating = AccountTierRatingService.calculateRating(expectedTier);
    if (a.Account_Tier__c != expectedTier || a.Rating != expectedRating) {
        mismatchCount++;
    }
}
System.debug('Accounts still mismatched after processing: ' + mismatchCount);
