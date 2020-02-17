public with sharing class Einstein_HttpBodyPartDatasetUrl extends Einstein_HttpBodyPart {

    private String url;
    private String type;
    private String language;
    
    public Einstein_HttpBodyPartDatasetUrl(String url, String type)  {
	    setUrl(url);
	    setType(type);
    }

    public Einstein_HttpBodyPartDatasetUrl(String url, String type, String language)  {
	    setUrl(url);
        setType(type);
        setLanguage(language);
    }

    public Blob build() {
        String body = '';
        body += WriteBoundary();
        body += WriteBodyParameter('path', url);
        body += WriteBoundary();
        body += WriteBodyParameter('type', type);
        if (!String.isBlank(language)) {
            body += WriteBoundary();
            body += WriteBodyParameter('language', language);
        }
        body += WriteBoundary(EndingType.CrLf);
        Blob bodyBlob = EncodingUtil.base64Decode(body);
        return bodyBlob;
    }
    
    public String getUrl() {
        return url;
    }

    public void setUrl(String url)  {
        if (String.isEmpty(url)) {
            throw new Einstein_StringIsEmptyException('url');
        }
        this.url = url;
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

}