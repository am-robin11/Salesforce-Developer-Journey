public class RevenueCat {
    public static void revfilter(){
        List<Account> accList = [SELECT Id, Name, AnnualRevenue, Customer_Category__c FROM Account
                                     Where AnnualRevenue != NULL];
        
        List<Account> recordUpdate = new List<Account>();
    	for(Account i : accList){
            if(i.AnnualRevenue >= 20000000){
                i.Customer_Category__c = 'Enterprise';
                System.debug('Enterprise: ' + i);
            }
            else if(i.AnnualRevenue >= 1000000){
                i.Customer_Category__c = 'Medium';
                System.debug('Medium: ' + i);
            }
            else{
                i.Customer_Category__c = 'Small';
                System.debug('Small: ' + i);
            }
            recordUpdate.add(i);
    	}
        
        if(!recordUpdate.isEmpty()){
            upsert recordUpdate;
        }
        System.debug('Categorization Complete!');
        System.debug('Total Accounts Processed: ' + accList.size());
    }

}