// Updated the Conditions inside the loop for the new business classification.
// Now the code fetches accounts with their Industry and Rating fields as well for enhanced categorization.
// It also gets accounts with a NULL Revenue field and then classifies it with logic inside the loop.
// Added a few variables to count the new changes.

public with sharing class AccountCustomize {
    public static void revfilter(){
        List<Account> accList = [SELECT Id, Name, AnnualRevenue, Industry, Rating, Customer_Category__c FROM Account];
        
        List<Account> recordUpdate = new List<Account>();
		Integer priorityCount = 0;
        Integer unclassifiedCount = 0;
        Integer enterpriseCount = 0;
        Integer mediumCount = 0;
        Integer smallCount = 0;
    	for(Account i : accList){
            if(i.AnnualRevenue == NULL){
                i.Customer_Category__c = 'Unclassified';
                unclassifiedCount++;
                System.debug('Unclassified: ' + i);
            }
            else if(i.AnnualRevenue >= 10000000){
                i.Customer_Category__c = 'Enterprise';
                enterpriseCount++;
                System.debug('Enterprise: ' + i);
            }
            else if(i.AnnualRevenue >= 5000000 && i.Industry == 'Technology'){
                i.Customer_Category__c = 'Priority';
                i.Rating = 'Hot';
                priorityCount++;
                System.debug('Priority: ' + i);
            }
            else if(i.AnnualRevenue >= 1000000){
                i.Customer_Category__c = 'Medium';
                mediumCount++;
                System.debug('Medium: ' + i);
            }
            else if(i.AnnualRevenue < 1000000){
                i.Customer_Category__c = 'Small';
                smallCount++;
                System.debug('Small: ' + i);
            }
            else{
                System.debug('Revenue cannot be Zero!');
            }
            recordUpdate.add(i);
    	}
        
        if(!recordUpdate.isEmpty()){
            update recordUpdate;
        }
        System.debug('Categorization Complete!');
        System.debug('Total Accounts Checked: ' + accList.size());
        System.debug('Total Accounts Processed: ' + recordUpdate.size());
        System.debug('Total Number of Priority Account: ' + priorityCount);
        System.debug('Total Number of Enterprise Account: ' + enterpriseCount);
        System.debug('Total Number of Medium Account: ' + mediumCount);
        System.debug('Total Number of Small Account: ' + smallCount);
        System.debug('Total Number of Unclassified Account: ' + unclassifiedCount);
    }

}
