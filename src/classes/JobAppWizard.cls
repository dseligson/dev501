public class JobAppWizard {

	// These properties will be used to maintain state

	// Search results are not transient in case the user accidentally selects
	//	the wrong one and wants to go back

	// TODO: Create a candidate list property called "results" that instantiates a new list if results is currently set to null
	public List<Candidate__c> results {
		get{
			if (results==null) {
				results = new List<Candidate__c>();
			}
			return results;
		}
		set;
	}

	// TODO: Create a property named "controller" that references the standard controller
	public ApexPages.StandardController controller {get;set;}

	// TODO: Create a String property called "searchText" that automatically sets an asterisk ("*") at the end of the search string if it does not already have one
	public String searchText {
		get;
		set{
			value = value.endsWith('*') ? value : value + '*';
			searchText = value;
		}
	}

	// TODO: Create a Boolean property called "showSearch" that returns a true value instead of null
	public Boolean showSearch {
		get{
			if (showSearch == null) {
				showSearch = true;
			}
			return showSearch;
		}
		set;
	}

	public Job_Application__c jobApplication { get; set; }

	public Candidate__c candidate {
		get{
			if (candidate == null) candidate = new Candidate__c();
			return candidate;
		}
		set;
	}
	// TODO: Create an ID property called "candidateId" with default getters/setters
	public ID candidateId {get;set;}

	public JobAppWizard(ApexPages.StandardController stdController) {
		// constructor
		controller = stdController;
		this.jobApplication = (Job_Application__c)stdController.getRecord();
		if ((ApexPages.currentPage().getParameters().get('posId') != null)&&
					(ApexPages.currentPage().getParameters().get('posId') != '')){
			jobApplication.Position__c = ApexPages.currentPage().getParameters().get('posId');
		}
	}

	// The next 3 methods control navigation through
	// the wizard. Each returns a PageReference for one of the 3 pages
	// in the wizard. Note that the redirect attribute does not need to
	// be set on the PageReference because the URL does not need to change
	// when users move from page to page.
	// TODO: Create a method called "step1" to return the page reference for the JobAppStep1 page
	public PageReference step1() {

		return Page.JobAppStep1;
	}

	// TODO: Create a method called "step2" to return the page reference for the JobAppStep2 page
	public PageReference step2() {
		return Page.JobAppStep2;

	}
	// TODO: Create a method called "step3" that validates that the Candidate's last name is not null
	public PageReference step3() {
		if (candidate.last_name__c == null){
			candidate.last_name__c.addError('Last Name is required');
			return null;
		} else {
			return Page.jobAppStep3;
		}
	}
	// this function is called by step2 & step3 pages in the action attribute,
	//	in case anyone tries to go directly to them it will navigate the user back to step1
	public PageReference checkPosition(){
		if (jobApplication.Position__c == null) {
			PageReference newRef = Page.jobAppStep1;
			newRef.setRedirect(true);
			return newRef;
		} else {
			return null;
		}
	}

	public PageReference doSearch() {
		results = (List<Candidate__c>)[FIND :searchText IN ALL FIELDS RETURNING Candidate__c(Id, First_Name__c, Last_Name__c, Email__c, City__c, State_Province__c, Phone__c)] [0];
		return null;
	}

	// doing a separate query here to keep the view state down

	// TODO: Create a method called "selectCandidate" that retrieves all of the candidate information for the given id and returns the user to step 3
	public PageReference SelectCandidate() {
		candidate = [select id,first_name__c,last_name__c,phone__c,email__c,mobile__c, street_address_1__c,street_address_2__c,city__c,state_province__c,zip_postal_code__c,country__c from Candidate__c where id=:candidateId];
		return Page.jobAppStep3;
	}

	// TODO: Create a method called "newCandidate" that resets the candidateId to null so that it inserts the candidate information when ultimately saved
	public PageReference NewCandidate(){
		if (!showSearch) {
			candidate = new Candidate__c();
			candidateId = null; // reset the id so we know what to do upon save
		}
		return null;
	}

		public PageReference save() {
			// catches need to return null; redo using ApexPages.addMessages(e) & <apex:pageMessages>
			if (candidateId == null) {
				// it's a brand spanking new candidate so we need to insert it first
				try{
					insert candidate;
					System.debug('new candidate=' + candidate);
				} catch (System.DmlException e) {
					ApexPages.addMessages(e);
					return null;
				}
			}
			System.debug('jobApplication=' + jobApplication);
			jobApplication.Candidate__c = candidate.id;
			try{
				insert jobApplication;
			} catch (System.DmlException e) {
				ApexPages.addMessages(e);
				return null;
			}
			controller = new ApexPages.standardController(jobApplication);
			return controller.view();
		}
}