trigger CandidateKeyTrigger on Candidate__c (before insert, before update) {

	CandidateKey.hasCandidateDuplicates(Trigger.new);

}