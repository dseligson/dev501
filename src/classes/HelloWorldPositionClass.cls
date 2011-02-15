public class HelloWorldPositionClass {

	public static void updateHello(List<Position__c> updateList) {
		for (Position__c p : updateList) {
			if (p.Hello__c != 'Hello World') {
				p.Hello__c = 'Hello World';
				updateList.add(p);
			}
		}
	}


}