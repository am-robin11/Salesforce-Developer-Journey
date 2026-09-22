// Creates an audit trail whenever an Opportunity moves into Closed Won.
// Runs in after-update context since we only want to log CONFIRMED changes,
// after the Opportunity has actually been saved.

public with sharing class AuditEditor {

    public static void createAuditRecords(List<Opportunity> newList, Map<Id, Opportunity> oldMap){
        List<Opportunity_Audit__c> auditList = new List<Opportunity_Audit__c>();
        Integer auditCount = 0;

        for(Opportunity opp : newList){
            Opportunity oldOpp = oldMap.get(opp.Id);

            // Only log it if the Stage actually CHANGED into Closed Won.
            // This covers requirement 4: bulk-safe, and ignores edits that don't touch Stage.

            if(opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won'){
                Opportunity_Audit__c audit = new Opportunity_Audit__c();
                audit.Opportunity__c   = opp.Id;
                audit.Previous_Stage__c = oldOpp.StageName;
                audit.New_Stage__c      = opp.StageName;
                audit.Changed_Date__c   = opp.CloseDate;
                audit.Changed_By__c     = UserInfo.getUserId();

                auditList.add(audit);
                auditCount++;
                System.debug('Audit prepared for: ' + opp.Name);
            }
        }

        if(!auditList.isEmpty()){
            // Using Database.insert with allOrNone = false so that if ONE audit record
            // fails, it does not throw an unhandled exception and roll back the
            // Opportunity update that already succeeded.
            Database.SaveResult[] results = Database.insert(auditList, false);

            Integer successCount = 0;
            Integer failCount = 0;

            for(Database.SaveResult sr : results){
                if(sr.isSuccess()){
                    successCount++;
                }
                else{
                    failCount++;
                    for(Database.Error err : sr.getErrors()){
                        System.debug('Audit creation FAILED: ' + err.getMessage());
                    }
                }
            }

            System.debug('Audit Records Attempted: ' + auditCount);
            System.debug('Audit Records Succeeded: ' + successCount);
            System.debug('Audit Records Failed: ' + failCount);
        }
        else{
            System.debug('No Stage changes to Closed Won detected in this batch.');
        }
    }
}