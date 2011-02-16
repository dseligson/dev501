trigger OfferTrigger on Offer__c (after insert, after update) {
	// TODO: Create a List called "jobApps" to hold the JobApps to be updated
	// There is a validation rule on the Offer__c object that requires Job_Application__c
	//	to be specified.  Therefore we can assume all offers have a valid JobApplication.

	List<Offer__c> offerList = [select id,job_application__r.id,
							job_application__r.status__c, job_application__r.stage__c
							from offer__c
							where offer__c.id IN :Trigger.new];

	Set<Job_Application__c> ja = new Set<Job_Application__c>();
	for (Offer__c o : offerList) {
		if (o.job_application__r.status__c!= 'Hold' && o.job_application__r.stage__c != 'Other') {
			ja.add(new Job_Application__c(id=o.job_application__r.id, stage__c='Offer Extended', status__c='Hold'));
		}
	}
	// perform the update of job application records
	List<Job_application__c> appList = new List<Job_application__c>(ja);
	if (appList.size() > 0){
		try{
			//TODO: Update the jobApps and put the results in a SaveResult list called "saveResults"
			update appList;

		} catch (Exception e){
			System.debug('error updating job applications:' + e);
		}
	}
}