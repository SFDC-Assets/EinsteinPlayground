public  class Einstein_RecordVisionController {

    @AuraEnabled
    public static Einstein_Model[] getCustomModels()
    {
       Einstein_PredictionService service = new Einstein_PredictionService(Einstein_PredictionService.Types.IMAGE);
       Einstein_Dataset[] datasetList = service.getDatasets();
     
        if (service.httpStatusCode>200) {
                throw new AuraHandledException(service.httpErrorMessage);
            }
       
		 List<Einstein_Model> modelList = new  List<Einstein_Model>();
        
        for(Einstein_Dataset dataset: datasetList) {
            List<Einstein_Model> newModelList = service.getModels(dataset.id);
            if (service.httpStatusCode>200) {
                throw new AuraHandledException(service.httpErrorMessage);
            }
              for(Einstein_Model model: newModelList) {
                  modelList.add(model);
              }
        }
       
        return modelList;
        
  
    }
    
    @AuraEnabled
    public static Einstein_PredictionResult  analyseImage(String base64Data, String modelName, ID recId , String fileName, String contentType, String keyContent, String email) {

       System.debug('recId' + recId + ' :: fileName ' + fileName + ' :: base64Data :: ' + base64Data.length() + ' :: ContentType :: ' + contentType + ' :: modelName :: ' + modelName );
       System.debug(base64Data.length());
     
        //List<CQB_Vision.Prediction> predictions = CQB_Vision.predictBase64(base64Data, getToken(keyContent, email), modelName);  
        
        Einstein_PredictionService service = new Einstein_PredictionService(Einstein_PredictionService.Types.IMAGE);
        Einstein_PredictionResult result = service.predictImageBase64( modelName, base64Data, 4, null);
        
          if (service.httpStatusCode>200) {
                throw new AuraHandledException(service.httpErrorMessage);
            }
        
        //ID attachementId = CreateAttachmentCtrl.receiveData(recId, fileName, base64Data, contentType);
        
        System.debug(result);
        
       return result;
    }
    
    @AuraEnabled
    public static Id  createRecord(ID recordId, String objectName, String fieldName, String intentLabel) {
       	System.debug(recordId + ' ' + fieldName + ' ' + intentLabel);
       
        sObject sObj = Schema.getGlobalDescribe().get(objectName).newSObject() ;
        sObj.put(fieldName, intentLabel);
    	
        Schema.SObjectType token = recordId.getSObjectType();
        Schema.DescribeSObjectResult dr = token.getDescribe();
       
        String lookupObjectType =  dr.getName();
      	System.debug('Object name ' + objectName  + ' ' + lookupObjectType);
        String lookupName = null;
        
        List<FieldDefinition> fieldList = [Select Label, QualifiedApiName , DataType, FieldDefinition.Publisher.isSalesforce From FieldDefinition where EntityDefinition.QualifiedApiName =: objectName ];
        
        List<String> fieldNames = new List<String>();
        for(FieldDefinition item: fieldList) {
            String name = item.QualifiedApiName ;
            Boolean isSalesforce =  item.Publisher.IsSalesforce;
            
             if((item.DataType.contains('Lookup') ||  item.DataType.contains('Master-Detail') ) && item.QualifiedApiName.contains(lookupObjectType)) {    
              	lookupName = name;
                 System.debug('Lookup field ' + lookupName );
                sObj.put(lookupName, recordId);
               // break;
            }
        }
			
        insert sObj;
    	return sObj.id;
    }
        
    @AuraEnabled
    public static void postImageToChatter(String recordId, String docId, String comment) {
        
        System.debug('postImageToChatter ' + recordId + ' - ' + docId + ' - ' + comment);
        // Define the FeedItemInput object to pass to postFeedElement
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
       // feedItemInput.subjectId = 'me';
        feedItemInput.subjectId = recordId;
        
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text = comment;
        
        // The MessageBodyInput object holds the text in the post
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        messageBodyInput.messageSegments.add(textSegmentInput);
        feedItemInput.body = messageBodyInput;
        
        
        // The FeedElementCapabilitiesInput object holds the capabilities of the feed item.
        // For this feed item, we define a files capability to hold the file(s).
        
       List<String> fileIds = new List<String>();
        fileIds.add(docId);
       
        ConnectApi.FilesCapabilityInput filesInput = new ConnectApi.FilesCapabilityInput();
        filesInput.items = new List<ConnectApi.FileIdInput>();
        
        for (String fileId : fileIds) {
            ConnectApi.FileIdInput idInput = new ConnectApi.FileIdInput();
            idInput.id = fileId;
            filesInput.items.add(idInput);
        } 
        
        ConnectApi.FeedElementCapabilitiesInput feedElementCapabilitiesInput = new ConnectApi.FeedElementCapabilitiesInput();
        feedElementCapabilitiesInput.files = filesInput;
        
        feedItemInput.capabilities = feedElementCapabilitiesInput;
        
        // Post the feed item. 
        ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
    
    //ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), recordId, ConnectApi.FeedElementType.FeedItem, 'On vacation this week.');
        
    }
    
    
  @AuraEnabled
    public static string createContentUrl(String contentDocumentId) {
  		 string CD_TEMP_PREFIX = 'EinsteinTemp';
        integer EXPIRY = 5;

        ContentVersion CV = [select id, Title from ContentVersion where ContentDocumentId =: contentDocumentId and isLatest = true];
		ContentDistribution CD = new ContentDistribution();
		CD.ContentVersionId = CV.Id;
		CD.Name = CD_TEMP_PREFIX + '_' + CV.Title;
		CD.PreferencesAllowOriginalDownload = true;
		CD.PreferencesLinkLatestVersion = true;
		CD.ExpiryDate = system.now().addMinutes(EXPIRY);
		CD.PreferencesExpires = true;
		CD.PreferencesNotifyOnVisit = false;
		CD.PreferencesNotifyRndtnComplete = false;
		insert CD;

        ContentDistribution CD2 = [select id, ContentDownloadUrl from ContentDistribution where Id =: cd.Id];
        return CD2.ContentDownloadUrl;
    }
    
      @AuraEnabled
    public static Einstein_PredictionResult  analyseImageUrl(String url, String modelName) {

      // System.debug('recId' + recId + ' :: fileName ' + fileName + ' :: base64Data :: ' + base64Data.length() + ' :: ContentType :: ' + contentType + ' :: modelName :: ' + modelName );
       //System.debug(base64Data.length());
     System.debug('Model ' + modelName + ' url ' + url);
        //List<CQB_Vision.Prediction> predictions = CQB_Vision.predictBase64(base64Data, getToken(keyContent, email), modelName);  
        
        Einstein_PredictionService service = new Einstein_PredictionService(Einstein_PredictionService.Types.IMAGE);
        Einstein_PredictionResult result = service.predictImageUrl(modelName,  url, 3, null); 
       //(String modelId, String url, Integer numResults, String sampleId)
          if (service.httpStatusCode>200) {
                throw new AuraHandledException(service.httpErrorMessage);
            }
        
        //ID attachementId = CreateAttachmentCtrl.receiveData(recId, fileName, base64Data, contentType);
        
        System.debug(result);
        
       return result;
    }

    
  /*   public static void createPredictionRecord(String category, Decimal probability, String classifier, ID recId)
    {  
       String modelName = '';
        try {
        	modelName = [SELECT Model_Name__c FROM Einstein_Vision_Model__c WHERE Model_Id__c = :classifier][0].Model_Name__c;
        } catch (Exception e) {
            System.debug('ERROR:' + e);
        }         
        
        Einstein_Vision_Prediction__c prediction = new Einstein_Vision_Prediction__c();
        prediction.Category__c = category;
        prediction.Probability__c = probability;
        
        if (String.isBlank(modelName)) {
        	prediction.Classifier__c = classifier;   
        } else {
            prediction.Classifier__c = modelName;
        }
        
        if (recId != null) {
            prediction.Related_To_ID__C = recId;
        }
        prediction.Classifier_ID__c = classifier;
        insert prediction;
        return prediction; 

    } */
   
    
}