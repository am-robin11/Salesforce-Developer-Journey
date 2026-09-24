import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getAtRiskOpportunitiesThisMonth from '@salesforce/apex/AtRiskPipelineController.getAtRiskOpportunitiesThisMonth';
import escalateOpportunity from '@salesforce/apex/AtRiskPipelineController.escalateOpportunity';
import advanceToProposal from '@salesforce/apex/AtRiskPipelineController.advanceToProposal';

export default class AtRiskPipelineTracker extends LightningElement {
    // No reactive parameters this time — the Apex method takes no arguments,
    // so @wire just needs the method reference. It still runs automatically
    // on component load, same as any other @wire.
    wiredSummaryResult;

    @wire(getAtRiskOpportunitiesThisMonth)
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

    get opportunities() {
        return this.summary ? this.summary.opportunities : [];
    }

    get totalAtRiskValue() {
        return this.summary ? this.summary.totalAtRiskValue : 0;
    }

    get hasNoRows() {
        return this.summary && this.summary.opportunities.length === 0;
    }

    async handleEscalate(event) {
        const oppId = event.target.dataset.id;
        try {
            await escalateOpportunity({ oppId });
            await refreshApex(this.wiredSummaryResult);
            this.notify('Escalated', 'Opportunity flagged for executive review.', 'success');
        } catch (error) {
            this.notify('Error escalating', this.extractMessage(error), 'error');
        }
    }

    async handleAdvance(event) {
        const oppId = event.target.dataset.id;
        try {
            await advanceToProposal({ oppId });
            await refreshApex(this.wiredSummaryResult);
            this.notify('Advanced', 'Opportunity moved to Proposal/Price Quote.', 'success');
        } catch (error) {
            this.notify('Error advancing stage', this.extractMessage(error), 'error');
        }
    }

    extractMessage(error) {
        return error?.body?.message || 'Unknown error';
    }

    notify(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
