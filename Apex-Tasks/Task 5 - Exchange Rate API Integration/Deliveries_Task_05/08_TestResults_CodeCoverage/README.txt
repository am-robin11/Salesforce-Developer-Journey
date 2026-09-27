Test Execution Result and Code Coverage
==========================================

final_test_run_all_passing.png shows all 4 test classes run together:
  - CurrencyConversionBatchTest        - 2/2 passing
  - CurrencyConversionServiceTest      - 1/1 passing
  - ExchangeRateApiClientTest          - 5/5 passing
  - OpportunityCurrencyTriggerTest     - 4/4 passing
  Total: 12/12 passing, 0 failures

Code coverage per class:
  - CurrencyConversionQueueable          100%
  - OpportunityCurrencyTrigger           100%
  - OpportunityCurrencyTriggerHandler    94%
  - CurrencyConversionService            93%
  - CurrencyConversionBatch              85%
  - ExchangeRateApiClient                85%

All figures are well above Salesforce's 75% org-wide minimum. Every test
uses HttpCalloutMock; no real HTTP callouts are made anywhere in the suite.
