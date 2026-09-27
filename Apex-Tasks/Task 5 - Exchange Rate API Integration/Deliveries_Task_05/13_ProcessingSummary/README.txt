Processing Summary for the ~500 Opportunities
================================================
Final verified tally against the provided 500-record sample dataset:

  Success  : 392   (USD, EUR, GBP, JPY, AUD, CAD - the 6 supported currencies)
  Failed   : 105   (102 valid-but-unsupported codes: SGD, CHF, INR, CNY
                      + 3 invalid codes: XYZ)
  Pending  :   3   (blank Expected Currency Type - correctly skipped,
                     left untouched)
  --------------------
  Total    : 500

Per-currency breakdown of the 392 successful conversions:
  USD: 108   EUR: 78   JPY: 73   GBP: 61   AUD: 42   CAD: 30

An additional 53 Opportunities exist in the org from unrelated, pre-existing
scratch-org seed data (created before this project began, with no
Expected Currency Type value) and were correctly never touched by this
integration -- confirmed by direct inspection. 500 + 53 = 553, matching
the org's total Opportunity count exactly.
