# Opportunity Renewal Tracker

## Business scenario
Sales ops wants a component on the Opportunity Home / Record page showing every **open** Opportunity closing within the **next 30 days**, optionally filtered by **Stage**, with the **total pipeline value** of that filtered list shown at the top. Reps need to be able to, without leaving the component:
1. Push an **overdue** Opportunity's Close Date out by 30 days, and
2. Mark any listed Opportunity **Closed Won**

...with the list refreshing immediately after either action.

## Problem breakdown

Before touching any code, the scenario splits into four separate sub-problems:

**1. What to read (the query)**
- Object: Opportunity.
- Must be **open** only → `IsClosed = false`.
- Must be closing soon → `CloseDate` within the next 30 days from today.
- Must support an **optional** narrowing filter → Stage, chosen by the user at runtime.
- Needs to be sorted so the most urgent (soonest-closing) deals appear first → `ORDER BY CloseDate ASC`.
- Needs a cap so a busy org doesn't return hundreds of rows → `LIMIT`.

**2. What to calculate on top of the read data**
- A running total of `Amount` across the filtered list (pipeline value).
- A count of how many of those rows are already **past** their Close Date but still open (overdue) — this requires comparing each row's `CloseDate` to "today" as the list is built, not just returning raw records.
- Decision: should this math happen in Apex (server) or in JavaScript (client)? Doing it in Apex means the client never has to re-implement the same logic, and it can be bundled into the same response as the list — so it belongs in the Apex method, packaged into a wrapper object alongside the list.

**3. What can be written back (the two actions)**
- Action A — "push the close date": needs the record's Id and a number of days, reads the current `CloseDate`, adds days, saves it back.
- Action B — "mark Closed Won": needs the record's Id, sets `StageName` to a fixed value and `CloseDate` to today.
- Both are single-field-ish updates on one record at a time, triggered by a button on that record's row — so both should take an `Id` parameter and perform exactly one `update`.
- Both change data, so neither can be marked `cacheable` — that decision is made before writing a line of the method body.

**4. What the UI actually needs to expose**
- A way to change the Stage filter → a combobox, whose selected value needs to reach the Apex call.
- A list of rows, each showing enough fields to be useful (Name, Stage, Amount, Close Date) and carrying enough information for its buttons to know *which* record they act on.
- Two buttons per applicable row, each triggering one of the two write actions.
- Some way to reflect the result of a write back to the user (success/failure) and get the list to reflect the new data immediately afterward, without a manual page refresh.

Once broken down this way, the shape of the solution follows directly: **one cacheable read method returning a wrapper (list + totals), two non-cacheable write methods each taking an Id, and an LWC that wires the read method reactively to the filter and calls the write methods imperatively from button clicks.**

## Apex — `OpportunityRenewalController.cls`

**Wrapper class:**
```java
public class OpportunitySummary {
    @AuraEnabled public List<Opportunity> opportunities;
    @AuraEnabled public Decimal totalPipelineValue;
    @AuraEnabled public Integer overdueCount;
}
```
Lets one cacheable method return the record list **and** two server-calculated numbers in a single round trip.

**Read method (cacheable, filterable):**
```java
@AuraEnabled(cacheable=true)
public static OpportunitySummary getUpcomingOpenOpportunities(String stageFilter)
```
- `Date cutoff = Date.today().addDays(30);`
- Two static SOQL branches: one for "no stage filter", one for "filter applied" (`WHERE IsClosed = false AND CloseDate <= :cutoff [AND StageName = :stageFilter]`), ordered by `CloseDate ASC`, `LIMIT 10`.
- Loops the results in Apex to sum `Amount` into `totalPipelineValue` and count overdue rows into `overdueCount`.

**Write methods (DML, non-cacheable):**
```java
@AuraEnabled
public static Opportunity pushCloseDateByDays(Id oppId, Integer numDays)

@AuraEnabled
public static Opportunity markOpportunityAsClosedWon(Id oppId)
```
- `pushCloseDateByDays` queries the record, adds `numDays` to `CloseDate`, updates it.
- `markOpportunityAsClosedWon` sets `StageName = 'Closed Won'` and `CloseDate = Date.today()`.
- Both validate/guard before the DML and wrap it in `try/catch` → `AuraHandledException`.

## LWC — `opportunityRenewalTracker`

- `lightning-combobox` (Stage filter) drives a **reactive** `@wire` param: `@wire(getUpcomingOpenOpportunities, { stageFilter: '$stageFilter' })`, wired to a **function** so the whole `{data, error}` object is captured for `refreshApex`.
- `for:each` list of rows, each with `key={opp.Id}`; overdue rows get a distinct style via a computed `rowClass`.
- Overdue rows show a **"Push 30 Days"** button; every row shows a **"Mark Closed Won"** button. Both read the clicked row's Id via `data-id={opp.Id}` / `event.target.dataset.id`.
- Both handlers: imperative Apex call → `await refreshApex(this.wiredSummaryResult)` (the golden rule — pass the *whole* wired object, never just `.data`) → `ShowToastEvent` success/error toast.
- **Timezone gotcha handled deliberately:** "today" is built as a local `YYYY-MM-DD` string and compared against `opp.CloseDate` as strings, instead of comparing `Date` objects — avoids an off-by-one-day bug from UTC conversion.
- Uses `lightning-formatted-number` (currency) and `lightning-formatted-date-time` for display formatting.

## Concepts covered
| Concept | Source |
|---|---|
| `@AuraEnabled(cacheable=true)` for reads, plain `@AuraEnabled` for writes | Day 3 — Apex Integration |
| `@wire` with a reactive (`$param`) argument | Day 3 |
| Imperative Apex call + `try/catch` + `AuraHandledException` | Day 3 |
| `refreshApex(wholeWiredObject)` golden rule | Day 3 |
| `event.detail.value` (combobox) vs. `event.target.value` | Day 1 — Input handling |
| `data-id` / `event.target.dataset.id` for row-level actions | Day 3 |
| `for:each` + `key`, conditional `lwc:if` | Day 1 |
| `ShowToastEvent` | Day 3 — Platform services |
| Custom Apex wrapper class as a wire return type | Beyond the slide deck — general Apex/OOP |

## Golden rules this scenario reinforces
- A method with `cacheable=true` must never perform DML; a method that performs DML must never be `cacheable=true`.
- `refreshApex()` always takes the *entire* wired `{data, error}` object, never just `.data`.
- Wiring to a **function** (not a property) is required whenever you need to manually hold onto the wired result for a later `refreshApex()` call.
- Every DML call from LWC should be wrapped in Apex `try/catch` → `AuraHandledException`, so the real error message reaches `error.body.message` on the client.
- `data-id={record.Id}` + `event.target.dataset.id` is the standard way to know which row was acted on in a `for:each` list.
