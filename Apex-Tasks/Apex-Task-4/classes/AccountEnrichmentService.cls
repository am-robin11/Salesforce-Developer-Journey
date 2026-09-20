/**
 * AccountEnrichmentService  (BONUS - not required by Task 04 itself)
 * ---------------------------------------------------------------------
 * Task 04's requirements never call an external system, so nothing above
 * needed a callout. But your Trailhead list includes "Apex Integration
 * Services", and the cleanest way to actually understand callouts is to
 * see one wired into something you already understand - so this is a
 * small, realistic example: given a company website, ask a (fake, for
 * this example) external API for a size estimate, which a real
 * integration might use to help set AnnualRevenue/NumberOfEmployees in
 * the first place before AccountTierRatingService ever runs.
 *
 * CORE INTEGRATION CONCEPTS THIS DEMONSTRATES:
 *   - HttpRequest / HttpResponse / Http - the three classes at the heart
 *     of every synchronous Apex callout.
 *   - Callouts are NOT allowed in the same transaction as an uncommitted
 *     DML statement (Salesforce will throw
 *     "System.CalloutException: You have uncommitted work pending").
 *     That's exactly why real callout code is usually invoked from a
 *     Queueable (see below) or an @future(callout=true) method rather
 *     than directly inside a trigger.
 *   - Named Credentials (referenced here as 'callout:Company_Info_API')
 *     are the recommended way to store an endpoint + auth so it never
 *     appears as a hardcoded URL/secret in Apex code.
 *   - Test.setMock() lets you unit test callout code with ZERO real
 *     network access - required, since Apex tests can never make real
 *     callouts.
 */
public with sharing class AccountEnrichmentService {

    /**
     * Runs as a Queueable specifically BECAUSE it makes a callout.
     * Queueable Apex (as opposed to @future) is preferred for new code
     * because it supports complex input types (like this whole
     * Set<Id>), can be chained to a follow-up job, and its status is
     * trackable via the AsyncApexJob record it returns.
     */
    public class EnrichAccountsQueueable implements Queueable, Database.AllowsCallouts {
        private Set<Id> accountIds;

        public EnrichAccountsQueueable(Set<Id> accountIds) {
            this.accountIds = accountIds;
        }

        public void execute(QueueableContext context) {
            List<Account> accounts = [SELECT Id, Website FROM Account WHERE Id IN :accountIds];
            List<Account> toUpdate = new List<Account>();

            for (Account acc : accounts) {
                if (String.isBlank(acc.Website)) {
                    continue;
                }
                CompanySizeEstimate estimate = getCompanySizeEstimate(acc.Website);
                if (estimate != null) {
                    acc.AnnualRevenue = estimate.annualRevenue;
                    acc.NumberOfEmployees = estimate.numberOfEmployees;
                    toUpdate.add(acc);
                    // Note: updating AnnualRevenue/NumberOfEmployees here
                    // will cause AccountTrigger to recalculate Tier/Rating
                    // automatically on this same update - the two pieces
                    // of automation compose for free.
                }
            }

            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
        }
    }

    /** Simple wrapper so callers get typed data back, not a raw JSON map. */
    public class CompanySizeEstimate {
        public Decimal annualRevenue;
        public Integer numberOfEmployees;
    }

    /**
     * The actual callout. Kept as its own method (rather than inline in
     * execute()) so it can be unit tested on its own with a mock, and so
     * it's obvious at a glance which method is safe to call from a
     * trigger context and which is not.
     */
    public static CompanySizeEstimate getCompanySizeEstimate(String website) {
        HttpRequest req = new HttpRequest();
        // 'callout:Company_Info_API' refers to a Named Credential that
        // would be set up in Setup > Named Credentials, storing the real
        // base URL and any auth - never hardcode https://... + an API key
        // directly in Apex.
        req.setEndpoint('callout:Company_Info_API/lookup?domain=' + EncodingUtil.urlEncode(website, 'UTF-8'));
        req.setMethod('GET');
        req.setTimeout(10000); // 10 seconds - Apex callouts default to 10s, max 120s

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            System.debug(LoggingLevel.WARN, 'Company info lookup failed: ' + res.getStatusCode() + ' ' + res.getBody());
            return null;
        }

        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        CompanySizeEstimate estimate = new CompanySizeEstimate();
        estimate.annualRevenue = (Decimal) parsed.get('estimatedAnnualRevenue');
        estimate.numberOfEmployees = (Integer) parsed.get('estimatedEmployeeCount');
        return estimate;
    }
}
