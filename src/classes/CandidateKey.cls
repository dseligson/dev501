public class CandidateKey {

	// This method acts as a uniqueness checker for the Candidate object based on the Email__c field
	public static void hasCandidateDuplicates(Candidate__c[] candidates){

		List<Candidate__c> cList = [select id, name, email__c, unique_key__c from Candidate__c where id in :candidates];
		//TODO: Define a map for unique Candidates called "candidateMap" that maps a String to the Candidate
		Map<String, Candidate__c > candidateMap = new Map<String, Candidate__c>();

		//TODO: Declare a for loop to cycle through the candidates.
		for (Candidate__c c : cList) {
			if (c.email__c != null && c.email__c != '' ) {
				if ( !candidateMap.containsKey(c.unique_key__c) ) {
					candidateMap.put(c.unique_key__c, c);
				} else {
					c.addError('Duplicate Record:'+ c.unique_key__c);
				}
			}

		}

			// TODO: Within that loop, check to verify that the email is not null and if it has a value pull back the unique_key__c
			// and then check to see if there are duplicate unique keys within this batch of records.  If there are, use addError to prevent them,
			// and if not, add the unique key/candidate combo to the candidateMap.



		//Now hit the DB looking for dupes
		if (!candidateMap.isEmpty()){
			for(Candidate__c[] candidatesCheck:[select unique_key__c from Candidate__c where unique_key__c IN :candidateMap.keySet()]) {
				for(Candidate__c candidate:candidatesCheck) {
					String currentCandidateId = candidate.Id;
					//if there's a dupe and this isn't the current record, then add the error.
					if(candidateMap.containsKey(candidate.unique_key__c) && (currentCandidateId != candidateMap.get(candidate.unique_key__c).Id)) {
						candidateMap.get(candidate.unique_key__c).addError('Duplicate LastName + Email found in salesforce(id: ' + candidate.id + ')');
					}
				}
				}
		}
	}
}