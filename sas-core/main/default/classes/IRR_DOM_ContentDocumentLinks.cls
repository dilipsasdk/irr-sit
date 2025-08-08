public class IRR_DOM_ContentDocumentLinks extends fflib_SObjectDomain implements IRR_DOM_IContentDocumentLinks{
    

    public static IRR_DOM_IContentDocumentLinks  newInstance(List<SObject> sObjectList) {
        return (IRR_DOM_IContentDocumentLinks) IRR_Application.Domain.newInstance(sObjectList);
    }

    
    public Map<Id, String> getBodyAsStringByLinkedEntityId (){
        Map <Id, String> bodyAsString = new Map<Id, String>();
        for(ContentDocumentLink file : (List<ContentDocumentLink>) Records){
            Blob FileBody = file.ContentDocument.LatestPublishedVersion.VersionData;
            String attachmentAsString = FileBody.toString();
            bodyAsString.put(file.LinkedEntityId, attachmentAsString);
        }
        return bodyAsString;
    }

public IRR_DOM_ContentDocumentLinks(List<SObject> records) {
        super(records);
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new IRR_DOM_ContentDocumentLinks(records);
        }
    }

}