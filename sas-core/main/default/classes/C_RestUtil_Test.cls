/**
    Test class for rest util class
*/
@isTest
private class C_RestUtil_Test {
    
    /**
        Tests setting OK and Status code 200 on success. 
    */
    @isTest static void restUtilsetOKTest(){
        setupRestContext(
            '/TEST', 
            'GET', 
            null, 
            new Map<String,String>{'p1'=>'TEST','p2'=>'','p3'=>'5','p4'=>'5.4'}, 
            null
        );
        C_RestUtil.init();
        C_RestUtil.setOK('OK');
    }
    
    /**
        Tests retrival of query parameters
    */
    @isTest static void restUtilQueryParams(){
        setupRestContext(
            '/TEST', 
            'GET', 
            null, 
            new Map<String,String>{'p1'=>'TEST','p2'=>'','p3'=>'5','p4'=>'5.4'}, 
            null
        );

        C_RestUtil.init();
        C_RestUtil.ParamCollection pc = C_RestUtil.getQueryParams();
        //Tests normal retrieval
        String v1 = pc.get('p1',false);
        String v2 = pc.get('p2',false);
        String v3 = pc.get('p3',false);
        String v4 = pc.get('p4',false);
        String v5 = pc.get('p5',false);
        System.assertEquals('TEST', v1);
        System.assertEquals(null, v2);
        System.assertEquals('5', v3);
        System.assertEquals('5.4', v4);
        System.assertEquals(null, v5);

        //TEST required retrieval
        Boolean error = false;

        try{String v = pc.get('p1',true);}
        catch(Exception e){error = true;}
        System.assertEquals(false, error);

        error = false;
        try{String v = pc.get('p2',true);}
        catch(Exception e){error = true;}
        System.assertEquals(true, error);

        error = false;
        try{String v = pc.get('p3',true);}
        catch(Exception e){error = true;}
        System.assertEquals(false, error);

        error = false;
        try{String v = pc.get('p4',true);}
        catch(Exception e){error = true;}
        System.assertEquals(false, error);

        error = false;
        try{String v = pc.get('p5',true);}
        catch(Exception e){error = true;}
        System.assertEquals(true, error);

        //Test integer retrieval (empty values ok)
        error = false;
        try{Integer v = pc.getInt('p1',false);}
        catch(Exception e){error = true;}
        System.assertEquals(true, error);

        error = false;
        try{Integer v = pc.getInt('p2',false);}
        catch(Exception e){error = true;}
        System.assertEquals(false, error);

        error = false;
        try{Integer v = pc.getInt('p3',false);}
        catch(Exception e){error = true;}
        System.assertEquals(false, error);

        error = false;
        try{Integer v = pc.getInt('p4',false);}
        catch(Exception e){error = true;}
        System.assertEquals(true, error);

        error = false;
        try{Integer v = pc.getInt('p5',false);}
        catch(Exception e){error = true;}
        System.assertEquals(false, error);

    }

    /**
        Tests parsing a JSON body with all variables 
    */
    @isTest static void restUtilBodyParseFull(){
        setupRestContextStringBody(
            '/TEST', 
            'POST', 
            null, 
            null, 
            '{"a":5,"b":"STR"}'
        );
        C_RestUtil.init();
        TestClass tc = (TestClass)C_RestUtil.getJSONBody(TestClass.class);
        System.assertEquals(5,tc.a);
        System.assertEquals('STR',tc.b);
    }

    /**
        Tests parsing a JSON body with a subset of the variables
    */
    @isTest static void restUtilBodyParseSubset(){
        setupRestContextStringBody(
            '/TEST', 
            'POST', 
            null, 
            null, 
            '{"a":5}'
        );
        C_RestUtil.init();
        TestClass tc = (TestClass)C_RestUtil.getJSONBody(TestClass.class);
        System.assertEquals(5,tc.a);
        System.assertEquals(null,tc.b);
    }

    /**
        Tests parsing a JSON body with a superset of the variables, i.e. a variable not in the class
    */
    @isTest static void restUtilBodyParseSuperset(){
        setupRestContextStringBody(
            '/TEST', 
            'POST', 
            null, 
            null, 
            '{"a":5,"b":"STR","c":"ABC"}'
        );
        C_RestUtil.init();
        Integer statusCode;
        try{
            TestClass tc = (TestClass)C_RestUtil.getJSONBody(TestClass.class);    
        }
        catch(C_RestUtil.RestException e){
            statusCode = e.statusCode;
        }
        System.assertEquals(400,statusCode);
    }

    /**
        Tests parsing an invalid JSON body
    */
    @isTest static void restUtilBodyParseBadJSON(){
        setupRestContextStringBody(
            '/TEST', 
            'POST', 
            null, 
            null, 
            '{"a":5,,,}'
        );
        C_RestUtil.init();
        Integer statusCode;
        try{
            TestClass tc = (TestClass)C_RestUtil.getJSONBody(TestClass.class);    
        }
        catch(C_RestUtil.RestException e){
            statusCode = e.statusCode;
        }
        System.assertEquals(400,statusCode);
    }

    /**
        Tests the transaction control and logging 
    */
    @isTest static void restUtilTransactionControlRestException(){
        setupRestContextStringBody(
            '/TEST', 
            'POST', 
            new Map<String,String>{'h1'=>'hv1','h2'=>'hv2'}, 
            new Map<String,String>{'q1'=>'qv1','q2'=>'qv2'}, 
            '{"a":5}'
        );
        C_RestUtil.init();
        insert new FeedItem(Title='TEST',Body='TEST',ParentId=UserInfo.getUserId());
        try{
            C_RestUtil.badRequest('TEST MESSAGE');
        }
        catch(Exception e){
            C_RestUtil.handleException(e);
        }
        System.assertEquals(0,Database.countQuery('SELECT COUNT() FROM FeedItem'));
        C_Log__c l = [SELECT Id,HttpResource__c,HttpMethod__c,HttpHeaders__c,HttpQueryParameters__c,HttpBody__c,HttpRemoteAddress__c FROM C_Log__c];
        System.assertEquals('/TEST',l.HttpResource__c);
        System.assertEquals('POST',l.HttpMethod__c);
        System.assert(l.HttpHeaders__c.contains('h1'));
        System.assert(l.HttpHeaders__c.contains('h2'));
        System.assert(l.HttpHeaders__c.contains('hv1'));
        System.assert(l.HttpHeaders__c.contains('hv2'));
        System.assert(l.HttpQueryParameters__c.contains('q1'));
        System.assert(l.HttpQueryParameters__c.contains('q2'));
        System.assert(l.HttpQueryParameters__c.contains('qv1'));
        System.assert(l.HttpQueryParameters__c.contains('qv2'));
        System.assertEquals('1.2.3.4',l.HttpRemoteAddress__c);
        System.assertEquals('{"a":5}',l.HttpBody__c);
    }

    /**
        Tests the transaction control and logging using non rest exceptions
    */
    @isTest static void restUtilTransactionControlNonRestException(){
        setupRestContextStringBody(
            '/TEST', 
            'POST', 
            new Map<String,String>{'h1'=>'hv1','h2'=>'hv2'}, 
            new Map<String,String>{'q1'=>'qv1','q2'=>'qv2'}, 
            '{"a":5}'
        );
        C_RestUtil.init();
        insert new FeedItem(Title='TEST',Body='TEST',ParentId=UserInfo.getUserId());
        try{
            throw new TypeException();
        }
        catch(Exception e){
            C_RestUtil.handleException(e);
        }
        System.assertEquals(0,Database.countQuery('SELECT COUNT() FROM FeedItem'));
        C_Log__c l = [SELECT Id,HttpResource__c,HttpMethod__c,HttpHeaders__c,HttpQueryParameters__c,HttpBody__c,HttpRemoteAddress__c FROM C_Log__c];
        System.assertEquals('/TEST',l.HttpResource__c);
        System.assertEquals('POST',l.HttpMethod__c);
        System.assert(l.HttpHeaders__c.contains('h1'));
        System.assert(l.HttpHeaders__c.contains('h2'));
        System.assert(l.HttpHeaders__c.contains('hv1'));
        System.assert(l.HttpHeaders__c.contains('hv2'));
        System.assert(l.HttpQueryParameters__c.contains('q1'));
        System.assert(l.HttpQueryParameters__c.contains('q2'));
        System.assert(l.HttpQueryParameters__c.contains('qv1'));
        System.assert(l.HttpQueryParameters__c.contains('qv2'));
        System.assertEquals('1.2.3.4',l.HttpRemoteAddress__c);
        System.assertEquals('{"a":5}',l.HttpBody__c);
    }

    /**
        Tests the transaction control and logging where the data is not a string
    */
    @isTest static void restUtilTransactionControlRestExceptionBlobData(){
        setupRestContext(
            '/TEST', 
            'POST', 
            new Map<String,String>{'h1'=>'hv1','h2'=>'hv2'}, 
            new Map<String,String>{'q1'=>'qv1','q2'=>'qv2'}, 
            EncodingUtil.base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=')
        );
        C_RestUtil.init();
        insert new FeedItem(Title='TEST',Body='TEST',ParentId=UserInfo.getUserId());
        try{
            C_RestUtil.badRequest('TEST MESSAGE');
        }
        catch(Exception e){
            C_RestUtil.handleException(e);
        }
        System.assertEquals(0,Database.countQuery('SELECT COUNT() FROM FeedItem'));
        C_Log__c l = [SELECT Id,HttpResource__c,HttpMethod__c,HttpHeaders__c,HttpQueryParameters__c,HttpBody__c,HttpRemoteAddress__c FROM C_Log__c];
        System.assertEquals('/TEST',l.HttpResource__c);
        System.assertEquals('POST',l.HttpMethod__c);
        System.assert(l.HttpHeaders__c.contains('h1'));
        System.assert(l.HttpHeaders__c.contains('h2'));
        System.assert(l.HttpHeaders__c.contains('hv1'));
        System.assert(l.HttpHeaders__c.contains('hv2'));
        System.assert(l.HttpQueryParameters__c.contains('q1'));
        System.assert(l.HttpQueryParameters__c.contains('q2'));
        System.assert(l.HttpQueryParameters__c.contains('qv1'));
        System.assert(l.HttpQueryParameters__c.contains('qv2'));
        System.assertEquals('1.2.3.4',l.HttpRemoteAddress__c);
        System.assertEquals('Blob Data (68)',l.HttpBody__c);
    }



    /**
        Class used to test parsing of JSON
    */
    private class TestClass{
        private Integer a;
        private String b;
    }

    /**
        Sets up the rest context required to test rest methods using a text based body
        @param resource The resource of the request
        @param method The method of the request
        @param headers The HTTP header of the request
        @param params The parameters of the request
        @param body THe body of the request
    */
    static void setupRestContextStringBody(String resource,String method,Map<String,String> headers,Map<String,String> params,String body){
        setupRestContext(resource,method,headers,params,body!=null?Blob.valueOf(body):null);
    }

    /**
        Sets up the rest context required to test rest methods
        @param resource The resource of the request
        @param method The method of the request
        @param headers The HTTP header of the request
        @param params The parameters of the request
        @param body THe body of the request
    */
    static void setupRestContext(String resource,String method,Map<String,String> headers,Map<String,String> params,Blob body){
        RestRequest req = new RestRequest();
        RestContext.request = req;
        req.resourcePath=resource;
        req.httpMethod = method;
        if(headers!=null)req.headers.putAll(headers);
        if(params!=null)req.params.putAll(params);
        req.requestBody = body;
        req.remoteAddress = '1.2.3.4';
        RestContext.response = new RestResponse();
    }
}
