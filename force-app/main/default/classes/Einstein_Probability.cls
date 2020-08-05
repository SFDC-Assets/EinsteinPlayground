global with sharing class Einstein_Probability {

	@AuraEnabled
	global String label {get; set;}
	@AuraEnabled
	global Double probability {get; set;}
	@AuraEnabled
	global String token {get; set;}
	@AuraEnabled
	global String normalizedValue {get; set;}

	@AuraEnabled
	global Attributes attributes {get; set;}

	@AuraEnabled
	global BoundingBox boundingBox {get; set;}


	global class Attributes {

		// When OCR Task == 'table'
		@AuraEnabled
		global CellLocation cellLocation {get; set;}
		// When OCR Task == 'contact'
		@AuraEnabled
		global String tag {get; set;}
		// when OCR task == 'form'
		@AuraEnabled
		global Integer blockId {get; set;}
		@AuraEnabled
		global String language {get; set;}
		@AuraEnabled
		global EntityBlock key {get; set;}
		@AuraEnabled
		global EntityBlock value {get; set;}	

		// When OCR Task == any && file type == PDF
		@AuraEnabled
		global Integer pageNumber {get; set;}
	}
	
	global class EntityBlock {
		@AuraEnabled
		global String text {get; set;}
		@AuraEnabled
		global String entity {get; set;}
		@AuraEnabled
		global BoundingBox boundingBox {get; set;}
	}

    global class CellLocation {
        @AuraEnabled
        global Integer colIndex {get; set;}
        @AuraEnabled
        global Integer rowIndex {get; set;}
    }

    global class BoundingBox {
        @AuraEnabled
        global Integer minX {get; set;}
        @AuraEnabled
        global Integer minY {get; set;}
        @AuraEnabled
        global Integer maxX {get; set;}
        @AuraEnabled
        global Integer maxY {get; set;}
    }

}