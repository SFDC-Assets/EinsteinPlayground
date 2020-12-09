public with sharing class Einstein_RecordLanguageController {
	@AuraEnabled
	public static String getRecordName(final Id recordId){
		Schema.SObjectType objectName = recordId.getSObjectType();
		return objectName.getDescribe().getLabel();
	}

	@AuraEnabled(Cacheable=true)
	public static String getLanguagePhrase (final Id recordId, final String fieldName) {
		Schema.SObjectType objectName = recordId.getSObjectType();
		if(objectName.getDescribe().isAccessible())
		{
			String escapedFieldName = String.escapeSingleQuotes(fieldName);
			// Bind variables fail in cached Apex, apparently.  Use string concatenation to build query string
			String queryString = 'SELECT id, ' + escapedFieldName + ' FROM ' + objectName + ' where id = \'' + recordId + '\' order by id limit 1';
			SObject recordItem = Database.query(queryString);
			System.debug(recordItem);
			return (String)recordItem.get(fieldName);
		}
		else
		{
			System.debug('-- fields not accessible ---');
			return null;
		}
	}

	@AuraEnabled(Cacheable=true)
	public static List<Einstein_Probability> getRecordAnalysis(final Id recordId, final String modelId, final String fieldName){
		System.debug('Getting Predictions...' + recordId  + ' ' + modelId + ' ' + fieldName);
		Schema.SObjectType objectName = recordId.getSObjectType();
		if(objectName.getDescribe().isAccessible())
		{
			String escapedFieldName = String.escapeSingleQuotes(fieldName);
			// Bind variables fail in cached Apex, apparently.  Use string concatenation to build query string
			String queryString = 'SELECT id, ' + escapedFieldName + ' FROM ' + objectName + ' where id = \'' + recordId + '\' order by id limit 1';
            SObject recordItem = Database.query(queryString);
            System.debug(recordItem);
			String text = (String)recordItem.get(fieldName);
			// This field could be a Rich text field.  Attempt to strip out any HTML tags at least.
			text = text.replaceAll('<[^>]+>',' ');
            Einstein_PredictionService service = new Einstein_PredictionService(Einstein_PredictionService.Types.SENTIMENT);
            Einstein_PredictionResult result = null; 
            if(modelId == 'CommunitySentiment') {
                result  = service.predictSentiment('CommunitySentiment',  text, 4, null);
            } else {
                result  = service.predictIntent(modelId,  text, 4, null);
            }
            if (service.httpStatusCode>200) {
                throw new AuraHandledException(service.httpErrorMessage);
            }
            return result.probabilities;
        }
        else
        {
            System.debug('-- fields not accessible ---');
            return null;
        }
    }

    @AuraEnabled
    public static void savePredictionValue(final Id recordId, final String fieldName, final String value){
        System.debug(recordId + ' ' + fieldName + ' ' + value);
        // Retrieve the current record
        Schema.SObjectType objectName = recordId.getSObjectType();
        // isAccessible() check done on line 60 before update action

		String escapedFieldName = String.escapeSingleQuotes(fieldName);
		// Bind variables fail in cached Apex, apparently.  Use string concatenation to build query string
		String queryString = 'SELECT id, ' + escapedFieldName + ' FROM ' + objectName + ' where id = \'' + recordId + '\' order by id limit 1';
        SObject recordItem = Database.query(queryString);
        // Update the field value and save the record
        // 
        if(objectName.getDescribe().isAccessible() && objectName.getDescribe().isUpdateable())
		{     
            recordItem.put(fieldName, value);
            System.debug(recordItem);
            update recordItem;
        }
        else
        {
            System.debug('-- fields not accessible ---');
        }
    }
}