public with sharing class Einstein_RecordLanguageController {
    @AuraEnabled
    public static String getRecordName(Id recordId){
        Schema.SObjectType objectName = recordId.getSObjectType(); 
        return   objectName.getDescribe().getLabel();
    }
    @AuraEnabled
    public static String getLanguagePhrase (Id recordId, String fieldName) {
        Schema.SObjectType objectName = recordId.getSObjectType(); 
        if(objectName.getDescribe().isAccessible())
        {
            SObject recordItem = Database.query('SELECT id, :fieldName FROM :objectName where id =:recordId order by id limit 1');
            System.debug(recordItem);
            return (String)recordItem.get(fieldName);
        }
        else
        {
            system.debug('-- fields not accessible ---');
            return null;
        }
        
    }
    
    @AuraEnabled
    public static List<Einstein_Probability> getRecordAnalysis(Id recordId, String modelId, String fieldName){
        System.debug('Getting Predictions...' + recordId  + ' ' + modelId + ' ' + fieldName);
        Schema.SObjectType objectName = recordId.getSObjectType(); 
        if(objectName.getDescribe().isAccessible())
        {
            SObject recordItem = Database.query('SELECT id, :fieldName FROM :objectName where id =:recordId order by id limit 1');
            System.debug(recordItem);
            String text = (String)recordItem.get(fieldName);
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
            system.debug('-- fields not accessible ---');
            return null;
        }
    } 
    @AuraEnabled
    public static void savePredictionValue(Id recordId, String fieldName, String value){
        System.debug(recordId + ' ' + fieldName + ' ' + value);
        // Retrieve the current record
        Schema.SObjectType objectName = recordId.getSObjectType();
        // isAccessible() check done on line 60 before update action
        SObject recordItem = Database.query('SELECT id, :fieldName FROM :objectName where id =:recordId order by id limit 1');
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
            system.debug('-- fields not accessible ---');
        }
    }
    
}