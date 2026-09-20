import { LightningElement } from 'lwc';

export default class InventoryDashboard extends LightningElement {
    inventoryInputText = 'Current Inventory Items';
    myitemList = [
        { Id: 1, Name: "Ryzen 7 5700X", Price: 12500, Stock_Count: 50 },
        { Id: 2, Name: "PNY RTX 3060Ti", Price: 35000, Stock_Count: 7 },
        { Id: 3, Name: "Corsair CV650", Price: 6500, Stock_Count: 15 }
    ]; // Plain array field (Reactive on assignment)
    // childError = null;

    searchTerm = '';
    delayTimeout;

    // Debounced Search Handler (Waits 300ms after the last keystroke)
    handleSearchInput(event) {
        // 1. Grab what the user typed IMMEDIATELY
        const value = event.target.value;

        // 2. Clear the old timer completely so the countdown starts over
        window.clearTimeout(this.delayTimeout);

        // 3. Start a brand new 300ms countdown timer
        // FIX: We assign 'this' inside a safe tracking scope
        this.delayTimeout = window.setTimeout(() => {
            this.searchTerm = value;
            console.log('Debounce finished! Showing Items...:', this.myitemList);
        }, 300);
    }

    get filteredItems() {
        if (!this.searchTerm) {
            return this.myitemList;
        }
        const term = this.searchTerm.toLowerCase();
        return this.myitemList.filter((item) =>
            item.Name.toLowerCase().includes(term)
        );
    }

    handleStockChange(event) {
        const targetId = event.detail.productId;

        this.myitemList = this.myitemList.map((item) => {
            if (item.Id === targetId) {
                return { ...item, Stock_Count: item.Stock_Count - 1 };
            }
            return item;
        });
    }

    get sumTotal() {
        return this.myitemList.reduce(
            (sum, item) => sum + item.Price * item.Stock_Count,
            0
        );
    }
}
