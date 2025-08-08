/**
 * @author Philip Ossler
 * @date 2020-04-22
 * @description Class for Take Ownership and Remove Ownership buttons in Social Post List Views
 */
public with sharing class FCS_SocialPostController {
    /**
     * @param setCon Variable for passing the current listview
     * @param retUrl Url to return to after performed action
     */
    ApexPages.StandardSetController setCon;
    String retUrl;

    public FCS_SocialPostController(ApexPages.StandardSetController controller) {
        retUrl = ApexPages.currentPage().getParameters().get('vfRetURLInSFX');
        if(Test.isRunningTest()) {
            String listView = [SELECT Id FROM ListView WHERE SobjectType = 'SocialPost' LIMIT 1].Id;
            retUrl = Url.getSalesforceBaseUrl().toExternalForm() + '/lightning/o/SocialPost/list?filterName=' + listView;
        }
        System.debug('URL to redirect: ' + retUrl);
        setCon = controller;
    }

    /**
     * Used to take over ownership of SocialPost to current User
     * @return If selected Social Post/s return to previous listview otherwise cancel action
     */
    public PageReference takeOwnership() {
        System.debug('Action Take Ownership executing');
        List<SocialPost> spIds = (List<SocialPost>) setCon.getSelected();
        System.debug(spIds);

        if(!spIds.isEmpty()) {
            List<SocialPost> spToUpdate = new List<SocialPost>();

            for(SocialPost sp : [SELECT Id, OwnerId, FCS_PreviousQueue__c FROM SocialPost WHERE Id IN :spIds]) {
                sp.OwnerId = UserInfo.getUserId();
                spToUpdate.add(sp);
            }
            update spToUpdate;
    
            //Redirect user to listview
            System.debug('Redirecting to listview');
            PageReference pageRef = new PageReference(retUrl);
            return pageRef;
        } else {
            System.debug('No selected records');
            return setCon.cancel();
        }
    }

    /**
     * Used to remove ownership of SocialPost and assign it back to queue
     * @return If selected Social Post/s return to previous listview otherwise cancel action
     */
    public PageReference removeOwnership() {
        System.debug('Action Remove Ownership executing');
        List<SocialPost> spIds = (List<SocialPost>) setCon.getSelected();
        System.debug(spIds);

        if(!spIds.isEmpty()) {
            List<SocialPost> spToUpdate = new List<SocialPost>();

            for(SocialPost sp : [SELECT Id, OwnerId, FCS_PreviousQueue__c FROM SocialPost WHERE Id IN :spIds]) {
                if(sp.FCS_PreviousQueue__c != null) {
                    sp.OwnerId = sp.FCS_PreviousQueue__c;
                    spToUpdate.add(sp);
                }
            }
            update spToUpdate;

            //Redirect user to listview
            System.debug('Redirecting to listview');
            PageReference pageRef = new PageReference(retUrl);
            return pageRef;            
        } else {
            System.debug('No selected records');
            return setCon.cancel();
        }
    }
}
