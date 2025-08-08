public interface IRR_SEL_IContentDocumentLinksSelector extends fflib_ISObjectSelector {
    
    List<ContentDocumentLink> selectByLinkedEntityId (Set<Id> IdSet);
}