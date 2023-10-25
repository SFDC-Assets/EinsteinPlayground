public with sharing class Einstein_HttpBodyPartDatasetFile extends Einstein_HttpBodyPart {

    private String name;
    private String type;
    private String language;
    private String data;
    
    public Einstein_HttpBodyPartDatasetFile(String type)  {
	    setType(type);
    }

    public Einstein_HttpBodyPartDatasetFile(String name, String type, String language, String data)  {
        setName(name);
        setType(type);
        setLanguage(language);
        setData(data);
    }

    public Blob build() {
        String body = '';
        body += WriteBoundary();
        body += WriteBodyParameter('type', type);
        if (!String.isBlank(language)) {
            body += WriteBoundary();
            body += WriteBodyParameter('language', language);
        }
        body += WriteBoundary();
        body += WriteBlobBodyParameter('data', data, name);
        Blob bodyBlob = EncodingUtil.base64Decode(body);
        System.debug('bodyBlob is ' + bodyBlob.toString());
        return bodyBlob;
    }
    
    public String getName() {
        return name;
    }

	public void setName(String name) {
        if (!String.isEmpty(name)) {
            if (name.length()>180) {
                throw new Einstein_StringTooLongException('name', 180, name.length());
            }
        }
        this.name = name;
    }

    public String getType() {
	    return type;
    }

    public void setType(String type)  {
	    if (String.isEmpty(type)) {
		    throw new Einstein_StringIsEmptyException('type');
	    }
	    this.type = type;
    }

    public String getLanguage() {
	    return language;
    }

    public void setLanguage(String language)  {
	    if (!String.isEmpty(language)) {
    	    this.language = language;
	    }
    }

    public String getData() {
        return data;
    }

	public void setData(String data) {
        if (String.isEmpty(data)) {
            throw new Einstein_StringIsEmptyException('data');
        }
        this.data = data;
    }

}