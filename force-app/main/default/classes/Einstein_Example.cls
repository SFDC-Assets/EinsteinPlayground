global with sharing class Einstein_Example {

	@AuraEnabled
	global Integer id {get; set;}
	@AuraEnabled
	global String name {get; set;}
	@AuraEnabled
	global DateTime createdAt {get; set;}
	@AuraEnabled
	global Einstein_Label label {get; set;}
	@AuraEnabled
	global String location {get; set;}

	global enum Types {
		ALL,
		FEEDBACK,
		UPLOAD
	}

}