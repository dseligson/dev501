trigger InterviewerPickerTrigger on Interviewer__c (after insert, before delete, after delete) {
	if (Trigger.isInsert){
		List<Review__c> reviews = new List<Review__c>();
		List<Job_Application__Share> jobAppShares = new List<Job_Application__Share>();
		List<Candidate__Share> candidateShares = new List<Candidate__Share>();
		List<ID> positionIds = new List<ID>();

		// get a list of all the position ids
		for(Interviewer__c i:Trigger.new){
			System.debug('*****************the interviewer record: ' + i);
			positionIds.add(i.Position__c);
		}

		// select all the job apps associated to those positions
		List<Job_Application__c> jobApps = [select j.id,j.position__c,j.candidate__c,j.ownerid,j.candidate__r.ownerid from Job_Application__c j where j.position__c IN :positionIds];

		// loop thru all the jobApps we just retrieved
		for(Job_Application__c jobApp:jobApps){
			for(Interviewer__c i:Trigger.new){
				if (i.Position__c == jobApp.Position__c){
					// create the new review sobject
					Review__c review = new Review__c();
					review.Interviewer__c = i.Id;
					review.Job_Application__c = jobApp.Id;
					reviews.add(review);
					// create the jobApp share sobject ONLY if the interviewer is not the owner of the job app
					if (i.employee__c != jobApp.ownerid){
						Job_Application__Share jobAppShare = new Job_Application__Share();
						jobAppShare.ParentId = jobApp.Id;
						jobAppShare.UserOrGroupId = i.Employee__c;
						jobAppShare.AccessLevel = 'Edit';
						jobAppShares.add(jobAppShare);
					}
					// now the candidate share sobject ONLY if the interviewer is not the owner of the candidate
					if (i.employee__c != jobApp.candidate__r.ownerid){
						// make sure there is a candidate on the Job App
						if (jobApp.candidate__c != null){
							Candidate__Share candidateShare = new Candidate__Share();
							candidateShare.ParentId = jobApp.candidate__c;
							candidateShare.UserOrGroupId = i.Employee__c;
							candidateShare.AccessLevel = 'Read';
							candidateShares.add(candidateShare);
						}
					}
				}
			}
		}
		// now create the incomplete reviews for the interviewers
		insert reviews;

		// now share the job apps and candidates with the interviewer
		System.debug('***candidateShares=' + candidateShares);
		insert candidateShares;
		System.debug('***jobAppShares=' + jobAppShares);
		insert jobAppShares;

	} else if (Trigger.isDelete){
		if (Trigger.isBefore){
			// first remove the reviews associated to the interviewer **only if they are not already completed
			Map<ID,Interviewer__c> iMap = Trigger.oldMap;
			List<Review__c> reviews = [select id,job_application__c,interviewer__c,review_completed__c from review__c where interviewer__c IN :iMap.keySet() and review_completed__c != true];
			delete reviews;
		} else if (Trigger.isAfter){
			// now remove the sharing from the old interviewer on the Job App and Candidate

		}
	}
}