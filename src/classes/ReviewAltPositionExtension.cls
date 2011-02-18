public class ReviewAltPositionExtension {

	public Review__c review {get;set;}
	public Job_Application__c jobApplication {get; set;}
	private ApexPages.StandardController controller;
	public Boolean bUpdate {get;set;}

	// TODO: Create a String property "candidateId" that returns the candidate id for updates using the record's review id
	private String candidateId {
		get{
			return review.Job_Application__r.Candidate__c;
		}
		set;
	}

	private String positionId;

	// TODO: Create a Boolean property called "showAltPosition" that sets it to false if its value is null
	public Boolean showAltPosition {
		get{
			if (showAltPosition == null) showAltPosition = false;
			return showAltPosition;
		}
		set;
	}

	public String recruiterNote {get;set;}
	public Task recruiterTask {
		get{
			if (recruiterTask == null){
				Task t = new Task();
				t.Subject = 'New Job App: Alt Position Suggested';
				t.ActivityDate = System.today() + 3;
				t.IsReminderSet = true;
				t.ReminderDateTime = System.now()+1;
				t.Status = 'Not Started';
				t.Priority = 'Normal';
				recruiterTask = t;
			}
			return recruiterTask;
		}
		set;
	}

	// TODO: Create a private List of Positions property called "positions" that retrieves all of the data for the relevant positions
	// HINT: Use the schema.brower to help you quickly construct the SOQL statement
	// HINT: Only bring back positions that match the selected department and are open and approved
	private List<Position__c> positions {
		get{
			return [select id, name,location__c,priority__c,type__c,department__c,status__c, sub_status__c,Pay_Grade__c,Start_Date__c,Hiring_Manager__c,Duration__c,Days_Opened__c from Position__c
					where department__c = :selectedDept
					and  status__c = 'Open'
					and sub_status__c = 'Approved'];
		}
		set;
	}

	public String SelectedDept {get;set;}
	public String SelectedPositionId {get;set;}

	public Position__c SelectedPosition {
		get{
			// make sure we have the latest position by checking the SelectedPositionId from the selectList
			if ((SelectedPositionId != 'null') && (SelectedPositionId != null)){
				if ((SelectedPosition == null)||(SelectedPosition.id != SelectedPositionId)) {
					//get the Position record that corresponds to the SelectOption position Id chosen
					Map<ID,Position__c> positionsMap = new Map<ID,Position__c>(positions);
					SelectedPosition = positionsMap.get(SelectedPositionId);
				}
			} else {
			SelectedPosition = new Position__c();
		}
			return SelectedPosition;
		}
		set;
	}

	public reviewAltPositionExtension(ApexPages.StandardController stdController) {
		// constructor
		controller = stdController;
		this.review= (Review__c)stdController.getRecord();
		if ((ApexPages.currentPage().getParameters().get('jobAppId') != null)&&
					(ApexPages.currentPage().getParameters().get('jobAppId') != '')){
			review.Job_Application__c = ApexPages.currentPage().getParameters().get('jobAppId');
			jobApplication = [select candidate__c,position__c from job_application__c where id = :review.Job_Application__c];
			candidateId = jobApplication.candidate__c;
			positionId = jobApplication.position__c;
		}
		bUpdate = (review.id != null ? true : false);
		System.debug('bUpdate = ' + bUpdate);
	}

	public List<SelectOption> getDeptOptions() {
		// this function builds the list of SelectOptions for the Department field
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('null','-- Select One --'));
		// do describe here to get the Department__c field picklist values
		Schema.DescribeFieldResult deptDFR = Schema.sObjectType.Position__c.fields.Department__c;
		for (Schema.PickListEntry deptPickVal : deptDFR.getPicklistValues()){
			// create a selectoption for each pickval
			options.add(new SelectOption(deptPickVal.getValue(),deptPickVal.getLabel()));
		}
		return options;
	}

	public List<SelectOption> getPositionOptions() {
		// this function builds the list of selectOptions containing the position records
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('null','-- Select One --'));
		// make sure a valid Department was chosen
		if (SelectedDept != 'null') {
			for(Position__c p:positions){
				String label = p.Name + ', ' + p.location__c;
				options.add(new SelectOption(p.id,label));
			}
		}
		return options;
	}

	private String checkOwnerIdForQueue(String ownerId){
		// simple helper function to check if the ownerId of the position that gets passed in is a user or queue
		//  if it's a queue then we need to select a user at random from the queue because a task can't
		//   belong to a queue
		try{
			ownerId = [select id,(select groupid,userorgroupid from groupmembers) from group g where id=:ownerId].groupmembers[0].UserOrGroupId;
		} catch(Exception e){
			ApexPages.addMessages(e);
		}
		return ownerId;
	}

	public void createJobAppAndTask(){
		// check the ownerId of the position before creating the jobApp & task
		//  the Task cannot be owned by a Queue
		String ownerId = checkOwnerIdForQueue(SelectedPosition.OwnerId);
		// create the job app first
		Job_Application__c jobApp = new Job_Application__c();
		jobApp.position__c = SelectedPositionId;
		// will have to query for the candidate__c on the selected jobApp if this Review is a new one rather than an update
		jobApp.candidate__c = candidateId == null ? [select candidate__c from job_application__c where id = :review.job_application__c].candidate__c : candidateId;
		jobApp.status__c = 'Open';
		jobApp.stage__c = 'New';
		jobApp.ownerid = ownerId;
		try{
			insert jobApp;
		} catch (Exception e){
			ApexPages.addMessages(e);
		}

		//create a task for the owner of the position
		recruiterTask.WhatId = jobApp.Id;
		recruiterTask.OwnerId = ownerId;

		try{
			insert recruiterTask;
		} catch (Exception e){
			ApexPages.addMessages(e);
		}
	}

	public PageReference save(){
		// create the job app & task if a position was selected
		if (SelectedPositionId != null) { createJobAppAndTask(); }
		return controller.save();
	}


}