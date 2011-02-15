trigger PositionSharingTrigger on Position__c (after insert, after update) {

		// Positions were updated so many things need to happen in regards to sharing
		//	Some of these items affect Positions AND associated Salaries
		//  1. We need to remove the old hiring manager completely from sharing IFF the hiring manager has changed
		//  2. We need to remove old department VP from related Salary sharing
		//  3. We need to add the new hiring manager to Read/Write sharing IFF the position is in the Open status
		//  4. We need to add related Salary record sharing to make sure the VP and Hiring Mgr have access
		//  5. We need to update the existing hiring manager ReadOnly sharing IFF the position has been updated to the Closed status
		// We need to process the above in order to avoid conflicts
		//  6. Need to add Entire Organization to ReadOnly sharing IFF position is Open & Approved
		//  7. Need to remove any existing Entire Organization ReadOnly sharing IFF position is Closed

		Map<ID,ID> posIdToNewMgrIdMap = new Map<ID,ID>();			// Map of Position ID --> New Hiring Mgr Id
		Map<ID,String> posIdToDeptMap = new Map<ID,String>();			// Map of Position ID --> New Department
		List<Position__c> approvedPositions = new List<Position__c>();  	// List of all approved Positions
		List<Position__c> nonApprovedPositions = new List<Position__c>(); 	// List of all non-Approved positions
		Set<ID> removeOrgWideSharingSet = new Set<ID>();			// Set of all closed or non-approved positions
		List<Position__c> nonClosedPositions = new List<Position__c>();		// List of non-closed positions; for SalarySharing
		List<Position__c> closedPositions = new List<Position__c>();		// List of closed positions; for SalarySharing

		for (Position__c position:Trigger.new){
			// Most of the actions are the same for inserts and updates, but the first tracking of hiring manager changes only applies
			//  to updates.
			if (Trigger.isUpdate){
				// 1. Build the Map	of Hiring Manager changes
				if(position.Hiring_Manager__c != Trigger.oldMap.get(position.Id).Hiring_Manager__c){
					posIdToNewMgrIdMap.put(position.Id,position.Hiring_Manager__c);
				}
				// 2. Build the Map of Department changes
				if(position.Department__c != Trigger.oldMap.get(position.Id).Department__c){
					posIdToDeptMap.put(position.Id,position.Department__c);
				}
			}

			// 3.  Build the List of all closed and non-closed Positions for Position & Salary sharing
			if (position.Status__c != 'Closed'){
				nonClosedPositions.add(position);
			} else {
				closedPositions.add(position);
			}
			// 4.  Build the List of approved positions
			if ((position.Status__c == 'Open') && (position.Sub_Status__c=='Approved')){
				approvedPositions.add(position);
			} else {
			// 5.  Build the Set of non-approved positions
				removeOrgWideSharingSet.add(position.id);
				nonApprovedPositions.add(position);
			}
		}

		if (Trigger.isUpdate){
			// 1. Remove Old Hiring Mgr
			PositionSharing.deleteHiringMgrSharing(posIdToNewMgrIdMap);
//Salary:		SalarySharing.deleteHiringMgrSharing(posIdToNewMgrIdMap);
//Jop App:		JobAppSharing.deleteHiringMgrSharing(posIdToNewMgrIdMap);
			// 2. Remove Old salary VP sharing
//Salary:		SalarySharing.deleteVPSharing(posIdToDeptMap);
		}
		// 3. Add Hiring Mgr to Read/Write sharing
		PositionSharing.addSharing(nonApprovedPositions,'Read');
		PositionSharing.addSharing(approvedPositions,'Edit');
//Jop App: 	JobAppSharing.createSharing(Trigger.new,'Hiring_Manager__c','Edit');
		// 4. Add Sharing to Related Salary Records
//Salary:	SalarySharing.addSharing(nonClosedPositions,'Read');
//Salary:	SalarySharing.addSharing(approvedPositions,'Edit');
//Salary:	SalarySharing.closeSharing(closedPositions);
		// 5. Update Hiring Mgr to ReadOnly Sharing
		PositionSharing.addSharing(ClosedPositions,'Read');
		PositionSharing.closeHiringMgrSharing(closedPositions);
//Jop App:	JobAppSharing.createSharing(closedPositions,'Hiring_Manager__c','Read');
//Jop App:	JobAppsharing.closeHiringMgrSharing(closedPositions);
		// 6. Add Entire Organization sharing IFF Approved
		PositionSharing.addSharing(approvedPositions,'Approved_Position__c','Edit');
		// 7. Remove Entire Organization sharing
		PositionSharing.removeOrgWideSharing(removeOrgWideSharingSet);

}