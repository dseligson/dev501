trigger CandidateKeyTrigger on Candidate__c (before insert, before update) {

	// Get the batch of new candidates and pass them to the CandidateKey class for checking
	private Candidate__c[] newCandidates = Trigger.new;
	CandidateKey.hasCandidateDuplicates(newCandidates);
}