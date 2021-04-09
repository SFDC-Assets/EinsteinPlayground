global with sharing class Einstein_Invocable_Language {
    @InvocableMethod(label='Einstein Text Prediction - Language')
    global static void AnalyzeLanguage(list<LanguageRequest> LRs) {
        //don't allow this run in future, batch, or queueable
        if (system.isFuture() || system.isBatch() || system.isQueueable()){
            return;
        }
        list<string> singleBatch = new list<string>();
        list<list<string>> Batches = new list<list<string>>();
        Integer Batchsize = Limits.GetLimitCallouts()-1; //because we'll use a call to get a token for each batch
        //get the actual text
        list<LanguageRequest> deduped = dedupeLRs(LRs);
        list<ID> lrIDs = new list<ID>();
        list<string> fields = new list<string>();
        for (LanguageRequest LR:deduped) {
            lrIDs.add(LR.recordId);
            fields.add(LR.FieldToAnalyze);
        }
        // Get the object type of the record and confirm it is accessible
        string objType = id.valueOf(deduped[0].recordId).getSObjectType().getDescribe().getName();
        Schema.sObjectType sobj = Schema.getGlobalDescribe().get(objType);
        if(sobj.getDescribe().isAccessible()) {
            Integer cntr = 0; 
            for(String f : fields) {
                // check if each of the fields exist
                if(sobj.getDescribe().fields.getMap().get(f).getDescribe().isAccessible())
                {
                    cntr += 1; 
                }
                f = f.replaceAll('[^a-zA-Z0-9_]', ' ');
            }
            //counter to keep track of the length of the list
            Integer len = fields.size(); 
            if(cntr == len) { 
                // isAccessible() check done on line 26
                // Each value of the string is sanitized by regex on line 30
                objType = objType.replaceAll('[^a-zA-Z0-9_]', ' ');
                string soql = 'select id, ' + string.join(fields, ', ') + ' from ' + objType + ' where id in: lrIDs';
                //system.debug(soql);  
                list<sobject> records = database.query(soql);
                //system.debug(records);
                map<id, sobject> recordMap = new map<id, sobject>();
                for (sobject so:records) {
                    recordMap.put((id)so.get('Id'), so);
                }
                system.debug(recordMap);
                // Future methods cannot take complex parameters.
                // Serialize as JSON
                for (LanguageRequest LR:deduped) {
					LR.objectType = objType;
					// It is possible this is a rich text field, so try to strip out html tags.
                    LR.actualText = string.valueOf(recordMap.get(LR.recordId).get(LR.FieldToAnalyze)).replaceAll('<[^>]+>',' ');
                    //batch is full, put it in the batch list, blank it for new adds
                    if (singleBatch.size()==Batchsize) {
                        Batches.add(singleBatch);
                        singleBatch = new list<string>();
                    }
                    singleBatch.add(JSON.serialize(LR));
                }
                Batches.add(singleBatch);
                for (list<string> batch:batches) {
                    getAnalysis(batch);
                }
            }
            else {
                system.debug('-- fields are not accessible --');
            }
        }
        else {
            system.debug('-- object not accessible --');
        }
    }
    @future(callout=true)
    public static void getAnalysis(list<string> input){
        // ID list
        list<ID> lrIDs = new list<ID>();
        // fields list 
        set<string> fields = new set<string>();
        // Deserialize into LanguageRequests
        list<LanguageRequest> LRs = new list<LanguageRequest>();
        for (string s:input) {
            LRs.add((LanguageRequest)JSON.deserialize(s, LanguageRequest.class));
        }
        // Perform the prediction operations for each LanguageRequest
        for (LanguageRequest LR:LRs) {
            lrIDs.add(LR.recordId);
            fields.add(LR.LabelStoreField);
            if (LR.ProbabilityStoreField != null) {
                fields.add(LR.ProbabilityStoreField);
            }
            if (LR.RawStoreField != null) {
                fields.add(LR.RawStoreField);
            }
            if (LR.ModelType=='Sentiment') {
                Einstein_PredictionService service = new Einstein_PredictionService(Einstein_PredictionService.Types.SENTIMENT);
                LR.prediction = service.predictSentiment(LR.ModelId, LR.actualText, 0, '');
            } else if (LR.ModelType=='Intent') {
                Einstein_PredictionService service = new Einstein_PredictionService(Einstein_PredictionService.Types.INTENT);
                LR.prediction = service.predictIntent(LR.ModelId, LR.actualText, 0, '');
            } else if (LR.ModelId == null && (LR.ModelType=='Sentiment' || LR.ModelType==null)) {
                //default this
                Einstein_PredictionService service = new Einstein_PredictionService(Einstein_PredictionService.Types.SENTIMENT);
                LR.prediction = service.predictSentiment('CommunitySentiment', LR.actualText, 0, '');
            }
            system.debug(LR);
        }
        list<string> fieldNames = new list<string>(fields);
        // Add CRUD here. 
        string objType = String.valueOf(LRs[0].objectType) ; 
        Schema.sObjectType sobj = Schema.getGlobalDescribe().get(objType);
        Integer cntr = 0; 
        // Confirm the object is accessible to this user
        if(sobj.getDescribe().isAccessible() && sobj.getDescribe().isUpdateable()) {
            for(String f : fieldNames) {
                // check if each of the fields exist
                if(sobj.getDescribe().fields.getMap().get(f).getDescribe().isAccessible()) {
                    cntr += 1; 
                }
                f = f.replaceAll('[^a-zA-Z0-9_]', ' ');
            }
        }
        if(cntr == fieldNames.size()) { 
            String lrObjType = LRs[0].objectType;
            // isAccessible() check done on line 110
            // Each value of the string is sanitized by regex on line 118
            lrObjType = lrObjType.replaceAll('[^a-zA-Z0-9_]', ' ');
            string soql = 'select id, ' + string.join(fieldNames, ', ') + ' from ' + lrObjType + ' where id in: lrIDs';
            system.debug(soql);
            // Fetch the records
            list<sobject> records = database.query(soql);
            system.debug(records);
            map<id, sobject> recordMap = new map<id, sobject>();
            for (sobject so:records) {
                recordMap.put((id)so.get('Id'), so);
            }
            system.debug(recordMap);
            //handle the predictions and update that record
            for (LanguageRequest LR:LRs) {
                // If the URL field is blank, we may not get a prediction
                if (LR.prediction == null || LR.prediction.probabilities == null) {
                    recordMap.get((id)LR.recordId).put(LR.LabelStoreField, '');
                    if (LR.ProbabilityStoreField != null) {
                        recordMap.get((id)LR.recordId).put(LR.ProbabilityStoreField, null);
                    }
                    if (LR.RawStoreField != null) {
                        recordMap.get((id)LR.recordId).put(LR.RawStoreField, '');
                    }
                    continue;
                }
                // Store the Prediction
                recordMap.get((id)LR.recordId).put(LR.LabelStoreField, LR.prediction.probabilities[0].label);
                // Store the Probability, if requested
                if (LR.ProbabilityStoreField != null) {
                    try {
                        recordMap.get((id)LR.recordId).put(LR.ProbabilityStoreField, LR.prediction.probabilities[0].probability);
                    } catch (SObjectException e) {
                        //might be a text field instead of decimal?
                        recordMap.get((id)LR.recordId).put(LR.ProbabilityStoreField, string.valueOf(LR.prediction.probabilities[0].probability));
                    }
                }
                // Store the Raw response, if requested
                if (LR.RawStoreField != null) {
                    // we don't need the coordinates property for anything besides object detection!
                    recordMap.get((id)LR.recordId).put(LR.RawStoreField, 
                        JSON.serialize(LR.prediction)
                            .remove('"boundingBox":null')
                            .remove('"token":null')
                            .remove('"normalizedData":null')
                            .remove('"normalizedValue":null')
                            .remove('"span":null')
							.remove('"attributes":null')
							.replace(',,', ',')
							.replace(',,', ',')
                            .replace('{,', '{')
                            .replace(',}', '}'));
                }
            }
            // Update all records
            list<sobject> output = recordMap.values();
            // isUpdateable() check done on line 99
            update output;
        }
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                                       'Insufficient access')); 
            throw new System.NoAccessException();
        }
    }
    public static list<LanguageRequest> dedupeLRs(list<LanguageRequest> input) {
        set<LanguageRequest> temp = new set<LanguageRequest>(input);
        return new list<LanguageRequest>(temp);
    }
    global class LanguageRequest {
        @InvocableVariable (required=true label='RecordId of record to Analyze')
        global string RecordId;
        @InvocableVariable (required=true label='Field to Analyze: Literal string of Field Name (i.e. "MyField__c")')
        global string FieldToAnalyze;
        @InvocableVariable (required=true label='Field to Store Answer: Literal string of Field Name (i.e. "Classification__c")' description='The top label will be stored in this text field')
        global string LabelStoreField;
        @InvocableVariable (required=true label='ModelId (CommunitySentiment or ModelId of custom Einstein.ai model)' description='Model Id String value from Einstein.ai (not the Salesforce ID)')
        global string ModelId;
        @InvocableVariable (required=true label='Model Type (Sentiment or Intent)' description='Allowed String values are Sentiment and Intent')
        global string ModelType;
        @InvocableVariable (label='Field to Store Probability: Literal string of Field Name (i.e. "Confidence__c")' description='The probability on the top label will be stored in this number/percentage field')
        global string ProbabilityStoreField;
        @InvocableVariable (label='Field to Store Raw Results: Literal string of Field Name (i.e. "Raw_Results__c")' description='This text field will get all predictions (label/probability pairs) stored as JSON')
        global string RawStoreField;
        public string actualText;
        public string objectType;
        public Einstein_PredictionResult prediction;
    }
}