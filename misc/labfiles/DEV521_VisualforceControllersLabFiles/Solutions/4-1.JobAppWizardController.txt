public class JobAppWizard {
 
    // These properties will be used to maintain state
    
    // Search results are not transient in case the user accidentally selects 
    //	the wrong one and wants to go back
    public List<Candidate__c> results {
    	get{
    		if(results == null) results = new List<Candidate__c>();
        	return results;
    	}
    	set;	
    }
    
    public ApexPages.standardController controller {get; set;}
    
    public String searchText {
    	get;
    	set{
    		value = value.endsWith('*') ? value : value + '*';
            searchText = value; 
    	}
    }
    
    public Boolean showSearch {
    	get{
    		if (showSearch == null) showSearch = true;
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
    
    public ID candidateId { get; set; }
    
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
    public PageReference step1() {
        return Page.jobAppStep1;
    }
    public PageReference step2() {
    	return Page.jobAppStep2;
    }
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
    public PageReference SelectCandidate() {    
        candidate = [select id,first_name__c,last_name__c,phone__c,email__c,mobile__c, street_address_1__c,street_address_2__c,city__c,state_province__c,zip_postal_code__c,country__c from Candidate__c where id=:candidateId];   
        return Page.jobAppStep3;
    }
    
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