Salesforce Configuration Used to Connect with ExchangeRate-API
================================================================

External Credential: ExchangeRateAPI_Cred
  - Authentication Protocol: Custom
  - Principal: ExchangeRateAPIPrincipal (required for Permission Set access)
  - Custom Header: Name = "Authorization", Value = "Bearer <API_KEY>"
    (this header is injected automatically on every callout; the key is
    never referenced in Apex code)

Named Credential: ExchangeRateAPI
  - URL: https://v6.exchangerate-api.com/v6
  - Linked External Credential: ExchangeRateAPI_Cred
  - Enabled for Callouts: true
  - Generate Authorization Header: false (authentication is handled by the
    Custom Header above, not OAuth)

Permission Set: Currency Integration Access
  - Grants External Credential Principal Access to
    ExchangeRateAPI_Cred / ExchangeRateAPIPrincipal
  - Grants object + field permissions on Exchange_Rate_History__c and
    Opportunity_Currency_Update__c
  - Grants field permissions on the 6 new Opportunity fields
  - Assigned to the running user

Apex callout endpoint used in ExchangeRateApiClient.cls:
    callout:ExchangeRateAPI/pair/<BASE>/<TARGET>

See attached screenshots:
  - external_credential_detail.png : External Credential detail page showing
    the linked Named Credential and Principal
  - successful_callout_test.png    : Anonymous Apex test confirming a live
    callout through this configuration returns HTTP 200 and a real
    conversion rate (BDT -> USD)
