global with sharing class Einstein_Invocable_Image_Classification {
    @InvocableMethod(label='Einstein Image Classification')
    global static void AnalyzeImageClassification(List<ClassificationRequest> CRs) {
        //don't allow this run in future, batch, or queueable
        if (system.isFuture() || system.isBatch() || system.isQueueable()){
            return;
        }
        list<string> singleBatch = new list<string>();
        list<list<string>> Batches = new list<list<string>>();
        Integer Batchsize = Limits.GetLimitCallouts()-1; //because we'll use a call to get a token for each batch
        list<ClassificationRequest> deduped = dedupeCRs(CRs);
        list<ID> crIDs = new list<ID>();
        list<string> fields = new list<string>();
        for (ClassificationRequest CR :deduped) {
            crIDs.add(CR.RecordId);
            fields.add(CR.FieldToAnalyze);
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
                // isAccessible() check done on line 25
                // Each value of the string is sanitized by regex on line 29
                objType = objType.replaceAll('[^a-zA-Z0-9_]', ' ');
                string soql = 'select id, ' + string.join(fields, ', ') + ' from ' + objType + ' where id in: crIDs';
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
                for (ClassificationRequest CR : deduped) {
                    CR.objectType = objType;
                    CR.actualURL = string.valueOf(recordMap.get(CR.RecordId).get(CR.FieldToAnalyze));
                    //batch is full, put it in the batch list, blank it for new adds
                    if (singleBatch.size()==Batchsize) {
                        Batches.add(singleBatch);
                        singleBatch = new list<string>();
                    }
                    singleBatch.add(JSON.serialize(CR));
                }
                Batches.add(singleBatch);
                for (list<string> batch:batches) {
                    runClassification(batch);
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
    private static void runClassification(List<String> input) {
        // ID list
        list<ID> crIDs = new list<ID>();
        // fields list 
        set<string> fields = new set<string>();
        // Deserialize into ClassificationRequests
        list<ClassificationRequest> CRs = new list<ClassificationRequest>();
        for (string s:input) {
            CRs.add((ClassificationRequest)JSON.deserialize(s, ClassificationRequest.class));
        }
        // Perform the prediction operations for each ClassificationRequest
        for (ClassificationRequest CR : CRs) {
            crIDs.add(CR.recordId);
            fields.add(CR.LabelStoreField);
            if (CR.ProbabilityStoreField != null) {
                fields.add(CR.ProbabilityStoreField);
            }
            if (CR.RawStoreField != null) {
                fields.add(CR.RawStoreField);
            }
            Einstein_PredictionService service = new Einstein_PredictionService(Einstein_PredictionService.Types.IMAGE);
            CR.prediction = service.predictImageUrl(CR.modelId, CR.actualURL, 2, '');
        }
        list<string> fieldNames = new list<string>(fields);
        // Add CRUD here. 
        string objType = String.valueOf(CRs[0].objectType) ; 
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
            // isAccessible() check done on line 101
            String crObjType = CRs[0].objectType;
            // Each value of the string is sanitized by regex on line 107
            crObjType = crObjType.replaceAll('[^a-zA-Z0-9_]', ' ');
            string soql = 'select id, ' + string.join(fieldNames, ', ') + ' from ' + crObjType + ' where id in: crIDs';
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
            for (ClassificationRequest CR :CRs) {
                // If the URL field is blank, we may not get a prediction
                if (CR.prediction == null || CR.prediction.probabilities == null) {
                    recordMap.get((id)CR.recordId).put(CR.LabelStoreField, '');
                    if (CR.ProbabilityStoreField != null) {
                        recordMap.get((id)CR.recordId).put(CR.ProbabilityStoreField, null);
                    }
                    if (CR.RawStoreField != null) {
                        recordMap.get((id)CR.recordId).put(CR.RawStoreField, '');
                    }
                    continue;
                }
                // Store the Prediction
                recordMap.get((id)CR.recordId).put(CR.LabelStoreField, CR.prediction.probabilities[0].label);
                // Store the Probability, if requested
                if (CR.ProbabilityStoreField != null) {
                    try {
                        recordMap.get((id)CR.recordId).put(CR.ProbabilityStoreField, CR.prediction.probabilities[0].probability);
                    } catch (SObjectException e) {
                        //might be a text field instead of decimal?
                        recordMap.get((id)CR.recordId).put(CR.ProbabilityStoreField, string.valueOf(CR.prediction.probabilities[0].probability));
                    }
                }
                // Store the Raw response, if requested
                if (CR.RawStoreField != null) {
                    // we don't need the coordinates property for anything besides object detection!
                    recordMap.get((id)CR.recordId).put(CR.RawStoreField, 
                        JSON.serialize(CR.prediction)
                            .remove('"boundingBox":null')
                            .remove('"token":null')
                            .remove('"normalizedData":null')
                            .remove('"normalizedValue":null')
                            .remove('"span":null')
                            .replace(',,', ',')
                            .replace(',,', ',')
                            .replace('{,', '{')
                            .replace(',}', '}'));
                }
            }
            // Update all records
            list<sobject> output = recordMap.values();
            
            // isUpdateable() check done on line 101
            update output;
        }
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                                       'Insufficient access')); 
            throw new System.NoAccessException();
        }        
    }
    public static list<ClassificationRequest> dedupeCRs(list<ClassificationRequest> input) {
        set<ClassificationRequest> temp = new set<ClassificationRequest>(input);
        return new list<ClassificationRequest>(temp);
    }
    global class ClassificationRequest {
        @InvocableVariable(required=true label='RecordID of record to Analyze' description='The ID of the record that should be analyzed.')
        global String RecordId;
        @InvocableVariable(required=true label='Field containing URL of Image to analyze' description='Enter the name of the fields, that contains the URL of the image')
        global String FieldToAnalyze;
        @InvocableVariable(required=true label='Field to Store Answer: Literal string of Field Name (i.e. "Classification__c")' description='Enter the name of the field, that should be analyzed via Einstein Vision.')
        global String LabelStoreField;
        @InvocableVariable(required=true label='ModelId of custom Einstein.ai model')
        global String ModelId;
        @InvocableVariable (label='Field to Store Probability: Literal string of Field Name (i.e. "Confidence__c")' description='The probability on the top label will be stored in this number/percentage field')
        global string ProbabilityStoreField;
        @InvocableVariable (label='Field to Store Raw Results: Literal string of Field Name (i.e. "Raw_Results__c")' description='This text field will get all predictions (label/probability pairs) stored as JSON')
        global string RawStoreField;
        public String actualURL;
        public String objectType;
        public Einstein_PredictionResult prediction;
    }
}