/**
* @author Chetan Singh, CoforgeTech
* @date 2021
*
*/
public class IRR_SEL_ContentDocumentLinksSelector extends fflib_SObjectSelector implements IRR_SEL_IContentDocumentLinksSelector{
   

    public static IRR_SEL_IContentDocumentLinksSelector newInstance() {
        return (IRR_SEL_IContentDocumentLinksSelector) 
                IRR_Application.Selector.newInstance(ContentDocumentLink.SObjectType);
    }


    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>
        {
                ContentDocumentLink.fields.Id,
                ContentDocumentLink.fields.ContentDocumentId,
                ContentDocumentLink.fields.LinkedEntityId
        };
    }

     public Schema.SObjectType getSObjectType() {
        return ContentDocumentLink.SObjectType;
    }

    public List<ContentDocumentLink> selectByLinkedEntityId (Set<Id> IdSet) {
        fflib_QueryFactory queryFactory = newQueryFactory ()
            .selectField('ContentDocument.LatestPublishedVersion.VersionData')
            .setCondition('LinkedEntityId IN :IdSet');

        List<ContentDocumentLink> contentDocumentLinkRecords = Database.query(queryFactory.toSOQL());
        return contentDocumentLinkRecords;
    }
}