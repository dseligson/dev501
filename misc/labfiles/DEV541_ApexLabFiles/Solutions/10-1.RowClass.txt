public class Row {
	public List<Cell> cells {get; set;}
	public sobject record {get; set;}
	public boolean header {get; set;}
	
	public Row(){
		header = false;
		cells = new List<Cell>();
	}
	
	public Row(Boolean isHeader){
		header = isHeader;	
		cells = new List<Cell>();
	}
	
	public String html {
		get{
			if (html == null) {
				html = '<tr>';
				if (cells != null){
					for(cell c : cells){
						html += header ? '<th>' + c.fieldName + '</th>' : '<td>' + c.fieldVal + '</td>';
					}
				}
				html += '</tr>';
			}
			return html;
		}	
		set;	
	}

	public class Cell{
		public String fieldName {get; set;}
		public String fieldVal {get; set;}	
	}
}