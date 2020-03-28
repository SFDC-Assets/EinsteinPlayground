public with sharing class Einstein_PlaygroundController {

    public static Einstein_PredictionService service;
    public static final integer EXPIRY = 5;
    public static final string CD_TEMP_PREFIX = 'EinsteinTemp';

    private static void setType(String dataType) {
	    if (service==null) {
		    service = new Einstein_PredictionService(Einstein_PredictionService.Types.IMAGE);
	    }
	    if (dataType=='image') {
		    service.setType(Einstein_PredictionService.Types.IMAGE);
	    } else if (dataType=='image-detection') {
		    service.setType(Einstein_PredictionService.Types.IMAGE_DETECTION);
	    } else if (dataType=='image-multi-label') {
		    service.setType(Einstein_PredictionService.Types.IMAGE_MULTI_LABEL);
	    } else if (dataType=='text-intent') {
		    service.setType(Einstein_PredictionService.Types.INTENT);
	    } else if (dataType=='text-sentiment') {
		    service.setType(Einstein_PredictionService.Types.SENTIMENT);
	    } else if (dataType=='text-ner') {
		    service.setType(Einstein_PredictionService.Types.NER);
	    } else if (dataType=='ocr') {
		    service.setType(Einstein_PredictionService.Types.OCR);
	    }
    }

    private static void setLanguage(String language) {
	    if (service==null) {
		    service = new Einstein_PredictionService(Einstein_PredictionService.Types.INTENT);
	    }
	    if (language=='en_US') {
		    service.setLanguage(Einstein_PredictionService.Languages.ENGLISH_US);
	    } else if (language=='en_GB') {
	        service.setLanguage(Einstein_PredictionService.Languages.ENGLISH_UK);
	    } else if (language=='fr') {
	        service.setLanguage(Einstein_PredictionService.Languages.FRENCH);
	    } else if (language=='de') {
	        service.setLanguage(Einstein_PredictionService.Languages.GERMAN);
	    } else if (language=='it') {
	        service.setLanguage(Einstein_PredictionService.Languages.ITALIAN);
	    } else if (language=='pt_PT') {
	        service.setLanguage(Einstein_PredictionService.Languages.PORTUGUESE);
	    } else if (language=='es') {
	        service.setLanguage(Einstein_PredictionService.Languages.SPANISH);
	    }
    }

    @AuraEnabled
    public static id getMyUserId(){
        return UserInfo.getUserId();
    }

    @AuraEnabled
    public static String getModelMetrics(string modelId, string dataType){
        setType(dataType);
        String metrics = service.getModelMetrics(modelId);
        if (service.httpStatusCode>200) {
            throw new AuraHandledException(service.httpErrorMessage);
        }
        return metrics;
    }

    @AuraEnabled
    public static String getLearningCurves(string modelId, string dataType){
        setType(dataType);
        String curves = service.getModelLearningCurve(modelId);
        if (service.httpStatusCode>200) {
            throw new AuraHandledException(service.httpErrorMessage);
        }
        return curves;
    }

    @AuraEnabled
    public static List<Einstein_ApiUsage> getUsage() {
        try {
            setType('image'); //default
            List<Einstein_ApiUsage> usage = service.getApiUsage();
            if (service.httpStatusCode>200) {
        	    AuraHandledException ex = new AuraHandledException(service.httpErrorMessage);
	            // setMessage is necessary for some reason to have the message propagate properly in the catch block, below.
	            ex.setMessage(service.httpErrorMessage);
	            throw ex;
            }
        	return usage;
            
    	} catch(Exception e){
         throw new AuraHandledException(e.getMessage());
    	}
    }

    @AuraEnabled
    public static void createDatasetFromUrl(String url, String dataType, String language) {
        setType(dataType);
        if (!String.isBlank(language)) {
            setLanguage(language);
        }
        service.createDatasetFromUrlAsync(url);
        if (service.httpStatusCode>200) {
            throw new AuraHandledException(service.httpErrorMessage);
        }
    }

    @AuraEnabled
    public static Einstein_Example createFeedbackLanguageExample(String expectedLabel, String modelId, String text) {
        try {
            setType('text-intent');
            Einstein_Example example = service.createFeedbackLanguageExample( expectedLabel,  modelId,  text);
            if (service.httpStatusCode>200) {
	            AuraHandledException ex = new AuraHandledException(service.httpErrorMessage);
	            // setMessage is necessary for some reason to have the message propagate properly in the catch block, below.
	            ex.setMessage(service.httpErrorMessage);
	            throw ex;
            }
            return example;
        } catch(Exception e) {
            System.debug(e);
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<Einstein_Dataset> getDatasets(String dataType) {
        /*try {*/
            setType(dataType);
            List<Einstein_Dataset> datasets = service.getDatasets();

            if (service.httpStatusCode>200) {
                throw new AuraHandledException(service.httpErrorMessage);
            }
            List<Einstein_Dataset> datasetsReturn = new List<Einstein_Dataset>();
            for (Einstein_Dataset dataset : datasets) {
                if (dataset.type==dataType) {
                    datasetsReturn.add(dataset);
                }
            }
            return datasetsReturn;
       /* }*/ /*catch(Exception e){
          System.debug('-- inside catch --');
          throw new AuraHandledException(e.getMessage());
    	}*/
    }

    @AuraEnabled
    public static List<Einstein_Model> getModels(Long datasetId, String dataType) {
        setType(dataType);
        Einstein_Model[] models = service.getModels(datasetId);
        if (service.httpStatusCode>200) {
            throw new AuraHandledException(service.httpErrorMessage);
        }
        return models;
    }

    @AuraEnabled
    public static String trainDataset(Decimal datasetId, String modelName, String dataType, String algorithm, Boolean augment) {
        setType(dataType);
        Einstein_Model model;
        if (augment != null) {
            crisisapp.Einstein_TrainParams trainParams = new crisisapp.Einstein_TrainParams();
            trainParams.augmentData = augment;
            model = service.trainDataset(datasetId.longValue(), modelName, 0, 0, trainParams, algorithm);
        } else {
	        model = service.trainDataset(datasetId.longValue(), modelName, 0, 0, null, algorithm);
        }
        if (service.httpStatusCode>200) {
            throw new AuraHandledException(service.httpErrorMessage);
        }
        return model.modelId;
    }

    @AuraEnabled
    public static String retrainDataset(String modelId, String dataType, String algorithm) {
        setType(dataType);
        Einstein_Model model = service.retrainDataset(modelId, 0, 0, null, algorithm);
        if (service.httpStatusCode>200) {
            throw new AuraHandledException(service.httpErrorMessage);
        }
        return model.modelId;
    }

    @AuraEnabled
    public static void deleteDataset(Long datasetId, String dataType) {
	    setType(dataType);
	    service.deleteDataset(datasetId);
	    if (service.httpStatusCode>200) {
		    throw new AuraHandledException(service.httpErrorMessage);
	    }
    }

    @AuraEnabled
    public static void deleteModel(String modelId, String dataType) {
	    setType(dataType);
	    service.deleteModel(modelId);
	    if (service.httpStatusCode>200) {
		    throw new AuraHandledException(service.httpErrorMessage);
	    }
    }

    @AuraEnabled
    public static Einstein_PredictionResult predictImageClassification(String modelId, String base64) {
        setType('');
        service.setType(Einstein_PredictionService.Types.IMAGE);
        Einstein_PredictionResult result = service.predictImageBase64(modelId, base64, 0, '');
        if (service.httpStatusCode>200) {
            throw new AuraHandledException(service.httpErrorMessage);
        }
        return result;
    }

    @AuraEnabled
    public static Einstein_PredictionResult predictImageClassificationURL(String modelId, String url) {
        setType('');
        service.setType(Einstein_PredictionService.Types.IMAGE);
        Einstein_PredictionResult result = service.predictImageUrl(modelId, url, 0, '');
        if (service.httpStatusCode>200) {
            throw new AuraHandledException(service.httpErrorMessage);
        }
        return result;
    }

    @AuraEnabled
    public static Einstein_PredictionResult predictImageDetection(String modelId, String base64) {
        setType('');
        service.setType(Einstein_PredictionService.Types.IMAGE_DETECTION);
        Einstein_PredictionResult result = service.detectImageBase64(modelId, base64, 0, '');
        if (service.httpStatusCode>200) {
            throw new AuraHandledException(service.httpErrorMessage);
        }
        return result;
    }

    @AuraEnabled
    public static Einstein_PredictionResult predictImageDetectionURL(String modelId, String url) {
        setType('');
        service.setType(Einstein_PredictionService.Types.IMAGE_DETECTION);
        Einstein_PredictionResult result = service.detectImageUrl(modelId, url, 0, '');
        if (service.httpStatusCode>200) {
            throw new AuraHandledException(service.httpErrorMessage);
        }
        return result;
    }


    @AuraEnabled
    public static Einstein_PredictionResult predictOcr(String modelId, String base64, String task) {
         try {
        setType('');
        service.setType(Einstein_PredictionService.Types.OCR);
        Einstein_PredictionResult result = service.predictOcrBase64(modelId, base64, task, 0, '');
        if (service.httpStatusCode>200) {
            AuraHandledException ex = new AuraHandledException(service.httpErrorMessage);
            // setMessage is necessary for some reason to have the message propagate properly in the catch block, below.
            ex.setMessage(service.httpErrorMessage);
            throw ex;
        }
        return result;
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Einstein_PredictionResult predictOcrURL(String modelId, String url, String task) {
        try {
            setType('');
            service.setType(Einstein_PredictionService.Types.OCR);
            Einstein_PredictionResult result = service.predictOcrUrl(modelId, url, task, 0, '');
            if (service.httpStatusCode>200) {
		        AuraHandledException ex = new AuraHandledException(service.httpErrorMessage);
		        // setMessage is necessary for some reason to have the message propagate properly in the catch block, below.
		        ex.setMessage(service.httpErrorMessage);
		        throw ex;
            }
            return result;
        } catch(Exception e) {
            System.debug(e);
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Einstein_PredictionResult predictIntent(String modelId, String phrase) {
        setType('');
        service.setType(Einstein_PredictionService.Types.INTENT);
        Einstein_PredictionResult result = service.predictIntent(modelId, phrase, 0, '');
        if (service.httpStatusCode>200) {
            throw new AuraHandledException(service.httpErrorMessage);
        }
        return result;
    }

    @AuraEnabled
    public static Einstein_PredictionResult predictSentiment(String modelId, String phrase) {
        setType('');
        service.setType(Einstein_PredictionService.Types.SENTIMENT);
        Einstein_PredictionResult result = service.predictSentiment(modelId, phrase, 0, '');
        if (service.httpStatusCode>200) {
            throw new AuraHandledException(service.httpErrorMessage);
        }
        return result;
    }

    @AuraEnabled
    public static Einstein_PredictionResult predictNER(String modelId, String phrase) {
        try {
        setType('');
        service.setType(Einstein_PredictionService.Types.NER);
        Einstein_PredictionResult result = service.predictNER(modelId, phrase, 0, '');
        if (service.httpStatusCode>200) {
		    AuraHandledException ex = new AuraHandledException(service.httpErrorMessage);
		    // setMessage is necessary for some reason to have the message propagate properly in the catch block, below.
		    ex.setMessage(service.httpErrorMessage);
		    throw ex;
        }
        return result;
        } catch(Exception e) {
            System.debug(e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    // stuff related to dataset generation
    @AuraEnabled
    public static string getObjectOptions(){
        
        Map<String, Schema.SObjectType> objects = Schema.getGlobalDescribe();
        
        list<map<string, string>> output = new list<map<string, string>>();
        for (string s:objects.keySet()){
            DescribeSObjectResult dsor = objects.get(s).getDescribe();
            if (
                //if you can't update anything, you won't be able to save a prediction anywhere!
                dsor.isUpdateable() &&
                !dsor.isCustomSetting() //no custom settings
            ) {
                map<string, string> tempMap = new map<string, string>();
                if (dsor.getLabel() != dsor.getName()){
                    tempMap.put('label', dsor.getLabel() + ' (' + dsor.getName() + ')');
                } else {
                    tempMap.put('label', dsor.getLabel());
                }
                tempMap.put('name', dsor.getName());
                output.add(tempMap);
            }
            
        }
        
        return JSON.serialize(output);
    }

    /*for a given object, return the fields that are sources of text (string, textarea) or labels (picklist, boolean)*/
	@AuraEnabled
	public static string getObjectFields(string objectName, string sourceOrLabel){
		list<string> temp = new list<string>();
		temp.add(objectName);

		List<Schema.DescribeSObjectResult> describe = Schema.describeSObjects(temp);

		map<string, Schema.SObjectField> fieldmap = describe[0].fields.getMap();

		list<map<string, string>> output = new list<map<string, string>>();

		for (Schema.SObjectField field:fieldmap.values()){
			DescribeFieldResult dfr = field.getDescribe();
			if (
					(sourceOrLabel=='Source'
							&& (dfr.getType().name()=='String' || dfr.getType().name()=='TextArea')
					) ||
					(sourceOrLabel=='Label'
							&& (dfr.getType().name()=='Picklist' || dfr.getType().name()=='Boolean')
					)
			){
				map<string, string> tempMap = new map<string, string>();
				if (dfr.getLabel() != dfr.getName()){
					tempMap.put('label', dfr.getLabel() + ' (' + dfr.getName() + ')' + ' [' + dfr.getType().name() + ']');
				} else {
					tempMap.put('label', dfr.getLabel() + ' [' + dfr.getType().name() + ']');
				}
				tempMap.put('name', dfr.getName());
				tempMap.put('type', dfr.getType().name());
				output.add(tempMap);
			}
		} //end for loop of fieldmap

		
		return JSON.serialize(output);
	}

    @AuraEnabled
	public static ContentVersion saveFileToFiles(string obj, string src, string classify){

        String [] cvinsertFields = new String [] {'VersionData',
            'PathOnClient',
            'Title'};

      	// Obtaining the field name/token map for the Contact object
      	Map<String,Schema.SObjectField> m = Schema.SObjectType.ContentVersion.fields.getMap();
        for (String fieldToCheck : cvinsertFields) {
        // Check if the user has create access on the each field
        if (!m.get(fieldToCheck).getDescribe().isCreateable()) {
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                                    'Insufficient access')); 
          return null;
        }
      }
            
            
		ContentVersion CV = new ContentVersion();
		CV.VersionData = blob.valueof(makeCSV(obj, src, classify));
		CV.PathOnClient = obj +'-' + classify + '.csv';
		CV.Title = obj +'_' + classify + '_by_' + src;
		
        if (!Schema.sObjectType.ContentVersion.fields.VersionData.isCreateable()
           || !Schema.sObjectType.ContentVersion.fields.PathOnClient.isCreateable() || 
              !Schema.sObjectType.ContentVersion.fields.Title.isCreateable()){
            
			throw new System.NoAccessException();
        }
        
        
		insert CV;
        //requery to get contentdocumentID that was created
        //
        if (Schema.sObjectType.ContentVersion.fields.Title.isAccessible() && 
            Schema.sObjectType.ContentVersion.fields.ContentDocumentId.isAccessible() && 
            Schema.sObjectType.ContentVersion.fields.Id.isAccessible()) {
		
			ContentVersion CV2 = [select id, Title, ContentDocumentId from ContentVersion where id=: CV.id];
       		return CV2;
        } else {
            throw new System.NoAccessException();
        }

	}

    @AuraEnabled
    public static ContentDistribution writeCD(id contentDocumentId, string name){

        ContentVersion CV = [select id from ContentVersion where ContentDocumentId =: contentDocumentId and isLatest = true];
		
        String [] cdinsertFields = new String [] {'VersionData',
            'ContentVersionId',
            'Name',
            'PreferencesAllowOriginalDownload',
            'PreferencesLinkLatestVersion',
            'PathOnClient',
            'ExpiryDate',
            'PreferencesExpires',
            'PreferencesNotifyOnVisit',
            'PreferencesNotifyRndtnComplete'};
                
                // Obtaining the field name/token map for the Contact object
                Map<String,Schema.SObjectField> m = Schema.SObjectType.ContentDistribution.fields.getMap();
        
        try{
            for (String fieldToCheck : cdinsertFields) {
                // Check if the user has create access on the each field
                if (!m.get(fieldToCheck).getDescribe().isCreateable()) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                                               'Insufficient access')); 
                    throw new System.NoAccessException();
                }
            }
        }
        catch(System.NullPointerException e)
        {
            System.debug('--Null Pointer Exception--'); 
        }
        
        ContentDistribution CD = new ContentDistribution();
		CD.ContentVersionId = CV.Id;
		CD.Name = CD_TEMP_PREFIX + name;
		CD.PreferencesAllowOriginalDownload = true;
		CD.PreferencesLinkLatestVersion = true;
		CD.ExpiryDate = system.now().addMinutes(EXPIRY);
		CD.PreferencesExpires = true;
		CD.PreferencesNotifyOnVisit = false;
		CD.PreferencesNotifyRndtnComplete = false;
		
        if (!Schema.sObjectType.ContentDistribution.fields.ContentVersionId.isCreateable()
            && !Schema.sObjectType.ContentDistribution.fields.Name.isCreateable() && 
            !Schema.sObjectType.ContentDistribution.fields.PreferencesAllowOriginalDownload.isCreateable() &&
            !Schema.sObjectType.ContentDistribution.fields.PreferencesLinkLatestVersion.isCreateable() &&
            !Schema.sObjectType.ContentDistribution.fields.PreferencesExpires.isCreateable() &&
            !Schema.sObjectType.ContentDistribution.fields.PreferencesNotifyOnVisit.isCreateable() &&
            !Schema.sObjectType.ContentDistribution.fields.PreferencesNotifyRndtnComplete.isCreateable() ){
               
			throw new System.NoAccessException();
        }
        
        
        insert CD;
        if (Schema.sObjectType.ContentDistribution.fields.ContentDownloadUrl.isAccessible() && 
            Schema.sObjectType.ContentDistribution.fields.Id.isAccessible()) {
            
            ContentDistribution CD2 = [select id, ContentDownloadUrl from ContentDistribution where Id =: cd.Id];
            return CD2;
        }
		
		return null;
    }

    //for long text areas with newlines, get rid of them so they don't confuse the file or the learning
    public static string csvLineClean(string input){
        string output = input;
        output = output.replaceAll('\\r\\n', ' ');
        output = output.replaceAll('\\n', ' ');
        output = output.replaceAll('\"', '\'');
        return output;
    }

	public static string makeCSV (string obj, string src, string classify){
        SObjectType sObjType = Schema.getGlobalDescribe().get(obj);
		String query = '';
        list<sobject> data;
        
        if (sObjType.getDescribe().isAccessible()) {
        	query = 'select ' + String.escapeSingleQuotes(src)+ ', ' + String.escapeSingleQuotes(classify)+ ' from ' + String.escapeSingleQuotes(obj)+ ' where ' + String.escapeSingleQuotes(classify)+ '!= null limit 50000';
        	data = database.query(query);
        } else {
            throw new System.NoAccessException();
        }
 
        //null check
        if (data.isEmpty()){
            throw new AuraHandledException('There is no valid data for that object and those fields');
        }
		list<string> lines = new list<string>();

		for (sobject so:data){
			
			if ((string)so.get(src)!=null){ //filter for null src field here, since we can't avoid them in SOQL where
				string thisLine = '"' + csvLineClean((string)so.get(src)) + '",' + '"' + csvLineClean((string)so.get(classify)) + '"';
				lines.add(thisLine);
			}
		}

		string csv = string.join(lines, '\n');

		
		return csv;
	}

    @future
    // expires publicly shared files that have already been accessed.  @future to avoid impacting users with DML stuff
    public static void handleCDV (list<ID> CDIDs){
        list<ContentDistribution> CDs = [select name, ExpiryDate from ContentDistribution where id in: CDIDs];
        
        
        String [] cdUpdateFields = new String [] {'name',
            'ExpiryDate'};
                
      	Map<String,Schema.SObjectField> m = Schema.SObjectType.ContentDistribution.fields.getMap();
        
        for (String fieldToCheck : cdUpdateFields) {
            // Check if the user has create access on the each field
            if (!m.get(fieldToCheck).getDescribe().isAccessible()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                                           'Insufficient access')); 
                throw new System.NoAccessException();
            }
        }
        
        for (ContentDistribution CD:CDs){
            if (CD.Name.startsWith(CD_TEMP_PREFIX)){
                CD.ExpiryDate = system.now();
            }
        }
        
        if (!Schema.sObjectType.ContentDistribution.fields.ExpiryDate.isUpdateable() && 
            !Schema.sObjectType.ContentDistribution.fields.name.isUpdateable()){
                system.debug('-- Object Not accessible --- ');
            }
        
        update CDs;
    }
    
    @AuraEnabled
    public static Einstein_Settings__c getSettings() {
        crisisapp__Einstein_Settings__c settings = crisisapp__Einstein_Settings__c.getOrgDefaults();

		
        String [] esAccessSettings = new String [] {'id','crisisapp__CertName__c', 'crisisapp__Einstein_EMail__c', 'crisisapp__Secret_Key__c'};
            
            // Obtaining the field name/token map for the Settings object
            Map<String,Schema.SObjectField> m = Schema.SObjectType.crisisapp__Einstein_Settings__c.fields.getMap();
        
        for (String fieldToCheck : esAccessSettings) {
            // Check if the user has create access on the each field
            if (!m.get(fieldToCheck).getDescribe().isAccessible()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                                           'Insufficient access')); 
                throw new System.NoAccessException();
            }
        }
        
        
        return settings;
    } 
    
    
    @AuraEnabled
    public static Boolean getFeatureCodeEnabled() {
        crisisapp__Einstein_Settings__c settings = crisisapp__Einstein_Settings__c.getOrgDefaults();
                
        return (settings.crisisapp__FeatureCode__c == 'EinsteinRocks');
    } 
    
    
   @AuraEnabled
    public static Map<String, String> validateSetup() {
        Map<String, String> setupInfo = new  Map<String, String>();
        String status = 'Working';
        String message = null;
        
		// double check settings are complete
		 crisisapp__Einstein_Settings__c settings = crisisapp__Einstein_Settings__c.getOrgDefaults();
        
        if(settings.crisisapp__Einstein_EMail__c ==  null) {
            setupInfo.put('status', 'Configuration Incomplete');
            setupInfo.put('message', 'Please enter the Einstein Platform Account email address');
            return setupInfo;
        }
        
        if(settings.crisisapp__CertName__c  ==  null) {
            setupInfo.put('status', 'Configuration Incomplete');
            setupInfo.put('message', 'Please ensure the authentication settings have been completed.');
            return setupInfo;
        }

        
        // make an outbound call
        try {
            setType('image'); //default
            List<Einstein_ApiUsage> usage = service.getApiUsage();
            System.debug('--- status code --- ' + service.httpStatusCode);
            if (service.httpStatusCode > 200) {
                status = 'Connection Error';
           		message = service.httpErrorMessage;
            }
            else
            {
                 status = 'Working';
                 message = 'Test out a prediction '; 
                 System.debug(' --- status --- ' + status);
            }
       
        } catch(Exception e) {
            status = 'Connection Error';
            message = e.getMessage();
             
        }
        
        setupInfo.put('status', status);
        setupInfo.put('message', message);
        return setupInfo;
    }
    
  
    @AuraEnabled
    public static void saveSettings(crisisapp__Einstein_Settings__c settings){ 
                
        String [] esinsertFields = new String [] {'id','crisisapp__CertName__c',
            'crisisapp__Secret_Key__c',
            'crisisapp__Einstein_EMail__c'};
                    
            // Obtaining the field name/token map for the Settings object
            Map<String,Schema.SObjectField> m = Schema.SObjectType.crisisapp__Einstein_Settings__c.fields.getMap();
        
        /*for (String fieldToCheck : esinsertFields) {
            // Check if the user has create access on the each field
            if (!m.get(fieldToCheck).getDescribe().isUpdateable() && !m.get(fieldToCheck).getDescribe().isCreateable()) {
                
                if(ApexPages.currentPage() != null){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                                               'Insufficient access')); 
                    throw new System.NoAccessException();
                }
                
            }
        }*/
        
        
        String [] esAccessSettings = new String [] {'id','crisisapp__CertName__c', 'crisisapp__Einstein_EMail__c', 'crisisapp__Secret_Key__c'};
        Map<String,Schema.SObjectField> xm = Schema.SObjectType.crisisapp__Einstein_Settings__c.fields.getMap();
        for (String fieldToCheck : esAccessSettings) {
            // Check if the user has create access on the each field
            if (!xm.get(fieldToCheck).getDescribe().isAccessible()) {
                throw new System.NoAccessException();
            }
        }
        
        

        if(settings.id == null) {
            crisisapp__Einstein_Settings__c existingSettings = crisisapp__Einstein_Settings__c.getOrgDefaults();
            settings.id = existingSettings.id;
        }
        
        if(settings.id == null)  {
            if (Schema.SObjectType.crisisapp__Einstein_Settings__c.isCreateable()) {
            	insert settings;
            } else {
                throw new System.NoAccessException();
            }
        } else {
            if (Schema.SObjectType.crisisapp__Einstein_Settings__c.isUpdateable()) {
            	update settings;
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'ERROR: Insufficient access'));
            }
        }  
    }
    
    @AuraEnabled 
    public static void deleteSettings()
    {
        
        crisisapp__Einstein_Settings__c settings = crisisapp__Einstein_Settings__c.getOrgDefaults();
        
        system.debug('--- es from delete ---- ' + settings);
        
        if (crisisapp__Einstein_Settings__c.sObjectType.getDescribe().isDeletable()){
            
            delete settings; 
            
            system.debug('### settings deleted ### ');
        }
        
        
        else
        {
            system.debug('Insuffient Privileges');
        }
    }
    
    

    
     @AuraEnabled
    public static String updatePemFile(String documentId){       
        System.debug ('updatePermFile documentId: ' + documentId);

        // Get the content of the PEM file document
        // 
        if (!Schema.sObjectType.ContentVersion.fields.Id.isAccessible() && 
            !Schema.sObjectType.ContentVersion.fields.VersionData.isAccessible() &&
            !Schema.sObjectType.ContentVersion.fields.Title.isAccessible() && 
            !Schema.sObjectType.ContentVersion.fields.FileExtension.isAccessible())
        {
            throw new System.NoAccessException();
            
        }
        
        ContentVersion v = [SELECT Id, VersionData, Title, FileExtension FROM contentversion WHERE ContentDocumentId  =:documentId]; 
        String cvId = v.id ;
        String fileName = v.Title; 
        System.debug('ContentVersion: ' + cvId);

        try{
            Blob cryptoKey = Crypto.generateAesKey(128);
            Blob data = v.VersionData ; 
            Blob encryptedData = Crypto.encryptWithManagedIV('AES128', cryptoKey, data);
            
            Blob decryptedData = Crypto.decryptWithManagedIV('AES128', cryptoKey, encryptedData);
            String decryptedDataString = decryptedData.toString();
            String ds = EncodingUtil.base64Encode(decryptedData); 
                        
            String [] settingsInsertFields = new String [] {'crisisapp__CertName__c',
                'crisisapp__Secret_Key__c',
                'crisisapp__Einstein_EMail__c'};
                    
            Map<String,Schema.SObjectField> m = Schema.SObjectType.crisisapp__Einstein_Settings__c.fields.getMap();
            
            for (String fieldToCheck : settingsInsertFields) {
                // Check if the user has create access on the each field
                if (!m.get(fieldToCheck).getDescribe().isUpdateable() && !m.get(fieldToCheck).getDescribe().isCreateable()) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                                               'Insufficient access')); 
                    throw new System.NoAccessException();
                }
            }
            
            
            String [] CVInsert = new String [] {
                'ContentDocumentId'};
                        
            Map<String,Schema.SObjectField> m_cv = Schema.SObjectType.ContentDocumentLink.fields.getMap();
            
            for (String fieldToCheck : CVInsert) {
                // Check if the user has create access on the each field
                if (!m_cv.get(fieldToCheck).getDescribe().IsCreateable() && !m_cv.get(fieldToCheck).getDescribe().IsUpdateable()) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                                               'Insufficient access')); 
                    throw new System.NoAccessException();
                }
            }
            
            
            // Create a new content version which, in turn, creates the new ContentDocument
            ContentVersion v2 = new ContentVersion (
            	Title = v.Title,
                ContentLocation = 'S',
            	ReasonForChange = 'Encrypted PEM file',
            	VersionData = encryptedData,
                pathOnClient = v.Title + '.' + v.FileExtension,
                IsMajorVersion = true );
            
            if (!Schema.sObjectType.ContentVersion.fields.Title.isCreateable() && 
                !Schema.sObjectType.ContentVersion.fields.Title.isCreateable() &&
                !Schema.sObjectType.ContentVersion.fields.ContentLocation.isCreateable() &&
                !Schema.sObjectType.ContentVersion.fields.VersionData.isCreateable() &&
                !Schema.sObjectType.ContentVersion.fields.pathOnClient.isCreateable() &&
                !Schema.sObjectType.ContentVersion.fields.IsMajorVersion.isCreateable()
               ){
                   
				throw new System.NoAccessException();
               }
    
            insert v2;
            
            if (!Schema.sObjectType.ContentVersion.fields.Id.isAccessible() && !Schema.sObjectType.ContentVersion.fields.ContentDocumentId.isAccessible())
            {
                throw new System.NoAccessException();
                
            }
            
             
            Id cdId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :v2.Id].ContentDocumentId;
            System.debug('New CV: ' + v2.Id + ' New ContentDocument: ' + cdId);

            // Delete the unencrypted version
            
            if (Schema.sObjectType.ContentDocument.fields.Id.isAccessible())
            {
                ContentDocument origCd = [SELECT Id FROM ContentDocument WHERE Id = :documentId];
                if (!ContentDocument.sObjectType.getDescribe().isDeletable()){
                    throw new System.NoAccessException();
                }
                
                delete origCd;
                
            }
            
      
            // Get the current settings or create a new record if none exist
            crisisapp__Einstein_Settings__c es = null;
            try {
                if (Schema.sObjectType.crisisapp__Einstein_Settings__c.fields.crisisapp__CertName__c.isAccessible() && 
                    Schema.sObjectType.crisisapp__Einstein_Settings__c.fields.crisisapp__Einstein_EMail__c.isAccessible() && 
                    Schema.sObjectType.crisisapp__Einstein_Settings__c.fields.crisisapp__Secret_Key__c.isAccessible() && 
                    Schema.sObjectType.crisisapp__Einstein_Settings__c.fields.Id.isAccessible())
                {
                    es = [SELECT id, crisisapp__CertName__c, crisisapp__Einstein_EMail__c, crisisapp__Secret_Key__c FROM crisisapp__Einstein_Settings__c LIMIT 1]; 
                    system.debug(' ---- es ----' + es); 
                }
            } catch(Exception e) {
                es = new crisisapp__Einstein_Settings__c();
            }
            
            if (!Schema.sObjectType.crisisapp__Einstein_Settings__c.fields.crisisapp__CertName__c.isCreateable()
                && !Schema.sObjectType.crisisapp__Einstein_Settings__c.fields.crisisapp__Einstein_EMail__c.isCreateable() && 
                !Schema.sObjectType.crisisapp__Einstein_Settings__c.fields.crisisapp__Secret_Key__c.isCreateable() &&
                !Schema.sObjectType.crisisapp__Einstein_Settings__c.fields.id.isCreateable() &&
                !Schema.sObjectType.crisisapp__Einstein_Settings__c.fields.crisisapp__CertName__c.isUpdateable()
                && !Schema.sObjectType.crisisapp__Einstein_Settings__c.fields.crisisapp__Einstein_EMail__c.isUpdateable() && 
                !Schema.sObjectType.crisisapp__Einstein_Settings__c.fields.crisisapp__Secret_Key__c.isUpdateable() &&
                !Schema.sObjectType.crisisapp__Einstein_Settings__c.fields.id.isUpdateable()
               ){
                   
				throw new System.NoAccessException();
               }
            
            // Add the cryptoKey and new documentId to the settings            
            try{
                
                es.crisisapp__Secret_Key__c = EncodingUtil.base64Encode(cryptoKey);
                es.crisisapp__CertName__c = cdId;
                upsert es;
                
                system.debug('--- upsert done --- ' + es);
            } catch(DMLException e) {
                system.debug('-- update exception --- ' + e);
                throw new AuraHandledException(e.getMessage());
            }

            // Return the new document Id to the Lighting client
            return cdId;
                
        }
        
        catch(Exception e)
        {
            System.debug('-- exception --- ' + e); 
            throw new AuraHandledException(e.getMessage());
        }
       
          
        
    }
    


}