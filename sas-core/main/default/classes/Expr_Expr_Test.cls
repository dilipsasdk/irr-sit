/**
    Tests of compilation and evaluation of expressions in the created 
    and evaluated in the Expr_Expr class.
    @author Peter Södergren
*/
@isTest
global class Expr_Expr_Test {
    /**
        Tests valid compilation and evaluation of valid simple expressions
    */
    @isTest static void testSimpleExpressions(){
        assertExpression('true && true',null,null,true);
        assertExpression('true && false',null,null,false);
        assertExpression('false && true',null,null,false);
        assertExpression('false && false',null,null,false);

        assertExpression('true || true',null,null,true);
        assertExpression('true || false',null,null,true);
        assertExpression('false || true',null,null,true);
        assertExpression('false || false',null,null,false);

        assertExpression('2>1',null,null,true);
        assertExpression('1>1',null,null,false);
        assertExpression('1>2',null,null,false);
        assertExpression('2>-1',null,null,true);
        assertExpression('1>-1',null,null,true);
        assertExpression('1>-2',null,null,true);
        assertExpression('-2>1',null,null,false);
        assertExpression('-1>1',null,null,false);
        assertExpression('-1>2',null,null,false);
        assertExpression('-2>-1',null,null,false);
        assertExpression('-1>-1',null,null,false);
        assertExpression('-1>-2',null,null,true);

        assertExpression('2>=1',null,null,true);
        assertExpression('1>=1',null,null,true);
        assertExpression('1>=2',null,null,false);
        assertExpression('2>=1',null,null,true);
        assertExpression('1>=-1',null,null,true);
        assertExpression('1>=-2',null,null,true);
        assertExpression('-2>=1',null,null,false);
        assertExpression('-1>=1',null,null,false);
        assertExpression('-1>=2',null,null,false);
        assertExpression('-2>=-1',null,null,false);
        assertExpression('-1>=-1',null,null,true);
        assertExpression('-1>=-2',null,null,true);

        assertExpression('2<=1',null,null,false);
        assertExpression('1<=1',null,null,true);
        assertExpression('1<=2',null,null,true);
        assertExpression('2<=1',null,null,false);
        assertExpression('1<=-1',null,null,false);
        assertExpression('1<=-2',null,null,false);
        assertExpression('-2<=1',null,null,true);
        assertExpression('-1<=1',null,null,true);
        assertExpression('-1<=2',null,null,true);
        assertExpression('-2<=-1',null,null,true);
        assertExpression('-1<=-1',null,null,true);
        assertExpression('-1<=-2',null,null,false);

        assertExpression('2<1',null,null,false);
        assertExpression('1<1',null,null,false);
        assertExpression('1<2',null,null,true);
        assertExpression('2<1',null,null,false);
        assertExpression('1<-1',null,null,false);
        assertExpression('1<-2',null,null,false);
        assertExpression('-2<1',null,null,true);
        assertExpression('-1<1',null,null,true);
        assertExpression('-1<2',null,null,true);
        assertExpression('-2<-1',null,null,true);
        assertExpression('-1<-1',null,null,false);
        assertExpression('-1<-2',null,null,false);

        assertExpression('2==1',null,null,false);
        assertExpression('1==1',null,null,true);
        assertExpression('1==2',null,null,false);
        assertExpression('2==1',null,null,false);
        assertExpression('1==-1',null,null,false);
        assertExpression('1==-2',null,null,false);
        assertExpression('-2==1',null,null,false);
        assertExpression('-1==1',null,null,false);
        assertExpression('-1==2',null,null,false);
        assertExpression('-2==-1',null,null,false);
        assertExpression('-1==-1',null,null,true);
        assertExpression('-1==-2',null,null,false);

        assertExpression('2!=1',null,null,true);
        assertExpression('1!=1',null,null,false);
        assertExpression('1!=2',null,null,true);
        assertExpression('2!=1',null,null,true);
        assertExpression('1!=-1',null,null,true);
        assertExpression('1!=-2',null,null,true);
        assertExpression('-2!=1',null,null,true);
        assertExpression('-1!=1',null,null,true);
        assertExpression('-1!=2',null,null,true);
        assertExpression('-2!=-1',null,null,true);
        assertExpression('-1!=-1',null,null,false);
        assertExpression('-1!=-2',null,null,true);

        assertExpression('""<""',null,null,false);
        assertExpression('"A"<"A"',null,null,false);
        assertExpression('"AA"<"AA"',null,null,false);
        assertExpression('"A"<"B"',null,null,true);
        assertExpression('"AA"<"AB"',null,null,true);
        assertExpression('"A"<"AA"',null,null,true);
        assertExpression('"B"<"A"',null,null,false);
        assertExpression('"AB"<"AA"',null,null,false);
        assertExpression('"AA"<"A"',null,null,false);

        assertExpression('""<=""',null,null,true);
        assertExpression('"A"<="A"',null,null,true);
        assertExpression('"AA"<="AA"',null,null,true);
        assertExpression('"A"<="B"',null,null,true);
        assertExpression('"AA"<="AB"',null,null,true);
        assertExpression('"A"<="AA"',null,null,true);
        assertExpression('"B"<="A"',null,null,false);
        assertExpression('"AB"<="AA"',null,null,false);
        assertExpression('"AA"<="A"',null,null,false);

        assertExpression('"">=""',null,null,true);
        assertExpression('"A">="A"',null,null,true);
        assertExpression('"AA">="AA"',null,null,true);
        assertExpression('"A">="B"',null,null,false);
        assertExpression('"AA">="AB"',null,null,false);
        assertExpression('"A">="AA"',null,null,false);
        assertExpression('"B">="A"',null,null,true);
        assertExpression('"AB">="AA"',null,null,true);
        assertExpression('"AA">="A"',null,null,true);

        assertExpression('"">""',null,null,false);
        assertExpression('"A">"A"',null,null,false);
        assertExpression('"AA">"AA"',null,null,false);
        assertExpression('"A">"B"',null,null,false);
        assertExpression('"AA">"AB"',null,null,false);
        assertExpression('"A">"AA"',null,null,false);
        assertExpression('"B">"A"',null,null,true);
        assertExpression('"AB">"AA"',null,null,true);
        assertExpression('"AA">"A"',null,null,true);

        assertExpression('""==""',null,null,true);
        assertExpression('"A"=="A"',null,null,true);
        assertExpression('"AA"=="AA"',null,null,true);
        assertExpression('"A"=="B"',null,null,false);
        assertExpression('"AA"=="AB"',null,null,false);
        assertExpression('"A"=="AA"',null,null,false);
        assertExpression('"B"=="A"',null,null,false);
        assertExpression('"AB"=="AA"',null,null,false);
        assertExpression('"AA"=="A"',null,null,false);

        assertExpression('""!=""',null,null,false);
        assertExpression('"A"!="A"',null,null,false);
        assertExpression('"AA"!="AA"',null,null,false);
        assertExpression('"A"!="B"',null,null,true);
        assertExpression('"AA"!="AB"',null,null,true);
        assertExpression('"A"!="AA"',null,null,true);
        assertExpression('"B"!="A"',null,null,true);
        assertExpression('"AB"!="AA"',null,null,true);
        assertExpression('"AA"!="A"',null,null,true);

        assertExpression('2+3',null,null,5);
        assertExpression('3+2',null,null,5);
        assertExpression('3+-2',null,null,1);
        assertExpression('-3+2',null,null,-1);
        assertExpression('-3+-2',null,null,-5);

        assertExpression('2-3',null,null,-1);
        assertExpression('3-2',null,null,1);
        assertExpression('3--2',null,null,5);
        assertExpression('-3-2',null,null,-5);
        assertExpression('-3--2',null,null,-1);

        assertExpression('2*3',null,null,6);
        assertExpression('3*2',null,null,6);
        assertExpression('3*-2',null,null,-6);
        assertExpression('-3*2',null,null,-6);
        assertExpression('-3*-2',null,null,6);

        assertExpression('2/3',null,null,2.0/3.0);
        assertExpression('3/2',null,null,3.0/2.0);
        assertExpression('3/-2',null,null,3.0/-2.0);
        assertExpression('-3/2',null,null,-3.0/2.0);
        assertExpression('-3/-2',null,null,-3.0/-2.0);
    }

    /**
        Tests valid compilation and evaluation of valid complex expressions
    */
    @isTest static void testComplexExpressions(){
        SymbolValueResolverMock svr = new SymbolValueResolverMock();
        SymbolModelResolverMock smr = new SymbolModelResolverMock(svr);
        assertExpression('5*7',smr,svr,35);
        assertExpression('5 * 7',smr,svr,35);
        assertExpression('5 * test.NumSeven',smr,svr,35);
        assertExpression('5 == test.NumFive && "TEST"==test.String && (false || test.boolT)',smr,svr,true);
        assertExpression('5 == test.NumFive && 5>3 && !(5<3) && 3!=test.NumFive && 4<=4 && 3<=4 && test.NumFive>=5 && 5>=test.NumFive',smr,svr,true);
        assertExpression('"TEST" == test.String && "TESTING" == test.String & "ING"',smr,svr,true);
        assertExpression('test.NumSeven + 5 - 3 * 2',smr,svr,6);
        assertExpression('  test.NumFive / 2 + (5 - 3) * -2.5    ',smr,svr,-2.5);
        assertExpression('!test.boolF && !!test.boolT',smr,svr,true);
        assertExpression('!!test.boolF || !test.boolT',smr,svr,false);
        assertExpression('null == null && "AA"<"AB" && "AA"<="AA" && "AA">="AA" && "AB">"AA" && "\\"" == "\\"" && "\\"A"!="A\\"" && "A\\"A"=="A\\"A"',smr,svr,true);
        assertExpression('TESTFUN(test.NumFive==(3+3),4,2) + TESTFUN(test.NumFive==(2+3),17,1)',smr,svr,19);
        assertExpression('test.GenericObjectType',smr,svr,new Map<String,String>{'Key'=>'Value'});

        Expr_Expr e = Expr_Expr.compile('TESTFUN(test.NumFive==(3+3),4,2) + TESTFUN(test.NumFive==(2+3),17,1)',smr);
        Expr_Expr.SymbolCollection sc = e.retrieveSymbols(smr);
        System.assertEquals(1,sc.dataSymbols.size());
        System.assertEquals('test.NumFive',(new List<Expr_Expr.SymbolExpression>(sc.dataSymbols))[0].getDisplayName());
        System.assertEquals(1,sc.functionSymbols.size());
        System.assertEquals('TESTFUN',(new List<Expr_Expr.SymbolExpression>(sc.functionSymbols))[0].getDisplayName());

    }

    /**
        Tests invalid expressions with errors during the lexing process
    */
    @isTest static void testInvalidExpressionsLex(){
        SymbolValueResolverMock svr = new SymbolValueResolverMock();
        SymbolModelResolverMock smr = new SymbolModelResolverMock(svr);
		assertExpressionInvalidCompile('',smr);
		assertExpressionInvalidCompile('A &&',smr);
		assertExpressionInvalidCompile('"',smr);
		assertExpressionInvalidCompile('"\\"',smr);
		assertExpressionInvalidCompile('"A',smr);
		assertExpressionInvalidCompile('½',smr);
		assertExpressionInvalidCompile('5.4A',smr);
		assertExpressionInvalidCompile('5A',smr);
		assertExpressionInvalidCompile('5.4.6',smr);
		assertExpressionInvalidCompile('5.',smr);
		assertExpressionInvalidCompile('test.noSuchField',smr);
		assertExpressionInvalidCompile('2 == ',smr);
		assertExpressionInvalidCompile('== 2',smr);
		assertExpressionInvalidCompile('test.BADFUNCTION(true,false)',smr);
    }

    /**
        Tests invalid expressions with errors during the parsing process
    */
    @isTest static void testInvalidExpressionsParse(){
        SymbolValueResolverMock svr = new SymbolValueResolverMock();
        SymbolModelResolverMock smr = new SymbolModelResolverMock(svr);
		assertExpressionInvalidCompile('2 == (!)',smr);
		assertExpressionInvalidCompile('null == ()',smr);
		assertExpressionInvalidCompile(' 5 4 3',smr);
		assertExpressionInvalidCompile('5+4 3',smr);
		assertExpressionInvalidCompile('5 * (1',smr);
		assertExpressionInvalidCompile('5)',smr);
    }

    /**
        Tests invalid expressions with errors related to incompatible types
    */
    @isTest static void testInvalidExpressionsIncompatibleTypes(){
        SymbolValueResolverMock svr = new SymbolValueResolverMock();
        SymbolModelResolverMock smr = new SymbolModelResolverMock(svr);
        assertExpressionInvalidCompile('"A">5',smr);
		assertExpressionInvalidCompile('5>"A"',smr);
		assertExpressionInvalidCompile('5 & "A"',smr);
		assertExpressionInvalidCompile('null > null',smr);
		assertExpressionInvalidCompile('5 && true',smr);
		assertExpressionInvalidCompile('!3',smr);
		assertExpressionInvalidCompile('-"T"',smr);
    }
    /**
     * Tests the expression trees of complex expression to ensure for additional sanity check
     */
    @isTest static void testExpressionTree(){
        SymbolValueResolverMock svr = new SymbolValueResolverMock();
        SymbolModelResolverMock smr = new SymbolModelResolverMock(svr);
        Expr_Expr e;
        Expr_Expr.SymbolExpression s;
        Expr_Expr[] params;
        e = Expr_Expr.compile('  test.NumFive / 2 + (5 - 3) * -2.5    ', smr);
        assertExprTreeNode(e,Expr_Expr.T_PLUS,true,true,null,false,false);
        assertExprTreeNode(e.getLeftSubExpression(),Expr_Expr.T_DIV,true,true,null,false,false);
        assertExprTreeNode(e.getLeftSubExpression().getLeftSubExpression(),Expr_Expr.T_SYMBOL,false,false,null,true,false);
        assertExprTreeNode(e.getLeftSubExpression().getRightSubExpression(),Expr_Expr.T_NUM,false,false,'2',false,false);
        assertExprTreeNode(e.getRightSubExpression(),Expr_Expr.T_MULT,true,true,null,false,false);
        assertExprTreeNode(e.getRightSubExpression().getLeftSubExpression(),Expr_Expr.T_MINUS,true,true,null,false,false);
        assertExprTreeNode(e.getRightSubExpression().getLeftSubExpression().getLeftSubExpression(),Expr_Expr.T_NUM,false,false,'5',false,false);
        assertExprTreeNode(e.getRightSubExpression().getLeftSubExpression().getRightSubExpression(),Expr_Expr.T_NUM,false,false,'3',false,false);
        assertExprTreeNode(e.getRightSubExpression().getRightSubExpression(),Expr_Expr.T_NEG,false,true,null,false,false);
        assertExprTreeNode(e.getRightSubExpression().getRightSubExpression().getRightSubExpression(),Expr_Expr.T_NUM,false,false,'2.5',false,false);
        s = e.getLeftSubExpression().getLeftSubExpression().getSymbol();
        System.assertEquals('test.NumFive',s.getDisplayName());
        System.assertEquals(1,s.path.size());
        System.assertEquals('test',s.sourceRef);
        System.assertEquals('NumFive',s.path[0].field);
        System.assertEquals(s.getDisplayName().hashCode(),s.hashCode());


        e = Expr_Expr.compile('TESTFUN(test.NumFive==(3+3),4,2) + TESTFUN(test.NumFive==(2+3),17,1)',smr);
        assertExprTreeNode(e,Expr_Expr.T_PLUS,true,true,null,false,false);
        assertExprTreeNode(e.getLeftSubExpression(),Expr_Expr.T_SYMBOL,false,false,null,false,true);
        assertExprTreeNode(e.getRightSubExpression(),Expr_Expr.T_SYMBOL,false,false,null,false,true);
        params = e.getLeftSubExpression().getFunctionParameters();
        System.assertNotEquals(null,params);
        System.assertEquals(3,params.size());
        System.assertNotEquals(null,params[0]);
        System.assertNotEquals(null,params[1]);
        System.assertNotEquals(null,params[2]);

        assertExprTreeNode(params[0],Expr_Expr.T_EQ,true,true,null,false,false);
        assertExprTreeNode(params[0].getLeftSubExpression(),Expr_Expr.T_SYMBOL,false,false,null,true,false);
        assertExprTreeNode(params[0].getRightSubExpression(),Expr_Expr.T_PLUS,true,true,null,false,false);
        assertExprTreeNode(params[0].getRightSubExpression().getLeftSubExpression(),Expr_Expr.T_NUM,false,false,'3',false,false);
        assertExprTreeNode(params[0].getRightSubExpression().getRightSubExpression(),Expr_Expr.T_NUM,false,false,'3',false,false);
        s = params[0].getLeftSubExpression().getSymbol();
        System.assertEquals('test.NumFive',s.getDisplayName());
        System.assertEquals(1,s.path.size());
        System.assertEquals('test',s.sourceRef);
        System.assertEquals('NumFive',s.path[0].field);
        System.assertEquals(s.getDisplayName().hashCode(),s.hashCode());
        assertExprTreeNode(params[1],Expr_Expr.T_NUM,false,false,'4',false,false);
        assertExprTreeNode(params[2],Expr_Expr.T_NUM,false,false,'2',false,false);

        params = e.getRightSubExpression().getFunctionParameters();
        System.assertNotEquals(null,params);
        System.assertEquals(3,params.size());
        System.assertNotEquals(null,params[0]);
        System.assertNotEquals(null,params[1]);
        System.assertNotEquals(null,params[2]);

        assertExprTreeNode(params[0],Expr_Expr.T_EQ,true,true,null,false,false);
        assertExprTreeNode(params[0].getLeftSubExpression(),Expr_Expr.T_SYMBOL,false,false,null,true,false);
        assertExprTreeNode(params[0].getRightSubExpression(),Expr_Expr.T_PLUS,true,true,null,false,false);
        assertExprTreeNode(params[0].getRightSubExpression().getLeftSubExpression(),Expr_Expr.T_NUM,false,false,'2',false,false);
        assertExprTreeNode(params[0].getRightSubExpression().getRightSubExpression(),Expr_Expr.T_NUM,false,false,'3',false,false);
        s = params[0].getLeftSubExpression().getSymbol();
        System.assertEquals('test.NumFive',s.getDisplayName());
        System.assertEquals(1,s.path.size());
        System.assertEquals('test',s.sourceRef);
        System.assertEquals('NumFive',s.path[0].field);
        System.assertEquals(s.getDisplayName().hashCode(),s.hashCode());
        assertExprTreeNode(params[1],Expr_Expr.T_NUM,false,false,'17',false,false);
        assertExprTreeNode(params[2],Expr_Expr.T_NUM,false,false,'1',false,false);
    }

    /**
     * Tetss that composite expressions generates the correct required symbols
     */
    @isTest static void testCompositeExpressions(){
        SymbolValueResolverMock svr = new SymbolValueResolverMock();
        SymbolModelResolverMock smr = new SymbolModelResolverMock(svr);
        Expr_Expr e;
        Expr_Expr.SymbolCollection sc;
        Set<String> dataSymbolNames;
        e = Expr_Expr.compile('TESTFUN(1==1,NestedListObject.OUTERF1,NestedListObject.OUTERF2)[0].INNERF1',smr);
        sc = new Expr_Expr.SymbolCollection();
        e.addSymbols(sc,smr);
        System.assertEquals('V11',e.eval(svr));
        dataSymbolNames = new Set<String>();
        for(Expr_Expr.SymbolExpression sym : sc.dataSymbols){
            dataSymbolNames.add(sym.getDisplayName());
        }
        System.assertEquals(true,dataSymbolNames.contains('NestedListObject.OUTERF1'));
        System.assertEquals(true,dataSymbolNames.contains('NestedListObject.OUTERF2'));
        System.assertEquals(true,dataSymbolNames.contains('NestedListObject.OUTERF1[].INNERF1'));
        System.assertEquals(true,dataSymbolNames.contains('NestedListObject.OUTERF2[].INNERF1'));
        System.assertEquals(4,dataSymbolNames.size());


        e = Expr_Expr.compile('TESTFUN(1==2,NestedListObject.OUTERF1,TESTARRAYSOURCE())[0].INNERF1',smr);
        sc = new Expr_Expr.SymbolCollection();
        e.addSymbols(sc,smr);
        System.assertEquals('VCUSTOM',e.eval(svr));
        dataSymbolNames = new Set<String>();
        for(Expr_Expr.SymbolExpression sym : sc.dataSymbols){
            dataSymbolNames.add(sym.getDisplayName());
        }
        System.assertEquals(true,dataSymbolNames.contains('NestedListObject.OUTERF1'));
        System.assertEquals(true,dataSymbolNames.contains('NestedListObject.OUTERF1[].INNERF1'));
        System.assertEquals(2,dataSymbolNames.size());

        e = Expr_Expr.compile('TESTFUN(1==2,NestedListObject.OUTERF1,TESTFUN(1==1,NestedListObject.OUTERF2,TESTARRAYSOURCE()))[0].INNERF1',smr);
        sc = new Expr_Expr.SymbolCollection();
        e.addSymbols(sc,smr);
        System.assertEquals('V21',e.eval(svr));
        dataSymbolNames = new Set<String>();
        for(Expr_Expr.SymbolExpression sym : sc.dataSymbols){
            dataSymbolNames.add(sym.getDisplayName());
        }
        System.assertEquals(true,dataSymbolNames.contains('NestedListObject.OUTERF1'));
        System.assertEquals(true,dataSymbolNames.contains('NestedListObject.OUTERF2'));
        System.assertEquals(true,dataSymbolNames.contains('NestedListObject.OUTERF1[].INNERF1'));
        System.assertEquals(true,dataSymbolNames.contains('NestedListObject.OUTERF2[].INNERF1'));
        System.assertEquals(4,dataSymbolNames.size());

    }

    /**
     * Method to simplify asserting a tree node in an expression
     * @param e The expression tree node
     * @param tkn The expression token
     * @param isLeaf Whether the expression is a leaf node
     * @param hasLeft Whether a left sub expression exists
     * @param hasRight Whether a right sub expression exists
     * @param constVal The constant value of the expression
     * @param isDataSymbol Whether the expression is a data symbol
     * @param isFuncSymbol Whether the expression is a function symbol
     */
    static void assertExprTreeNode(Expr_Expr e,Integer tkn,Boolean hasLeft,Boolean hasRight,String constVal,Boolean isDataSymbol, Boolean isFuncSymbol){
        System.assertEquals(tkn,e.getOperatorToken());
        System.assertEquals(!hasLeft && !hasRight,e.isLeafExpr());
        System.assertEquals(hasLeft,e.getLeftSubExpression()!=null);
        System.assertEquals(hasRight,e.getRightSubExpression()!=null);
        System.assertEquals(constVal!=null,e.isConstant());
        System.assertEquals(constVal,e.getConstantValue());
        System.assertEquals(isDataSymbol,e.isData());
        System.assertEquals(isFuncSymbol,e.isFunction());
        System.assertEquals(isDataSymbol || isFuncSymbol,e.getSymbol()!=null);
    }
    /**
        Compiles the provided expression string into an expression and assert the result
        Also evaluates the JSON conversino back and foruth to ensure the conversion works correctly
        @param exprString The string expression which should be compiled
        @param smr The symbol model resolver used to resolve data and functions
        @param svr The symbol value resolver used to resolve data and functions
        @param exprectedResult The expected result from evauating the expression
    */
    private static void assertExpression(String exprString,Expr_Expr.SymbolModelResolver smr,Expr_Expr.SymbolValueResolver svr,Object expectedResult){
        Expr_Expr e = Expr_Expr.compile(exprString,smr);
        System.assertEquals(expectedResult,e.eval(svr));
        e = Expr_Expr.fromJSON(e.toJSON());
        System.assertEquals(expectedResult,e.eval(svr));
    }

    /**
        Asserts that the provided expression cannot be compiled
        @param exprString The string expression which should be compiled
        @param smr The symbol model resolver used to resolve data and functions
    */
    private static void assertExpressionInvalidCompile(String exprString,Expr_Expr.SymbolModelResolver smr){
        Boolean error = false;
        try{
            Expr_Expr e = Expr_Expr.compile(exprString,smr);
        }
        catch(Exception e){
            error = true;
        }
        System.assert(error,'Unexpected successful compile of expression: '+exprString);
    }


    /**
		Mock symbol resolver to test custom data and functions
	*/
	global class SymbolValueResolverMock extends Expr_Expr.SymbolValueResolver{
		/**
			Map from symbol name to data value
		*/
		private Map<String,Object> dataValMap;

		/**
			Map from symbol name to data type
		*/
		private Map<String,Type> dataTypeMap;

		/**
			Creates a symbol resolver mock instance
		*/
		private SymbolValueResolverMock(){
			dataValMap = new Map<String,Object>();
			dataTypeMap = new Map<String,Type>();
			addData('test.boolT',true,Boolean.class);
			addData('test.boolF',false,Boolean.class);
			addData('test.String','TEST',String.class);
			addData('test.NumFive',5,Decimal.class);
            addData('test.NumSeven',7,Decimal.class);
            addData('test.GenericObjectType',new Map<String,String>{'Key'=>'Value'},Object.class);
            addData('NestedListObject',new Map<String,Object>{
                'OUTERF1'=>new List<Object>{
                    new Map<String,Object>{'INNERF1'=>'V11'}
                },
                'OUTERF2'=>new List<Object>{
                    new Map<String,Object>{'INNERF1'=>'V21'}
                }
            },Object.class);
		}

		/**
			Adds the data to the symbol resolver
			@param f The name of the symbol registered as data
			@param val The data value
			@param t The data type
		*/
		private void addData(String f,Object val,Type t){
			dataValMap.put(f,val);
			dataTypeMap.put(f,t);
        }

        /**
		 * Retrieves the value provider for the supplied function source reference and reference path
		 * @param sourceRef The function source reference
		 * @param exprParamList The expression used as parameters to the function 
		 * @param path The reference path from which to retrieve the value
		 * @return The data value for the data source and reference path
		 */
		global override Object getFunctionValue(String sourceRef,Expr_Expr[] exprParamList,SymbolSubReference[] path){
			if(sourceRef=='TESTFUN'){
                return getData((Boolean)eval(exprParamList[0]) ? eval(exprParamList[1]) : eval(exprParamList[2]),path);
            }
            if(sourceRef=='TESTARRAYSOURCE'){
                return new List<Object>{
                    new Map<String,Object>{'INNERF1'=>'VCUSTOM'}
                };
            }
			return null;
        }
        
		/**
			Retrieves the value stored for the symbol
			@param sym The symbol which value to retrieve
			@return The current value for the symbol
		*/
		global override Object getDataValue(String sourceRef,Expr_Expr.SymbolSubReference[] path){
            if(sourceRef=='NestedListObject')return getData(dataValMap.get(sourceRef),path);
            String s = sourceRef;
            for(Expr_Expr.SymbolSubReference ref : path){
                s += '.'+ref.field;
            }
			return dataValMap.get(s);
		}
    }
    
    /**
		Mock symbol resolver to test custom data and functions
	*/
	global class SymbolModelResolverMock extends Expr_Expr.SymbolModelResolver{
        /**
         * The mock symbol value resolver
         */
        SymbolValueResolverMock svr;

        /**
         * Creates a symbol resolver mock instance
         * @param svr The mock symbol value resolver
         */
		private SymbolModelResolverMock(SymbolValueResolverMock svr){
            this.svr = svr;
        }

        /**
			Returns the type for the value of the provided symbol
			@param sym The symbol to retrieve the type of
			@return The type of the symbol value
		*/
		global override Type getDataType(String sourceRef,Expr_Expr.SymbolSubReference[] path){
            if(svr.dataTypeMap.containsKey(sourceRef))return svr.dataTypeMap.get(sourceRef);
            String s = sourceRef;
            for(Expr_Expr.SymbolSubReference ref : path){
                s += '.'+ref.field;
            }
			return svr.dataTypeMap.get(s);
		}
        /**
		 * Retrieves the resulting data type from the function
		 * @param sourceRef The function source reference
		 * @param exprParamList The expressions used as parameters to the function 
		 * @param path The reference path from which to retrieve the type
		 * @return The type of the function
		 */
        global override Type getFunctionType(String sourceRef,Expr_Expr[] exprParamList,SymbolSubReference[] path){
            if(sourceRef=='TESTFUN'){
                Type t = Object.class;
                if(exprParamList[1].getType()== exprParamList[1].getType())t = exprParamList[1].getType();
                return t;
            }
            if(sourceRef=='TESTARRAYSOURCE'){
                return List<Object>.class;
            }
            return null;
        }

        /**
		 * Retrieves any eventual composite symbol expressions generated by the function. I.e. where the returned 
		 * value is composed from a combination sub fields of its parameters and thus requires additional data to
		 * be fetched.
		 * @param sourceRef The function source reference
		 * @param exprParamList The expressions used as parameters to the function 
		 * @param path The reference path used to build the composite expressions
		 * @return Any eventual composite symbool expressions required from running the function
		 */
        global override SymbolExpression[] getCompositeSymbols(String sourceRef,Expr_Expr[] exprParamList,SymbolSubReference[] path){
            if(sourceRef=='TESTFUN'){
                List<Expr_Expr.SymbolExpression> compositeExprList = new List<Expr_Expr.SymbolExpression>();
                List<Expr_Expr.SymbolExpression> se1 = createRootCompositeExpressions(exprParamList[1],path);
                List<Expr_Expr.SymbolExpression> se2 = createRootCompositeExpressions(exprParamList[2],path);
                if(se1!=null)compositeExprList.addAll(se1);
                if(se2!=null)compositeExprList.addAll(se2);
                return compositeExprList;
            }
            return null;
        }
    }
}
