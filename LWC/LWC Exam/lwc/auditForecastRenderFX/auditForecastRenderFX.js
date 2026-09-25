import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getForecastOpportunities from '@salesforce/apex/AuditForecastControllerFX.getForecastOpportunities';
import setExpectedRevenueLogic from '@salesforce/apex/AuditForecastControllerFX.setExpectedRevenueLogic';

// NOTE the class name: it MUST match the bundle name "auditForecastRender"
// (converted to PascalCase) — this is what caused the deploy-breaking
// mismatch in the original submission (it was named after the Apex class).
export default class AuditForecastRenderFX extends NavigationMixin(LightningElement) {
    wiredOppsResult;

    // Wired to a function (not a property) so we keep a handle on the whole
    // {data, error} object for refreshApex() later.
    @wire(getForecastOpportunities)
    wiredOpps(result) {
        this.wiredOppsResult = result;
    }

    get opportunities() {
        return this.wiredOppsResult?.data || [];
    }

    get hasError() {
        return !!this.wiredOppsResult?.error;
    }

    get errorMessage() {
        return this.wiredOppsResult?.error?.body?.message || 'Something went wrong.';
    }

    get hasNoRows() {
        return this.wiredOppsResult?.data && this.wiredOppsResult.data.length === 0;
    }

    async handleProcessRevenue(event) {
        const recordId = event.target.dataset.id;
        try {
            // Parameter name here MUST match the Apex method's parameter
            // name exactly: setExpectedRevenueLogic(Id recordId).
            await setExpectedRevenueLogic({ recordId });

            // 1. Clear the cache so the row's new Expected Revenue shows up.
            await refreshApex(this.wiredOppsResult);

            // 2. Green success toast.
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Expected revenue updated.',
                    variant: 'success'
                })
            );

            // 3. Redirect back to the standard Opportunity Home view.
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Opportunity',
                    actionName: 'home'
                }
            });
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error setting expected revenue',
                    message: error.body?.message || 'Unknown error',
                    variant: 'error'
                })
            );
        }
    }
}
