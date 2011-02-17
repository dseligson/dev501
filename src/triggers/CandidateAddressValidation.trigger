trigger CandidateAddressValidation on Candidate__c (after insert, after update, before update) {
	// We only call the async method if this trigger was fired from the UI, not from a batch API call
	if (Trigger.new.size() == 1){
		// If this is an insert we always do the async call
		if (Trigger.isInsert) { AddressValidator.validateAddress(Trigger.new[0].id); }

		// If this is an update, we check the AsyncValidationFlag to see if this address has been validated already
		// If already validated (flag==true) then we don't do the callout again
		// Only do the callout when the asyncvalidationflag is false
		if (Trigger.isUpdate){
			if (Trigger.isBefore) {
				// in the before we just check to see if the streets, city, or state have changed (NOTE: not zip since that is changed by the async method)
				// if one of them has changed, we change the flag to be false
				if ((Trigger.new[0].Street_Address_1__c != Trigger.old[0].Street_Address_1__c) ||
					(Trigger.new[0].Street_Address_2__c != Trigger.old[0].Street_Address_2__c) ||
					(Trigger.new[0].City__c != Trigger.old[0].City__c) ||
					(Trigger.new[0].State_Province__c != Trigger.old[0].State_Province__c)) {
					// if one of the above fields changed then reset the flag so the record gets picked up by the async call
					Trigger.new[0].AsyncValidationFlag__c = false;
				}
				System.debug('\ncandidate=' + Trigger.new[0] + '\n');
			} else {
				if (!Trigger.new[0].asyncvalidationflag__c){
					AddressValidator.validateAddress(Trigger.new[0].id);
				}
			}
		}
	}
}