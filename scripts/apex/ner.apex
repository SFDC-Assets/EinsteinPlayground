Einstein_PredictionService service = new Einstein_PredictionService(Einstein_PredictionService.Types.NER);
Einstein_PredictionResult res = service.predictNER('ENTITIES', 'Dennis Schultz works at Salesforce on Friday', 3, null);

System.debug(res);