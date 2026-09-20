import { LightningElement, api } from 'lwc';

export default class ProductItem extends LightningElement {
    @api itemId;
    @api name;
    @api price;
    @api stockCount;

    // --- GETTERS ---
    get upperProductName() {
        return this.name ? this.name.toUpperCase() : '';
    }

    // Communication up via Custom Events
    handleSellClick() {
        const sellEvent = new CustomEvent('stockchange', {
            detail: {
                productId: this.itemId
            }
        });
        this.dispatchEvent(sellEvent);
    }
}
