import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getUpcomingOpenOpportunities from '@salesforce/apex/OpportunityRenewalController.getUpcomingOpenOpportunities';
import pushCloseDateByDays from '@salesforce/apex/OpportunityRenewalController.pushCloseDateByDays';
import markOpportunityAsClosedWon from '@salesforce/apex/OpportunityRenewalController.markOpportunityAsClosedWon';

const STAGE_OPTIONS = [
    { label: 'All Stages', value: 'All' },
    { label: 'Prospecting', value: 'Prospecting' },
    { label: 'Qualification', value: 'Qualification' },
    { label: 'Needs Analysis', value: 'Needs Analysis' },
    { label: 'Value Proposition', value: 'Value Proposition' },
    { label: 'Negotiation/Review', value: 'Negotiation/Review' }
];

export default class OpportunityRenewalTracker extends LightningElement {
    stageFilter = 'All';
    stageOptions = STAGE_OPTIONS;

    // Captured manually because we're using the "wire to function" style,
    // not "wire to property" — refreshApex() needs this exact object later.
    wiredSummaryResult;

    @wire(getUpcomingOpenOpportunities, { stageFilter: '$stageFilter' })
    wiredSummary(result) {
        this.wiredSummaryResult = result;
    }

    get summary() {
        return this.wiredSummaryResult?.data;
    }

    get hasError() {
        return !!this.wiredSummaryResult?.error;
    }

    get errorMessage() {
        return this.wiredSummaryResult?.error?.body?.message || 'Something went wrong.';
    }

    get totalPipelineValue() {
        return this.summary ? this.summary.totalPipelineValue : 0;
    }

    get overdueCount() {
        return this.summary ? this.summary.overdueCount : 0;
    }

    get hasNoRows() {
        return this.summary && this.summary.opportunities.length === 0;
    }

    // IMPORTANT: build "today" as a local YYYY-MM-DD string and compare it
    // to Opportunity.CloseDate (also YYYY-MM-DD) as STRINGS. Wrapping
    // CloseDate in `new Date(...)` treats it as UTC midnight, which can be
    // off by a day from the user's local "today" — a classic LWC + Salesforce
    // Date-field bug. String comparison sidesteps it entirely.
    get opportunityRows() {
        if (!this.summary) {
            return [];
        }
        const now = new Date();
        const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;

        return this.summary.opportunities.map((opp) => {
            const isOverdue = opp.CloseDate < todayStr;
            return {
                ...opp,
                isOverdue,
                rowClass: isOverdue
                    ? 'slds-box slds-theme_error slds-m-bottom_x-small'
                    : 'slds-box slds-m-bottom_x-small'
            };
        });
    }

    handleStageChange(event) {
        this.stageFilter = event.detail.value;
    }

    async handlePushDate(event) {
        const oppId = event.target.dataset.id;
        try {
            await pushCloseDateByDays({ oppId, numDays: 30 });
            await refreshApex(this.wiredSummaryResult);
            this.notify('Success', 'Close date pushed by 30 days.', 'success');
        } catch (error) {
            this.notify('Error pushing close date', this.extractMessage(error), 'error');
        }
    }

    async handleMarkWon(event) {
        const oppId = event.target.dataset.id;
        try {
            await markOpportunityAsClosedWon({ oppId });
            await refreshApex(this.wiredSummaryResult);
            this.notify('Success', 'Opportunity marked Closed Won.', 'success');
        } catch (error) {
            this.notify('Error closing opportunity', this.extractMessage(error), 'error');
        }
    }

    extractMessage(error) {
        return error?.body?.message || 'Unknown error';
    }

    notify(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
