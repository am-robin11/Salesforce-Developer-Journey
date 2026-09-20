// Run this in the Developer Console's "Execute Anonymous Window", or via
// VS Code (Salesforce Extension Pack) > "SFDX: Execute Anonymous Apex with
// Currently Selected Text", or `sf apex run --file 01_run_batch.apex`.
//
// This is Deliverable #3's "code used to process the existing Account
// records". Chunk size 2000 is chosen because this job does no callouts
// and only touches two simple fields per record - a larger scope size
// means fewer execute() invocations (fewer rows in Setup > Apex Jobs)
// for the same ~100,000 records, without risking the heap/CPU limits
// that a larger scope could cause for heavier logic.

Id jobId = Database.executeBatch(new AccountTierBatch(), 2000);
System.debug('AccountTierBatch submitted. Monitor progress at Setup > Apex Jobs. Job Id: ' + jobId);
