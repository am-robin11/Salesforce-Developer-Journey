Exchange-Rate Tracking Implementation
=======================================

Custom object: Exchange_Rate_History__c

Purpose: records one entry per distinct supported currency actually
queried during a processing run — the rate-level audit trail.

Fields:
  - Base_Currency__c        (Text)      - always "BDT"
  - Target_Currency__c      (Text)      - the currency the rate was for
  - Exchange_Rate__c        (Number)    - the rate returned by the API
  - Retrieved_Date_Time__c  (DateTime)  - when the rate was fetched
  - API_Status__c           (Picklist)  - Success / Failed
  - Error_Details__c        (Long Text) - API error details, if failed

Created in CurrencyConversionService.processOpportunities() -- one record
per distinct SUPPORTED currency present in the batch/chunk being processed,
inserted via Database.insert(list, false) so one bad record cannot block
the others.

Full field/object metadata XML: Exchange_Rate_History__c_metadata.xml
Evidence of populated records: see item 11 (Exchange-Rate History Evidence)
