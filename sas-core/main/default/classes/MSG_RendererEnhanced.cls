/**
    Enhanced renderer used to render both LEX and classic
    email templates. The renderer allows for querying details
    which are detailed on parent levels.
    @author Peter Södergren, Niklas Lundkvist
*/
global class MSG_RendererEnhanced implements MSG_IRenderer{
    /**
        Custom exception thrown when an issue with rendering occurs
    */
    class RenderingException extends Exception{}
    /**
        The string used to open an expression in classic email templates
    */
    private static String CLASSIC_EXPR_OPEN='{!';
    /**
        The string used to close an expression in classic email templates
    */
    private static String CLASSIC_EXPR_CLOSE='}';
    /**
        The string used to open an expression in lightning email templates
    */
    private static String LEX_EXPR_OPEN='{{{';
    /**
        The string used to close an expression in lightning email templates
    */
    private static String LEX_EXPR_CLOSE='}}}';

    private static String LEX_EXPR_ALT_OPEN = '[[[';
    private static String LEX_EXPR_ALT_CLOSE = ']]]';
    /**
     * Name of function used to start a loop segment
     */
    private static String LOOP_FN_NAME='LOOP';
    /**
     * Name of function used to end a loop segment
     */
    private static String END_LOOP_FN_NAME = 'ENDLOOP';
    /**
     * Name of function used to start a conditional display segment
     */
    private static String DISPLAY_IF_FN_NAME='DISPLAYIF';
    /**
     * Name of function used to end a conditional display segment
     */
    private static String END_DISPLAY_IF_FN_NAME = 'ENDDISPLAYIF';

    private MSG_ITemplateCache templateCache;

    private Map<String, TemplateModel> templateModelsByTemplateNameHTML = new Map<String, TemplateModel>();

    public MSG_RendererEnhanced(MSG_ITemplateCache templateCache) {
        this.templateCache = templateCache;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Renders message content and subject for parameter message.
     *
     * @param message Message to render
     */
    public void renderMessage(IRR_MOD_Message message) {
        MSG_TemplateCache.TemplateContent tc = templateCache.getTemplateByName(message.template);
        Boolean isHtml = tc.isHtml() && message.channel != IRR_MOD_Message.MessageChannel.SMS;
        TemplateModel tm = templateModelsByTemplateNameHTML.get(message.template + isHtml);
        if (tm == null) {
            TemplateLetterheadModel tlm = tc.letterhead != null ? new TemplateLetterheadModel(tc.letterhead) : null;
            tm = new TemplateModel(tc, tlm, isHtml);
            templateModelsByTemplateNameHTML.put(message.template, tm);
        }
        ObjectValueResolver resolver = new ObjectValueResolver(message.variables, isHtml);
        if (tm.subject!=null) message.subject = tm.subject.render(resolver);
        String body;
        if (tm.letterhead == null || !isHtml) {
            body = tm.body.render(resolver);
        }
        else {
            body = (tm.letterhead.header != null ? tm.letterhead.header.render(resolver) : '') +
                    tm.body.render(resolver) +
                    (tm.letterhead.footer != null ? tm.letterhead.footer.render(resolver) : '');
        }
        message.content = body;
    }


    /**
        Class containing the different parts of a template to be rendered
    */
    class TemplateModel{

        /**
            The template for rendering the subject
        */
        Template subject;
        /**
            The template for rendering the body
        */
        Template body;
        /**
            Template model containing the letterhead
        */
        TemplateLetterheadModel letterhead;


        /**
            @param tc The template content from which to create the renderable template
            @param letterhead The renderable letterhead used in this template model
            @param isHtml Whether the template should be rendered as html
        */
        TemplateModel(MSG_TemplateCache.TemplateContent tc,TemplateLetterheadModel letterhead,Boolean isHtml){
            if(tc.isUiTypeLEX()){
                if (String.isNotBlank(tc.subject)) subject = new Template(tc.subject,LEX_EXPR_OPEN,LEX_EXPR_CLOSE, LEX_EXPR_ALT_OPEN, LEX_EXPR_ALT_CLOSE);
                String bodySrc = tc.getData(isHtml);
                // 26429-Manual tampering on email templates causes error 
                bodySrc = bodySrc.replace('&#39;','\'');
                if(letterhead==null && isHtml)bodySrc = bodySrc.replace('<head>','<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8">');
                body = new Template(bodySrc,LEX_EXPR_OPEN,LEX_EXPR_CLOSE, LEX_EXPR_ALT_OPEN, LEX_EXPR_ALT_CLOSE);
            }
            else if(tc.isUiTypeClassic()){
                if (String.isNotBlank(tc.subject)) subject = new Template(tc.subject,CLASSIC_EXPR_OPEN,CLASSIC_EXPR_CLOSE, null, null);
                body = new Template(tc.getData(isHtml),CLASSIC_EXPR_OPEN,CLASSIC_EXPR_CLOSE, null, null);
                if(letterhead==null && isHtml)letterhead = new TemplateLetterheadModel(new Template('<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>',CLASSIC_EXPR_OPEN,CLASSIC_EXPR_CLOSE, null, null),new Template('</html>',CLASSIC_EXPR_OPEN,CLASSIC_EXPR_CLOSE, null, null));
            }
            else throw new RenderingException('Unknown template UI type: '+tc.uiType);
            this.letterhead = letterhead;
        }
    }

    /**
        Class for rendering the letterhead
    */
    class TemplateLetterheadModel{
        /**
            The template for rendering the header
        */
        Template header;
        /**
            The template for rendering the footer
        */
        Template footer;

        /**
            Creates a letterhead from the provided template letterhead
            @param tl The letterhead to from which to create the renderable templates
        */
        TemplateLetterheadModel(MSG_TemplateCache.TemplateLetterhead tl){
            if(tl.isUiTypeLEX()){
                header = new Template('<meta http-equiv="Content-Type" content="text/html; charset=utf-8"><table border="0" cellpadding="1" width="100%" cellspacing="5" height="100%"><tbody><tr><td>'+(tl.header!=null ? tl.header : '')+'</td></tr><tr><td><div id="htmlValue">',LEX_EXPR_OPEN,LEX_EXPR_CLOSE, LEX_EXPR_ALT_OPEN, LEX_EXPR_ALT_CLOSE);
                footer = new Template('</div></td></tr><tr><td>'+(tl.footer!=null ? tl.footer : '')+'</td></tr></tbody></table>',LEX_EXPR_OPEN,LEX_EXPR_CLOSE, LEX_EXPR_ALT_OPEN, LEX_EXPR_ALT_CLOSE);
            }
            else if(tl.isUiTypeClassic()){
                if(!String.isBlank(tl.header))header = new Template(tl.header,CLASSIC_EXPR_OPEN,CLASSIC_EXPR_CLOSE, null, null);
                if(!String.isBlank(tl.footer))footer = new Template(tl.footer,CLASSIC_EXPR_OPEN,CLASSIC_EXPR_CLOSE, null, null);
            }
            else throw new RenderingException('Unknown letterhead UI type: '+tl.id);
        }

        /**
            Cretaes a letterhead model from the provided header and footer
            @param header The header template
            @param footer The footer template
        */
        TemplateLetterheadModel(Template header,Template footer){
            this.header = header;
            this.footer = footer;
        }
    }

    /**
        Represents a template which contains 
    */
    class Template{
        /**
         * The root node to render for the template
         */
        TemplateNodeContainer rootNode;
        /**
            Creates a template from a source string
            @param src The source template string from which the template is constructed
            @param exprOpen The character sequence which is used to start an expression in a template
            @param exprClose The character sequence which is used to stop an expression in a template
            @param altOpen Alternative character sequence for starting an expression (optional)
            @param altClose Alternative character sequence for closing an expression (optional)
        */
        Template(String src, String exprOpen, String exprClose, String altOpen, String altClose){
            rootNode = new TemplateNodeContainer();
            List<TemplateNodeContainer> nodeStack = new List<TemplateNodeContainer>();
            TemplateNodeContainer topNode = rootNode;

            final String EXPR_OPEN = exprOpen;
            String EXPR_CLOSE = exprClose;
            Integer openLen = EXPR_OPEN.length();
            Integer closeLen = EXPR_CLOSE.length();
            Integer idx = 0;
            Integer idxNext = 0;
            while(true){
                idxNext = src.indexOf(EXPR_OPEN,idx);
                if (EXPR_CLOSE != exprClose) EXPR_CLOSE = exprClose;
                if (String.isNotBlank(altOpen) && String.isNotBlank(altClose)) {
                    Integer altNext = src.indexOf(altOpen, idx);
                    if (altNext != -1 && (idxNext == -1  ||  altNext < idxNext)) {
                        EXPR_CLOSE = altClose;
                        idxNext = altNext;
                    }
                }
                if (idxNext == -1) break;

                Integer idxTo = src.indexOf(EXPR_CLOSE,idxNext);

                if(idxTo==-1)throw new RenderingException('Bad template, cannot find closing expression token from index: '+idxNext);
                topNode.nodeList.add(new TemplateTextNode(src.substring(idx,idxNext)));
                TemplateExprNode ten = new TemplateExprNode(src.substring(idxNext+openLen,idxTo));
                if(ten.e.isFunction() && ten.e.isLeafExpr()){
                    Expr_Expr.SymbolExpression sym = ten.e.getSymbol();
                    if(sym.sourceRef==LOOP_FN_NAME){
                        TemplateLoopNode tln = new TemplateLoopNode(ten.e);
                        topNode.nodeList.add(tln);
                        nodeStack.add(topNode);
                        topNode=tln;
                    }
                    else if(sym.sourceRef==END_LOOP_FN_NAME){
                        if(!(topNode instanceof TemplateLoopNode))throw new RenderingException('Bad template, cannot find matching loop for end loop at index: '+idxNext);
                        topNode = nodeStack.get(nodeStack.size()-1);
                        nodeStack.remove(nodeStack.size()-1);
                    }
                    else if(sym.sourceRef==DISPLAY_IF_FN_NAME){
                        TemplateConditionalNode tcn = new TemplateConditionalNode(ten.e);
                        topNode.nodeList.add(tcn);
                        nodeStack.add(topNode);
                        topNode=tcn;
                    }
                    else if(sym.sourceRef==END_DISPLAY_IF_FN_NAME){
                        if(!(topNode instanceof TemplateConditionalNode))throw new RenderingException('Bad template, cannot find matching display if for end display if at index: '+idxNext);
                        topNode = nodeStack.get(nodeStack.size()-1);
                        nodeStack.remove(nodeStack.size()-1);
                    }
                    else topNode.nodeList.add(ten);
                }
                else topNode.nodeList.add(ten);
                idx = idxTo + closeLen;
            }
            topNode.nodeList.add(new TemplateTextNode(src.substring(idx)));
            if(nodeStack.size()!=0)throw new RenderingException('Bad template, not all opened scopes were closed');
        }

        /**
            Renders the message using the provided symbol resolver
            @param svr The symbol value resolver to use when rendering the message
            @return The rendered message
        */
        String render(Expr_Expr.SymbolValueResolver svr){
            return rootNode.render(svr);
        }
    }
    /**
     * Base class for template nodes
     */
    abstract class TemplateNode{
        /**
            Renders the the node into a string
            @param svr The symbol value resolver used to render dynamic data
            @return The rendered content
        */
        abstract String render(Expr_Expr.SymbolValueResolver svr);
    }
    /**
        Represents a simple text node without dynamic data
    */
    class TemplateTextNode extends TemplateNode{
        /**
            The text to render
        */
        String text;
        /**
            Creates a text node instance
            @param text The text to render
        */
        TemplateTextNode(String text){
            this.text = text;
        }

        /**
            Renders the the node into a string
            @param svr The symbol value resolver used to render dynamic data
            @return The rendered content
        */
        override String render(Expr_Expr.SymbolValueResolver svr){
            return text;
        }


    }

    /**
        Represents an expression node in a template
    */
    class TemplateExprNode extends TemplateNode{
        /**
            Expression of the text
        */
        Expr_Expr e;
        /**
            Creates an instance of the template expression node
            @param text The text to be parsed as an expression
        */
        TemplateExprNode(String text){
            e = Expr_Expr.compile(text, null);
        }

        /**
            Renders the node into a string
            @param svr The symbol value resolver used to render dynamic data
            @return The rendered content
        */
        override String render(Expr_Expr.SymbolValueResolver svr){
            Object v = e.eval(svr);
            return v!=null ? ''+v : '';
        }
    }

    /**
     * Represents a template node containing other nodes
     */
    virtual class TemplateNodeContainer extends TemplateNode{
        /**
         * List of template nodes to render inside the node
         */
        List<TemplateNode> nodeList;
        /**
         * Creates template node container instance
         */
        TemplateNodeContainer(){
            this.nodeList = new List<TemplateNode>();
        }

        /**
         * Renders the child nodes
         * @param svr The symbol value resolver used to render dynamic data
         * @return The rendered content
         */
        virtual override String render(Expr_Expr.SymbolValueResolver svr){
            Integer sz = nodeList.size();
            String[] parts = new String[sz];
            for(Integer i=0;i<sz;i++){
                parts[i] = nodeList[i].render(svr);
            }
            return String.join(parts,'');
        }

    }

    /**
     * Represents a loop expression node
     */
    class TemplateLoopNode extends TemplateNodeContainer{
        /**
         * The loop expression
         */
        Expr_Expr e;
        /**
         * Creates a loop node from a loop expression
         * @param e The loop expression
         */
        TemplateLoopNode(Expr_Expr e){
            this.e = e;
            Expr_Expr[] eParams = e.getFunctionParameters();
            if(eParams==null || eParams.size()!=2)throw new RenderingException('Invalid template loop. Must include exactly two parameters');
            if(!eParams[1].isLeafExpr() || eParams[1].getOperatorToken()!=Expr_Expr.T_STRING)throw new RenderingException('Invalid template loop. Second parameter must be simple string');
            this.nodeList = new List<TemplateNode>();
        }

        /**
         * Iterates over the loop and renders the content
         * @param svr The symbol value resolver used to render dynamic data
         * @return The rendered content
         */
        override String render(Expr_Expr.SymbolValueResolver svr){
            String content = '';
            Expr_Expr[] eParams = e.getFunctionParameters();
            List<Object> objList = (List<Object>)eParams[0].eval(svr);
            String objName = (String)eParams[1].eval(svr);
            if(objList!=null){
                for(Integer i=0;i<objList.size();i++){
                    svr.registerLocalVar(objList[i],objName);
                    content += super.render(svr);
                }
            }
            return content;
        }
    }

    /**
     * Represents a conditional template node
     */
    class TemplateConditionalNode extends TemplateNodeContainer{
        /**
         * The conditional expression evaluated to decide whether to display the components
         */
        Expr_Expr e;
        /**
         * Creates a conditional node
         * @param e The function expression containing the condition to evaluate
         */
        TemplateConditionalNode(Expr_Expr e){
            Expr_Expr[] eParams = e.getFunctionParameters();
            if(eParams==null || eParams.size()!=1)throw new RenderingException('Invalid template conditional display. Must include exactly one parameter');
            this.e = eParams[0];
            this.nodeList = new List<TemplateNode>();
        }

        /**
         * Evaluates the expression and conditionally renders the child nodes
         * @param svr The symbol value resolver used to render dynamic data
         * @return The rendered content
         */
        override String render(Expr_Expr.SymbolValueResolver svr){
            if(interpretExprValToBool(e.eval(svr))){
                return super.render(svr);
            }
            return '';
        }
    }
    /**
     * Interprets the supplied expression value as a boolean
     * The interpretation is according to the following types
     * Boolean: The boolean value
     * Null: False
     * Integer/Long/Double/Decimal: True if not 0
     * String: True if not empty
     * Others: False
     * @param v The uncasted value to interpret as a boolean
     * @return The boolean interpretation
     */
    static Boolean interpretExprValToBool(Object v){
        if(v==null)return false;
        if(v instanceof Boolean)return (Boolean)v;
        if(v instanceof Integer)return ((Integer)v)!=0;
        if(v instanceof Long)return ((Long)v)!=0;
        if(v instanceof Double)return ((Double)v)!=0;
        if(v instanceof Decimal)return ((Decimal)v)!=0;
        if(v instanceof String)return String.isNotBlank((String)v);
        return false;
    }

    global class ObjectValueResolver extends Expr_Expr.SymbolValueResolver {

        Map<String, Object> variableMap;
        Boolean isHTML;

        public ObjectValueResolver(Map<String, Object> variableMap, Boolean isHTML) {
            this.variableMap = variableMap;
            this.isHTML = isHTML;
        }

        /**
         * Retrieves the value provider for the supplied data source reference and reference path
         * @param sourceRef The data source reference
         * @param subReferences The reference path from which to retrieve the value
         * @return The data value for the data source and reference path
         */
        global override Object getDataValue(String sourceRef,Expr_Expr.SymbolSubReference[] subReferences){
            Object parsedValue = variableMap.get(sourceRef);
            for (Expr_Expr.SymbolSubReference ref : subReferences) {
                if (parsedValue != null && parsedValue instanceof Map<String, Object>) {
                    Map<String, Object> obj = (Map<String, Object>) parsedValue;
                    parsedValue = obj.get(ref.field);
                } else {
                    return null;
                }
            }
            if (parsedValue instanceof String && isHTML) {
                String parsedString = (String) parsedValue;
                parsedValue = parsedString.replace('\n', '<br />');
            }
            return parsedValue;
        }

        /**
         * Registers the provided symbol expression as a local variable¨
         * @param localVar The name to register for the value object
         * @param obj The value object to register
         */
        global override void registerLocalVar(Object obj,String localVar){
            variableMap.put(localVar, obj);
        }

        /**
		 * Retrieves the value provider for the supplied function source reference and reference path
		 * @param sourceRef The function source reference
		 * @param exprParamList The expression used as parameters to the function
		 * @param path The reference path from which to retrieve the value
		 * @return The data value for the data source and reference path
		 */
        global override Object getFunctionValue(String sourceRef,Expr_Expr[] exprParamList,Expr_Expr.SymbolSubReference[] path){
            if (sourceRef == 'contains') {
                Object value = this.eval(exprParamList[0]);
                Object iterable = this.eval(exprParamList[1]);
                if (iterable instanceof List<Object>) {
                    List<Object> objList = (List<Object>) iterable;
                    return objList.contains(value);
                }
                else if (iterable instanceof Set<Object>) {
                    Set<Object> objSet = (Set<Object>) iterable;
                    return objSet.contains(value);
                } else {
                    return false;
                }
            }
            else if (sourceRef=='formatDatetimeUTC') {
                String stringValue = (String) this.eval(exprParamList[0]);
                if (String.isBlank(stringValue)) return null;
                //Parse Datetime ISO String into Datetime using de-serialization, string must be wrapped in quotes
                Datetime datetimeValue = (Datetime) JSON.deserialize('"' + stringValue + '"', Datetime.class);
                String format = (String) this.eval(exprParamList[1]);
                if (datetimeValue != null && String.isNotBlank(format)) {
                    return datetimeValue.formatGmt(format);
                }
            }
            return null;
        }
    }
}