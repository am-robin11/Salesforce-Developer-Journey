/**
 * Scenario: "Early-Stage Deal Escalation Tracker"
 *
 * Show every OPEN Opportunity closing THIS MONTH that hasn't progressed past
 * "Perception Analysis" in the standard sales funnel (still Prospecting,
 * Qualification, Needs Analysis, Value Proposition, Id. Decision Makers, or
 * Perception Analysis) — deals expected to close soon but stuck early.
 * Reps can Escalate a deal (flag NextStep + halve Probability) or manually
 * Fast-Track it to Proposal/Price Quote.
 */
public with sharing class AtRiskPipelineController {

    // Same wrapper-class idea as before: hand back the list AND a
    // server-calculated total in one round trip.
    public class AtRiskSummary {
        @AuraEnabled public List<Opportunity> opportunities;
        @AuraEnabled public Decimal totalAtRiskValue;
    }

    // Everything before "Proposal/Price Quote" in the standard funnel order.
    private static final List<String> EARLY_STAGES = new List<String>{
        'Prospecting', 'Qualification', 'Needs Analysis',
        'Value Proposition', 'Id. Decision Makers', 'Perception Analysis'
    };

    // ------------------------------------------------------------------
    // READ (SOQL) — cacheable=true for use with @wire.
    // ------------------------------------------------------------------
    @AuraEnabled(cacheable=true)
    public static AtRiskSummary getAtRiskOpportunitiesThisMonth() {
        // THIS_MONTH is a SOQL date literal — no bind variable, no Apex date
        // math. It automatically covers the 1st through the last day of the
        // current calendar month, whatever month "today" happens to be in.
        List<Opportunity> opps = [
            SELECT Id, Name, StageName, Amount, CloseDate, Probability, NextStep
            FROM Opportunity
            WHERE CloseDate = THIS_MONTH
              AND IsClosed = false
              AND StageName IN :EARLY_STAGES
            ORDER BY Amount DESC
        ];

        Decimal total = 0;
        for (Opportunity o : opps) {
            total += (o.Amount == null ? 0 : o.Amount);
        }

        AtRiskSummary result = new AtRiskSummary();
        result.opportunities = opps;
        result.totalAtRiskValue = total;
        return result;
    }

    // ------------------------------------------------------------------
    // WRITE #1 (DML: update) — flags the deal for executive attention.
    // ------------------------------------------------------------------
    @AuraEnabled
    public static Opportunity escalateOpportunity(Id oppId) {
        try {
            Opportunity opp = [
                SELECT Id, NextStep, Probability
                FROM Opportunity
                WHERE Id = :oppId
                LIMIT 1
            ];
            opp.NextStep = 'ESCALATED: Needs executive review before month-end close.';
            opp.Probability = (opp.Probability == null ? 0 : opp.Probability) / 2;
            update opp;
            return opp;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to escalate: ' + e.getMessage());
        }
    }

    // ------------------------------------------------------------------
    // WRITE #2 (DML: update) — manually advances the deal's stage.
    // ------------------------------------------------------------------
    @AuraEnabled
    public static Opportunity advanceToProposal(Id oppId) {
        try {
            Opportunity opp = new Opportunity(
                Id = oppId,
                StageName = 'Proposal/Price Quote'
            );
            update opp;
            return opp;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to advance stage: ' + e.getMessage());
        }
    }
}
