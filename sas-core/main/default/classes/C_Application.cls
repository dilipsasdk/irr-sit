/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Contains factory methods for various objects.
*/

public class C_Application {

    public class MessageRendererFactory {
        MSG_IRenderer rendererMock;
        MSG_ITemplateCache templateCacheMock;

        public MSG_IRenderer newInstance(Set<String> templateNames) {
            MSG_ITemplateCache templateCache = templateCacheMock != null ? templateCacheMock :
                    (MSG_ITemplateCache) new MSG_TemplateCache();
            templateCache.loadTemplates(templateNames);
            if (rendererMock!=null) {
                return rendererMock;
            }
            return (MSG_IRenderer) new MSG_RendererEnhanced(templateCache);
        }

        public void setMock(MSG_IRenderer rendererMock) {
            this.rendererMock = rendererMock;
        }

        public void setMock(MSG_ITemplateCache templateCacheMock) {
            this.templateCacheMock = templateCacheMock;
        }
    }

    public class IntegrationExecutorBuilderFactory {

        Map<Object, Type> implementationsByTypeKey = new Map<Object, Type>();

        Map<Object, C_IIntegrationExecutorBuilder> mockInstancesByTypeKey =
                new Map<Object, C_IIntegrationExecutorBuilder>();

        public IntegrationExecutorBuilderFactory(Map<Object, Type> implementationMap) {
            this.implementationsByTypeKey = implementationMap;
        }

        public C_IIntegrationExecutorBuilder newInstance(Object typeKey) {

            if (mockInstancesByTypeKey.containsKey(typeKey)) {
                return mockInstancesByTypeKey.get(typeKey);
            }

            Type builderType = implementationsByTypeKey.get(typeKey);
            if (builderType==null) {
                throw new DeveloperException('No implementation registered for key ' + String.valueOf(typeKey));
            }

            return (C_IIntegrationExecutorBuilder) new C_IntegrationExecutorBuilder(builderType);
        }

        public void setMock(Object typeKey, C_IIntegrationExecutorBuilder mockExecutorBuilder) {
            mockInstancesByTypeKey.put(typeKey, mockExecutorBuilder);
        }
    }

    public class EventProcessorFactory {

        Map<String, EventDefinition> eventDefinitionsByEventType = new Map<String, EventDefinition>();

        Map<String, IRR_EVT_IEventProcessor> mockInstancesByEventType = new Map<String, IRR_EVT_IEventProcessor>();

        public EventProcessorFactory(Map<String, EventDefinition> eventDefinitionsByEventType) {
            this.eventDefinitionsByEventType = eventDefinitionsByEventType;
        }

        public IRR_EVT_IEventProcessor newInstance(String eventType, String jsonPayload) {

            if (mockInstancesByEventType.containsKey(eventType)) {
                return mockInstancesByEventType.get(eventType);
            }

            EventDefinition definition = eventDefinitionsByEventType.get(eventType);
            if (definition==null) {
                throw new EventDefinitionException('No definition found for event type ' + eventType);
            }

            Object payload = JSON.deserialize(jsonPayload, definition.payloadModel);
            return newInstance(eventType, payload);
        }

        public IRR_EVT_IEventProcessor newInstance(String eventType, Object payload) {

            if (mockInstancesByEventType.containsKey(eventType)) {
                return mockInstancesByEventType.get(eventType);
            }

            EventDefinition definition = eventDefinitionsByEventType.get(eventType);
            if (definition==null) {
                throw new EventDefinitionException('No definition found for event type ' + eventType);
            }

            IRR_EVT_EventProcessor.IConstructable constructable = (IRR_EVT_EventProcessor.IConstructable)
                    definition.processorConstructor.newInstance();

            return (IRR_EVT_IEventProcessor) constructable.newInstance(payload);
        }

        public void setMock(String eventType, IRR_EVT_IEventProcessor eventMock) {
            mockInstancesByEventType.put(eventType, eventMock);
        }
    }

    public class EventDefinition {
        public Type payloadModel;
        public Type processorConstructor;

        public EventDefinition(Type payloadModel, Type processorConstructor) {
            this.payloadModel = payloadModel;
            this.processorConstructor = processorConstructor;
        }
    }

    public class EventDefinitionException extends Exception { }

    /**
     * Exception representing a developer coding error, not intended for end user eyes
     **/
    public class DeveloperException extends Exception { }
}