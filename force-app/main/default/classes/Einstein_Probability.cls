@JsonAccess(serializable='always' deserializable='always')
global with sharing class Einstein_Probability {

	@AuraEnabled
	global String label {get; set;}
	@AuraEnabled
	global Double probability {get; set;}
	@AuraEnabled
	global String token {get; set;}

	// Legacy NER prior to V3.  No longer used
	@AuraEnabled
	global String normalizedValue {get; set;}
	// NER Only
	@AuraEnabled
	global Span span {get; set;}
	@AuraEnabled
	global List<NormalizedData> normalizedData {get; set;}

	// OCR
	@AuraEnabled
	global Attributes attributes {get; set;}

	// All but Entities
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
	
	global class Span {
		@AuraEnabled 
		// Actual name is 'end', which is an Apex reserved word
		global Integer endx {get; set;}
		@AuraEnabled 
		global Integer start {get; set;}
	}

	global class NormalizedData {
		@AuraEnabled 
		global String firstName {get;set;}
		@AuraEnabled 
		global String lastName {get;set;}
		@AuraEnabled 
		global String middleName {get;set;}
		@AuraEnabled 
		global String suffix {get;set;}
		@AuraEnabled 
		global String value {get; set;}
		@AuraEnabled 
		global String unit {get; set;}
		@AuraEnabled 
		global String type {get;set;}
		@AuraEnabled 
		global Integer countryCode {get;set;}
		@AuraEnabled 
		global Integer nationalNumber {get;set;}
		@AuraEnabled 
		global normalizedDataUnit to {get;set;}
		@AuraEnabled 
		global normalizedDataUnit fromx {get;set;}
	}

	global class normalizedDataUnit {
		@AuraEnabled 
		global String value {get; set;}
		@AuraEnabled 
		global String unit {get; set;}
		@AuraEnabled 
		global String type {get;set;}
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