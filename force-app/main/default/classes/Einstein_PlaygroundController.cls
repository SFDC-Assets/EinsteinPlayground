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
		} else if (language=='zh_CN') {
			service.setLanguage(Einstein_PredictionService.Languages.CHINESE_SIMPLIFIED);
		} else if (language=='zh_TW') {
			service.setLanguage(Einstein_PredictionService.Languages.CHINESE_TRADITIONAL);
		} else if (language=='ja') {
			service.setLanguage(Einstein_PredictionService.Languages.JAPANESE);
		}
	}

	@AuraEnabled(cacheable=true)
	public static id getMyUserId(){
		return UserInfo.getUserId();
	}

	@AuraEnabled(cacheable=true)
	public static String getPackageVersion() {
		try {
			// Determine if we are in a managed package
			UserInfo.isCurrentUserLicensed('einsteinplay');
			System.Version ver = System.requestVersion();
			return ver.major().format() + '.' + ver.minor().format();
		}
		catch (Exception e) {
			return 'unmanaged';
		}
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

		} catch(Exception e) {
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
			Einstein_TrainParams trainParams = new Einstein_TrainParams();
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
	public static Einstein_PredictionResult predictOcr(String modelId, String base64, String task, String formType) {
		try {
			setType('ocr');
			Einstein_PredictionResult result = service.predictOcrBase64(modelId, base64, task, formType, 0, '');
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
	public static Einstein_PredictionResult predictOcrURL(String modelId, String url, String task, String formType) {
		try {
			setType('ocr');
			Einstein_PredictionResult result = service.predictOcrUrl(modelId, url, task, formType, 0, '');
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
			setType('text-ner');
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

		list<map<string, string> > output = new list<map<string, string> >();
		for (string s:objects.keySet()) {
			DescribeSObjectResult dsor = objects.get(s).getDescribe();
			if (
				//if you can't update anything, you won't be able to save a prediction anywhere!
				dsor.isUpdateable() &&
				!dsor.isCustomSetting() //no custom settings
				) {
				map<string, string> tempMap = new map<string, string>();
				if (dsor.getLabel() != dsor.getName()) {
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

		for (Schema.SObjectField field:fieldmap.values()) {
			DescribeFieldResult dfr = field.getDescribe();
			if (
				(sourceOrLabel=='Source'
				 && (dfr.getType().name()=='String' || dfr.getType().name()=='TextArea')
				) ||
				(sourceOrLabel=='Label'
				 && (dfr.getType().name()=='Picklist' || dfr.getType().name()=='Boolean')
				)
				) {
				map<string, string> tempMap = new map<string, string>();
				if (dfr.getLabel() != dfr.getName()) {
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

		String [] cvinsertFields = new String [] {
			'VersionData',
			'PathOnClient',
			'Title'
		};
		checkAccess(
			'ContentVersion',
			Einstein_PlaygroundController.accessLevels.CREATE_ACCESS,
			cvinsertFields
			);

		ContentVersion CV = new ContentVersion();
		CV.VersionData = blob.valueof(makeCSV(obj, src, classify));
		CV.PathOnClient = obj +'-' + classify + '.csv';
		CV.Title = obj +'_' + classify + '_by_' + src;

		insert CV;
		//requery to get contentdocumentID that was created
		ContentVersion CV2 = [select id, Title, ContentDocumentId from ContentVersion where id=: CV.id];
		return CV2;

	}

	@AuraEnabled
	public static ContentDistribution writeCD(id contentDocumentId, string name){

		String [] cvReadFields = new String [] {
			'Id'
		};

		checkAccess(
			'ContentVersion',
			Einstein_PlaygroundController.accessLevels.READ_ACCESS,
			cvReadFields
			);

		ContentVersion CV = [select id from ContentVersion where ContentDocumentId =: contentDocumentId and isLatest = true];

		ContentDistribution CD = new ContentDistribution();
		CD.ContentVersionId = CV.Id;
		CD.Name = CD_TEMP_PREFIX + name;
		CD.PreferencesAllowOriginalDownload = true;
		CD.PreferencesLinkLatestVersion = true;
		CD.ExpiryDate = system.now().addMinutes(EXPIRY);
		CD.PreferencesExpires = true;
		CD.PreferencesNotifyOnVisit = false;
		CD.PreferencesNotifyRndtnComplete = false;

		String[] contentDistributionInsertFields = new String[] {
			'ContentVersionId',
			'Name',
			'PreferencesAllowOriginalDownload',
			'PreferencesLinkLatestVersion',
			'PreferencesExpires',
			'PreferencesNotifyOnVisit',
			'PreferencesNotifyRndtnComplete'
		};
		checkAccess(
			'ContentDistribution',
			Einstein_PlaygroundController.accessLevels.CREATE_ACCESS,
			contentDistributionInsertFields
			);

		insert CD;
		ContentDistribution CD2 = [select id, ContentDownloadUrl from ContentDistribution where Id =: cd.Id];
		return CD2;
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
		String query = '';
		list<sobject> data;

		checkAccess(
			obj,
			Einstein_PlaygroundController.accessLevels.READ_ACCESS,
			null
			);

		query = 'select ' + String.escapeSingleQuotes(src)+ ', ' + String.escapeSingleQuotes(classify)+ ' from ' + String.escapeSingleQuotes(obj)+ ' where ' + String.escapeSingleQuotes(classify)+ '!= null limit 50000';
		data = database.query(query);

		//null check
		if (data.isEmpty()) {
			throw new AuraHandledException('There is no valid data for that object and those fields');
		}
		list<string> lines = new list<string>();

		for (sobject so:data) {

			if ((string)so.get(src)!=null) { //filter for null src field here, since we can't avoid them in SOQL where
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


		String [] cdUpdateFields = new String [] {
			'name',
			'ExpiryDate'
		};
		checkAccess(
			'ContentDistribution',
			Einstein_PlaygroundController.accessLevels.READ_ACCESS,
			cdUpdateFields
			);

		for (ContentDistribution CD:CDs) {
			if (CD.Name.startsWith(CD_TEMP_PREFIX)) {
				CD.ExpiryDate = system.now();
			}
		}

		checkAccess(
			'ContentDistribution',
			Einstein_PlaygroundController.accessLevels.UPDATE_ACCESS,
			cdUpdateFields
			);

		update CDs;
	}

	@AuraEnabled
	public static Einstein_Settings__c getSettings() {
		einsteinplay__Einstein_Settings__c settings = einsteinplay__Einstein_Settings__c.getOrgDefaults();


		String [] esAccessSettings = new String [] {
			'id',
			'einsteinplay__CertName__c',
			'einsteinplay__Secret_Key__c',
			'einsteinplay__Einstein_EMail__c',
			'einsteinplay__certificate_part_1__c',
			'einsteinplay__certificate_part_2__c',
			'einsteinplay__certificate_part_3__c',
			'einsteinplay__certificate_part_4__c',
			'einsteinplay__certificate_part_5__c',
			'einsteinplay__certificate_part_6__c',
			'einsteinplay__certificate_part_7__c',
			'einsteinplay__certificate_part_8__c',
			'einsteinplay__certificate_part_9__c'
		};

		// Verify the necessary fields of the custom setting are readable
		checkAccess(
			'einsteinplay__Einstein_Settings__c',
			Einstein_PlaygroundController.AccessLevels.READ_ACCESS,
			esAccessSettings
			);

		return settings;
	}


	@AuraEnabled(cacheable=true)
	public static Boolean getFeatureCodeEnabled() {
		// Verify the necessary fields of the custom setting are readable
		checkAccess(
			'einsteinplay__Einstein_Settings__c',
			Einstein_PlaygroundController.AccessLevels.READ_ACCESS,
			new String[] {'einsteinplay__FeatureCode__c'}
			);

		einsteinplay__Einstein_Settings__c settings = einsteinplay__Einstein_Settings__c.getOrgDefaults();
		return (settings.einsteinplay__FeatureCode__c == 'EinsteinRocks');
	}


	@AuraEnabled
	public static Map<String, String> validateSetup() {
		Map<String, String> setupInfo = new  Map<String, String>();
		String status = 'Working';
		String message = null;

		// Does this user have read access to the custom settings?
		String [] esAccessSettings = new String [] {
			'id',
			'einsteinplay__CertName__c',
			'einsteinplay__Secret_Key__c',
			'einsteinplay__Einstein_EMail__c',
			'einsteinplay__certificate_part_1__c',
			'einsteinplay__certificate_part_2__c',
			'einsteinplay__certificate_part_3__c',
			'einsteinplay__certificate_part_4__c',
			'einsteinplay__certificate_part_5__c',
			'einsteinplay__certificate_part_6__c',
			'einsteinplay__certificate_part_7__c',
			'einsteinplay__certificate_part_8__c',
			'einsteinplay__certificate_part_9__c'
		};

		// Verify the necessary fields of the custom setting are readable
		try {
			checkAccess(
				'einsteinplay__Einstein_Settings__c',
				Einstein_PlaygroundController.AccessLevels.READ_ACCESS,
				esAccessSettings
				);
		} catch (Exception e) {
			setupInfo.put('status', 'Configuration Incomplete');
			setupInfo.put('message', 'Have your Admin assign the Einstein Playground permission set to you.');
			return setupInfo;
		}

		einsteinplay__Einstein_Settings__c settings = einsteinplay__Einstein_Settings__c.getOrgDefaults();

		// Is there an Einstein Platform Account email address?
		if (settings.einsteinplay__Einstein_EMail__c ==  null) {
			setupInfo.put('status', 'Configuration Incomplete');
			setupInfo.put('message', 'Please enter the Einstein Platform Account email address');
			return setupInfo;
		}

		// If there are values in the certificate custom settings,
		if ((settings.einsteinplay__certificate_part_1__c !=  null) &&
		    (settings.einsteinplay__certificate_part_1__c != '')) {
			// Attempt to make a call out.
			try {
				setType('image'); //default
				List<Einstein_ApiUsage> usage = service.getApiUsage();
				System.debug('--- status code --- ' + service.httpStatusCode);
				if (service.httpStatusCode > 200) {
					status = 'Connection Error';
					message = service.httpErrorMessage;
				} else {
					status = 'Working';
					message = 'Test out a prediction';
					System.debug(' --- status --- ' + status);
				}
			} catch(Exception e) {
				status = 'Connection Error';
				message = e.getMessage();
			}

			setupInfo.put('status', status);
			setupInfo.put('message', message);
			return setupInfo;

		} else {

			// If no certificate values, see if there is a CertName and PEM file
			if ((settings.einsteinplay__CertName__c  !=  null) &&
			    (settings.einsteinplay__CertName__c  !=  '')) {
				// If so, convert the PEM file to certificate custom settings

				// Confirm there is access to the fields in the ContentVersion (pem file)
				checkAccess (
					'ContentVersion',
					Einstein_PlaygroundController.AccessLevels.READ_ACCESS,
					new String[] {
					'VersionData',
					'Title'
				}
					);

				// Try to retrieve private key from ContentVersion
				ContentVersion encryptedKeyCV;
				try {
					encryptedKeyCV = [SELECT Title, VersionData FROM ContentVersion where ContentDocumentId =: settings.einsteinplay__CertName__c AND IsLatest=true LIMIT 1];
				} catch (QueryException e) {
					throw new Einstein_ConfigurationException('Could not retrieve the Einstein Platform certificate file as defined in setup. Please ensure your user has access to the file.', e);
				}

				storeEncryptedKey(encryptedKeyCV.VersionData, settings);

				// Delete the encrypted contentDocument
				checkAccess ('ContentDocument', Einstein_PlaygroundController.AccessLevels.DELETE_ACCESS, null);
				checkAccess ('ContentDocument', Einstein_PlaygroundController.AccessLevels.READ_ACCESS, new String[] {'id'});
				ContentDocument origCd = [SELECT Id FROM ContentDocument WHERE Id = :settings.einsteinplay__CertName__c];
				delete origCd;

				// Update the settings
				try {
					settings.einsteinplay__CertName__c = '';
					upsert settings;
				} catch(DMLException e) {
					throw new AuraHandledException(e.getMessage());
				}

				setupInfo.put('status', 'Working');
				setupInfo.put('message', 'Private Key storage updated');
				return setupInfo;

			} else {
				// If neither CertName nor Certificate fields have data, you need to configure it.
				setupInfo.put('status', 'Configuration Incomplete');
				setupInfo.put('message', 'Please ensure the authentication settings have been completed.');
				return setupInfo;
			}
		}
	}


	@AuraEnabled
	public static void saveSettings(einsteinplay__Einstein_Settings__c settings){

		// Verify the necessary fields of the custom setting are writeable
		String [] esAccessSettings = new String [] {
			'einsteinplay__CertName__c',
			'einsteinplay__Secret_Key__c',
			'einsteinplay__Einstein_EMail__c',
			'einsteinplay__certificate_part_1__c',
			'einsteinplay__certificate_part_2__c',
			'einsteinplay__certificate_part_3__c',
			'einsteinplay__certificate_part_4__c',
			'einsteinplay__certificate_part_5__c',
			'einsteinplay__certificate_part_6__c',
			'einsteinplay__certificate_part_7__c',
			'einsteinplay__certificate_part_8__c',
			'einsteinplay__certificate_part_9__c'
		};
		// Verify the necessary fields of the custom setting are readable
		checkAccess(
			'einsteinplay__Einstein_Settings__c',
			Einstein_PlaygroundController.AccessLevels.READ_ACCESS,
			esAccessSettings
			);

		if(settings.id == null) {
			einsteinplay__Einstein_Settings__c existingSettings = einsteinplay__Einstein_Settings__c.getOrgDefaults();
			settings.id = existingSettings.id;
		}

		if(settings.id == null)  {
			// Verify the necessary fields of the custom setting are readable
			checkAccess(
				'einsteinplay__Einstein_Settings__c',
				Einstein_PlaygroundController.AccessLevels.CREATE_ACCESS,
				esAccessSettings
				);
			insert settings;

		} else {
			// Verify the necessary fields of the custom setting are readable
			checkAccess(
				'einsteinplay__Einstein_Settings__c',
				Einstein_PlaygroundController.AccessLevels.UPDATE_ACCESS,
				esAccessSettings
				);
			update settings;
		}
	}

	@AuraEnabled
	public static void deleteSettings() {

		// Verify the necessary the custom setting is deletable
		checkAccess(
			'einsteinplay__Einstein_Settings__c',
			Einstein_PlaygroundController.AccessLevels.DELETE_ACCESS,
			null
			);

		einsteinplay__Einstein_Settings__c settings = einsteinplay__Einstein_Settings__c.getOrgDefaults();
		system.debug('--- es from delete ---- ' + settings);

		delete settings;
		system.debug('### settings deleted ### ');
	}

	@AuraEnabled
	public static String updatePemFile(String documentId){
		System.debug ('updatePermFile documentId: ' + documentId);

		// Confirm there is access to the fields in the ContentVersion (pem file)
		checkAccess (
			'ContentVersion',
			Einstein_PlaygroundController.AccessLevels.READ_ACCESS,
			new String[] {
			'Id',
			'VersionData',
			'Title',
			'FileExtension'
		}
			);

		// Get the content of the new, unencrypted PEM file document
		ContentVersion v = [SELECT Id, VersionData, Title, FileExtension FROM contentversion WHERE ContentDocumentId  =:documentId];
		String cvId = v.id;
		System.debug('ContentVersion: ' + cvId);

		try{
			String [] settingsInsertFields = new String [] {
				'einsteinplay__CertName__c',
				'einsteinplay__Secret_Key__c',
				'einsteinplay__Einstein_EMail__c',
				'einsteinplay__certificate_part_1__c',
				'einsteinplay__certificate_part_2__c',
				'einsteinplay__certificate_part_3__c',
				'einsteinplay__certificate_part_4__c',
				'einsteinplay__certificate_part_5__c',
				'einsteinplay__certificate_part_6__c',
				'einsteinplay__certificate_part_7__c',
				'einsteinplay__certificate_part_8__c',
				'einsteinplay__certificate_part_9__c'
			};

			// Verify the necessary fields of the custom setting are writeable
			checkAccess(
				'einsteinplay__Einstein_Settings__c',
				Einstein_PlaygroundController.AccessLevels.CREATE_ACCESS,
				settingsInsertFields);

			// Create the query string
			einsteinplay__Einstein_Settings__c es = null;
			String queryString = 'SELECT Id';
			for (String queryField : settingsInsertFields) {
				queryString += ', ' + queryField;
			}
			queryString += ' FROM einsteinplay__Einstein_Settings__c LIMIT 1';

			// Get the current settings or create a new record if none exist
			try {
				es = Database.query(queryString);
				system.debug(' ---- es ----' + es);
			} catch(Exception e) {
				es = new einsteinplay__Einstein_Settings__c();
			}

			// Generage a new crypto key used to encrypt the private key.
			Blob cryptoKey = Crypto.generateAesKey(128);
			// Store the crypto key in a custom setting field
			es.einsteinplay__Secret_Key__c = EncodingUtil.base64Encode(cryptoKey);

			// Encrypt the private key and encode it as a string for storage
			Blob data = v.VersionData;
			System.debug('data: ' + data.toString());
			Blob encryptedData = Crypto.encryptWithManagedIV('AES128', cryptoKey, data);

			storeEncryptedKey(encryptedData, es);

			// Delete the unencrypted contentDocument
			checkAccess ('ContentDocument', Einstein_PlaygroundController.AccessLevels.DELETE_ACCESS, null);
			checkAccess ('ContentDocument', Einstein_PlaygroundController.AccessLevels.READ_ACCESS, new String[] {'id'});
			ContentDocument origCd = [SELECT Id FROM ContentDocument WHERE Id = :documentId];
			delete origCd;


			// Update the settings (note: does not include the email address field)
			try {
				upsert es;
				system.debug('--- upsert done --- ' + es);
			} catch(DMLException e) {
				system.debug('-- update exception --- ' + e);
				throw new AuraHandledException(e.getMessage());
			}

			return '';
		}

		catch(Exception e) {
			System.debug('-- exception --- ' + e);
			throw new AuraHandledException(e.getMessage());
		}
	}

	private enum AccessLevels {
		READ_ACCESS,
		UPDATE_ACCESS,
		CREATE_ACCESS,
		DELETE_ACCESS
	}

	private static void checkAccess (String objectName, AccessLevels accessLevel, String[] fieldsToCheck) {
		// Get the object description
		SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
		// Get a map of the object's fields, in case they need to be checked
		Map<String,Schema.SObjectField> m = sObjType.getDescribe().fields.getMap();

		// Check the object first
		switch on accessLevel {
			when READ_ACCESS {
				if (!sObjType.getDescribe().isAccessible()) {
					throw new System.NoAccessException();
				}
				if (fieldsToCheck != null) {
					for (String fieldToCheck : fieldsToCheck) {
						if (!m.get(fieldToCheck).getDescribe().isAccessible()) {
							throw new System.NoAccessException();
						}
					}
				}
			}
			when UPDATE_ACCESS {
				if (!sObjType.getDescribe().isUpdateable() ||
				    !sObjType.getDescribe().isAccessible()) {
					throw new System.NoAccessException();
				}
				if (fieldsToCheck != null) {
					for (String fieldToCheck : fieldsToCheck) {
						if (!m.get(fieldToCheck).getDescribe().isAccessible() ||
						    !m.get(fieldToCheck).getDescribe().isUpdateable()) {
							throw new System.NoAccessException();
						}
					}
				}
			}
			when CREATE_ACCESS {
				if (!sObjType.getDescribe().isCreateable() &&
				    !sObjType.getDescribe().isAccessible()) {
					throw new System.NoAccessException();
				}
				if (fieldsToCheck != null) {
					for (String fieldToCheck : fieldsToCheck) {
						if (!m.get(fieldToCheck).getDescribe().isCreateable() ||
						    !m.get(fieldToCheck).getDescribe().isAccessible()) {
							throw new System.NoAccessException();
						}
					}
				}
			}
			when DELETE_ACCESS {
				if (!sObjType.getDescribe().isDeletable()) {
					throw new System.NoAccessException();
				}
			}
			when else {
				throw new System.NoAccessException();
			}
		}
	}

	private static void storeEncryptedKey (Blob encryptedData, einsteinplay__Einstein_Settings__c settings) {
		String encryptedDataBase64 = EncodingUtil.Base64Encode(encryptedData);
		System.debug('encryptedDataBase64: ' + encryptedDataBase64);

		// Store the encrypted data in a series of custom setting fields, 255 characters at a time.
		Integer stringIndex = 0;
		Integer stringSliceEndIndex = 0;
		Integer fieldIndex = 1;
		while (stringIndex < encryptedDataBase64.length()) {
			if (fieldIndex == 10) {
				throw new System.LimitException('Not enough fields');
			}
			stringSliceEndIndex = stringIndex + 255;
			if (stringSliceEndIndex > encryptedDataBase64.length()) {
				stringSliceEndIndex = encryptedDataBase64.length();
			}
			settings.put(
				'einsteinplay__certificate_part_' + fieldIndex + '__c',
				encryptedDataBase64.substring(stringIndex, stringSliceEndIndex));
			stringIndex += 255;
			fieldIndex += 1;
		}
	}

}