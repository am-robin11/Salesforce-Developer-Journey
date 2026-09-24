# Early-Stage Deal Escalation Tracker

## Business scenario
Sales leadership wants to see every **open** Opportunity closing **this calendar month** that hasn't progressed past **Perception Analysis** in the standard sales funnel (still sitting in `Prospecting`, `Qualification`, `Needs Analysis`, `Value Proposition`, `Id. Decision Makers`, or `Perception Analysis`) — deals expected to close soon but stuck early. The component shows the **total dollar value at risk**. For each listed deal, a rep can:
1. **Escalate** it — flags `NextStep` with an executive-review note and halves `Probability`, or
2. **Fast-Track to Proposal** — manually advances `StageName` to `Proposal/Price Quote`

## Problem breakdown

This scenario was reverse-engineered from the pattern in the instructor's test data, so the breakdown starts one level earlier than usual — at "what is this data actually testing?" — before getting to the technical shape.

**1. Decode the filter from the test data's design**
- Two named groups existed: "Exam Opp" (should appear) and "Control Opp" (should be excluded), each control row labeled with *why* it's excluded ("Exclude Proposal Stage", "Exclude Future Month", etc.).
- All "in scope" rows shared one `CloseDate` (within the current month) and used only stages that come **before** `Proposal/Price Quote` in the standard funnel order.
- All excluded rows were either a **later-funnel stage** (`Proposal/Price Quote`, `Negotiation/Review`, `Closed Won`/`Closed Lost`) or a **different month**.
- Conclusion: the filter is "closing this month" **AND** "still in an early stage" — two independent conditions that both have to hold.

**2. Translate each condition into SOQL**
- "Closing this month" — could be hardcoded date math (`Date.today().toStartOfMonth()` ... `addMonths(1).addDays(-1)`), but the fact that the *only* excluded date was a different month (not a different day within the same month) points at a **date literal**: `CloseDate = THIS_MONTH`. This avoids reimplementing "start and end of month" logic by hand.
- "Still in an early stage" — this can be written either as a positive list (`StageName IN (...)` naming the six early stages) or a negative list (`StageName NOT IN (...)` naming the four late/closed stages). Either is valid; the choice mostly affects readability and how many items you have to name.
- Both conditions apply to the same query and don't depend on any user input at runtime, so — unlike the previous scenario's Stage filter — there's no need for a parameter or a reactive wire argument at all.

**3. What to calculate on top of the read data**
- A running total of `Amount` across the filtered ("at risk") list — same aggregation idea as the previous scenario, just without an overdue-count this time, since "overdue" isn't part of this scenario's definition of risk.

**4. What can be written back (the two actions)**
- Action A — "escalate": needs the record's Id, sets a fixed warning string on `NextStep`, and mathematically transforms an existing field (`Probability / 2`) rather than just overwriting it with a constant — this is the first place two different *kinds* of field changes (a fixed string, a derived number) happen in a single update.
- Action B — "fast-track": needs the record's Id, sets `StageName` to a fixed value — structurally identical to "Mark Closed Won" from the previous scenario, just a different destination stage.
- Both are single-record updates, both change data so neither can be `cacheable`.

**5. What the UI actually needs to expose**
- No filter control needed this time (no combobox) — the whole point is that the query criteria are fixed business rules, not something a rep chooses.
- A list of rows with fields relevant to *this* decision: Name, Stage, Amount, Close Date.
- Two buttons per row, each triggering one of the two write actions, each needing to know which record it's acting on.
- Same requirement as before: reflect success/failure to the user, and refresh the list immediately after either write.

The breakdown lands on a structure almost identical to the previous scenario's — **one cacheable read method returning a wrapper (list + total), two non-cacheable write methods each taking an Id** — which is the point: once you've built the skeleton once, recognizing "this is the same skeleton, different business rules" is the fast way through a new scenario under time pressure.

## Apex — `AtRiskPipelineController.cls`

**Wrapper class:**
```java
public class AtRiskSummary {
    @AuraEnabled public List<Opportunity> opportunities;
    @AuraEnabled public Decimal totalAtRiskValue;
}
```

**Read method (cacheable, no parameters):**
```java
@AuraEnabled(cacheable=true)
public static AtRiskSummary getAtRiskOpportunitiesThisMonth()
```
- `private static final List<String> EARLY_STAGES = {...}` — the six pre-Proposal stages.
- SOQL: `WHERE CloseDate = THIS_MONTH AND IsClosed = false AND StageName IN :EARLY_STAGES`, `ORDER BY Amount DESC`.
- `THIS_MONTH` is a **SOQL date literal** — covers the entire current calendar month automatically, no `Date` math needed.
- Sums `Amount` into `totalAtRiskValue` in an Apex loop.

**Write methods (DML, non-cacheable):**
```java
@AuraEnabled
public static Opportunity escalateOpportunity(Id oppId)

@AuraEnabled
public static Opportunity advanceToProposal(Id oppId)
```
- `escalateOpportunity` sets `NextStep` to an escalation message and halves `Probability`.
- `advanceToProposal` sets `StageName = 'Proposal/Price Quote'`.
- Same `try/catch` → `AuraHandledException` pattern.

## LWC — `atRiskPipelineTracker`

- `@wire(getAtRiskOpportunitiesThisMonth)` with **no arguments** — the Apex method takes no parameters, so the wire config object is simply omitted; it still fires automatically on load.
- Same list-rendering, row-button, imperative-call/`refreshApex`/toast pattern as the Renewal Tracker, applied to the `Escalate` and `Fast-Track to Proposal` buttons.

## Concepts covered
| Concept | Source / notes |
|---|---|
| SOQL date literal `CloseDate = THIS_MONTH` | New — not in the sample training code, directly inferred from the instructor's test-data design |
| `StageName IN :boundList` (bound `List<String>`) | Alternative to the two-static-queries if/else pattern |
| `@wire` with **no** config object | Variant of the reactive-wire pattern used when the query has no runtime-chosen filter |
| Multiple fields updated in a single DML statement (`NextStep` + `Probability` together) | Extends the single-field-update pattern with a derived value |
| Aggregation in Apex (`SUM` via loop) | Same technique as the Renewal Tracker, reused |
| Reading intent from test-data design (naming patterns, deliberate exclusions) | General exam-prep skill, not a code concept |

## Golden rules this scenario reinforces
- A method with `cacheable=true` must never perform DML; a method that performs DML must never be `cacheable=true`.
- `refreshApex()` always takes the *entire* wired `{data, error}` object, never just `.data`.
- `@wire` doesn't require a config object when the underlying Apex method takes no parameters.
- A single `update` statement can set several fields at once, including one derived from the record's own existing value (e.g., halving `Probability`).
- `data-id={record.Id}` + `event.target.dataset.id` is the standard way to know which row was acted on in a `for:each` list.
