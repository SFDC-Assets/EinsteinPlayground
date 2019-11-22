public class EinsteinLanguageMassUpdateController {

    
    @AuraEnabled
	public static List<String> getObjectOptions(){

		Map<String, Schema.SObjectType> objects = Schema.getGlobalDescribe();
 		List<String> results = new List<String> ();
		list<map<string, string>> output = new list<map<string, string>>();
		for (string s:objects.keySet()){
			DescribeSObjectResult dsor = objects.get(s).getDescribe();
			if (
				//if you can't update anything, you won't be able to save a prediction anywhere!
				dsor.isUpdateable() &&
				!dsor.isCustomSetting() //no custom settings
			) {
          
                results.add(dsor.getName());
               
			}

		}
        results.sort();
		system.debug('--- results---' + results);
		return results;
	}
    
    /*for a given object, return the fields that are sources of text (string, textarea) or labels (picklist, boolean)*/
	@AuraEnabled
	public static List<string> getObjectFields(string objectName, string sourceOrLabel){
		list<string> temp = new list<string>();
		temp.add(objectName);

		List<Schema.DescribeSObjectResult> describe = Schema.describeSObjects(temp);

		map<string, Schema.SObjectField> fieldmap = describe[0].fields.getMap();

		list<map<string, string>> output = new list<map<string, string>>();

        list<string> results = new list<string>();
        
		for (Schema.SObjectField field:fieldmap.values()){
			DescribeFieldResult dfr = field.getDescribe();
		
				map<string, string> tempMap = new map<string, string>();
				if (dfr.getLabel() != dfr.getName()){
					tempMap.put('label', dfr.getLabel() + ' (' + dfr.getName() + ')' + ' [' + dfr.getType().name() + ']');
				} else {
					tempMap.put('label', dfr.getLabel() + ' [' + dfr.getType().name() + ']');
				}
				tempMap.put('name', dfr.getName());
				tempMap.put('type', dfr.getType().name());
				output.add(tempMap);
                results.add(dfr.getName());

		} //end for loop of fieldmap

		system.debug(output);
		//return JSON.serialize(output);
		 results.sort();
		return results;
	}

    @AuraEnabled
    @Readonly
    @RemoteAction
    public static Integer getObjectCount(string objectName){
        Integer count = 0;
 
        AggregateResult[] groupedResults  = Database.query('SELECT count(Id)cnt FROM ' + objectName );
		count = (Integer) groupedResults[0].get('cnt');
        
        return count;
    }

    
    
    
  @AuraEnabled
    public static String goClassify( String sourceName, String destinationName, String objectName, Integer batchSize, String modelId, String dataType,
                                    String overwriteValues, String latestId, String ignoreErrors) {
         

        System.debug('---- Started Classification ----');
         Boolean overwrite = Boolean.valueOf(overwriteValues);
        Boolean ignoreErrorVal = Boolean.valueOf(ignoreErrors);
        
        System.debug(modelId + ' '  + latestId + ' ' + batchSize  + ' ' + dataType + ' ' + overwrite  + ' ' + ignoreErrorVal);
      //  System.debug( overwriteValues);
  
       Integer maxSize = Integer.valueOf(batchSize);
      
       
        List<SObject > dataList = null;
        if(latestId == null ) {
             System.debug('- Started From Scratch --');
           dataList =  Database.query('SELECT id, ' + sourceName + ',' + destinationName +  ' FROM ' + objectName + ' order by id limit ' + maxSize);
        } else {
            dataList =  Database.query('SELECT id, ' + sourceName + ',' + destinationName +  ' FROM ' + objectName + ' where id > \'' + latestId + '\' order by id limit ' + maxSize);
        }
        
         System.debug('Got dataset of size ' + dataList.size());
       List<SObject > shortList  = new List<SObject >();   
        
        Einstein_PredictionService service;
           if(dataType == 'text-intent') {
               service = new Einstein_PredictionService(Einstein_PredictionService.Types.Intent);
           } else if(dataType == 'image') {
                service = new Einstein_PredictionService(Einstein_PredictionService.Types.Image);
           }
      
        
              for (Integer i = 0; i < dataList.size() && i < maxSize; i++) {
                  
                  SObject  obj = dataList.get(i);
                  latestId = (string) obj.get('id');
                  String text = (String)obj.get(sourceName);
                   String existingValue = (String)obj.get(destinationName);
              
                   if((overwrite || existingValue == null || existingValue.length() ==0) && (text != null && text.length() >0) ) {
                      
                       try {
                           
                       
                        Einstein_PredictionResult predictionList = null;
                       
                           
                       if(modelId == 'CommunitySentiment') {
                         	predictionList = service.predictSentiment(modelId, text, 2, null);
                        } else  if(dataType == 'text-intent') {
                         
							predictionList  = service.predictIntent(modelId, text, 2, null);
                        } else if(dataType == 'image') {
                            predictionList  = service.predictImageUrl(modelId, text, 2, null);
                       }
                          
                        System.debug(predictionList);  
                           
                        Double topPred = 0;
                        String label = '';
                       
                       
                        if (service.httpStatusCode>200 && ignoreErrorVal == false) {
                            throw new AuraHandledException('API http error:' + service.httpErrorMessage);
                        }
                                    
                        for(Einstein_Probability pred : predictionList.probabilities) {
                            System.debug(pred);
                            if(pred.probability > topPred) {
                               label = pred.label;
                               topPred = pred.probability;
                            }
                        }  
                       
                    
                           
						System.debug(label); 
                        obj.put(destinationName, label);
                 
                        shortList.add(obj);
                       } catch(Exception e) {
                           System.debug(e);
                           if(ignoreErrorVal == false) {
                               throw new AuraHandledException(e.getMessage());
                           }
                       }
                    }
                }
            System.debug('---- Saving List ' + shortList.size() + ' ----');
           System.debug(shortList); 
        	update shortList; 
           
            return latestId;  
   }
    
    @AuraEnabled
    public static List<Einstein_Dataset> getDatasetList() {
     
          Einstein_PredictionService service = new Einstein_PredictionService(Einstein_PredictionService.Types.Intent);
       List<Einstein_Dataset> datasetList = service.getDatasets();
      
        
       if (service.httpStatusCode>200) {
                throw new AuraHandledException(service.httpErrorMessage);
            }
       
        return datasetList;
        
    }
    
    @AuraEnabled
    public static List<Einstein_Model> getModelList(Integer datasetId) {
       System.debug('Getting models');
        System.debug(datasetId);
        
          Einstein_PredictionService service = new Einstein_PredictionService(Einstein_PredictionService.Types.Intent);
       List<Einstein_Model> datasetList = service.getModels(datasetId);
        
        
       if (service.httpStatusCode>200) {
                throw new AuraHandledException(service.httpErrorMessage);
            }
       
        return datasetList;
        
    }  

        
    
}