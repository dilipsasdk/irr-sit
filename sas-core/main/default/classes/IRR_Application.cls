/**
* @author Niklas Lundkvist, Deloitte
* @date 2022
*
* @description Application specific configuration for various factories.
*/

public class IRR_Application {

    public enum MessageType { SMS, Email }

    public enum IntegrationType { REST, SOAP }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Configure and create the IntegrationExecutorBuilder for this Application.
     */
    public static final C_Application.IntegrationExecutorBuilderFactory IntegrationExecutorBuilder =
            new C_Application.IntegrationExecutorBuilderFactory(
                    new Map<Object, Type> {
                            IntegrationType.REST => C_IntegrationExecutorRest.Constructor.class
                    }
            );

    public static final C_Application.MessageRendererFactory MessageRenderer =
            new C_Application.MessageRendererFactory();

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Configure and create the SelectorFactory for this Application.
     */
    public static final fflib_Application.SelectorFactory Selector =
            new fflib_Application.SelectorFactory(
                    new Map<SObjectType, Type> {
                            EmailTemplate.SObjectType => IRR_SEL_EmailTemplatesSelector.class,
                            IRR_EventLog__c.SObjectType =>IRR_SEL_EventLogsSelector.class,
                            IRR_CommunicationLog__c.SObjectType => IRR_SEL_CommunicationLogsSelector.class,
                            IRR_SMSResponse__c.SObjectType => IRR_SEL_SMSResponsesSelector.class,
                            IRR_DelayLog__c.SObjectType => IRR_SEL_DelayLogsSelector.class,
                            IRR_ManualCommunicationTemplate__mdt.SObjectType => IRR_SEL_ManualTemplatesSelector.class,
                            IRR_ManualOverride__c.SObjectType => IRR_SEL_ManualOverridesSelector.class,
                            IRR_RecipientWhitelist__mdt.SObjectType => IRR_SEL_RecipientWhitelistSelector.class,
                            Organization.SObjectType => IRR_SEL_OrganizationSelector.class,
                            SFMC_SMSDefinition__mdt.SObjectType => IRR_SEL_SMSDefinitionsSelector.class,
                            ContentDocumentLink.SObjectType =>IRR_SEL_ContentDocumentLinksSelector.class,
                            IRR_AutomatedMessage__mdt.SObjectType =>IRR_SEL_AutomatedMessagesSelector.class,
                            IRR_Icoupon_Voucher__mdt.SObjectType =>IRR_SEL_IcouponVoucherSelector.class,
                            IRR_AutomatedNoHandBag__mdt.SObjectType =>IRR_SEL_AutomatedNoHandBagSelector.class,
                            IRR_Manual_Airport_Timezone__mdt.SObjectType =>IRR_SEL_ManualAirportTimezone.class,
                            IRR_Manual_Icoupon_Voucher__mdt.SObjectType =>IRR_SEL_ManualIcouponVoucherSelector.class,
                            IRR_LoungeAccessQRCode__c.SObjectType =>IRR_SEL_LoungeAccessQRCodeSelector.class,
                            IRR_Constant__mdt.SObjectType =>IRR_SEL_ConstantSelector.class,
                            IRR_Standalone_Icoupon_Voucher__mdt.SObjectType => IRR_SEL_StandaloneIcouponSelector.class,
                            Automated_Message_Outbound__mdt.SObjectType => IRR_SEL_AutomatedMessageSelector.class
                    }
            );

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Configure and create the DomainFactory for this Application
     */
    public static final fflib_Application.DomainFactory Domain =
            new fflib_Application.DomainFactory(
                    IRR_Application.Selector,
                    new Map<SObjectType, Type> {
                            IRR_CommunicationLog__c.SObjectType => IRR_DOM_CommunicationLogs.Constructor.class,
                            IRR_SMSResponse__c.SObjectType => IRR_DOM_SMSResponses.Constructor.class,
                            IRR_EventLog__c.SObjectType => IRR_DOM_EventLogs.Constructor.class,
                            ContentDocumentLink.SObjectType => IRR_DOM_ContentDocumentLinks.Constructor.class
                    });

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Configure and create the ServiceFactory for this Application.
     */
    public static final fflib_Application.ServiceFactory Service =
            new fflib_Application.ServiceFactory(
                    new Map<Type, Type>{
                            IRR_SVC_ICommunicationService.class => IRR_SVC_CommunicationServiceImpl.class,
                            IRR_SVC_ISFMCService.class => IRR_SVC_SFMCServiceImpl.class,
                            IRR_SVC_ITedsService.class => IRR_SVC_TedsServiceImpl.class,
                            IRR_SVC_ILogsService.class => IRR_SVC_LogsServiceImpl.class,
                            IRR_SVC_IICouponService.Class =>IRR_SVC_ICouponServiceImpl.class,
                            IRR_SVC_IShortenURLService.Class =>IRR_SVC_ShortenURLServiceImpl.class
                            
                    }
            );

    public static final C_Application.EventProcessorFactory EventProcessor =
            new C_Application.EventProcessorFactory(
                    new Map<String, C_Application.EventDefinition> {
                            'bookingItineraryUpdateSASDisruption' => new C_Application.EventDefinition(
                                    IRR_MOD_RebookInfo.class, IRR_EVT_RebookProcessor.Constructor.class),
                            'bookingItineraryUpdateSASScheduleChange' => new C_Application.EventDefinition(
                                    IRR_MOD_ScheduledChangeInfo.class, IRR_EVT_ScheduledChangeProcessor.Constructor.class),
                            'flightDelayDeparture' => new C_Application.EventDefinition(
                                    IRR_MOD_DelayInfo.class, IRR_EVT_DelayProcessor.Constructor.class),
                            'flightNewInfoDeparture' => new C_Application.EventDefinition(
                                    IRR_MOD_NewInfo.class, IRR_EVT_NewInfoProcessor.Constructor.class),
                            'flightCancellation' => new C_Application.EventDefinition(
                                    IRR_MOD_CancelInfo.class, IRR_EVT_CancelProcessor.Constructor.class),
                            'manualCommunication' => new C_Application.EventDefinition(
                                    IRR_MOD_ManualRequest.class, IRR_EVT_ManualProcessor.Constructor.class),
                            'automatedCommunication' => new C_Application.EventDefinition(
                                    IRR_MOD_AutomatedRequest.class, IRR_EVT_AutomatedProcessor.Constructor.class),
                            'NoAlternativeUN' => new C_Application.EventDefinition(
                                    IRR_MOD_NoRebookInfo.class, IRR_EVT_NoRebookProcessor.Constructor.class),
                            'bookingItineraryUpdateSASAirportChange' => new C_Application.EventDefinition(
                                    IRR_MOD_AirportChangeInfo.class, IRR_EVT_AirportChangeProcessor.Constructor.class) 
                    }
            );


    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2019
     *
     * @description Configure and create the UnitOfWorkFactory for this Application
     */
    public static final fflib_Application.UnitOfWorkFactory UnitOfWork =
            new fflib_Application.UnitOfWorkFactory(
                    new List<SObjectType> {
                            IRR_DelayLog__c.SObjectType,
                            IRR_EventLog__c.SObjectType,
                            IRR_CommunicationLog__c.SObjectType,
                            IRR_SMSResponse__c.SObjectType,
                            IRR_LoungeAccessQRCode__c.SObjectType
                    });
}