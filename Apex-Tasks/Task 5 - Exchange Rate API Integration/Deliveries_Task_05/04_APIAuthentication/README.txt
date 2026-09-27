API Authentication Configuration
==================================

Authentication is Bearer-token based, using a Custom Header on the
External Credential (see item 03 for full configuration). This keeps the
API key out of Apex source code, debug logs, and version control entirely.

Key points:
  - The API key is stored ONLY as the value of a Custom Header named
    "Authorization" on the External Credential ExchangeRateAPI_Cred.
  - No Apex class references, stores, or logs the key at any point.
  - Access to the credential is restricted via the "Currency Integration
    Access" Permission Set, granted only to users/automation that need it,
    rather than being globally available.
  - An earlier attempt used a Principal-level Authentication Parameter
    referenced via the {!$Credential.AuthHeader} merge field in Apex; this
    returned HTTP 403 / invalid-key even with a verified-working key,
    indicating the merge field was not resolving correctly in this org.
    The Custom Header approach was adopted instead and confirmed working
    (see successful_callout_test.png in item 03).

This satisfies the requirement that the API key must be securely configured
and never hardcoded in Apex.
