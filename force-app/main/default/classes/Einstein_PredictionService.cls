global with sharing class Einstein_PredictionService {

	global Integer httpStatusCode = 0;
	global String httpErrorMessage = '';
	global String baseUrl;

	// Base URL for the PredictionService
	private static String BASE_URL = 'https://api.einstein.ai/v2';

	private String API_USAGE = BASE_URL + '/apiusage';
	private static String OAUTH2 = BASE_URL + '/oauth2/token';

	private boolean isExecuting = false;
	private String bearerToken = '';
	private Types typeEnum;
	private String typeString;
	private Languages langEnum;
	private String langString;

	global enum Types {
		IMAGE,
		IMAGE_MULTI_LABEL,
		IMAGE_DETECTION,
		SENTIMENT,
		INTENT,
		NER,
		OCR
	}

	global enum Languages {
		CHINESE_SIMPLIFIED,
		CHINESE_TRADITIONAL,
		ENGLISH_US,
		ENGLISH_UK,
		FRENCH,
		GERMAN,
		ITALIAN,
		JAPANESE,
		PORTUGUESE,
		SPANISH
	}

	/**
	 * <p>Create a new object of type Einstein_PredictionService.</p>
	 *
	 * <p>The Einstein_PredictionService is the foundation for communicating with the Salesforce Einstein Platform API.
	 *
	 * @param typeEnum
	 * An Enum of type Einstein_PredictionService.Types which defines the type of prediction (image, image-multi-model, sentiment or intent).
	 */
	global Einstein_PredictionService(Einstein_PredictionService.Types typeEnum) {
		this.bearerToken = getAccessToken();
		this.typeEnum = typeEnum;
		this.baseUrl = resolveBaseUrl();
		this.typeString = resolveType();
	}

	/**
	 * <p>Create a new object of type Einstein_PredictionService.</p>
	 *
	 * <p>The Einstein_PredictionService is the foundation for communicating with the Salesforce Einstein Platform API.
	 *
	 * @param bearerToken
	 * A valid Bearer token
	 * @param typeEnum
	 * An Enum of type Einstein_PredictionService.Types which defines the type of prediction (image, image-multi-model, sentiment or intent).
	 */
	global Einstein_PredictionService(String bearerToken, Einstein_PredictionService.Types typeEnum) {
		this.bearerToken = bearerToken;
		this.typeEnum = typeEnum;
		this.baseUrl = resolveBaseUrl();
		this.typeString = resolveType();
	}

	/**
	 * Creates a new dataset with data from a remote file (async call).
	 * @param url
	 * The remote URL of the to be trained data.
	 * @return
	 * An object of type Einstein_Dataset
	 */
	public Einstein_Dataset createDatasetFromUrlAsync(String url) {
		System.debug('Starting createDatasetFromUrlAsync call from URL ' + url + ' for type ' + typeString + ' with language ' + langString +'.');
		Einstein_HttpBodyPartDatasetUrl parts = new Einstein_HttpBodyPartDatasetUrl(url, typeString,langString);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/datasets/upload', parts.build());
		client.isPost(true);
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call createDatasetFromUrlAsync has been executed.');
		if (!client.isError()) {
			Einstein_Dataset dataset = (Einstein_Dataset)client.getParser().readValueAs(Einstein_Dataset.class);
			System.debug('New dataset with id ' + dataset.id + ' has been created.');
			return dataset;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Creates a new dataset with data from a remote file (sync call).
	 * @param url
	 * The remote URL of the to be trained image.
	 * @return
	 * An object of type Einstein_Dataset
	 */
	public Einstein_Dataset createDatasetFromUrlSync(String url) {
		System.debug('Starting createDatasetFromUrlSync call from URL ' + url + ' for type ' + typeString + '.');
		Einstein_HttpBodyPartDatasetUrl parts = new Einstein_HttpBodyPartDatasetUrl(url, typeString, langString);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/datasets/upload/sync', parts.build());
		client.isPost(true);
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call createDatasetFromUrlSync has been executed.');
		if (!client.isError()) {
			Einstein_Dataset dataset = (Einstein_Dataset)client.getParser().readValueAs(Einstein_Dataset.class);
			System.debug('New dataset with id ' + dataset.id + ' has been created.');
			return dataset;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Gets an existing Einstein_Dataset.
	 * @param id
	 * The id of the Einstein_Dataset that needs to be fetched.
	 * @return
	 * An object of type Einstein_Dataset
	 */
	public Einstein_Dataset getDataset(Long id) {
		if (id==0) {
			throw new Einstein_NoValuesException('datasetId');
		}
		System.debug('Starting getDataset call with parameter ' + id);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/datasets/' + id);
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting() );
		}
		System.debug('Call getDataset has been executed.');
		if (!client.isError()) {
			Einstein_Dataset dataset = (Einstein_Dataset)client.getParser().readValueAs(Einstein_Dataset.class);
			System.debug('Dataset has been read.');
			return dataset;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Gets the globally, by Salesforce provided, datasets.
	 * @return
	 * An array of type Einstein_Dataset
	 */
	public Einstein_Dataset[] getGlobalDatasets() {
		final Integer pageSize = 25;
		List<Einstein_Dataset> datasets = new List<Einstein_Dataset>();
		Boolean done = false;
		Integer offset = 0;

		while (!done) {
			List<Einstein_Dataset> tempDatasets = getDatasets(pageSize, offset, Einstein_Dataset.Types.ALL, true);
			datasets.addAll(tempDatasets);
			offset += pageSize;

			// If array is shorter than pageSize, we are done
			done = (tempDatasets.size() < pageSize);
		}

		return datasets;
	}

	/**
	 * Gets all Einstein_Datasets.
	 * @return
	 * An array of type Einstein_Dataset
	 */
	public Einstein_Dataset[] getDatasets() {
		final Integer pageSize = 25;
		List<Einstein_Dataset> datasets = new List<Einstein_Dataset>();
		Boolean done = false;
		Integer offset = 0;

		while (!done) {
			List<Einstein_Dataset> tempDatasets = getDatasets(pageSize, offset, Einstein_Dataset.Types.ALL);
			if (this.httpStatusCode>200) {
				return null;
			}
			datasets.addAll(tempDatasets);
			offset += pageSize;

			// If array is shorter than pageSize, we are done
			done = (tempDatasets.size() < pageSize);
		}

		return datasets;
	}

	/**
	 * Gets datasets based on the provided parameter for pagination and type.
	 * @param count
	 * Defines the number of objects that should be returned for this call. Maximum is 25.
	 * @param offset
	 * The offset count for dataset pagination.
	 * @param typeEnum
	 * The type of data that should be fetched. Either all datasets, feedback or upload.π
	 * @return
	 * An array of type Einstein_Dataset
	 */
	public Einstein_Dataset[] getDatasets(Integer count, Integer offset, Einstein_Dataset.Types typeEnum) {
		return getDatasets(count, offset, typeEnum, false);
	}

	private Einstein_Dataset[] getDatasets(Integer count, Integer offset, Einstein_Dataset.Types typeEnum, Boolean isGlobal) {
		System.debug('Starting getDatasets call');
		String queryParameter = 'offset=' + offset + '&count='+ count + resolveEinsteinDatasetType(typeEnum);
		if (isGlobal) {
			queryParameter = 'global=true';
		}
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/datasets?' + queryParameter);
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while (isExecuting()) {
			System.debug('Status is: ' + isExecuting() );
		}
		System.debug('Call getDatasets has been executed.');
		if (!client.isError()) {
			Einstein_Dataset[] datasets = (Einstein_Dataset[])client.getParser().readValueAs(Einstein_Dataset[].class);
			System.debug('Datasets have been read.');
			return datasets;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Deletes an existing dataset.
	 * @param datasetId
	 * The id of the Einstein_Dataset that should be deleted.
	 * @return
	 * True if the deletion was successful.
	 */
	public boolean deleteDataset(Long datasetId) {
		System.debug('Starting deleteDataset call');
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/datasets/' + datasetId);
		client.isDelete(true);
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while (isExecuting()) {
			System.debug('Status is: ' + isExecuting() );
		}
		System.debug('Call deleteDataset has been executed.');
		if (!client.isError()) {
			System.debug('Dataset ' + datasetId + ' has been deleted.');
			return true;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return false;
	}

	/**
	 * Deletes an existing model.
	 * @param modelId
	 * The id of the Einstein_Model that should be deleted.
	 * @return
	 * True if the deletion was successful.
	 */
	public boolean deleteModel(String modelId) {
		System.debug('Starting deleteModel call');
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/models/' + modelId);
		client.isDelete(true);
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while (isExecuting()) {
			System.debug('Status is: ' + isExecuting() );
		}
		System.debug('Call deleteModel has been executed.');
		if (!client.isError()) {
			System.debug('Model ' + modelId + ' has been deleted.');
			return true;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return false;
	}

	/**
	 * Adds new image examples for the vision training.
	 * @param datasetId
	 * The id of the Einstein_Dataset to which the image should be added.
	 * @param name
	 * The name of the example.
	 * @param labelId
	 * The id of the label to which the example should be added.
	 * @param fileBlob
	 * The blog of the to be trained image.
	 * @return
	 * An object of type Einstein_Example
	 */
	public Einstein_Example createExample(Long datasetId, String name, Long labelId, Blob fileBlob) {
		System.debug('Starting createExample call from blob');
		Einstein_HttpBodyPartExample parts = new Einstein_HttpBodyPartExample(name, labelId, EncodingUtil.base64Encode(fileBlob));
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/datasets/' + datasetId + '/examples', parts.build());
		System.debug('Target URL is ' + client.getUrl());
		client.isPost(true);
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call createExample from blob has been executed.');
		if (!client.isError()) {
			Einstein_Example example = (Einstein_Example)client.getParser().readValueAs(Einstein_Example.class);
			System.debug('New example with id ' + example.id + ' has been created.');
			return example;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Adds new examples for the prediction training via a remote file.
	 * @param datasetId
	 * The id of the Einstein_Dataset to which the data should be added.
	 * @param url
	 * The remote URL of the training data source.
	 * @return
	 * An object of type Einstein_Dataset
	 */
	public Einstein_Dataset createExamplesFromUrl(Long datasetId, String url) {
		System.debug('Starting createExamplesFromUrl call from URL ' + url);
		Einstein_HttpBodyPartDatasetUrl parts = new Einstein_HttpBodyPartDatasetUrl(url, this.typeString);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/datasets/' + datasetId + '/upload', parts.build());
		client.isPut(true);
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call createExampleFromUrl has been executed.');
		if (!client.isError()) {
			Einstein_Dataset dataset = (Einstein_Dataset)client.getParser().readValueAs(Einstein_Dataset.class);
			System.debug('New examples for dataset with id ' + dataset.id + ' have been created.');
			return dataset;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Adds new image examples for model feedback to vision training.
	 * @param name
	 * The name of the example.
	 * @param expectedLabel
	 * The label name to which the feedback image should be added.
	 * @param modelId
	 * The model id to which the image should be added as feedback.
	 * @param fileBlob
	 * The blob of the to be trained image.
	 * @return
	 * An object of type Einstein_Example
	 */
	global Einstein_Example createFeedbackImageExample(String name, String expectedLabel, String modelId, Blob fileBlob) {
		System.debug('Starting createFeedbackImageExample call from blob');
		Einstein_HttpBodyPartFeedbackExample parts = new Einstein_HttpBodyPartFeedbackExample(name, expectedLabel, modelId, EncodingUtil.base64Encode(fileBlob), Einstein_HttpBodyPartFeedbackExample.Types.BASE64);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/feedback', parts.build());
		System.debug('Target URL is ' + client.getUrl());
		client.isPost(true);
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call createFeedbackImageExample from blob has been executed.');
		if (!client.isError()) {
			Einstein_Example example = (Einstein_Example)client.getParser().readValueAs(Einstein_Example.class);
			System.debug('New example with id ' + example.id + ' has been created.');
			return example;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Adds new text for model feedback to language training.
	 * @param name
	 * The name of the example.
	 * @param expectedLabel
	 * The label name to which the feedback text should be added.
	 * @param modelId
	 * The model id to which the image should be added as feedback.
	 * @param text
	 * The text that should be added.
	 * @return
	 * An object of type Einstein_Example
	 */
	global Einstein_Example createFeedbackLanguageExample(String expectedLabel, String modelId, String text) {
		System.debug('Starting createFeedbackLanguageExample call from text');
		Einstein_HttpBodyPartFeedbackExample parts = new Einstein_HttpBodyPartFeedbackExample('', expectedLabel, modelId, text, Einstein_HttpBodyPartFeedbackExample.Types.DOCUMENT);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/feedback', parts.build());
		System.debug('Target URL is ' + client.getUrl());
		client.isPost(true);
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call createFeedbackLanguageExample from blob has been executed.');
		if (!client.isError()) {
			Einstein_Example example = (Einstein_Example)client.getParser().readValueAs(Einstein_Example.class);
			System.debug('New example with id ' + example.id + ' has been created.');
			return example;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Gets an array of all Einstein_Examples that are associated with the given dataset id.
	 * @param datasetId
	 * The id Einstein_Dataset to which the Einstein_Examples are associated.
	 * @return
	 * An object of type Einstein_Example
	 */
	public Einstein_Example[] getExamples(Long datasetId) {
		final Integer pageSize = 100;
		List<Einstein_Example> examples = new List<Einstein_Example>();
		Boolean done = false;
		Integer offset = 0;

		while (!done) {
			List<Einstein_Example> tempExamples = getExamples(datasetId, pageSize, offset, Einstein_Example.Types.ALL);
			examples.addAll(tempExamples);
			offset += pageSize;

			// If array is shorter than pageSize, we are done
			done = (tempExamples.size() < pageSize);
		}

		return examples;

	}

	/**
	 * Gets an array of all Einstein_Examples that are associated with the given dataset id.
	 * @param datasetId
	 * The id of the Einstein_Dataset to which the Einstein_Examples are associated.
	 * @param count
	 * Defines the number of objects that should be returned for this call. Maximum is 100.
	 * @param offset
	 * The offset count for example pagination.
	 * @param typeEnum
	 * The type of data that should be fetched. Either all datasets, feedback or upload.
	 * @return
	 * An object of type Einstein_Example
	 */
	public Einstein_Example[] getExamples(Long datasetId, Integer count, Integer offset, Einstein_Example.Types typeEnum) {
		System.debug('Starting getExamples call');
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/datasets/' + datasetId + '/examples?offset=' + offset + '&count='+ count + resolveEinsteinExampleType(typeEnum));
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while (isExecuting()) {
			System.debug('Status is: ' + isExecuting() );
		}
		System.debug('Call getExamples has been executed.');
		if (!client.isError()) {
			Einstein_Example[] examples = (Einstein_Example[])client.getParser().readValueAs(Einstein_Example[].class);
			System.debug('Examples have been read.');
			return examples;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Starts the training of a Einstein_Dataset.
	 * @param datasetId
	 * The Einstein_Dataset id that should be trained.
	 * @param name
	 * The name of the Einstein_Dataset.
	 * @param epochs
	 * Optional. The number of training iterations, valid values are between 1-100. Set to 0 if you want to use the default.
	 * @param learningRate
	 * Optional. The learning rate, valid values are betweed 0.0001 and 0.01. Set to 0 if you want to use the default.
	 * @param trainParams
	 * Custom training parameters for the training.
	 *@param algorithm
	 * Optional.Intent V2 training algorithm
	 * @return
	 * An object of type Einstein_Model
	 */
	public Einstein_Model trainDataset(Long datasetId, String name, Integer epochs, Decimal learningRate, Einstein_TrainParams trainParams) {
		return trainDataset(datasetId, name, epochs, learningRate, trainParams, null);
	}

	public Einstein_Model trainDataset(Long datasetId, String name, Integer epochs, Decimal learningRate, Einstein_TrainParams trainParams, String algorithm) {
		System.debug('Starting trainDataset call with name ' + name);
		Einstein_HttpBodyPartTraining parts = new Einstein_HttpBodyPartTraining(datasetId, name, epochs, learningRate, trainParams, algorithm);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/train', parts.build());
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call trainDataset has been executed.');
		if (!client.isError()) {
			Einstein_Model model = (Einstein_Model)client.getParser().readValueAs(Einstein_Model.class);
			System.debug('New Model with id ' + model.modelId + ' has been created.');
			return model;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}


	/**
	 * Starts the retraining of a Einstein_Dataset.
	 * @param modelId
	 * The Einstein_Model id that should be retrained.
	 * @param epochs
	 * Optional. The number of training iterations, valid values are between 1-100. Set to 0 if you want to use the default.
	 * @param learningRate
	 * Optional. The learning rate, valid values are betweed 0.0001 and 0.01. Set to 0 if you want to use the default.
	 * @param trainParams
	 * Custom training parameters for the retraining.
	 * @param algorithm
	 * Optional. Intent V2 training algorithm
	 * @return
	 * An object of type Einstein_Model
	 */
	public Einstein_Model retrainDataset(String modelId, Integer epochs, Decimal learningRate, Einstein_TrainParams trainParams) {
		return retrainDataset(modelId, epochs, learningRate, trainParams, null);
	}

	public Einstein_Model retrainDataset(String modelId, Integer epochs, Decimal learningRate, Einstein_TrainParams trainParams, String algorithm) {
		System.debug('Starting retrainDataset call with name ' + modelId);
		Einstein_HttpBodyPartRetraining parts = new Einstein_HttpBodyPartRetraining(modelId, epochs, learningRate, trainParams, algorithm);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/retrain', parts.build());
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call retrainDataset has been executed.');
		if (!client.isError()) {
			Einstein_Model model = (Einstein_Model)client.getParser().readValueAs(Einstein_Model.class);
			System.debug('Model with id ' + model.modelId + ' has been retrained.');
			return model;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Fetches the model for the given id.
	 * @param modelId
	 * The id of the model that needs to be fetched.
	 * @return
	 * An object of type Einstein_Model
	 */
	public Einstein_Model getModel(String modelId) {
		System.debug('Starting getModel call with parameter ' + modelId);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/train/' + modelId);
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting() );
		}
		System.debug('Call getModel has been executed.');
		if (!client.isError()) {
			Einstein_Model model = (Einstein_Model)client.getParser().readValueAs(Einstein_Model.class);
			System.debug('Model status has been read.');
			return model;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}



	/**
	 * Gets the learning curve of a model.
	 *
	 * Let me explain....
	 * Originally, this class was written with the two getModelLearningCurve methods that return
	 * raw JSON string responses.  Converting to objects is left up to the client.  The Playground
	 * Lighting UI components were written to do that.  But getModelLearningCurve(modelId) only retrieved
	 * one page of epochs, which meant the confusion matrix displayed for any model with more than 25
	 * epochs was incorrect - it was always just the matrix from epoch 25.  This method was
	 * modified to enable the iteration over all
	 * pages of returned epochs and the merging the pages together into one return value... which could be really big.
	 *
	 * To further complicate matters, the learning curve for a language model returns a blank object for epochResults
	 * where a vision model returns an array of objects.
	 *
	 * @param modelId
	 * The model id for which the learning curve should be fetched.
	 * @return
	 * The JSON response as raw String
	 */
	public String getModelLearningCurve(String modelId) {
		final Integer pageSize = 25;
		Boolean done = false;
		Integer offset = 0;



		String lcs = '';

		// 12/1/19:   There is a bug in the vision learning curve endpoint that causes it to return the first
		//            page of results if the offset is greater than the number of epochs.  So, get the model training
		//            data and use the epoch number to know how many pages to get.
		//            Language learning curves return a blank array of lc's when the offset is greater than the number
		//            of epochs, so just read pages of epochs until no more are returned.
		//            HOWEVER: The model training data for language models always has a value of 1000 for epoch count.
		// 10/13/20:  Apparently, the language learning curve endpoint was changed to behave just like Vision -
		//            possibly around Language V2 and we didn't notice it until now.  Older models still behave the same way
		//            as they did on 12/1/19, but models trained more recently behave like vision models did in December.
		//            So, use one algorithm or the other based on if the epoch count is 1000.
		Einstein_Model modelInfo = getModel(modelId);
		System.debug('Model epochs: ' + modelInfo.epochs);

		if (modelInfo.epochs == 1000) {
			// Old Language models???
			while (!done) {
				String jsonValue = getModelLearningCurve(pageSize, offset, modelId);
				System.debug('start lcs: ' + lcs);

				if (lcs.length() == 0) {
					// First time through, so nothing in lcs
					lcs = jsonValue;
				} else {
					Integer previousEndArrayIndex = lcs.lastIndexOf(']');
					Integer newBeginArrayIndex = jsonValue.indexOf('[');
					Integer newEndArrayIndex = jsonValue.lastIndexOf(']');

					if ( newEndArrayIndex == newBeginArrayIndex + 1) {
						// The most recent page returned nothing
						done = true;
					} else {
						// Still more to get.  Concatinate what we got and prepare another loop
						lcs = lcs.left(previousEndArrayIndex) + ',' + jsonValue.substring(newBeginArrayIndex+1);
					}
				}

				System.debug('end lcs: ' + lcs);
				offset += pageSize;
			}

		} else {
			// Newer Language models and all Vision models???
			while (!done) {
				String jsonValue = getModelLearningCurve(pageSize, offset, modelId);
				System.debug('start lcs: ' + lcs);

				if (lcs.length() == 0) {
					// First time through, so nothing in lcs
					lcs = jsonValue;
				} else {
					Integer previousEndArrayIndex = lcs.lastIndexOf(']');
					Integer newBeginArrayIndex = jsonValue.indexOf('[');
					Integer newEndArrayIndex = jsonValue.lastIndexOf(']');

					lcs = lcs.left(previousEndArrayIndex) + ',' + jsonValue.substring(newBeginArrayIndex+1);
				}

				System.debug('end lcs: ' + lcs);
				offset += pageSize;
				if (offset > modelInfo.epochs) {
					done = true;
				}
			}
		
		}

		System.debug('returning lcs: ' + lcs);
		return lcs;
	}


	public String getModelLearningCurve(Integer count, Integer offset, String modelId) {
		System.debug('Starting getModelLearningCurve call with parameter ' + modelId);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/models/' + modelId + '/lc?offset=' + offset + '&count='+ count);
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting() );
		}
		System.debug('Call getModelLearningCurve has been executed.');
		if (!client.isError()) {
			String modelLearningCurve = client.getResponseAsString();
			System.debug('ModelLearningCurve has been read.');
			System.debug('modelLearningCurve: ' + modelLearningCurve);
			return modelLearningCurve;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Gets the metrics of a model.
	 * @param modelId
	 * The model id for which the metrics should be fetched.
	 * @return
	 * The JSON response as raw String
	 */
	public String getModelMetrics(String modelId) {
		System.debug('Starting getModelMetrics call with parameter ' + modelId);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/models/' + modelId);
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting() );
		}
		System.debug('Call getModelMetrics has been executed.');
		if (!client.isError()) {
			system.debug(client);
			String modelMetrics = client.getResponseAsString();
			System.debug('ModelMetrics have been read.');
			return modelMetrics;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Gets all trained Einstein_Models that are trained for the given Einstein_Dataset id.
	 * @param datasetId
	 * The Einstein_Dataset id to which the Einstein_Models are assigned.
	 * @return
	 * An array of type Einstein_Model
	 */
	public Einstein_Model[] getModels(Long datasetId) {
		System.debug('Starting getModels call');
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/datasets/' + datasetId + '/models');
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while (isExecuting()) {
			System.debug('Status is: ' + isExecuting() );
		}
		System.debug('Call getModels has been executed.');
		if (!client.isError()) {
			Einstein_Model[] models = (Einstein_Model[])client.getParser().readValueAs(Einstein_Model[].class);
			System.debug('Models have been read.');
			return models;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Predicts the intent of the given text to a trained model.
	 * @param modelId
	 * The id of the Einstein_Model that should be used for the prediction.
	 * @param text
	 * The text that should be predicted.
	 * @param numResults
	 * The number of results that should be max. returned.
	 * @param sampleId
	 * Optional, can be empty. A string that gets returned as an association with the predicted image.
	 * @return
	 * An object of type Einstein_PredictionResult.
	 */
	global Einstein_PredictionResult predictIntent(String modelId, String text, Integer numResults, String sampleId) {
		System.debug('Starting predict intent call with model ' + modelId);
		Einstein_HttpBodyPartPrediction parts = new Einstein_HttpBodyPartPrediction(modelId, text, null, null, numResults, sampleId, Einstein_HttpBodyPartPrediction.Types.DOCUMENT);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/intent', parts.build());
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call predict has been executed.');
		if (!client.isError()) {
			Einstein_PredictionResult predictions = (Einstein_PredictionResult)client.getParser().readValueAs(Einstein_PredictionResult.class);
			System.debug('Intent has been predicted.');
			return predictions;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Predicts the sentiment of the given text to a trained model.
	 * @param modelId
	 * The id of the Einstein_Model that should be used for the prediction.
	 * @param text
	 * The text that should be predicted.
	 * @param numResults
	 * The number of results that should be max. returned.
	 * @param sampleId
	 * Optional, can be empty. A string that gets returned as an association with the predicted image.
	 * @return
	 * An object of type Einstein_PredictionResult.
	 */
	global Einstein_PredictionResult predictSentiment(String modelId, String text, Integer numResults, String sampleId) {
		System.debug('Starting predict sentiment call with model ' + modelId);
		Einstein_HttpBodyPartPrediction parts = new Einstein_HttpBodyPartPrediction(modelId, text, null,  null, numResults, sampleId, Einstein_HttpBodyPartPrediction.Types.DOCUMENT);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/sentiment', parts.build());
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call predict has been executed.');
		if (!client.isError()) {
			Einstein_PredictionResult predictions = (Einstein_PredictionResult)client.getParser().readValueAs(Einstein_PredictionResult.class);
			System.debug('Image has been predicted.');
			return predictions;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Predicts the Natural Entity Recognition of the given text to a trained model.
	 * @param modelId
	 * The id of the Einstein_Model that should be used for the prediction.
	 * @param text
	 * The text that should be predicted.
	 * @param numResults
	 * The number of results that should be max. returned.
	 * @param sampleId
	 * Optional, can be empty. A string that gets returned as an association with the predicted image.
	 * @return
	 * An object of type Einstein_PredictionResult.
	 */
	global Einstein_PredictionResult predictNER(String modelId, String text, Integer numResults, String sampleId) {
		System.debug('Starting predict NER call with model ' + modelId);
		Einstein_HttpBodyPartPrediction parts = new Einstein_HttpBodyPartPrediction(modelId, text, null,  null, numResults, sampleId, Einstein_HttpBodyPartPrediction.Types.DOCUMENT);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/entities', parts.build());
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call predict has been executed.');
		if (!client.isError()) {
			// The response contains Apex reserved words "from" and "end"
			Map<String,String> replacements = new Map<String,String>
				{ 'end' => 'endx',
				  'from' => 'fromX'};
			client.replaceTokens(replacements);
			Einstein_PredictionResult predictions = (Einstein_PredictionResult)client.getParser().readValueAs(Einstein_PredictionResult.class);
			System.debug('NER has been predicted.');
			return predictions;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Detects objects in the given image in Base64 format based a trained model.
	 * @param model
	 * The Einstein_Model that should be used for the prediction.
	 * @param base64
	 * The image that should be used for detecting objects in it.
	 * @param numResults
	 * The number of results that should be max. returned.
	 * @param sampleId
	 * Optional. A string that gets returned as an association with the image.
	 * @return
	 * An object of type Einstein_PredictionResult.
	 */
	global Einstein_PredictionResult detectImageBase64(String modelId, String base64, Integer numResults, String sampleId) {
		System.debug('Starting detect call with model ' + modelId + ' for base64');
		Einstein_HttpBodyPartPrediction parts = new Einstein_HttpBodyPartPrediction(modelId, base64, null,  null, numResults, sampleId, Einstein_HttpBodyPartPrediction.Types.BASE64);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/detect', parts.build());
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call detect has been executed.');
		if (!client.isError()) {
			Einstein_PredictionResult predictions = (Einstein_PredictionResult)client.getParser().readValueAs(Einstein_PredictionResult.class);
			System.debug('Image has been detected.');
			return predictions;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Detects objects in the given image in Base64 format based a trained model.
	 * @param model
	 * The Einstein_Model that should be used for the prediction.
	 * @param fileBlob
	 * The image that should be used for detecting objects in it.
	 * @param numResults
	 * The number of results that should be max. returned.
	 * @param sampleId
	 * Optional. A string that gets returned as an association with the image.
	 * @return
	 * An object of type Einstein_PredictionResult.
	 */
	global Einstein_PredictionResult detectImageBlob(String modelId, Blob fileBlob, Integer numResults, String sampleId) {
		System.debug('Starting detect call with model ' + modelId + ' for blob');
		Einstein_HttpBodyPartPrediction parts = new Einstein_HttpBodyPartPrediction(modelId, EncodingUtil.base64Encode(fileBlob), null,  null, numResults, sampleId, Einstein_HttpBodyPartPrediction.Types.BASE64);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/detect', parts.build());
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call predict has been executed.');
		if (!client.isError()) {
			Einstein_PredictionResult predictions = (Einstein_PredictionResult)client.getParser().readValueAs(Einstein_PredictionResult.class);
			System.debug('Image has been detected.');
			return predictions;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Detects objects in the given image in Base64 format based a trained model.
	 * @param model
	 * The Einstein_Model that should be used for the prediction.
	 * @param url
	 * The image url that should be used for detecting objects in it.
	 * @param numResults
	 * The number of results that should be max. returned.
	 * @param sampleId
	 * Optional. A string that gets returned as an association with the image.
	 * @return
	 * An object of type Einstein_PredictionResult.
	 */
	global Einstein_PredictionResult detectImageUrl(String modelId, String url, Integer numResults, String sampleId) {
		System.debug('Starting detect call with model ' + modelId + ' for url');
		Einstein_HttpBodyPartPrediction parts = new Einstein_HttpBodyPartPrediction(modelId, url, null,  null, numResults, sampleId, Einstein_HttpBodyPartPrediction.Types.URL);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/detect', parts.build());
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call predict has been executed.');
		if (!client.isError()) {
			Einstein_PredictionResult predictions = (Einstein_PredictionResult)client.getParser().readValueAs(Einstein_PredictionResult.class);
			System.debug('Image has been detected.');
			return predictions;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Detects objects in the given image in Base64 format based a trained model.
	 * @param model
	 * The Einstein_Model that should be used for the prediction.
	 * @param base64
	 * The image that should be used for detecting objects in it.
	 * @param task
	 * "text", "contact" or "table" or "form".  Default is "text"
	 * @param formType
	 * Only valid if task is "form"
	 * dl, w2, permanentResident, paystub, 1040, k1, passport
	 * @param numResults
	 * This parameter does not apply to OCR predictions
	 * @param sampleId
	 * Optional. A string that gets returned as an association with the image.
	 * @return
	 * An object of type Einstein_PredictionResult.
	 */
	global Einstein_PredictionResult predictOcrBase64(String modelId, String base64, String sampleId) {
		return predictOcrBase64(modelId, base64, 'text', null, 0, sampleId);
	}

	global Einstein_PredictionResult predictOcrBase64(String modelId, String base64, String task, String sampleId) {
		return predictOcrBase64(modelId, base64, task, null, 0, sampleId);
	}

	global Einstein_PredictionResult predictOcrBase64(String modelId, String base64, String task, String formType, String sampleId) {
		return predictOcrBase64(modelId, base64, task, formType, 0, sampleId);
	}

	global Einstein_PredictionResult predictOcrBase64(String modelId, String base64, Integer numResults, String sampleId) {
		return predictOcrBase64(modelId, base64, 'text', null, numResults, sampleId);
	}

	global Einstein_PredictionResult predictOcrBase64(String modelId, String base64, String task, Integer numResults, String sampleId) {
		return predictOcrBase64(modelId, base64, task, null, numResults, sampleId);
	}

	global Einstein_PredictionResult predictOcrBase64(String modelId, String base64, String task, String formType, Integer numResults, String sampleId) {
		System.debug('Starting OCR call with model ' + modelId + ' for base64');
		Einstein_HttpBodyPartPrediction parts = new Einstein_HttpBodyPartPrediction(modelId, base64, task, formType, numResults, sampleId, Einstein_HttpBodyPartPrediction.Types.BASE64);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/ocr', parts.build());
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call predict ocr has been executed.');
		if (!client.isError()) {
			Einstein_PredictionResult predictions = (Einstein_PredictionResult)client.getParser().readValueAs(Einstein_PredictionResult.class);
			System.debug('OCR has been detected.');
			return predictions;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}


	/**
	 * Detects objects in the given image in Base64 format based a trained model.
	 * @param model
	 * The Einstein_Model that should be used for the prediction.
	 * @param url
	 * The image url that should be used for detecting objects in it.
	 * @param task
	 * "text", "contact" or "table"
	 * @param formType
	 * Only valid if task is "form"
	 * dl, w2, permanentResident, paystub, 1040, k1, passport
	 * @param numResults
	 * The number of results that should be max. returned.
	 * @param sampleId
	 * Optional. A string that gets returned as an association with the image.
	 * @return
	 * An object of type Einstein_PredictionResult.
	 */
	global Einstein_PredictionResult predictOcrUrl(String modelId, String url, String sampleId) {
		return predictOcrUrl(modelId, url, 'text', null, 0, sampleId);
	}

	global Einstein_PredictionResult predictOcrUrl(String modelId, String url, String task, String sampleId) {
		return predictOcrUrl(modelId, url, task, null, 0, sampleId);
	}

	global Einstein_PredictionResult predictOcrUrl(String modelId, String url, String task, String formType, String sampleId) {
		return predictOcrUrl(modelId, url, task, null, 0, sampleId);
	}

	global Einstein_PredictionResult predictOcrUrl(String modelId, String url, Integer numResults, String sampleId) {
		return predictOcrUrl(modelId, url, 'text', null, numResults, sampleId);
	}

	global Einstein_PredictionResult predictOcrUrl(String modelId, String url, String task, Integer numResults, String sampleId) {
		return predictOcrUrl(modelId, url, task, null, numResults, sampleId);
	}

	global Einstein_PredictionResult predictOcrUrl(String modelId, String url, String task, String formType, Integer numResults, String sampleId) {
		System.debug('Starting ocr call with model ' + modelId + ' for url');
		Einstein_HttpBodyPartPrediction parts = new Einstein_HttpBodyPartPrediction(modelId, url, task, formType, numResults, sampleId, Einstein_HttpBodyPartPrediction.Types.URL);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/ocr', parts.build());
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call predict ocr has been executed.');
		if (!client.isError()) {
			Einstein_PredictionResult predictions = (Einstein_PredictionResult)client.getParser().readValueAs(Einstein_PredictionResult.class);
			System.debug('Ocr has been detected.');
			return predictions;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Predicts the association of the given image in Base64 format to a trained model.
	 * @param model
	 * The Einstein_Model that should be used for the prediction.
	 * @param base64
	 * The image that should be predicted.
	 * @param numResults
	 * The number of results that should be max. returned.
	 * @param sampleId
	 * Optional. A string that gets returned as an association with the predicted image.
	 * @return
	 * An object of type Einstein_PredictionResult.
	 */
	global Einstein_PredictionResult predictImageBase64(String modelId, String base64, Integer numResults, String sampleId) {
		System.debug('Starting predict call with model ' + modelId + ' for base64');
		Einstein_HttpBodyPartPrediction parts = new Einstein_HttpBodyPartPrediction(modelId, base64, null,  null, numResults, sampleId, Einstein_HttpBodyPartPrediction.Types.BASE64);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/predict', parts.build());
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call predict has been executed.');
		if (!client.isError()) {
			Einstein_PredictionResult predictions = (Einstein_PredictionResult)client.getParser().readValueAs(Einstein_PredictionResult.class);
			System.debug('Image has been predicted.');
			return predictions;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Predicts the association of the given image as Blob to a trained model.
	 * @param modelId
	 * The Einstein_Model that should be used for the prediction.
	 * @param fileBob
	 * The image that should be predicted.
	 * @param numResults
	 * The number of results that should be max. returned.
	 * @param sampleId
	 * Optional. A string that gets returned as an association with the predicted image.
	 * @return
	 * An object of type Einstein_PredictionResult.
	 */
	global Einstein_PredictionResult predictImageBlob(String modelId, Blob fileBlob, Integer numResults, String sampleId) {
		System.debug('Starting predict call with model ' + modelId + ' for blob');
		Einstein_HttpBodyPartPrediction parts = new Einstein_HttpBodyPartPrediction(modelId, EncodingUtil.base64Encode(fileBlob), null,  null, numResults, sampleId, Einstein_HttpBodyPartPrediction.Types.BASE64);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/predict', parts.build());
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call predict has been executed.');
		if (!client.isError()) {
			Einstein_PredictionResult predictions = (Einstein_PredictionResult)client.getParser().readValueAs(Einstein_PredictionResult.class);
			System.debug('Image has been predicted.');
			return predictions;
		}
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Predicts the association of the given image on a remote url to a trained model.
	 * @param modelId
	 * The Einstein_Model that should be used for the prediction.
	 * @param url
	 * The image url that should be predicted.
	 * @param numResults
	 * The number of results that should be max. returned.
	 * @param sampleId
	 * Optional. A string that gets returned as an association with the predicted image.
	 * @return
	 * An object of type Einstein_PredictionResult.
	 */
	global Einstein_PredictionResult predictImageUrl(String modelId, String url, Integer numResults, String sampleId) {
		System.debug('Starting predict call with model ' + modelId + ' for url');
		Einstein_HttpBodyPartPrediction parts = new Einstein_HttpBodyPartPrediction(modelId, url, null,  null, numResults, sampleId, Einstein_HttpBodyPartPrediction.Types.URL);
		Einstein_HttpClient client = new Einstein_HttpClient(this, '/predict', parts.build());
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while(isExecuting()) {
			System.debug('Status is: ' + isExecuting());
		}
		System.debug('Call predict has been executed.');
		if (!client.isError()) {
			Einstein_PredictionResult predictions = (Einstein_PredictionResult)client.getParser().readValueAs(Einstein_PredictionResult.class);
			System.debug('Image has been predicted.');
			return predictions;
		}

		System.debug('--- errors ---- ' + client.getStatusCode() + ' ' + client.getResponseError());
		handleError(client.getStatusCode(), client.getResponseError());
		return null;
	}

	/**
	 * Fetches data about the API usage of the authenticated PredictionService.
	 * @return
	 * An array of all Einstein_ApiUsage elements.
	 */
	public Einstein_ApiUsage[] getApiUsage() {
		System.debug('Starting getApiUsage call');
		Einstein_HttpClient client = new Einstein_HttpClient(this, API_USAGE);
		System.debug('Target URL is ' + client.getUrl());
		client.execute();
		while (isExecuting()) {
			System.debug('Status is: ' + isExecuting() );
		}
		System.debug('Call getApiUsage has been executed.');
		System.debug(client.getStatusCode() + '  ' + client.getResponseAsString());
		Einstein_ApiUsage[] apiUsage;
		if (!client.isError()) {
			try {
				apiUsage = (Einstein_ApiUsage[])client.getParser().readValueAs(Einstein_ApiUsage[].class);
				System.debug('API usage has been fetched.');
			} catch (JSONException e) {
				// If the account has not yet been used, the API returns a null array instead of
				// an ApiUsage with zero used.  Catch the JSON parsing error here and return a
				// dummy usage element in the array.
				Einstein_ApiUsage dummy = new Einstein_ApiUsage();
				dummy.startsAt = '';
				dummy.endsAt = '';
				dummy.predictionsUsed = 0;
				dummy.predictionsMax = 0;
				dummy.predictionsRemaining = 0;
				apiUsage = new Einstein_ApiUsage[] {dummy};
			}
			return apiUsage;
		}

		handleError(client.getStatusCode(), client.getResponseError());
		return null;

	}

	/**
	 *
	 * @return
	 */
	global boolean isExecuting() {
		return isExecuting;
	}

	/**
	 *
	 * @param isExecuting
	 */
	public void isExecuting(boolean isExecuting) {
		this.isExecuting = isExecuting;
	}

	/**
	 *
	 * @param message
	 */
	private void handleError(Integer statusCode, String message) {
		httpStatusCode = statusCode;
		httpErrorMessage = message;
		System.debug(LoggingLevel.Error, 'Response finished with Error: ' + message + ' (status code: ' + statusCode + ')');
	}

	/**
	 * Sets the Type of the Einstein_PredictionService
	 * @param typeEnum
	 * Value of type Einstein_PredictionService.Types
	 */
	global void setType(Types typeEnum) {
		this.typeEnum = typeEnum;
		this.baseUrl = resolveBaseUrl();
		this.typeString = resolveType();
	}

	/**
	 * Sets the Language of the Einstein_PredictionService
	 * @param langEnum
	 * Value of type Einstein_PredictionService.Languages
	 */
	global void setLanguage(Languages langEnum) {
		this.langEnum = langEnum;
		this.langString = resolveLang();
	}

	private String resolveLang() {
		if (this.langEnum == Einstein_PredictionService.Languages.ENGLISH_US) {
			return 'en_US';
		} else if (this.langEnum == Einstein_PredictionService.Languages.ENGLISH_UK) {
			return 'en_GB';
		} else if (this.langEnum == Einstein_PredictionService.Languages.FRENCH) {
			return 'fr';
		} else if (this.langEnum == Einstein_PredictionService.Languages.GERMAN) {
			return 'de';
		} else if (this.langEnum == Einstein_PredictionService.Languages.ITALIAN) {
			return 'it';
		} else if (this.langEnum == Einstein_PredictionService.Languages.PORTUGUESE) {
			return 'pt_PT';
		} else if (this.langEnum == Einstein_PredictionService.Languages.SPANISH) {
			return 'es';
		} else if (this.langEnum == Einstein_PredictionService.Languages.CHINESE_SIMPLIFIED) {
			return 'zh_CN';
		} else if (this.langEnum == Einstein_PredictionService.Languages.CHINESE_TRADITIONAL) {
			return 'zh_TW';
		} else if (this.langEnum == Einstein_PredictionService.Languages.JAPANESE) {
			return 'ja';
		}
		return '';
	}

	private String resolveType() {
		if (this.typeEnum == Einstein_PredictionService.Types.IMAGE) {
			return 'image';
		} else if (this.typeEnum == Einstein_PredictionService.Types.IMAGE_MULTI_LABEL) {
			return 'image-multi-label';
		} else if (this.typeEnum == Einstein_PredictionService.Types.IMAGE_DETECTION) {
			return 'image-detection';
		} else if (this.typeEnum == Einstein_PredictionService.Types.SENTIMENT) {
			return 'text-sentiment';
		} else if (this.typeEnum == Einstein_PredictionService.Types.INTENT) {
			return 'text-intent';
		} else if (this.typeEnum == Einstein_PredictionService.Types.NER) {
			return 'text-ner';
		} else if (this.typeEnum == Einstein_PredictionService.Types.OCR) {
			return 'ocr';
		}
		return '';
	}

	private String resolveBaseUrl() {
		if (this.typeEnum == Einstein_PredictionService.Types.IMAGE) {
			return BASE_URL + '/vision';
		} else if (this.typeEnum == Einstein_PredictionService.Types.IMAGE_MULTI_LABEL) {
			return BASE_URL + '/vision';
		} else if (this.typeEnum == Einstein_PredictionService.Types.IMAGE_DETECTION) {
			return BASE_URL + '/vision';
		} else if (this.typeEnum == Einstein_PredictionService.Types.SENTIMENT) {
			return BASE_URL + '/language';
		} else if (this.typeEnum == Einstein_PredictionService.Types.INTENT) {
			return BASE_URL + '/language';
		} else if (this.typeEnum == Einstein_PredictionService.Types.NER) {
			return BASE_URL + '/language';
		} else if (this.typeEnum == Einstein_PredictionService.Types.OCR) {
			return BASE_URL + '/vision';
		}
		return '';
	}

	private String resolveEinsteinDatasetType(Einstein_Dataset.Types typeEnum) {
		if (typeEnum == Einstein_Dataset.Types.ALL) {
			return '&type=all';
		} else if (typeEnum == Einstein_Dataset.Types.FEEDBACK) {
			return '&type=feedback';
		} else if (typeEnum == Einstein_Dataset.Types.UPLOAD) {
			return '&type=upload';
		}
		return '';
	}

	private String resolveEinsteinExampleType(Einstein_Example.Types typeEnum) {
		if (typeEnum == Einstein_Example.Types.ALL) {
			return '&type=all';
		} else if (typeEnum == Einstein_Example.Types.FEEDBACK) {
			return '&type=feedback';
		} else if (typeEnum == Einstein_Example.Types.UPLOAD) {
			return '&type=upload';
		}
		return '';
	}


	/**
	 *
	 * @return
	 */
	public String getBearerToken() {
		return bearerToken;
	}

	public static String getAccessToken() {
		// Try to retrieve settings
		einsteinplay__Einstein_Settings__c settings = new einsteinplay__Einstein_Settings__c();
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

		Map<String,Schema.SObjectField> m = Schema.SObjectType.einsteinplay__Einstein_Settings__c.fields.getMap();

		String queryString = 'SELECT Id';
		for (String fieldToCheck : settingsInsertFields) {
			// Check if the user has create access on the each field
			if (!m.get(fieldToCheck).getDescribe().isAccessible()) {
				throw new System.NoAccessException();
			}
			queryString += ', ' + fieldToCheck;
		}
		queryString += ' FROM einsteinplay__Einstein_Settings__c LIMIT 1';

		try {
			settings = Database.query(queryString);
		} catch (Exception e) {
			throw new Einstein_ConfigurationException('Go to Setup and Configuration on the Einstein Admin tab to configure access to your Einstein.ai account');
		}


		// Reassemble the certificate
		Integer index = 0;
		String encryptedDataString = '';
		for (Integer iteration = 1; iteration < 10; iteration++ ) {
			encryptedDataString += settings.get('einsteinplay__certificate_part_' + iteration + '__c');
		}
		Blob encryptedCertificate = EncodingUtil.base64Decode(encryptedDataString);

       
      	Einstein_JWT jwt = new Einstein_JWT('RS256');
        String accessToken = '';

        if (!Test.isRunningTest()) {

            if (settings.einsteinplay__Einstein_EMail__c == null) {
                throw new Einstein_ConfigurationException('Missing Einstein email setting. Check settings under the Einstein Admin tab.');
            }

                
				
			//Einstein_Settings__c es = [SELECT id,CertName__c, Einstein_EMail__c, Secret_Key__c FROM Einstein_Settings__c LIMIT 1]; 
				
            Blob cryptoKey = EncodingUtil.base64Decode(settings.einsteinplay__Secret_Key__c); 

            Blob decryptedData = Crypto.decryptWithManagedIV('AES128', cryptoKey, encryptedCertificate);
            String decryptedDataString = decryptedData.toString();
 			String keyContents = decryptedDataString; 
                
            //String keyContents = base64Content.VersionData.tostring();
            keyContents = keyContents.replace('-----BEGIN RSA PRIVATE KEY-----', '');
            keyContents = keyContents.replace('-----END RSA PRIVATE KEY-----', '');
            keyContents = keyContents.replace('\n', '');
            jwt.pkcs8 = keyContents;

            // Get a new token
            jwt.iss = 'developer.force.com';
            jwt.sub = settings.einsteinplay__Einstein_EMail__c;
            jwt.aud = OAUTH2;
            jwt.exp = '3600';      
        
            accessToken = Einstein_JWTBearerFlow.getAccessToken(OAUTH2, jwt);
        }

        return accessToken;
    }

}