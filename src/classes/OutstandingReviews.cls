public class OutstandingReviews{

	// TODO: Declare a Boolean variable "selectAll" and initialize it to false
	public Boolean selectAll = false;

	// TODO: Create a "position" property that retreives the Id, Name, Status, Sub-Status for the record
	public Position__c position {
		get{
			if(position == null) {
				position = [select Id,Name,Status__c,Sub_Status__c from Position__c where id = :ApexPages.currentPage().getParameters().get('id')];
			}
			return position;
		}
		set;
	}
	// TODO: Create an "interviewers" list of interviewers property that is instantiated if found to be null
	public List<Interviewer__c> interviewers {
		get {
			if (interviewers == null) {
				interviewers = new List<Interviewer__c>();
			}
			return interviewers;
		}
		set;
	}
	// TODO: Create a list of reviews properties called "reviews" that retrieves the following review record data set if found to be null:
	//  id, name, review_completed__c, position_name__c, interviewer__c, interviewer_name__c, interviewer__r.Employee__r.Name
	//  interviewer__r.role__c, interviewer__r.employee__c, interviewer__r.employee__r.email, job_application__c, job_application__r.name, candidate_name__c
	// HINT: In this case the data should only include reviews that are not complete
	// HINT: Use the salesforce.schema feature in the IDE to create the SOQL list quickly
	private List<Review__c> reviews {
		get{
			if(reviews == null) {
				reviews = [select r.id,r.name,r.review_completed__c,r.position_name__c,r.interviewer__c,r.interviewer_name__c,r.interviewer__r.Employee__r.Name,r.interviewer__r.role__c,r.interviewer__r.employee__c,r.interviewer__r.employee__r.email,r.job_application__c,r.job_application__r.name,r.candidate_name__c from review__c r where job_application__r.position__c = :position.Id and review_completed__c != true];
			}
			return reviews;
		}
		set;
	}


	// TODO: Create a "jobApplications" list of job applications property that is instantiated if found to be null
	public List<Job_Application__c> jobApplications {
		get {
			if (jobApplications == null) {
				jobApplications = new List<Job_Application__c>();
			}
			return jobApplications;
		}
		set;
	}

	// TODO: Create a "myOutstandingReviews" list of myOutStandingReviews property that wraps the review list created above
	// HINT: For each review, in the previous list you will need to instantiate the parallel myOutstandingReview and add it to the list
	public List<MyOutstandingReview> myOutstandingReviews{
		get{
			// perform the logic to find the Reviews that have not yet been completed for the current Position
			if (myOutstandingReviews == null) {
				myOutstandingReviews = new List<MyOutstandingReview>();
				for(Review__c review:reviews){
					MyOutstandingReview record = new MyOutstandingReview(review);
					myOutstandingReviews.add(record);
				}
			}
			return myOutstandingReviews;
		}
		set;
	}




	public PageReference createTasks(){
		List<Task> tasks = new List<Task>();
		for(MyOutstandingReview myORev:myOutstandingReviews){
			if (myORev.checked) {
				Task t = new Task();
				t.WhatId = myORev.review.Id;
				t.OwnerId = myORev.review.interviewer__r.Employee__c;
				t.Subject = 'Interview Reminder';
				t.ActivityDate = System.today() + 3;
				t.IsReminderSet = true;
				t.ReminderDateTime = System.now()+1;
				t.Status = 'Not Started';
				t.Priority = 'Normal';
				t.Description = 'Please complete this review as soon as possible';
				tasks.add(t);
			}
		}
		// insert the tasks and update the pageMessage
		if (tasks.size() > 0) {
			try{
				insert tasks;
				// set the message for the user
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'tasks successfully created'));
			} catch (DMLException e){
				// show the messages to the user
				ApexPages.addMessages(e);
			}
		} else {
			// set the message for the user
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'No tasks were created'));
		}

		return null;
	}

	public PageReference sendEmails(){
		// this function sends emails to the interviewers selected by the user on the page

		// first we declare an empty List of emails
		Messaging.SingleEmailMessage[] emails = new Messaging.SingleEmailMessage[0];

		// loop through the Outstanding Reviews and create emails
		for(MyOutstandingReview myORev:myOutstandingReviews){
			if (myORev.checked) {
				Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
				email.setSaveAsActivity(false);
				email.setTargetObjectId(myORev.review.interviewer__r.employee__c);
				email.setSubject('Reminder: Review ' + myORev.review.name + ' needs your attention');
				String htmlBody= 'Dear ' + myORev.review.interviewer_name__c + ':<br/><br/>';
				htmlBody += 'This is a reminder that your review of ' + myORev.review.Candidate_Name__c + ' for the position of ' +
					myORev.review.Position_Name__c + ' has not been completed yet. Please complete this review as soon as possible.' +
					'<br/><br/>Review Link: <a href=https://na1.salesforce.com/' + myORev.review.id + '>click here</a><br/><br/>Thank You,<br/>Recruiting Dept.';
				email.setHtmlBody(htmlBody);
				String[] emailAddresses = new String[] { myORev.review.interviewer__r.employee__r.email };
				email.setToAddresses(emailAddresses);
				emails.add(email);
			}
		}

		if (emails.size() > 0) {
			try{
				Messaging.sendEmail(emails, true);
				// set the message for the user
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,emails.size() + ' emails sent'));
			}
			catch (Exception e){
				// show the messages to the user
				ApexPages.addMessages(e);
			}
		}

		return null;
	}

	// TODO: Create a "doSelectAll" action method that toggles the value of "selectAll" and switches the checked value of all records to that same value
	public PageReference doSelectAll(){
		selectAll = !selectAll;
		for(MyOutstandingReview myORev:myOutstandingReviews){
			myORev.checked = selectAll;
		}
		return null;
	}


}