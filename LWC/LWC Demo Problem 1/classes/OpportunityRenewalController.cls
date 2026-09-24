/**
 * Scenario: "Opportunity Renewal Tracker"
 *
 * Sales ops wants a component that shows every OPEN Opportunity closing within
 * the next 30 days, optionally filtered by Stage, with the total pipeline value
 * of that list. Reps need to be able to:
 *   1) Push an overdue Opportunity's Close Date out by 30 days, and
 *   2) Mark any listed Opportunity as Closed Won,
 * both without leaving the component, and see the list refresh immediately.
 */
public with sharing class OpportunityRenewalController {

    // Wrapper class: lets one cacheable Apex method hand back BOTH the record
    // list AND a server-calculated total in a single round trip, instead of
    // making the LWC issue two separate @wire calls.
    public class OpportunitySummary {
        @AuraEnabled public List<Opportunity> opportunities;
        @AuraEnabled public Decimal totalPipelineValue;
        @AuraEnabled public Integer overdueCount;
    }

    // ------------------------------------------------------------------
    // READ (SOQL) — cacheable=true because this only reads data and is
    // meant to be used with @wire.
    // ------------------------------------------------------------------
    @AuraEnabled(cacheable=true)
    public static OpportunitySummary getUpcomingOpenOpportunities(String stageFilter) {
        Date cutoff = Date.today().addDays(30);
        List<Opportunity> opps;

        // Two static SOQL branches (same pattern as the Day 3 Apex demo):
        // one for "no filter", one for "filter applied".
        if (String.isBlank(stageFilter) || stageFilter == 'All') {
            opps = [
                SELECT Id, Name, StageName, Amount, CloseDate, Probability
                FROM Opportunity
                WHERE IsClosed = false AND CloseDate <= :cutoff
                ORDER BY CloseDate ASC
                LIMIT 10
            ];
        } else {
            opps = [
                SELECT Id, Name, StageName, Amount, CloseDate, Probability
                FROM Opportunity
                WHERE IsClosed = false
                  AND CloseDate <= :cutoff
                  AND StageName = :stageFilter
                ORDER BY CloseDate ASC
                LIMIT 10
            ];
        }

        Decimal total = 0;
        Integer overdue = 0;
        Date today = Date.today();
        for (Opportunity o : opps) {
            total += (o.Amount == null ? 0 : o.Amount);
            if (o.CloseDate < today) {
                overdue++;
            }
        }

        OpportunitySummary result = new OpportunitySummary();
        result.opportunities = opps;
        result.totalPipelineValue = total;
        result.overdueCount = overdue;
        return result;
    }

    // ------------------------------------------------------------------
    // WRITE #1 (DML: update) — NOT cacheable. Pushes an Opportunity's
    // Close Date forward by a given number of days.
    // ------------------------------------------------------------------
    @AuraEnabled
    public static Opportunity pushCloseDateByDays(Id oppId, Integer numDays) {
        if (numDays == null || numDays <= 0) {
            throw new AuraHandledException('Number of days must be a positive number.');
        }
        try {
            Opportunity opp = [
                SELECT Id, CloseDate
                FROM Opportunity
                WHERE Id = :oppId
                LIMIT 1
            ];
            opp.CloseDate = opp.CloseDate.addDays(numDays);
            update opp;
            return opp;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to push close date: ' + e.getMessage());
        }
    }

    // ------------------------------------------------------------------
    // WRITE #2 (DML: update) — NOT cacheable. Marks an Opportunity Closed Won.
    // ------------------------------------------------------------------
    @AuraEnabled
    public static Opportunity markOpportunityAsClosedWon(Id oppId) {
        try {
            Opportunity opp = new Opportunity(
                Id = oppId,
                StageName = 'Closed Won',
                CloseDate = Date.today()
            );
            update opp;
            return opp;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to close the opportunity: ' + e.getMessage());
        }
    }
}
