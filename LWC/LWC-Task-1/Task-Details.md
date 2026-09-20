# Core Tasks \& Challenges



###### **The Child Component (productItem)**



*Task A* (Public Properties): Must receive item data from the parent using @api properties. Naming conventions must map properly between JS (camelCase) and HTML (kebab-case).



*Task B* (Getter Data-Transformation): The child must display the product name in all uppercase letters using a clean JS getter. It cannot use string formatting methods inside the HTML template.



*Task C* (Action Events): Add a button labeled "Sell 1 Unit". Clicking this button must not modify the stock count internally (since parent data is read-only). Instead, it must dispatch a CustomEvent named stockchange containing the target product's ID as a payload.



###### **The Parent Component (inventoryDashboard)**



*Task A* (The Source of Truth): Must manage a hardcoded array of at least 3 product objects in JavaScript. Each product needs an Id, Name, Price, and StockCount.



*Task B* (The Debounced Search Engine): Add a search input box. Students must implement a 300ms debounce timer on the onchange hook. When the user stops typing, the component should instantly filter the array on screen.



*Task C* (Immutable Array Mutations): When the child dispatches the stockchange event, the parent must intercept it, find the matching item, and subtract 1 from its stock count. Crucial Rule: They must do this immutably using the spread operator (\[...] or .map()). Using .push() or in-place object mutations will fail to re-render the child and earn a deduction.



*Task D* (Getter Computations): The parent must feature an output summary panel displaying the total valuation of the entire inventory (Sum of all Price \* StockCount). This must update instantly whenever stock drops or items are filtered.



