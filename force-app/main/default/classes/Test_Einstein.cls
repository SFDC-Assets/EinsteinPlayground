@isTest
public with sharing class Test_Einstein {

	static testMethod void getAccessToken_failsWithoutEmailSetting() {
		// Test.startTest();
		// try {
		//     Einstein_PredictionService.getAccessToken();
		//     System.assert(false, 'Expected Einstein_ConfigurationException');
		// }
		// catch (Exception e) {
		//     System.assert(e instanceof Einstein_ConfigurationException);
		//     System.AssertEquals(e.getMessage().contains('email setting'), true);
		// }
		// Test.stopTest();
	}

	static testMethod void playgroundValidation(){

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		map<string, string> result = new map<string, string>();
		// Einstein_Settings__c settings = Einstein_Settings__c.getOrgDefaults();

		createSettings(null, null, null);

		Test.startTest();
		result = Einstein_PlaygroundController.validateSetup();
		system.assertEquals('Configuration Incomplete', result.get('status'));
		system.assertEquals('Please enter the Einstein Platform Account email address', result.get('message'));
		Test.stopTest();

	}
	static testMethod void playgroundValidation2(){

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		map<string, string> result = new map<string, string>();
		// Einstein_Settings__c settings = Einstein_Settings__c.getOrgDefaults();

		createSettings('test@gmail.com', null, null);

		Test.startTest();
		result = Einstein_PlaygroundController.validateSetup();
		system.assertEquals('Configuration Incomplete', result.get('status'));
		system.assertEquals('Please ensure the authentication settings have been completed.', result.get('message'));
		Test.stopTest();

	}
	static testMethod void playgroundValidation3(){

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		map<string, string> result = new map<string, string>();
		// Einstein_Settings__c settings = Einstein_Settings__c.getOrgDefaults();

		createSettings('test@gmail.com', null, 'fake cert');

		Test.startTest();
		result = Einstein_PlaygroundController.validateSetup();
		system.assertEquals('Working', result.get('status'));
		system.assertEquals('Test out a prediction', result.get('message'));
		Test.stopTest();

	}

// static testMethod void getAccessToken_failsWithoutCertificate() {
//     Einstein_Settings__c settings = Einstein_Settings__c.getOrgDefaults();
//     settings.Einstein_EMail__c = 'test@mail.com';
//     upsert settings;

//     Test.startTest();
//     try {
//         Einstein_PredictionService.getAccessToken();
//         System.assert(false, 'Expected Einstein_ConfigurationException');
//     }
//     catch (Exception e) {
//         System.assert(e instanceof Einstein_ConfigurationException);
//         System.AssertEquals(e.getMessage().contains('certificate file'), true);
//     }
//     Test.stopTest();
// }

	static testMethod void getAccessToken_works() {
		createSettings('test@gmail.com', null, null);

		ContentVersion certificate = new ContentVersion(Title = 'einstein_platform', PathOnClient='.', VersionData=Blob.valueOf('someData'));
		insert certificate;

		Test.startTest();
		String token = Einstein_PredictionService.getAccessToken();
		System.assertEquals(token, '');
		Test.stopTest();
	}

	static testMethod void createDataset() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.IMAGE);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		Einstein_Dataset dataset = service.createDatasetFromUrlAsync('https://myurl');
		System.assertEquals('Beach and Mountain', dataset.name);
		System.assertEquals(DateTime.newInstanceGmT(2016,9,15,16,51,41), dataset.updatedAt);

		dataset = service.createDatasetFromUrlSync('https://myurl');
		System.assertEquals('Beach and Mountain', dataset.name);
		System.assertEquals(DateTime.newInstanceGmT(2016,9,15,16,51,41), dataset.updatedAt);
		System.assertEquals(611, dataset.labelSummary.labels[0].id);
		System.assertEquals(57, dataset.labelSummary.labels[0].datasetId);
		System.assertEquals('beach', dataset.labelSummary.labels[0].name);
		System.assertEquals(0, dataset.labelSummary.labels[0].numExamples);
		System.assertEquals(2, dataset.totalLabels);
		System.assertEquals(true, dataset.available);
		System.assertEquals('SUCCEEDED', dataset.statusMsg);
		Test.stopTest();

	}


	static testMethod void getDataset() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.IMAGE);

		Test.startTest();

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		Einstein_Dataset dataset = service.getDataset(57);

		// Test 1: Valid Dataset returned
		System.assertEquals('Beach and Mountain', dataset.name);
		System.assertEquals(DateTime.newInstanceGmT(2016,9,15,16,51,41), dataset.updatedAt);
		System.assertEquals(99, dataset.totalExamples);
		Test.stopTest();
	}

	static testMethod void getDatasets() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.IMAGE);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		List<Einstein_Dataset> datasets = service.getDatasets();

		System.assertEquals(2, datasets.size());

		for (Einstein_Dataset dataset : datasets) {
			if (dataset.id == 57) {
				System.assertEquals('Beach and Mountain', dataset.name);
			}
		}

		datasets = service.getGlobalDatasets();
		System.assertEquals(1, datasets.size());

		datasets = service.getDatasets(1,1,Einstein_Dataset.Types.FEEDBACK);
		datasets = service.getDatasets(1,1,Einstein_Dataset.Types.UPLOAD);
		Test.stopTest();

	}

	static testMethod void deleteDataset() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.IMAGE);

		Test.startTest();

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		Boolean success = service.deleteDataset(108);

		System.assertEquals(true, success);

		Test.stopTest();

	}


	static testMethod void deleteModel() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.IMAGE);

		Test.startTest();

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		Boolean success = service.deleteModel('123');

		System.assertEquals(true, success);

		Test.stopTest();

	}


	static testMethod void createExample() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.IMAGE);

		Test.startTest();

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		Einstein_Example example = service.createExample(57, '77880132.jpg', 614, Blob.valueOf('data'));

		System.assertEquals(43887, example.id);
		System.assertEquals('77880132.jpg', example.name);
		System.assertEquals('https://jBke4mtMuOjrCK3A04Q79O5TBySI2BC3zqi7...', example.location);
		System.assertEquals(DateTime.newInstanceGmt(2016,9,15,23,18,13), example.createdAt);
		System.assertNotEquals(null, example.label);

		Test.stopTest();

	}

	static testMethod void createExamplesFromUrl() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.IMAGE);

		Test.startTest();

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		Einstein_Dataset dataset = service.createExamplesFromUrl(1000022, 'http://my.image.com/test.png');

		System.assertEquals('mountainvsbeach', dataset.name);
		System.assertEquals(DateTime.newInstanceGmt(2017,2,17,0,22,10), dataset.createdAt);
		System.assertEquals(DateTime.newInstanceGmt(2017,2,17,0,22,12), dataset.updatedAt);

		try {
			dataset = service.createExamplesFromUrl(1000022, '');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_StringIsEmptyException);
		}

		Test.stopTest();


	}

	static testMethod void getExamples() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.IMAGE);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		List<Einstein_Example> examples = service.getExamples(57);

		System.assertEquals(4, examples.size());

		service.getExamples(1,1,1,Einstein_Example.Types.FEEDBACK);
		service.getExamples(1,1,1,Einstein_Example.Types.UPLOAD);
		Test.stopTest();

	}

	static testMethod void trainDataset() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.IMAGE);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		Einstein_Model model = service.trainDataset(57, 'Beach and Mountain Model', 0, 0, null);

		System.assertEquals(DateTime.newInstanceGmt(2016,9,16,18,3,21), model.createdAt);
		System.assertEquals(DateTime.newInstanceGmt(2016,9,16,18,3,21), model.updatedAt);
		System.assertEquals(57, model.datasetId);
		System.assertEquals(0, model.datasetVersionId);
		System.assertEquals('Beach and Mountain Model', model.name);
		System.assertEquals('QUEUED', model.status);
		System.assertEquals(0, model.progress);
		System.assertEquals(0.001, model.learningRate);
		System.assertEquals(3, model.epochs);
		System.assertEquals(1, model.queuePosition);
		System.assertEquals('7JXCXTRXTMNLJCEF2DR5CJ46QU', model.modelId);
		System.assertEquals(null, model.trainParams);
		System.assertEquals('image', model.modelType);
		System.assertEquals(null, model.failureMsg);

		System.assertEquals('00:00:01:008', model.trainStats.datasetLoadTime);
		System.assertEquals(true, model.trainStats.earlyStopping);
		System.assertEquals(150, model.trainStats.examples);
		System.assertEquals(5, model.trainStats.labels);
		System.assertEquals(267, model.trainStats.lastEpochDone);
		System.assertEquals('00:00:01:561', model.trainStats.modelSaveTime);
		System.assertEquals(11, model.trainStats.testSplitSize);
		System.assertEquals('00:03:54:159', model.trainStats.totalTime);
		System.assertEquals('00:03:53:150', model.trainStats.trainingTime);
		System.assertEquals(139, model.trainStats.trainSplitSize);

		try {
			model = service.trainDataset(0, 'Beach and Mountain Model', 0, 0, null);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.debug('Error is: ' + e.getTypeName());
			System.assert (e instanceof Einstein_NoValuesException);
		}

		try {
			model = service.trainDataset(57, '', 0, 0, null);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_StringIsEmptyException);
		}

		try {
			String nameTooLong = 'AbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefg';
			model = service.trainDataset(57, nameTooLong, 0, 0, null);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_StringTooLongException);
		}

		try {
			model = service.trainDataset(57, 'Beach and Mountain Model', 101, 0, null);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_NumberTooBigException);
		}

		try {
			model = service.trainDataset(57, 'Beach and Mountain Model', 101, 0, null);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_NumberTooBigException);
		}

		try {
			model = service.trainDataset(57, 'Beach and Mountain Model', 0, 0.00001, null);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_NumberTooSmallException);
		}

		try {
			model = service.trainDataset(57, 'Beach and Mountain Model', 0, 0.1, null);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_NumberTooBigException);
		}

		service.setType(Einstein_PredictionService.Types.INTENT);
		service.setLanguage(Einstein_PredictionService.Languages.ENGLISH_US);
		service.trainDataset(57, 'Intent', 0, 0.01, null, 'multilingual-intent');
		Test.stopTest();
	}

	static testMethod void getModel() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.IMAGE);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		Einstein_Model model = service.getModel('7JXCXTRXTMNLJCEF2DR5CJ46QU');

		// TODO System.assertEquals(DateTime.newInstance(), model.createdAt);
		// TODO System.assertEquals(DateTime.newInstance(), model.updatedAt);
		System.assertEquals(57, model.datasetId);
		System.assertEquals(0, model.datasetVersionId);
		System.assertEquals('Beach and Mountain Model', model.name);
		System.assertEquals('SUCCEEDED', model.status);
		System.assertEquals(1, model.progress);
		System.assertEquals(0.001, model.learningRate);
		System.assertEquals(3, model.epochs);
		System.assertEquals('7JXCXTRXTMNLJCEF2DR5CJ46QU', model.modelId);
		System.assertEquals(null, model.trainStats);
		System.assertEquals('image', model.modelType);

		Einstein_Dataset dataset = new Einstein_Dataset();
		dataset.id = 57;

		model = service.getModel('7JXCXTRXTMNLJCEF2DR5CJ46QU');
		System.assertEquals('Beach and Mountain Model', model.name);
		Test.stopTest();
	}

	static testMethod void getModelLearningCurve() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.IMAGE);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		String learningCurves = service.getModelLearningCurve('7JXCXTRXTMNLJCEF2DR5CJ46QU');

		System.assertNotEquals(null, learningCurves);


		Test.stopTest();
	}

	static testMethod void getModelLearningCurveIntent() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.INTENT);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		String learningCurves2 = service.getModelLearningCurve('7JXCXTRXTMNLJCEF2DR5CJ46QU');

		System.assertNotEquals(null, learningCurves2);


		Test.stopTest();
	}

	static testMethod void getModelMetrics() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.IMAGE);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		String metrics = service.getModelMetrics('7JXCXTRXTMNLJCEF2DR5CJ46QU');

		System.assertNotEquals(null, metrics);
		Test.stopTest();

	}

	static testMethod void getModels() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.IMAGE);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		List<Einstein_Model> models = service.getModels(57);

		System.assertEquals(2, models.size());
		Einstein_Model model = models.get(0);
		System.assertEquals('To train a dataset and create a model, the dataset must contain at least 100 examples per label for test set', model.failureMsg);
		Test.stopTest();
	}

	static testMethod void predictImages() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.IMAGE);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		Einstein_PredictionResult result = service.predictImageBase64('YCQ4ZACEPJFGXZNRA6ERF3GL5E', 'aaabbbccc', 0, '');

		System.assertEquals(2, result.probabilities.size());
		System.assertEquals('beach', result.probabilities.get(0).label);
		System.assertEquals(0.039788953959941864, result.probabilities.get(1).probability);

		result = service.predictImageUrl('YCQ4ZACEPJFGXZNRA6ERF3GL5E', 'https://theurl', 0, '');
		result = service.predictImageBlob('modelId', Blob.valueof('somedata'), 0, 'sampleId');

		result = service.detectImageBase64('YCQ4ZACEPJFGXZNRA6ERF3GL5E', 'aaabbbccc', 0, '');

		System.assertEquals(100, result.probabilities[0].boundingBox.maxX);
		System.assertEquals(100, result.probabilities[0].boundingBox.maxY);
		System.assertEquals(100, result.probabilities[0].boundingBox.minX);
		System.assertEquals(100, result.probabilities[0].boundingBox.minX);

		result = service.detectImageBlob('YCQ4ZACEPJFGXZNRA6ERF3GL5E', Blob.valueof('somedata'), 0, '');
		result = service.detectImageUrl('YCQ4ZACEPJFGXZNRA6ERF3GL5E', 'aaabbbccc', 0, '');

		result = service.predictOcrBase64('YCQ4ZACEPJFGXZNRA6ERF3GL5E', 'aaabbbccc', 'text', 'sampleId');
		result = service.predictOcrBase64('YCQ4ZACEPJFGXZNRA6ERF3GL5E', 'aaabbbccc', 'text', 'sampleId');
		result = service.predictOcrBase64('YCQ4ZACEPJFGXZNRA6ERF3GL5E', 'aaabbbccc', 'text', 'id', 'sampleId');
		result = service.predictOcrBase64('YCQ4ZACEPJFGXZNRA6ERF3GL5E', 'aaabbbccc', 0, 'sampleId');
		result = service.predictOcrBase64('YCQ4ZACEPJFGXZNRA6ERF3GL5E', 'aaabbbccc', 'text', null, 0, '');

		result = service.predictOcrUrl('YCQ4ZACEPJFGXZNRA6ERF3GL5E', 'aaabbbccc', 'sampleId');
		result = service.predictOcrUrl('YCQ4ZACEPJFGXZNRA6ERF3GL5E', 'aaabbbccc', 'text', 'sampleId');
		result = service.predictOcrUrl('YCQ4ZACEPJFGXZNRA6ERF3GL5E', 'aaabbbccc', 'text', 'id', 'sampleId');
		result = service.predictOcrUrl('YCQ4ZACEPJFGXZNRA6ERF3GL5E', 'aaabbbccc', 0, 'sampleId');
		result = service.predictOcrUrl('YCQ4ZACEPJFGXZNRA6ERF3GL5E', 'aaabbbccc', 'text', 0, 'sampleId');

		service.setType(Einstein_PredictionService.Types.OCR);

		Test.stopTest();
	}

	static testMethod void predictLanguage() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.SENTIMENT);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		Einstein_PredictionResult result = service.predictSentiment('modelId', 'text', 0, '');

		System.assertEquals(3, result.probabilities.size());
		System.assertEquals('positive', result.probabilities.get(0).label);

		service.setType(Einstein_PredictionService.Types.INTENT);
		result = service.predictIntent('modelId', 'text', 0, '');

		System.assertEquals(3, result.probabilities.size());
		System.assertEquals('current-weather', result.probabilities.get(0).label);

		result = service.predictNER('modelId', 'text', 0, '');
		service.setType(Einstein_PredictionService.Types.NER);
		Test.stopTest();
	}


	static testMethod void createFeedback() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.INTENT);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		Einstein_Example example = service.createFeedbackLanguageExample('expectedLabel', 'modelId', 'text');
		System.assertEquals(1048038, example.id);
		System.assertEquals('text-intent', example.name);

		Blob theBlob = Blob.valueof('somedata');
		service.setType(Einstein_PredictionService.Types.IMAGE);
		example = service.createFeedbackImageExample('name', 'expectedLabel', 'modelId', theBlob);
		System.assertEquals(618168, example.id);
		System.assertEquals('alps.jpg', example.name);

		Test.stopTest();
	}

	static testMethod void retrainDataset() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.IMAGE);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		// Valid Values
		Einstein_TrainParams trainParams = new Einstein_TrainParams();
		trainParams.withFeedback = true;
		Einstein_Model model = service.retrainDataset('modelId', 3, 0.001, trainParams);
		System.assertEquals(57, model.datasetId);

		// Zero Defaults
		model = service.retrainDataset('modelId', 0, 0, trainParams);
		System.assertEquals(57, model.datasetId);

		// Null Defaults
		Integer epochs = null;
		Decimal learningRate = null;

		model = service.retrainDataset('modelId', epochs, learningRate, trainParams);
		System.assertEquals(57, model.datasetId);

		Einstein_HttpBodyPartRetraining parts = new Einstein_HttpBodyPartRetraining('modelId', epochs, learningRate, trainParams, null);
		System.assertEquals('modelId', parts.getModelId());
		System.assertEquals(null, parts.getEpochs());
		System.assertEquals(null, parts.getLearningRate());

		// Validation
		try {
			model = service.retrainDataset(null, epochs, learningRate, trainParams);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_StringIsEmptyException);
		}

		try {
			model = service.retrainDataset('modelId', 101, learningRate, trainParams);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_NumberTooBigException);
		}

		try {
			model = service.retrainDataset('modelId', epochs, 0.00001, trainParams);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_NumberTooSmallException);
		}

		try {
			model = service.retrainDataset('modelId', epochs, 0.1, trainParams);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_NumberTooBigException);
		}

		service.setType(Einstein_PredictionService.Types.INTENT);
		service.setLanguage(Einstein_PredictionService.Languages.ENGLISH_US);
		model = service.retrainDataset('modelId', epochs, 0, trainParams, 'multilanguage-intent');
		Test.stopTest();
	}

	static testMethod void testContentDistributionTrigger() {
		//create a file

		Case c = new Case();
		c.Description = 'this is a test description';
		c.origin = 'Email';
		c.Reason = 'Test';
		insert c;

		ContentVersion CV = Einstein_PlaygroundController.saveFileToFiles('case', 'Description', 'Reason');
		ContentDistribution CD = Einstein_PlaygroundController.writeCD(CV.ContentDocumentId, 'TestCD');

		ContentDistribution CD2 = [select id, Name, ExpiryDate, ContentDownloadUrl from ContentDistribution where Id =: cd.Id];

		System.assertNotEquals(null, CD2.ContentDownloadUrl, 'The download url did not get created');
		System.assert (CD2.ExpiryDate > System.now(), 'The content distribution should have not be expired yet.');


		User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs(thisUser) {
			//update the CD just to trigger the trigger
			test.startTest();
			CD2.Name = 'EinsteinTemp' + CD2.Name;
			update CD2;
			test.stopTest();
		}

		ContentDistribution CD3 = [select id, ExpiryDate from ContentDistribution where Id =: cd.Id];
		// System.assert(CD3.ExpiryDate < System.now(), 'The content distribution should have expired.');




	}



	static testMethod void apiUsage() {

		Einstein_PredictionService service = new Einstein_PredictionService('123', Einstein_PredictionService.Types.IMAGE);

		Test.startTest();

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		Einstein_ApiUsage[] apiUsages = service.getApiUsage();

		System.assertEquals(1, apiUsages.size());

		Einstein_ApiUsage apiUsage = apiUsages.get(0);

		System.assertEquals('489', apiUsage.id);
		System.assertEquals('108', apiUsage.organizationId);
		System.assertEquals('kJCHtYDCSf', apiUsage.licenseId);
		System.assertEquals(997, apiUsage.predictionsRemaining);
		System.assertEquals(3, apiUsage.predictionsUsed);
		System.assertEquals(1000, apiUsage.predictionsMax);
		System.assertEquals('2017-03-01T00:00:00.000Z', apiUsage.startsAt);
		System.assertEquals('2017-04-01T00:00:00.000Z', apiUsage.endsAt);

		Einstein_PlanData planData = apiUsage.planData.get(0);
		System.assertEquals('FREE', planData.plan);
		System.assertEquals('HEROKU', planData.source);
		System.assertEquals(1, planData.amount);

		Test.stopTest();

	}


	static testMethod void testOtherMethods() {

		System.assertEquals('1ff13444ed8140c7a32fc4e6451aa76d', Einstein_HttpBodyPart.getBoundary());


		Einstein_HttpBodyPartExample bodyPartExampleInit;

		try {
			bodyPartExampleInit = new Einstein_HttpBodyPartExample('', 0, '');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_StringIsEmptyException);
		}

		try {
			bodyPartExampleInit = new Einstein_HttpBodyPartExample('123', 0, '');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_NullPointerException);
		}

		try {
			bodyPartExampleInit = new Einstein_HttpBodyPartExample('123', 1, '');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_StringIsEmptyException);
		}

		Einstein_HttpBodyPartExample bodyPartExample = new Einstein_HttpBodyPartExample('name', 1, 'data');

		try {
			bodyPartExample.setName('');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_StringIsEmptyException);
		}

		try {
			bodyPartExample.setData('');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_StringIsEmptyException);
		}


		Einstein_HttpBodyPartDatasetUrl bodyPartDatasetUrl = new Einstein_HttpBodyPartDatasetUrl('http://my.test1.com', 'image');

		bodyPartDatasetUrl.setUrl('http://my.test2.com');
		System.assertEquals('http://my.test2.com', bodyPartDatasetUrl.getUrl());

		try {
			bodyPartDatasetUrl.setUrl('');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_StringIsEmptyException);
		}

		Einstein_HttpBodyPartPrediction bodyPartPrediction = new Einstein_HttpBodyPartPrediction('modelId1', 'testData1', null, null, 0, '', Einstein_HttpBodyPartPrediction.TYPES.BASE64);

		bodyPartPrediction.setModelId('modelId2');
		System.assertEquals('modelId2', bodyPartPrediction.getModelId());

		bodyPartPrediction.setData('data2');
		System.assertEquals('data2', bodyPartPrediction.getData());

		bodyPartPrediction.setSampleId('sampleId2');
		System.assertEquals('sampleId2', bodyPartPrediction.getSampleId());

		bodyPartPrediction.setType(Einstein_HttpBodyPartPrediction.Types.URL);
		System.assertEquals(Einstein_HttpBodyPartPrediction.Types.URL, bodyPartPrediction.getType());

		Einstein_HttpBodyPartTraining bodyPartTraining = new Einstein_HttpBodyPartTraining(1, 'Test1', 0, 0, null, null);

		bodyPartTraining.setDatasetId(2);
		System.assertEquals(2, bodyPartTraining.getDatasetId());

		try {
			bodyPartTraining.setDatasetId(0);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_NoValuesException);
		}

		bodyPartTraining.setName('Test2');
		System.assertEquals('Test2', bodyPartTraining.getName());

		try {
			bodyPartTraining.setName('');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_StringIsEmptyException);
		}

		try {
			String nameTooLong = 'AbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefgAbcdefg';
			bodyPartTraining.setName(nameTooLong);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_StringTooLongException);
		}

		bodyPartTraining.setEpochs(5);
		System.assertEquals(5, bodyPartTraining.getEpochs());

		try {
			bodyPartTraining.setEpochs(101);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_NumberTooBigException);
		}

		bodyPartTraining.setLearningRate(0.001);
		System.assertEquals(0.001, bodyPartTraining.getLearningRate());

		try {
			bodyPartTraining.setLearningRate(0.1);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_NumberTooBigException);
		}

		try {
			bodyPartTraining.setLearningRate(0.00001);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_NumberTooSmallException);
		}

		Einstein_HttpBodyPartFeedbackExample bodyPartFeedbackExample;

		try {
			bodyPartFeedbackExample = new Einstein_HttpBodyPartFeedbackExample('', '', '', '', Einstein_HttpBodyPartFeedbackExample.Types.BASE64);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_StringIsEmptyException);
		}

		try {
			bodyPartFeedbackExample = new Einstein_HttpBodyPartFeedbackExample('asdf', '', '', '', Einstein_HttpBodyPartFeedbackExample.Types.BASE64);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_StringIsEmptyException);
		}

		try {
			bodyPartFeedbackExample = new Einstein_HttpBodyPartFeedbackExample('asdf', 'asdf', '', '', Einstein_HttpBodyPartFeedbackExample.Types.BASE64);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_StringIsEmptyException);
		}

		try {
			bodyPartFeedbackExample = new Einstein_HttpBodyPartFeedbackExample('asdf', 'sadf', 'sadf', '', Einstein_HttpBodyPartFeedbackExample.Types.BASE64);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof Einstein_StringIsEmptyException);
		}

	}

	static testMethod void testJWT() {

		Einstein_JWT jwt = new Einstein_JWT('a');
		jwt.iss = 'b';
		jwt.aud = 'c';
		jwt.exp = 'd';
		jwt.iat = 'e';
		jwt.validFor = 1;
		jwt.cert = 'f';
		jwt.pkcs8 = 'g';
		jwt.privateKey = 'h';
		jwt.sub = 'j';

		String issued = jwt.issue();

		System.assertEquals('a', jwt.alg);
		System.assertEquals('b', jwt.iss);
		System.assertEquals('c', jwt.aud);
		System.assertEquals('d', jwt.exp);
		System.assertEquals('e', jwt.iat);
		System.assertEquals('f', jwt.cert);
		System.assertEquals('g', jwt.pkcs8);
		System.assertEquals('h', jwt.privateKey);
		System.assertEquals(1, jwt.validFor);


	}

	static testmethod void testPGgetModelMetrics(){
		createSettings('test@gmail.com', null, null);

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		test.startTest();
		Einstein_PlaygroundController.getModelMetrics('7JXCXTRXTMNLJCEF2DR5CJ46QU', 'image');
		test.stopTest();
		//already covered in the _service testing--this is just a wrapper
	}

	static testmethod void testPGObjectOptions(){
		string objectJSON = Einstein_PlaygroundController.getObjectOptions();
		system.assert (objectJSON.contains('Case'), 'Case should have been included, but wasn\'t');

	}

	static testmethod void testPGObjectFields(){
		string fieldsJSON = Einstein_PlaygroundController.getObjectFields('Case', 'Source');
		system.assert (fieldsJSON.contains('Description'), 'Case Description should have been included, but wasn\'t');

		fieldsJSON = Einstein_PlaygroundController.getObjectFields('Case', 'Label');
		system.assert (fieldsJSON.contains('Reason'), 'Case Reason should have been included, but wasn\'t');

	}

	static testmethod void testPGOtherMethods(){
		createSettings('test@gmail.com', null, null);

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		test.startTest();
		Einstein_PlaygroundController.getDatasets('image');
		Einstein_PlaygroundController.getDatasets('image-multi-label');
		Einstein_PlaygroundController.getDatasets('image-detection');
		Einstein_PlaygroundController.createDatasetFromUrl('https://www.google.com', 'image', null);
		Einstein_PlaygroundController.createDatasetFromUrl('https://www.google.com', 'text-intent',  'en_US');
		Einstein_PlaygroundController.createDatasetFromUrl('https://www.google.com', 'text-intent',  'en_GB');
		Einstein_PlaygroundController.createDatasetFromUrl('https://www.google.com', 'text-intent',  'fr');
		Einstein_PlaygroundController.createDatasetFromUrl('https://www.google.com', 'text-intent',  'de');
		Einstein_PlaygroundController.createDatasetFromUrl('https://www.google.com', 'text-intent',  'it');
		Einstein_PlaygroundController.createDatasetFromUrl('https://www.google.com', 'text-intent',  'pt_PT');
		Einstein_PlaygroundController.createDatasetFromUrl('https://www.google.com', 'text-intent',  'es');
		Einstein_PlaygroundController.createDatasetFromUrl('https://www.google.com', 'text-intent',  'zh_CN');
		Einstein_PlaygroundController.createDatasetFromUrl('https://www.google.com', 'text-intent',  'zh_TW');
		Einstein_PlaygroundController.createDatasetFromUrl('https://www.google.com', 'text-intent',  'ja');
		Einstein_PlaygroundController.getUsage();
		Einstein_PlaygroundController.getModels(57, 'image');
		Einstein_PlaygroundController.trainDataset(57, 'myModel', 'image', null, true);
		Einstein_PlaygroundController.retrainDataset('57', 'text-sentiment', null);

		//prediction methods
		Einstein_PlaygroundController.predictImageClassification('123', 'aaabbbccc');
		Einstein_PlaygroundController.predictImageClassificationURL('123', 'https://www.google.com');

		Einstein_PlaygroundController.predictImageDetection('123', 'aaabbbccc');
		Einstein_PlaygroundController.predictImageDetectionURL('123', 'https://www.google.com');

		Einstein_PlaygroundController.predictOcr('123', 'aaabbbccc', 'text', null);
		Einstein_PlaygroundController.predictOcrURL('123', 'https://www.google.com', 'text', null);

		Einstein_PlaygroundController.predictIntent('123', 'hello, world');
		Einstein_PlaygroundController.predictSentiment('123', 'hello, world');
		Einstein_PlaygroundController.predictNER('123', 'hello, world');



		Id myId = Einstein_PlaygroundController.getMyUserId();



		test.stopTest();
	}

	static testmethod void testPGOtherMethodsWithBadHTTP(){
		createSettings('test@gmail.com', null, null);

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponsesBadHTTP());

		test.startTest();
		try {
			Einstein_PlaygroundController.getDatasets('image');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof AuraHandledException);
		}
		try {
			Einstein_PlaygroundController.getDatasets('image-multi-label');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof AuraHandledException);
		}
		try {
			Einstein_PlaygroundController.getDatasets('image-detection');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof AuraHandledException);
		}
		try {
			Einstein_PlaygroundController.createDatasetFromUrl('https://www.google.com', 'image', null);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof AuraHandledException);
		}
		try {
			Einstein_PlaygroundController.getUsage();
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof AuraHandledException);
		}
		try {
			Einstein_PlaygroundController.getModels(57, 'image');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof AuraHandledException);
		}
		try {
			Einstein_PlaygroundController.trainDataset(57, 'myModel', 'image', null, true);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof AuraHandledException);
		}
		try {
			Einstein_PlaygroundController.retrainDataset('57', 'text-sentiment', null);
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof AuraHandledException);
		}



		//prediction methods
		try {
			Einstein_PlaygroundController.predictImageClassification('123', 'aaabbbccc');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof AuraHandledException);
		}
		try {
			Einstein_PlaygroundController.predictImageClassificationURL('123', 'https://www.google.com');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof AuraHandledException);
		}
		try {
			Einstein_PlaygroundController.predictImageDetection('123', 'aaabbbccc');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof AuraHandledException);
		}
		try {
			Einstein_PlaygroundController.predictImageDetectionURL('123', 'https://www.google.com');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof AuraHandledException);
		}
		try {
			Einstein_PlaygroundController.predictIntent('123', 'hello, world');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof AuraHandledException);
		}
		try {
			Einstein_PlaygroundController.predictSentiment('123', 'hello, world');
			System.assert (false, 'Exception Expected');
		} catch (Exception e) {
			System.assert (e instanceof AuraHandledException);
		}

		test.stopTest();
	}

// testing invocable methods

	static TestMethod void testInvocableImageClassification (){
		Case c1 = new Case();
		c1.Description = 'this is for image classification';
		c1.origin = 'Email';
		c1.Reason = 'Test';
		insert c1;

		createSettings('test@gmail.com', null, null);

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		list<Einstein_Invocable_Image_Classification.ClassificationRequest> CRs = new list<Einstein_Invocable_Image_Classification.ClassificationRequest>();

		Einstein_Invocable_Image_Classification.ClassificationRequest CR = new Einstein_Invocable_Image_Classification.ClassificationRequest();
		CR.recordId = c1.Id;
		CR.FieldToAnalyze = 'SuppliedName';
		CR.LabelStoreField = 'Reason';
		CR.ProbabilityStoreField = 'SuppliedCompany';
		CR.RawStoreField = 'Description';
		CR.ModelId = 'GeneralImageClassifier';

		CRs.add(CR);

		test.startTest();

		Einstein_Invocable_Image_Classification.AnalyzeImageClassification(CRs);

		test.stopTest();

		List<Case> c = [select id, Reason, Description, SuppliedName, SuppliedCompany, Comments from Case where Id = :c1.id];
		System.assertEquals(1,c.size());
		System.assertEquals('beach', c[0].Reason);
		System.assertEquals('0.96021104', c[0].SuppliedCompany);
		JSONParser parser = JSON.createParser(c[0].Description);
		Einstein_PredictionResult prediction = (Einstein_PredictionResult)parser.readValueAs(Einstein_PredictionResult.class);
		System.assertEquals('beach', prediction.probabilities[0].label);
		System.assertEquals(0.96021104, prediction.probabilities[0].probability);
	}


	static testmethod void testPBLanguage(){
		Case c1 = new Case();
		c1.Description = 'this is for standardSentiment';
		c1.origin = 'Email';
		c1.Reason = 'Test';
		insert c1;

		Case c2 = new Case();
		c2.Description = 'this is for customIntent';
		c2.origin = 'Email';
		c2.Reason = 'Test';
		insert c2;

		Case c3 = new Case();
		c3.Description = 'this is for customSentiment';
		c3.origin = 'Email';
		c3.Reason = 'Test';
		insert c3;

		createSettings('test@gmail.com', null, null);

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		list<Einstein_Invocable_Language.LanguageRequest> LRs = new list<Einstein_Invocable_Language.LanguageRequest>();

		Einstein_Invocable_Language.LanguageRequest LR = new Einstein_Invocable_Language.LanguageRequest();
		LR.recordId = c1.Id;
		LR.FieldToAnalyze = 'Description';
		LR.LabelStoreField = 'Reason';

		LRs.add(LR);

		Einstein_Invocable_Language.LanguageRequest LR2 = new Einstein_Invocable_Language.LanguageRequest();

		LR2.recordId = c3.Id;
		LR2.FieldToAnalyze = 'Description';
		LR2.LabelStoreField = 'Reason';
		LR2.ModelId = '1234';
		LR2.ModelType = 'Sentiment';

		list<Einstein_Invocable_Language.LanguageRequest> LRs2 = new list<Einstein_Invocable_Language.LanguageRequest>();

		LRs2.add(LR2);


		Einstein_Invocable_Language.LanguageRequest LR3 = new Einstein_Invocable_Language.LanguageRequest();

		LR3.recordId = c2.Id;
		LR3.FieldToAnalyze = 'Description';
		LR3.LabelStoreField = 'Reason';
		LR3.ModelId = '1234';
		LR3.ModelType = 'Intent';
		LR3.ProbabilityStoreField = 'Subject';
		LR3.RawStoreField = 'Description';
		list<Einstein_Invocable_Language.LanguageRequest> LRs3 = new list<Einstein_Invocable_Language.LanguageRequest>();

		LRs3.add(LR3);



		test.startTest();
		//your code here
		Einstein_Invocable_Language.AnalyzeLanguage(LRs);
		Einstein_Invocable_Language.AnalyzeLanguage(LRs2);
		Einstein_Invocable_Language.AnalyzeLanguage(LRs3);

		test.stopTest();

		for (case c: [select id, Reason, Description from Case] ) {
			if (c.Id == c1.Id) {
				//standard sentiment model
				system.assertEquals('positive', c.Reason);
			} else if (c.Id == c3.Id) {
				//custom sentiment
				system.assertEquals('positive', c.Reason);
			} else if (c.Id == c2.Id) {
				//custom intent model with probabilities,etc
				system.assertEquals('current-weather', c.Reason);
				system.assertEquals('{"probabilities":[{"probability":0.9904295,"label":"current-weather"},{"probability":0.009345241,"label":"five-day-forecast"},{"probability":2.2528473E-4,"label":"hourly-forecast"}]}', c.Description);
			}
		}

	}


	static testmethod void testPBLanguageFeedback(){
		createSettings('test@gmail.com', null, null);

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		Einstein_Invocable_Language_Feedback.LanguageFeedback LF = new Einstein_Invocable_Language_Feedback.LanguageFeedback();
		LF.ModelId = '1234';
		LF.Label = 'Complaint';
		LF.Text = 'I think this must be the longest apex test class I know';

		list<Einstein_Invocable_Language_Feedback.LanguageFeedback> LFs = new list<Einstein_Invocable_Language_Feedback.LanguageFeedback>();
		LFs.add(LF);
		test.startTest();
		//your code here
		Einstein_Invocable_Language_Feedback.AnalyzeLanguage(LFs);
		test.stopTest();
	}

/*static testmethod void testRecordLanguageController(){
        Account a1 = new Account();
        a1.Name = 'ACME';
        insert a1;

                createSettings('test@gmail.com', null);

        Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

        test.startTest();
        System.assertEquals('Account',Einstein_RecordLanguageController.getRecordName(a1.id));
        System.assertEquals('ACME',Einstein_RecordLanguageController.getLanguagePhrase(a1.id, 'Name'));

        List<Einstein_Probability> probs = Einstein_RecordLanguageController.getRecordAnalysis(a1.id, 'CommunitySentiment', 'Name');
        System.assertEquals('positive', probs[0].label);
        System.assertEquals(0.77945083, probs[0].probability);

        probs = Einstein_RecordLanguageController.getRecordAnalysis(a1.id, 'xyz', 'Name');
        System.assertEquals('current-weather', probs[0].label);
        System.assertEquals(0.9904295, probs[0].probability);

        Einstein_RecordLanguageController.savePredictionValue(a1.id, 'AccountNumber', 'rubber chicken');
        List<Account> a = [SELECT Id, AccountNumber FROM Account WHERE Id = :a1.id];
        System.assertEquals('rubber chicken', a[0].AccountNumber);
        test.stopTest();
   }*/

	static testmethod void testRecordVisionControllerClassification(){
		Account a1 = new Account();
		a1.Name = 'ACME';
		insert a1;

		createSettings('test@gmail.com', null, null);

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		test.startTest();
		Einstein_PredictionResult result = Einstein_RecordVisionController.analyseImage(
			'Fake Image',
			'Fake model');
		System.assertEquals('beach', result.probabilities[0].label);
		System.assertEquals(0.96021104,result.probabilities[0].probability);

		Id newId = Einstein_RecordVisionController.createRecord(a1.id, 'Contact', 'LastName', 'rubber chicken');
		List<Contact> addrs = [SELECT Id, LastName FROM Contact WHERE AccountId = :a1.id];
		System.assertEquals(newId, addrs[0].Id);
		System.assertEquals('rubber chicken', addrs[0].LastName);

		// postImageToChatter cannot be easily tested.  See https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/connectAPI_TestingApex.htm

		test.stopTest();
	}

	static testmethod void testRecordVisionControllerDetection(){
		Account a1 = new Account();
		a1.Name = 'ACME';
		insert a1;

		Contact cont = new Contact();
		cont.LastName = 'foo';
		cont.Title = 'rubber chicken';
		cont.AssistantName = '5';

		createSettings('test@gmail.com', null, null);

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		test.startTest();
		Einstein_PredictionResult result1 = Einstein_RecordVisionController.detectObjects(
			'Fake Image',
			'Fake model');
		System.assertEquals('box', result1.probabilities[0].label);
		System.assertEquals(0.96021104,result1.probabilities[0].probability);
		System.assertEquals(100, result1.probabilities[0].boundingBox.maxX);

		Einstein_PredictionResult result2 = Einstein_RecordVisionController.analyseImageUrl(
			'Fake Url',
			'Fake model');
		System.assertEquals('box', result2.probabilities[0].label);
		System.assertEquals(0.96021104,result2.probabilities[0].probability);
		System.assertEquals(100, result2.probabilities[0].boundingBox.maxX);

		Einstein_RecordVisionController.storeScanResults(cont, a1.Id, 'Contact');

		List<Contact> contacts = [SELECT Id, Title, AssistantName FROM Contact WHERE AccountId = :a1.id];
		System.assertEquals('rubber chicken', contacts[0].Title);
		System.assertEquals('5', contacts[0].AssistantName);

		ContentVersion cv = new ContentVersion();
		cv.title = 'test';
		cv.PathOnClient = 'test';
		cv.versionData = EncodingUtil.base64Decode('This is test content');
		insert cv;
		Id ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id][0].ContentDocumentId;

		System.debug('returned url is ' + Einstein_RecordVisionController.createContentUrl(ContentDocumentId));


		test.stopTest();
	}


	static testmethod void testLanguageMassUpdateController(){
		Opportunity o1 = new Opportunity();
		o1.Name = 'Foo';
		o1.CloseDate = Date.today();
		o1.StageName = 'Prospecting';
		insert o1;

		createSettings('test@gmail.com', null, null);

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		test.startTest();
		List<String> results = EinsteinLanguageMassUpdateController.getObjectOptions();
		List<String> results2 = EinsteinLanguageMassUpdateController.getObjectFields('Opportunity', 'Source');
		List<String> results3 = EinsteinLanguageMassUpdateController.getObjectFields('Opportunity', 'Label');
		List<String> results4 = EinsteinLanguageMassUpdateController.getObjectFields('Opportunity', 'Probability');
		Integer objectCount = EinsteinLanguageMassUpdateController.getObjectCount('Opportunity');
		String lastId = EinsteinLanguageMassUpdateController.goClassify(
			'Name',
			'NextStep',
			'TotalOpportunityQuantity',
			'Description',
			'Probability',
			null,
			null,
			'Opportunity',
			80,
			'CommunitySentiment',
			'text-sentiment',
			'true',
			null,
			'false');
		test.stopTest();

		System.assert (results.size() > 0);
		System.assert (results.contains('Opportunity'));
		System.assert (results2.size() > 0);
		System.assert (results2.contains('Description'));
		System.assert (results3.size() > 0);
		System.assert (results3.contains('IsPrivate'));
		System.assert (results4.size() > 0);
		System.assert (results4.contains('TotalOpportunityQuantity'));
		System.assertEquals(1, objectCount);
		System.assertEquals(o1.id, lastId);

	}

	static testmethod void testLanguageMassUpdateController2(){
		Opportunity o1 = new Opportunity();
		o1.Name = 'Foo';
		o1.CloseDate = Date.today();
		o1.StageName = 'Prospecting';
		insert o1;

		createSettings('test@gmail.com', null, null);

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		test.startTest();
		String lastId = EinsteinLanguageMassUpdateController.goClassify(
			'Name',
			'NextStep',
			'TotalOpportunityQuantity',
			null,
			null,
			'Description',
			'Probability',
			'Opportunity',
			80,
			'123456',
			'text-intent',
			'false',
			null,
			'false');
		test.stopTest();

		System.assertEquals(o1.id, lastId);

	}

	static testmethod void testLanguageMassUpdateController3(){
		Opportunity o1 = new Opportunity();
		o1.Name = 'Foo';
		o1.CloseDate = Date.today();
		o1.StageName = 'Prospecting';
		insert o1;

		createSettings('test@gmail.com', null, null);

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

		test.startTest();
		String lastId = EinsteinLanguageMassUpdateController.goClassify(
			'Name',
			'NextStep',
			'TotalOpportunityQuantity',
			null,
			null,
			'Description',
			'Probability',
			'Opportunity',
			80,
			'123456',
			'image',
			'true',
			null,
			'false');
		test.stopTest();

		System.assertEquals(o1.id, lastId);

	}

	static testmethod void testLanguageMassUpdateController4(){
		Opportunity o1 = new Opportunity();
		o1.Name = 'Foo';
		o1.CloseDate = Date.today();
		o1.StageName = 'Prospecting';
		insert o1;

		createSettings('test@gmail.com', null, null);

		Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponsesBadHTTP());

		test.startTest();
		try {
			String lastId = EinsteinLanguageMassUpdateController.goClassify(
				'Name',
				'NextStep',
				'TotalOpportunityQuantity',
				'Description',
				'Probability',
				null,
				null,
				'Opportunity',
				80,
				'123456',
				'image',
				'true',
				null,
				'false');
		} catch (Exception e) {

			System.assert (e.getMessage().contains('Script-thrown exception'));
		}
		test.stopTest();

	}

	static private void createSettings(String email, String certName, String certificatePart1) {
		Einstein_Settings__c settings =   Einstein_Settings__c.getOrgDefaults();
		settings.Einstein_Email__c = email;
		settings.CertName__c = certName;
		settings.certificate_part_1__c = certificatePart1;
		upsert settings;
	}

	static testmethod void exampleTestMethod(){
		createSettings(null, null, null);

	Test.setMock(HttpCalloutMock.class, new Test_Einstein_HttpMockResponses());

	test.startTest();
	//your code here
	test.stopTest();
}

}