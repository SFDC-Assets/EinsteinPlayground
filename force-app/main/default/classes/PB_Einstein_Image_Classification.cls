public with sharing class PB_Einstein_Image_Classification {

    @InvocableMethod(label='Einstein Image Classification')
    public static void AnalyzeEinsteinPlatform(List<Parameters> params) {
        
        for (Parameters param : params) {
            if (!String.isEmpty(param.fieldAnalyze) && !String.isEmpty(param.modelId)) {
                runClassification(param.recordIdAnalyze, param.fieldAnalyze, param.fieldReturn, param.modelId);
            }
        }
 
    }

    @future(callout=true)
    private static void runClassification(Id accountId, String fieldSourceName, String fieldTargetName, String modelId) {
        
        list<string> accessibleFields = new list<string>();
        accessibleFields.add('id');
        accessibleFields.add(accountId);
        accessibleFields.add(fieldSourceName);
        accessibleFields.add(fieldTargetName);
        
        Map<String,Schema.SObjectField> m = Schema.SObjectType.Account.fields.getMap();
                
        for (String f: accessibleFields) {
            // Check if the user has access to view field
            if (!m.get(f).getDescribe().isAccessible()) {
                //also pass error to client
                throw new System.NoAccessException();
            }
        }
        
        String soql = 'SELECT Id, ' + String.escapeSingleQuotes(fieldSourceName) + ' FROM Account WHERE Id=:' + String.escapeSingleQuotes(accountId);
        List<SObject> accts = Database.query(soql);
        Account acc = (Account)accts.get(0);
        Einstein_PredictionService service = new Einstein_PredictionService(Einstein_PredictionService.Types.IMAGE);
        Einstein_PredictionResult result = service.predictImageUrl(modelId, String.valueOf(acc.get(fieldSourceName)), 2, '');
        if (result!=null && result.probabilities.size()>0) {
            acc.put(fieldTargetName, result.probabilities.get(0).label);
            update acc;
        }
    }

    public class Parameters {

        @InvocableVariable(required=true label='Record ID' description='The ID of the record that should be analyzed.')
        public String recordIdAnalyze;

        @InvocableVariable(required=true label='Field for Image Classification URL' description='Enter the name of the fields, that contains the detecti')
        public String fieldAnalyze;

        @InvocableVariable(required=true label='Field for detected label' description='Enter the name of the field, that should be analyzed via Einstein Vision.')
        public String fieldReturn;

        @InvocableVariable(required=true label='Model ID for the Image Classification')
        public String modelId;

    }

}