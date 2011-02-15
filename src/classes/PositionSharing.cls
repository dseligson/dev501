public class PositionSharing {

	public static final Id ENTIRE_ORG_GROUP_ID_CONST;

	static {
		ENTIRE_ORG_GROUP_ID_CONST = getEntireOrgGroupId();
	}
	public static Id getEntireOrgGroupId() {
		return [select id from Group where type='Organization'].id;
	}

	//TODO: Create a static method called "getEntireOrgGroupId()" that returns the Id from the Standard Group object with Type=Organization

	public static void deleteHiringMgrSharing(Map<ID,ID> posIdToNewMgrIdMap){
		if (posIdToNewMgrIdMap.size() > 0){
			// go through the list of related sharing records in batch and remove old Hiring Manager shares
			for(List<Position__Share> batchOfShares:[select UserOrGroupId, RowCause, ParentId, Id, AccessLevel From Position__Share where ParentId IN :posIdToNewMgrIdMap.keySet() and RowCause='Hiring_Manager__c']){
				List<Position__Share> deleteShares = new List<Position__Share>();
				for(Position__Share posShare:batchOfShares){
					if (posIdToNewMgrIdMap.get(posShare.ParentId) != posShare.UserOrGroupId){
						deleteShares.add(posShare);
					}
				}
				try {
					delete deleteShares;
				} catch (System.DmlException e){
					System.debug('error bulk deleting position shares');
					for (Integer k = 0; k < e.getNumDml(); k++) {
						// Process exception here
						System.debug(e.getDmlMessage(k));
					}
				}
			}
		}
	}

	public static void closeHiringMgrSharing(List<Position__c> closedPositions){
		if (closedPositions.size() > 0){
			Set<ID> closedPositionSet = new Map<ID,Position__c>(closedPositions).keySet();
			// go through the list of related sharing records in batch and update any Hiring Manager
			//	sharing records to be Read Only
			for(List<Position__Share> batchOfShares:[select UserOrGroupId, RowCause, ParentId, Id, AccessLevel From Position__Share where ParentId IN :closedPositionSet and RowCause='Hiring_Manager__c']){
				for(Position__Share posShare:batchOfShares){
					posShare.AccessLevel = 'Read';
				}
				try {
					update batchOfShares;
				} catch (System.DmlException e){
					System.debug('error bulk updating position shares');
					for (Integer k = 0; k < e.getNumDml(); k++) {
						// Process exception here
						System.debug(e.getDmlMessage(k));
					}
				}
			}
		}
	}

	public static void addSharing(Position__c[] positions, String apexType, String accessLevel){
		System.debug('creating bulk Position__Share records');
		List<Position__Share> posShares = new List<Position__Share>();

		for (Position__c p:positions){
			// Build Sharing Records for each Open Position
			Position__Share ps = new Position__Share();

			ps.ParentId = p.Id;
			if (apexType == 'Hiring_Manager__c'){
				ps.UserOrGroupId = p.Hiring_Manager__c;
				ps.RowCause = Schema.Position__Share.RowCause.Hiring_Manager__c;
			} else if(apexType =='Approved_Position__c'){
				ps.UserOrGroupId = ENTIRE_ORG_GROUP_ID_CONST;
				ps.RowCause = Schema.Position__Share.RowCause.Approved_Position__c;
			}
			ps.AccessLevel = accessLevel;
			System.debug('this is ps: ' + ps);
			posShares.add(ps);
		}

		// Insert the sharing records
		if (posShares.size() > 0){
			try {
				System.debug('performing bulk Position__Share insert');
				Database.insert(posShares,false);
			} catch (System.DmlException e) {
				System.debug('error bulk inserting position shares');
				for (Integer k = 0; k < e.getNumDml(); k++) {
					// Process exception here
					System.debug(e.getDmlMessage(k));
				}
			}
		}
	}

	// overloaded function
	public static void addSharing(Position__c[] positions,String accessLevel){
		// receives a list of positions; need to grab the corresponding salary records
		List<Position__c> hiringMgrPositions = new List<Position__c>();
		for (Position__c p : positions) {
			if (p.Hiring_manager__c != null) {
				hiringMgrPositions.add(p);
			}
		}

		// now call the share creation methods
		if (hiringMgrPositions.size() > 0) PositionSharing.addSharing(hiringMgrPositions,'Hiring_Manager__c',accessLevel);
	}

	public static void removeOrgWideSharing(Set<ID> removeOrgWideSharingSet){
		if (removeOrgWideSharingSet.size() > 0){
			// go through the list of related sharing records in batch and delete any Approved_Position__c
			//	sharing records
			for(List<Position__Share> batchOfShares:[select UserOrGroupId, RowCause, ParentId, Id, AccessLevel From Position__Share where ParentId IN :removeOrgWideSharingSet and RowCause='Approved_Position__c' and UserOrGroupId =:ENTIRE_ORG_GROUP_ID_CONST]){
				try {
					Database.delete(batchOfShares,false);
				} catch (System.DmlException e){
					System.debug('error bulk deleting position shares');
					for (Integer k = 0; k < e.getNumDml(); k++) {
						// Process exception here
						System.debug(e.getDmlMessage(k));
					}
				}
			}
		}

	}
}