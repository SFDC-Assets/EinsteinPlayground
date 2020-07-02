public with sharing class EinsteinLanguageMassUpdateController {
	@AuraEnabled(cacheable=true)
	public static List<String> getObjectOptions(){
		Map<String, Schema.SObjectType> objects = Schema.getGlobalDescribe();
		List<String> results = new List<String> ();
		list<map<string, string> > output = new list<map<string, string> >();
		for (string s:objects.keySet()) {
			DescribeSObjectResult dsor = objects.get(s).getDescribe();
			if (
				//if you can't update anything, you won't be able to save a prediction anywhere!
				dsor.isUpdateable() &&
				//no custom settings
				!dsor.isCustomSetting() &&
				// No sharing objects
				!dsor.getName().endsWithIgnoreCase('Share')
				) {
				results.add(dsor.getName());
			}
		}
		results.sort();
		system.debug('--- results---' + results);
		return results;
	}
	/*for a given object, return the fields that are sources of text (string, textarea) or labels (picklist, boolean)*/
	@AuraEnabled(cacheable=true)
	public static List<string> getObjectFields(string objectName, string sourceOrLabel){
		list<string> temp = new list<string>();
		temp.add(objectName);
		List<Schema.DescribeSObjectResult> describe = Schema.describeSObjects(temp);
		map<string, Schema.SObjectField> fieldmap = describe[0].fields.getMap();
		list<map<string, string> > output = new list<map<string, string> >();
		list<string> results = new list<string>();
		for (Schema.SObjectField field:fieldmap.values()) {
			DescribeFieldResult dfr = field.getDescribe();
			map<string, string> tempMap = new map<string, string>();
			if (dfr.getLabel() != dfr.getName()) {
				tempMap.put('label', dfr.getLabel() + ' (' + dfr.getName() + ')' + ' [' + dfr.getType().name() + ']');
			} else {
				tempMap.put('label', dfr.getLabel() + ' [' + dfr.getType().name() + ']');
			}
			tempMap.put('name', dfr.getName());
			tempMap.put('type', dfr.getType().name());
			output.add(tempMap);

			switch on sourceOrLabel {
				// Sources can be picklists, strings, or textareas
				when 'Source' {
					switch on dfr.getType() {
						when PICKLIST, STRING, TEXTAREA {
							results.add(dfr.getName());
						}
						when else {

						}
					}
				}
				// Labels can be stored in picklists, strings, textareas or booleans
				when 'Label' {
					switch on dfr.getType() {
						when PICKLIST, STRING, TEXTAREA, BOOLEAN {
							results.add(dfr.getName());
						}
						when else {

						}
					}
				}
				// Probabilities can be stored in doubles or percents
				when 'Probability' {
					switch on dfr.getType() {
						when DOUBLE, PERCENT {
							results.add(dfr.getName());
						}
						when else {

						}
					}
				}
			}

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
		Schema.sObjectType sobj = Schema.getGlobalDescribe().get(objectName);
		if(sobj.getDescribe().isAccessible()) {
			//objectName isn't a user-enterable variable
			AggregateResult[] groupedResults  = Database.query('SELECT count(Id)cnt FROM ' + objectName);
			count = (Integer) groupedResults[0].get('cnt');
			return count;
		}
		else
		{
			return null;
		}
	}
	@AuraEnabled
	public static String goClassify(
		String sourceName,
		String destinationName1,
		String probabilityName1,
		String destinationName2,
		String probabilityName2,
		String destinationName3,
		String probabilityName3,
		String objectName,
		Integer batchSize,
		String modelId,
		String dataType,
		String overwriteValues,
		String latestId,
		String ignoreErrors) {

		// Mass update is only supported for some data types
		if((dataType != 'image') && (dataType != 'text-sentiment') && (dataType != 'text-intent')) {
			throw new AuraHandledException('Data type not supported for Mass Update');
		}

		System.debug('---- Started Classification ----');
		Boolean overwrite = Boolean.valueOf(overwriteValues);
		Boolean ignoreErrorVal = Boolean.valueOf(ignoreErrors);
		System.debug(modelId + ' '  + latestId + ' ' + batchSize  + ' ' + dataType + ' ' + overwrite  + ' ' + ignoreErrorVal);
		Integer maxSize = Integer.valueOf(batchSize);
		// Select records in batchSize chunks
		List<SObject> dataList = null;

		// Get the object type of the record and confirm it is accessible
		SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
		if(!sObjType.getDescribe().isAccessible() || !sObjType.getDescribe().isUpdateable()) {
			system.debug('-- not accessible -- ');
			return null;
		}

		// Clean field names and build query
		sourceName = sourceName.replaceAll('[^a-zA-Z0-9_]', ' ');
		destinationName1 = destinationName1.replaceAll('[^a-zA-Z0-9_]', ' ');
		String queryString = 'SELECT Id, ' + sourceName + ', ' + destinationName1;
		// Remaining fields are optional.
		if (!String.isBlank(probabilityName1)) {
			probabilityName1 = probabilityName1.replaceAll('[^a-zA-Z0-9_]', ' ');
			queryString += ', ' + probabilityName1;
		}
		if (!String.isBlank(destinationName2)) {
			destinationName2 = destinationName2.replaceAll('[^a-zA-Z0-9_]', ' ');
			queryString += ', ' + destinationName2;
		}
		if (!String.isBlank(probabilityName2)) {
			probabilityName2 = probabilityName2.replaceAll('[^a-zA-Z0-9_]', ' ');
			queryString += ', ' + probabilityName2;
		}
		if (!String.isBlank(destinationName3)) {
			destinationName3 = destinationName3.replaceAll('[^a-zA-Z0-9_]', ' ');
			queryString += ', ' + destinationName3;
		}
		if (!String.isBlank(probabilityName3)) {
			probabilityName3 = probabilityName3.replaceAll('[^a-zA-Z0-9_]', ' ');
			queryString += ', ' + probabilityName3;
		}
		objectName = objectName.replaceAll('[^a-zA-Z0-9_]', ' ');
		queryString += ' FROM ' + objectName;

		if(latestId == null ) {
			System.debug('- Started From Scratch --');
			//values sanitized above
			queryString += ' order by id limit :maxSize';
		} else {
			//values sanitized above
			queryString += ' where id > :latestId order by id limit :maxSize';
		}
		System.debug('queryString: ' + queryString);
		dataList =  Database.query(queryString);

		System.debug('Got dataset of size ' + dataList.size());
		List<SObject> shortList  = new List<SObject>();
		Einstein_PredictionService service;
		if(dataType == 'text-intent') {
			service = new Einstein_PredictionService(Einstein_PredictionService.Types.Intent);
		} else if(dataType == 'image') {
			service = new Einstein_PredictionService(Einstein_PredictionService.Types.Image);
		} else if(dataType == 'text-sentiment') {
			service = new Einstein_PredictionService(Einstein_PredictionService.Types.SENTIMENT);
		}
		for (Integer i = 0; i < dataList.size() && i < maxSize; i++) {
			SObject obj = dataList.get(i);
			string objType = id.valueOf(dataList[0].Id).getSObjectType().getDescribe().getName();
			Schema.sObjectType sobj = Schema.getGlobalDescribe().get(objType);
			if(sobj.getDescribe().isAccessible() && sobj.getDescribe().isUpdateable()) {
				latestId = (string) obj.get('id');
				String text = (String)obj.get(sourceName);
				String existingDestinationValue1 = (String)obj.get(destinationName1);
				Decimal existingProbabilityValue1 = null;
				if (!String.isBlank(probabilityName1)) {
					existingProbabilityValue1 = (Decimal)obj.get(probabilityName1);
				}
				String existingDestinationValue2 = null;
				if (!String.isBlank(destinationName2)) {
					existingDestinationValue2 = (String)obj.get(destinationName2);
				}
				Decimal existingProbabilityValue2 = null;
				if (!String.isBlank(probabilityName2)) {
					existingProbabilityValue2 = (Decimal)obj.get(probabilityName2);
				}
				String existingDestinationValue3 = null;
				if (!String.isBlank(destinationName3)) {
					existingDestinationValue3 = (String)obj.get(destinationName3);
				}
				Decimal existingProbabilityValue3 = null;
				if (!String.isBlank(probabilityName3)) {
					existingProbabilityValue3 = (Decimal)obj.get(probabilityName3);
				}
				if ((!String.isBlank(text)) &&
				    (overwrite ||
				     (String.isBlank(existingDestinationValue1) &&
				      String.isBlank(existingDestinationValue2) &&
				      String.isBlank(existingDestinationValue3) &&
				      (existingProbabilityValue1 == null) &&
				      (existingProbabilityValue2 == null) &&
				      (existingProbabilityValue3 == null)
				     )
				    )
				    ) {
					try {
						Einstein_PredictionResult predictionList = null;
						if(modelId == 'CommunitySentiment') {
							predictionList = service.predictSentiment(modelId, text, 3, null);
						} else if(dataType == 'text-intent') {
							predictionList  = service.predictIntent(modelId, text, 3, null);
						} else if(dataType == 'image') {
							predictionList  = service.predictImageUrl(modelId, text, 3, null);
						}
						System.debug(predictionList);
						if (service.httpStatusCode>200 && ignoreErrorVal == false) {
							AuraHandledException e = new AuraHandledException('API http error:' + service.httpErrorMessage);
							if (service.httpErrorMessage.contains('Bad sampleLocation')) {
								e.setMessage('The text field you want to classify on record ' + obj.Id + ' does not contain a valid URL');
							}
							throw e;
						}

						// Look for top prediction
						Double topProbability = 0;
						String topLabel = '';
						for(Einstein_Probability pred : predictionList.probabilities) {
							System.debug(pred);
							if(pred.probability > topProbability) {
								topLabel = pred.label;
								topProbability = pred.probability;
							}
						}
						System.debug(topLabel);
						obj.put(destinationName1, topLabel);
						if (!String.isBlank(probabilityName1)) {
							obj.put(probabilityName1, topProbability);
						}

						// Look for second highest prediction
						Double secondProbability = 0;
						if (!String.isBlank(destinationName2)) {
							String secondLabel = '';
							for(Einstein_Probability pred : predictionList.probabilities) {
								if((pred.probability > secondProbability) && (pred.probability < topProbability)) {
									secondLabel = pred.label;
									secondProbability = pred.probability;
								}
							}
							obj.put(destinationName2, secondLabel);
							if (!String.isBlank(probabilityName2)) {
								obj.put(probabilityName2, secondProbability);
							}
						}

						// Look for third highest prediction
						if (!String.isBlank(destinationName3)) {
							Double thirdProbability = 0;
							String thirdLabel = '';
							for(Einstein_Probability pred : predictionList.probabilities) {
								if((pred.probability > thirdProbability) && (pred.probability < secondProbability)) {
									thirdLabel = pred.label;
									thirdProbability = pred.probability;
								}
							}
							obj.put(destinationName3, thirdLabel);
							if (!String.isBlank(probabilityName3)) {
								obj.put(probabilityName3, thirdProbability);
							}
						}

						shortList.add(obj);

					} catch(Exception e) {
						System.debug(e);
						if(ignoreErrorVal == false) {
							System.debug('exception message: ' + e.getMessage());
							throw new AuraHandledException(e.getMessage());
						}
					}
				}
			} 
		}// end of for
		System.debug('---- Saving List ' + shortList.size() + ' ----');
		System.debug(shortList); 
		// Update Check Added on line 89 -- Shortlist is a variable that gets it's value from obj for which the test is complete
		update shortList; 
		return latestId;  
    }        
}