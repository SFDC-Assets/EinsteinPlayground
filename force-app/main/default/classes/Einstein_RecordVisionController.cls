public with sharing class Einstein_RecordVisionController {
@AuraEnabled
public static Einstein_PredictionResult  analyseImage(String base64Data, String modelName) {
	System.debug('base64Data :: ' + base64Data.length() + ' :: modelName :: ' + modelName );
	Einstein_PredictionService service = new Einstein_PredictionService(Einstein_PredictionService.Types.IMAGE);
	Einstein_PredictionResult result = service.predictImageBase64( modelName, base64Data, 4, null);
	if (service.httpStatusCode>200) {
		throw new AuraHandledException(service.httpErrorMessage);
	}
	System.debug(result);
	return result;
}
@AuraEnabled
public static Id  createRecord(ID recordId, String objectName, String fieldName, String intentLabel) {
	System.debug(recordId + ' ' + objectName + ' ' + fieldName + ' ' + intentLabel);
	sObject sObj = Schema.getGlobalDescribe().get(objectName).newSObject();
	sObj.put(fieldName, intentLabel);
	Schema.SObjectType token = recordId.getSObjectType();
	Schema.DescribeSObjectResult dr = token.getDescribe();
	String lookupObjectType =  dr.getName();
	System.debug('Object name ' + objectName  + ' ' + lookupObjectType);
	String lookupName = null;
    
    List<FieldDefinition> fieldList;
    if (Schema.sObjectType.FieldDefinition.fields.Label.isAccessible() 
		&& Schema.sObjectType.FieldDefinition.fields.QualifiedApiName.isAccessible() 
		&& Schema.sObjectType.FieldDefinition.fields.DataType.isAccessible()) {
			fieldList = [Select Label, QualifiedApiName, DataType, FieldDefinition.Publisher.isSalesforce From FieldDefinition where EntityDefinition.QualifiedApiName =: objectName ];
    } else {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'ERROR: Insufficient access'));
    	fieldList = null;
    }
            List<String> fieldNames = new List<String>();
	for(FieldDefinition item: fieldList) {
		String name = item.QualifiedApiName;
		Boolean isSalesforce =  item.Publisher.IsSalesforce;
		if((item.DataType.contains('Lookup') ||  item.DataType.contains('Master-Detail') ) && item.QualifiedApiName.contains(lookupObjectType)) {
			lookupName = name;
			System.debug('Lookup field ' + lookupName );
			sObj.put(lookupName, recordId);
			// break;
		}
	}
    
    sObjectType sObjType = Schema.getGlobalDescribe().get(objectName);   
    if (sObjType.getDescribe().isCreateable()) {
		insert sObj;
    } else {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'ERROR: Insufficient access'));
    }
    
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
}
@AuraEnabled
public static Einstein_PredictionResult detectObjects(String modelId, String base64){
	Einstein_PredictionService service = new Einstein_PredictionService(Einstein_PredictionService.Types.IMAGE_DETECTION);
	Einstein_PredictionResult result = service.detectImageBase64(modelId, base64, 0, '');
	if (service.httpStatusCode>200) {
		throw new AuraHandledException(service.httpErrorMessage);
	}
	return result;
}
@AuraEnabled
public static void storeScanResults(sObject dataJson, Id recordId, String objectName) {
	System.debug('------ Storing Results ----------');
	System.debug('Record - ' + recordId);
	//  System.debug(dataJson);
	Schema.SObjectType token = recordId.getSObjectType();
	Schema.DescribeSObjectResult dr = token.getDescribe();
	String lookupObjectType =  dr.getName();
	String lookupName = null;
    
    // Get all field definitions for the child object
    List<FieldDefinition> fieldList;  
    if (Schema.sObjectType.FieldDefinition.fields.Label.isAccessible() 
		&& Schema.sObjectType.FieldDefinition.fields.QualifiedApiName.isAccessible() 
		&& Schema.sObjectType.FieldDefinition.fields.DataType.isAccessible()) {  
		fieldList = [Select Label, QualifiedApiName, DataType, FieldDefinition.Publisher.isSalesforce From FieldDefinition where EntityDefinition.QualifiedApiName =: objectName ];
    } else {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'ERROR: Insufficient access'));
   		fieldList = null;
    }   
            
    // Find fields that are Lookup or Master-Detail relationships to the parent object
	List<String> fieldNames = new List<String>();
	for(FieldDefinition item: fieldList) {
		String name = item.QualifiedApiName;
		if((item.DataType.contains('Lookup') ||  item.DataType.contains('Master-Detail') ) && item.QualifiedApiName.contains(lookupObjectType)) {
			lookupName = name;
			break;
		}
	}
	System.debug('Lookup - ' + lookupName + ' ' + lookupObjectType);
	dataJson.put(lookupName, recordId);
	insert dataJson;
}
@AuraEnabled
public static string createContentUrl(String contentDocumentId) {
	System.debug('createContentUrl ' + contentDocumentId);
	string CD_TEMP_PREFIX = 'EinsteinTemp';
	integer EXPIRY = 5;
    ContentDistribution CD = new ContentDistribution();
    ContentVersion CV;
    
    if (!Schema.sObjectType.ContentVersion.fields.Id.isAccessible() 
        || !Schema.sObjectType.ContentVersion.fields.title.isAccessible()) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'ERROR: Insufficient access'));
		return null;
	} else {
		CV = [select id, Title from ContentVersion where ContentDocumentId =: contentDocumentId and isLatest = true];
    }
    
	CD.ContentVersionId = CV.Id;
	CD.Name = CD_TEMP_PREFIX + '_' + CV.Title;
	CD.PreferencesAllowOriginalDownload = true;
	CD.PreferencesLinkLatestVersion = true;
	CD.ExpiryDate = system.now().addMinutes(EXPIRY);
	CD.PreferencesExpires = true;
	CD.PreferencesNotifyOnVisit = false;
	CD.PreferencesNotifyRndtnComplete = false;
    
    if (Schema.sObjectType.ContentDistribution.isCreateable()) {
		insert CD;
    } else {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'ERROR: Insufficient access'));
        return null;
    }

    ContentDistribution CD2;
	if (Schema.sObjectType.ContentDistribution.fields.Id.isAccessible()
		&& Schema.sObjectType.ContentDistribution.fields.ContentDownloadUrl.isAccessible()) {    
		CD2 = [select id, ContentDownloadUrl from ContentDistribution where Id =: cd.Id];
    } else {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'ERROR: Insufficient access'));
        return null;
    }
    
	return CD2.ContentDownloadUrl;
}
@AuraEnabled
public static Einstein_PredictionResult  analyseImageUrl(String url, String modelName) {
	Einstein_PredictionService service = new Einstein_PredictionService(Einstein_PredictionService.Types.IMAGE_DETECTION);
	Einstein_PredictionResult result =  service.detectImageUrl(modelName, url, 3, null);
	//(String modelId, String url, Integer numResults, String sampleId)
	if (service.httpStatusCode>200) {
		throw new AuraHandledException(service.httpErrorMessage);
	}
	//ID attachementId = CreateAttachmentCtrl.receiveData(recId, fileName, base64Data, contentType);
	//  System.debug(result);
	return result;
}
}