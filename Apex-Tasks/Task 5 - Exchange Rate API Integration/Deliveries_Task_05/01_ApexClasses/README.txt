Apex Classes
==============
ExchangeRateApiClient.cls              - HTTP callout wrapper (no business logic)
CurrencyConversionService.cls          - core business logic: validation,
                                          currency grouping, calculation, DML
CurrencyConversionBatch.cls            - Database.Batchable wrapper for bulk
                                          processing and filtered reprocessing
CurrencyConversionQueueable.cls        - async callout handler for the trigger
OpportunityCurrencyTriggerHandler.cls  - trigger logic / bypass flag

Security note:
CurrencyConversionService.processOpportunities() begins with an explicit
enforceFieldLevelSecurity() check (Schema describe calls) verifying the
running user can read the required Opportunity fields, update the six
currency-tracking fields, and create records on both
Exchange_Rate_History__c and Opportunity_Currency_Update__c. If not, it
throws a custom InsufficientAccessException naming the missing permission,
rather than silently skipping or partially processing records. All classes
are declared "with sharing" to respect record-level sharing rules as well.
See item 14 (Technical Explanation), Section 7, for full detail.
