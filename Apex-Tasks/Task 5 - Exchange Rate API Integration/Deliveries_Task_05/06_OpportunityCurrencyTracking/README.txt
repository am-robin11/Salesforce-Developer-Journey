Opportunity Currency-Update Tracking Implementation
=====================================================

Custom object: Opportunity_Currency_Update__c

Purpose: records one entry per SUCCESSFUL conversion — the record-level
audit trail, distinct from the currency-level history in item 05.

Fields:
  - Opportunity__c                          (Lookup to Opportunity)
  - Opportunity_Amount_BDT__c                (Number)   - original BDT amount
  - Expected_Currency_Type__c                (Text)     - target currency
  - Exchange_Rate_Used__c                    (Number)   - rate applied
  - Previous_Expected_Currency_Amount__c     (Number)   - value before update
  - New_Expected_Currency_Amount__c          (Number)   - value after update
  - Updated_Date_Time__c                     (DateTime) - when it happened

Created in CurrencyConversionService.processOpportunities() -- one record
per Opportunity that converts successfully, inserted via
Database.insert(list, false).

Full field/object metadata XML: Opportunity_Currency_Update__c_metadata.xml
Evidence of populated records: see item 12 (Opportunity Currency-Update
History Evidence)
