/**
	THe expression class provides functionality to compile and evaluate
	expressions. The expression supports simple logical math and string operations.
	The supported operations are listed below specified in order of priority.
	---
	Constant Number
	Constant String
	Constant Boolean
	Data symbols
	Function Symbols
	---
	-  negation
	!  logical negation
	---
	*  multiplication
	/  division
	---
	+  addition
	-  subtraction
	&  concatenation
	---
	<  less than
	<= less or equal than
	>  greater than
	>= greater or equal than
	---
	== equality
	!= non equality
	---
	&& logical and
	---
	|| logical or

	The expression supports providing a symbol resolver to provide resolution for data
	and function symbols.

	@author Peter Södergren
*/
global with sharing class Expr_Expr {
	/**
		Excpetions thrown when the expression cannot be compiled
	*/
	global class CompileException extends Exception{}
    /**
        Type constant for string values
    */
    private static final Integer DATA_TYPE_STRING = 1;
    /**
        Type constant for decimal values
    */
    private static final Integer DATA_TYPE_NUM = 2;
    /**
        Type constant for boolean values
    */
	private static final Integer DATA_TYPE_BOOL = 3;
	/**
        Type constant for object values
    */
	private static final Integer DATA_TYPE_OBJECT = 4;
	/**
        Type constant for list values
    */
    private static final Integer DATA_TYPE_LIST = 5;
    /**
        Pattern used to split name by the '.' denominator
    */
	private static final Pattern DOT_PATTERN = Pattern.compile('\\.');
	/**
	 * Type constant for data symbol sources
	 */
	private static final Integer SYM_SOURCE_DATA = 1;
	/**
	 * Type constant for function symbol sources
	 */
	private static final Integer SYM_SOURCE_FUNCTION = 2;


	/**
		The token of the expression
	*/
	Integer tkn;
	/**
		The value in case of a primary parameter
	*/
	String val;
	/**
	 * The symbol expresion in case of a symbol expression
	 */
	SymbolExpression sym;
	/**
		The expression on the left side of the operator
	*/
	Expr_Expr eLeft;
	/**
		The expression on the right side of the expression
	*/
	Expr_Expr eRight;
	/**
		The implementation of the type which executes the expression
	*/
	transient ExprImpl impl;
	/**
		The index of the token in string
	*/
	transient Integer idx;
	/**
		Set temporarily during evaluation to allow for symbol resolve without adding the symbol resolver as a parameter in the tree evaluation
	*/
	static SymbolValueResolver SYM_RESOLVER;
	/**
		Creates a base expression for a primary expression
		@param t The expression token of the primary expression
		@param val The string value fo the primary expression
	*/
	private Expr_Expr(ExprToken t, String val){
		this.tkn = t.tkn;
		this.val = val;
		this.idx = t.idx;
	}
	/**
		Creates an expression where an operator is applied to expressions on each side
		@param eLeft The expression on the left side of the operator
		@param op The expression token used for the operator of the expression
		@param eRight The expression on the right side of the operator
	*/
	private Expr_Expr(Expr_Expr eLeft, ExprToken op, Expr_Expr eRight){
		this.tkn = op.tkn;
		this.eLeft = eLeft;
		this.eRight = eRight;
		this.idx = op.idx;
		if(eLeft==null)throw new CompileException('Cannot find left side expression for operator at index: '+op.idx);
		if(eRight==null)throw new CompileException('Cannot find right side expression for operator at index: '+op.idx);
	}

	/**
		Creates an expression where the operator is applied to the expression on the right side
		@param op The expression token used for the operator of the expression
		@param eRight The expression on the right side of the operator
	*/
	private Expr_Expr(ExprToken op, Expr_Expr eRight){
		this.tkn = op.tkn;
		this.eRight = eRight;
		this.idx = op.idx;
		if(eRight==null)throw new CompileException('Cannot find right side expression for operator at index: '+op.idx);
	}

	/**
		Creates an expression for a primary attribute reference to a symbol expression
		@param t The expression token of the field expression
		@param sym The symbol expression
	*/
	private Expr_Expr(ExprToken t, SymbolExpression sym){
		this.tkn = t.tkn;
		this.sym = sym;
		this.idx = t.idx;
	}

	/**
		Builds the expression by setting the expression implementation of each
		node in the expression tree
	*/
	private void build(){
		impl = EXPR_IMPL[tkn];
		if(eLeft!=null)eLeft.build();
		if(eRight!=null)eRight.build();
		if(sym!=null){
			if(sym.parameterList!=null){
				for(Integer i=0,sz=sym.parameterList.size();i<sz;i++){
					sym.parameterList[i].build();
				}
			}
			if(sym.path!=null){
				for(Integer i=0,sz=sym.path.size();i<sz;i++){
					if(sym.path[i].e!=null)sym.path[i].e.build();
				}
			}
		}
	}

	/**
		Sets the dynamic type values of all resolved expression.
		Recursively traverses the tree setting the type using the resolver
		@param smr The symbol model resolver to determine symbol validity and type
	*/
	private void setDynamicTypes(SymbolModelResolver smr){
		if(tkn==T_SYMBOL){
			sym.setDynamicTypes(smr,idx);
		}
		else {
			if(eLeft!=null)eLeft.setDynamicTypes(smr);
			if(eRight!=null)eRight.setDynamicTypes(smr);
		}
	}

	/**
		Evaluates the expression using the expression implementation
		@param svr The symbol value resolver providing values for the symbols in the expression (data and functions)
		@return The result of evaluating the expression
	*/
	global Object eval(SymbolValueResolver svr){
		SYM_RESOLVER = svr;
		Object o = eval();
		SYM_RESOLVER = null;
		return o;
	}

	/**
		Retrieves the symbols references by the expression
		@param smr The symbol model resolver used to retrieve resulting function symbols
		@return The symbols referenced by the collection
	*/
	global SymbolCollection retrieveSymbols(SymbolModelResolver smr){
		SymbolCollection sc = new SymbolCollection();
		addSymbols(sc,smr);
		return sc;
	}
	/**
		Adds the referenced symbols into the provided symbol collection
		@param sc The symbol collection into which the symbols should be added
		@param smr The symbol model resolver used to retrieve resulting function symbols
	*/
	global void addSymbols(SymbolCollection sc,SymbolModelResolver smr){
		if(tkn==T_SYMBOL && sym.sourceType==SYM_SOURCE_DATA)sc.dataSymbols.add(sym);
		if(tkn==T_SYMBOL && sym.sourceType==SYM_SOURCE_FUNCTION){
			sc.functionSymbols.add(sym);
			SymbolExpression[] cSymList = smr.getCompositeSymbols(sym.sourceRef, sym.parameterList, sym.path);
			if(cSymList!=null)sc.dataSymbols.addAll(cSymList);
		}
		if(eLeft!=null)eLeft.addSymbols(sc,smr);
		if(eRight!=null)eRight.addSymbols(sc,smr);
		if(sym!=null && sym.parameterList!=null){
			for(Integer i=0,sz=sym.parameterList.size();i<sz;i++){
				sym.parameterList[i].addSymbols(sc,smr);
			}
		}
	}

	/**
		Evaluates the expression using the expression implementation, using the currently set field resolver
		@return The result of evaluating the expression
	*/
	private Object eval(){
		return impl.eval(this);
	}

	/**
	 * @return The type of the result fo the expression
	 */
	global Type getType(){
		return impl.getType(this);
	}
	/**
	 * Returns whether the expression node is a function
	 * @return Whether the expression node is a function
	 */
	global Boolean isFunction(){
		return tkn == T_SYMBOL && sym.sourceType==SYM_SOURCE_FUNCTION;
	}
	/**
	 * Returns whether the expression node is a data symbol
	 * @return Whether the expression node is a data symbol
	 */
	global Boolean isData(){
		return tkn == T_SYMBOL && sym.sourceType==SYM_SOURCE_DATA;
	}
	/**
	 * Returns whether the expression node is constant
	 * @return Whether the expression node is constant
	 */
	global Boolean isConstant(){
		return tkn == T_BOOL || tkn == T_NUM || tkn == T_STRING || tkn == T_NULL;
	}
	/**
	 * Retrieves the operator token of the expression
	 * @return The operator token of the expression
	 */
	global Integer getOperatorToken(){
		return tkn;
	}
	/**
	 * Retireves the constant value of the expression if this expression is a
	 * constant, otherwise null is returned
	 * @return The constant value of the expression
	 */
	global String getConstantValue(){
		return val;
	}
	/**
	 * Retrieves the function parameter expressions
	 * Note: this value is null unless the expression node is a function
	 * @return The list of parameter expressions
	 */
	global Expr_Expr[] getFunctionParameters(){
		return sym!=null ? sym.parameterList : null;
	}
	/**
	 * Retrieves the symbol expression associated with this expression
	 * Note: this value is null unless the expression is a symbol
	 * @return The symbol expression of this expression
	 */
	global SymbolExpression getSymbol(){
		return sym;
	}
	/**
	 * Returns whether the expression is a leaf expression in the expression graph
	 * I.e. evaluating this expression wille not add any more sub expression unless
	 * the expression evaluated is a function with parameters.
	 * @return Whether the expression is a leaf expression
	 */
	global Boolean isLeafExpr(){
		return eLeft==null && eRight==null;
	}
	/**
	 * Retrieves the left sub expression of this expression in the expression tree
	 * @return The left sub expression
	 */
	global Expr_Expr getLeftSubExpression(){
		return eLeft;
	}

	/**
	 * Retrieves the right sub expression of this expression in the expression tree
	 * @return The right sub expression
	 */
	global Expr_Expr getRightSubExpression(){
		return eRight;
	}

	/**
		Validates the expression tree tro ensure that the expression is valid
	*/
	private void validate(){
		impl.validateTree(this);
	}

	/**
		@return A serialized JSON version of the expression
	*/
	global String toJSON(){
		return JSON.serialize(this);
	}

	/**
		Deserialzies the compiled expression using the provided JSON string.
		@param jsonStr The JSON string of the expression
	*/
	global static Expr_Expr fromJSON(String jsonStr){
		Expr_Expr e = (Expr_Expr)JSON.deserialize(jsonStr,Expr_Expr.class);
		e.build();
		return e;
	}

	/**
		Character constants
	*/
	static final Integer C_OR = 124;
	static final Integer C_AND = 38;
	static final Integer C_BANG = 33;
	static final Integer C_LT = 60;
	static final Integer C_EQ = 61;
	static final Integer C_GT = 62;
	static final Integer C_MULT = 42;
	static final Integer C_DIV = 47;
	static final Integer C_PLUS = 43;
	static final Integer C_MINUS = 45;
	static final Integer C_LPAREN = 40;
	static final Integer C_RPAREN = 41;
	static final Integer C_DQOUT = 34;
	static final Integer C_SQUOT = 39;
	static final Integer C_ESC = 92;
	static final Integer C_SPACE = 32;
	static final Integer C_CR = 13;
	static final Integer C_LF = 10;
	static final Integer C_DOT = 46;
	static final Integer C_COMMA = 44;
	static final Integer C_LSQBRACKET = 91;
	static final Integer C_RSQBRACKET = 93;
	static final Integer C_LCUBRACKET = 123;
	static final Integer C_RCUBRACKET = 125;


	/**
		Token constants
	*/
	global static final Integer T_OR = 0;
	global static final Integer T_AND = 1;
	global static final Integer T_EQ = 2;
	global static final Integer T_NEQ = 3;
	global static final Integer T_LT = 4;
	global static final Integer T_LEQT = 5;
	global static final Integer T_GT = 6;
	global static final Integer T_GEQT = 7;
	global static final Integer T_PLUS = 8;
	global static final Integer T_MINUS = 9;
	global static final Integer T_CONCAT = 10;
	global static final Integer T_MULT = 11;
	global static final Integer T_DIV = 12;
	global static final Integer T_NOT = 13;
	global static final Integer T_NEG = 14;
	static final Integer T_LPAREN = 15;
	static final Integer T_RPAREN = 16;
	global static final Integer T_BOOL = 17;
	global static final Integer T_NUM = 18;
	global static final Integer T_STRING = 19;
	global static final Integer T_NULL = 20;
	static final Integer T_COMMA = 21;
	static final Integer T_NAME = 22;
	static final Integer T_LSQBRACKET = 23;
	static final Integer T_RSQBRACKET = 24;
	static final Integer T_FIELDACCESS = 25;
	global static final Integer T_SYMBOL = 26;

	/**
		List of expression implementations by token
	*/
	private static ExprImpl[] EXPR_IMPL;

	/**
		Instantiates the expression implementaions to use for each token
	*/
	static{
		ExprImpl eLogic = new ExprLOGIC();
		ExprImpl eEq = new ExprEQ();
		ExprImpl eComp = new ExprCOMP();
		ExprImpl eMath = new ExprMATH();

		EXPR_IMPL = new ExprImpl[T_SYMBOL+1];
		EXPR_IMPL[T_OR] = eLogic;
		EXPR_IMPL[T_AND] = eLogic;
		EXPR_IMPL[T_NOT] = eLogic;
		EXPR_IMPL[T_EQ] = eEq;
		EXPR_IMPL[T_NEQ] = eEq;
		EXPR_IMPL[T_LT] = eComp;
		EXPR_IMPL[T_LEQT] = eComp;
		EXPR_IMPL[T_GT] = eComp;
		EXPR_IMPL[T_GEQT] = eComp;
		EXPR_IMPL[T_PLUS] = eMath;
		EXPR_IMPL[T_MINUS] = eMath;
		EXPR_IMPL[T_MULT] = eMath;
		EXPR_IMPL[T_DIV] = eMath;
		EXPR_IMPL[T_NEG] = eMath;
		EXPR_IMPL[T_CONCAT] = new ExprCONCAT();
		EXPR_IMPL[T_BOOL] = new ExprBOOL();
		EXPR_IMPL[T_NUM] = new ExprNUM();
		EXPR_IMPL[T_STRING] = new ExprSTRING();
		EXPR_IMPL[T_NULL] = new ExprNULL();
		EXPR_IMPL[T_SYMBOL] = new ExprSymbol();
	}


	/**
		Compiles the supplied expression string into an expression
		The compiler accepts an optional symbol resolver. If the resolver is present static typing
		is evaluated when compiling, otherwise dynamic typing will be conducted on runtime.
		@param exprString The expression in string format
		@param smr The symbol model resolver to determine symbol validity and type (optional)
		@throws CompileExpression Thrown when there is an issue compiling the expression
		@return The compiled expression
	*/
	global static Expr_Expr compile(String exprString,SymbolModelResolver smr){
		ExprToken[] tokens = lexer(exprString);
		Parser p = new Parser(tokens);
		Expr_Expr e = p.parse();
		e.build();
		if(smr!=null)e.setDynamicTypes(smr);
		e.validate();
		return e;
	}

	/**
		Splits the epression string into expression parts as a starting point for compiling the expression
		@param exprString The expression in string format
		@return The list of expression tokens of the expression string
	*/
	private static ExprToken[] lexer(String exprString){
		Integer sz = exprString.length();
		Integer lastChar = null;
		Integer c = null;
		Integer cNext = sz>0 ? exprString.charAt(0) : null;
		List<ExprToken> tList = new List<ExprToken>();
		for(Integer i=0;i<sz;i++){
			c = cNext;
			cNext = sz>(i+1) ? exprString.charAt(i+1) : null;
			if(c!=C_SPACE && c!=C_CR && c!=C_LF){
				if(isCtrlChar(c)){
					Integer tkn = null;
					if(c==C_OR && cNext==C_OR)tkn = T_OR;
					else if(c==C_AND){
						if(cNext==C_AND)tkn = T_AND;
						else tkn = T_CONCAT;
					}
					else if(c==C_LT){
						if(cNext==C_EQ)tkn = T_LEQT;
						else tkn = T_LT;
					}
					else if(c==C_GT){
						if(cNext==C_EQ)tkn = T_GEQT;
						else tkn = T_GT;
					}
					else if(c==C_EQ && cNext==C_EQ)tkn = T_EQ;
					else if(c==C_BANG){
						if(cNext==C_EQ)tkn = T_NEQ;
						else tkn = T_NOT;
					}
					else if(c==C_MULT)tkn = T_MULT;
					else if(c==C_DIV)tkn = T_DIV;
					else if(c==C_PLUS)tkn = T_PLUS;
					else if(c==C_MINUS)tkn = T_MINUS;
					else if(c==C_LPAREN)tkn = T_LPAREN;
					else if(c==C_RPAREN)tkn = T_RPAREN;
					else if(c==C_COMMA)tkn = T_COMMA;
					else if(c==C_LSQBRACKET)tkn = T_LSQBRACKET;
					else if(c==C_RSQBRACKET)tkn = T_RSQBRACKET;
					else if(c==C_DOT){
						Integer iStart = i;
						while(cNext!=null && !isCtrlChar(cNext)){
							i++;
							cNext = sz>(i+1) ? exprString.charAt(i+1) : null;
						}
						String var = exprString.substring(iStart+1,i+1);
						tList.add(new ExprToken(T_FIELDACCESS,iStart,var));
					}
					else if(c==C_SQUOT || c==C_DQOUT){
						Integer iStart = i;
						Boolean escMode = false;
						Integer cStart = c;
						i++;
						c = cNext;
						cNext = sz>(i+1) ? exprString.charAt(i+1) : null;
						Integer pStart = i;
						String val = '';
						while(cNext!=null && (c!=cStart || escMode)){
							escMode = false;
							if(c==C_ESC){
								val+=exprString.substring(pStart,i);
								escMode = true;
								pStart = i+1;
								if(pStart>=sz)throw new CompileException('Unexpected end of expression in escape mode at index: '+i);
							}
							i++;
							c = cNext;
							cNext = sz>(i+1) ? exprString.charAt(i+1) : null;
						}
						if(cNext==null && (c!=cStart || escMode))throw new CompileException('Unexpected end of expression in string mode at index: '+iStart);
						val+=exprString.substring(pStart,i);
						tList.add(new ExprToken(T_STRING,iStart,val));
					}
					else throw new CompileException('Unexpected control character "'+exprString.substring(i,i+1)+'" at index: '+i);
					if(tkn!=null){
						tList.add(new ExprToken(tkn,i));
						if(tkn==T_AND || tkn==T_EQ || tkn==T_OR || tkn==T_LEQT || tkn==T_GEQT || tkn==T_NEQ){
							i++;
							c = cNext;
							cNext = sz>(i+1) ? exprString.charAt(i+1) : null;
						}
					}
				}
				else {
					Integer iStart = i;
					Integer cStart = c;
					while(cNext!=null && !isCtrlChar(cNext)){
						i++;
						cNext = sz>(i+1) ? exprString.charAt(i+1) : null;
					}
					String var = exprString.substring(iStart,i+1);
					if(var=='false' || var=='true')tList.add(new ExprToken(T_BOOL,iStart,var));
					else if(var=='null')tList.add(new ExprToken(T_NULL,iStart,var));
					else if(cStart>=48 && cStart<=57){
						//Parse number
						if(cNext==C_DOT){
							i++;
							cNext = sz>(i+1) ? exprString.charAt(i+1) : null;
							while(cNext!=null && !isCtrlChar(cNext)){
								i++;
								cNext = sz>(i+1) ? exprString.charAt(i+1) : null;
							}
							String dec = exprString.substring(iStart+var.length()+1,i+1);
							if(dec.length()==0)throw new CompileException('Number cannot end with "." at index: '+iStart);
							if(!var.isNumeric())throw new CompileException('Cannot parse number at index: '+iStart);
							if(!dec.isNumeric())throw new CompileException('Cannot parse number at index: '+iStart);
							var = var+'.'+dec;
						}
						else {
							if(!var.isNumeric())throw new CompileException('Cannot parse number at index: '+iStart);
						}
						tList.add(new ExprToken(T_NUM,iStart,var));
					}
					else {
						//Parse expression field
						tList.add(new ExprToken(T_NAME,iStart,var));
					}
				}
			}
		}
		return tList;
	}

	/**
		Returns whether the supplied character is a control character
		@param c The character to check
		@return Whether the character is a control char
	*/
	private static Boolean isCtrlChar(Integer c){
		return c<=47 || (c>=58 && c<=64) || (c>=91 && c<=94) || c>=123;
	}

	/**
		Represents an expression token created by the lexer
	*/
	private class ExprToken{
		/**
			The value of a primary expression in string form
		*/
		String val;
		/**
			The token of the expression
		*/
		Integer tkn;
		/**
			THe start index of the expression
		*/
		Integer idx;
		/**
			Creates an operator expression token
			@param tkn The token of the expression
			@param idx The start index of the expression
		*/
		private ExprToken(Integer tkn, Integer idx){
			this.tkn=tkn;
			this.idx=idx;
		}
		/**
			Creates a primary value expression
			@param tkn The token of the expression
			@param idx The start index of the expression
			@param val The value of the symbol expression
		*/
		private ExprToken(Integer tkn, Integer idx, String val){
			this(tkn,idx);
			this.val = val;
		}
	}

	/**
		Class used to parse the tokens into an expression
		The parser uses a recursive descent algorithm
	*/
	private class Parser{
		/**
			The list of expression tokens to parse
		*/
		ExprToken[] tList;
		/**
			The size of the token list
		*/
		Integer sz;
		/**
			The current token
		*/
		ExprToken t;
		/**
			The next token
		*/
		ExprToken tNext;
		/**
			The current token index
		*/
		Integer idx;

		/**
			Creates a new parser instance
			@param tList The list of expression tokens to parse
		*/
		private Parser(ExprToken[] tList){
			this.tList = tList;
			this.sz = tList.size();
		}
		/**
			Parses the tokens into an expression
		*/
		private Expr_Expr parse(){
			t = null;
			tNext = sz>0 ? tList[0] : null;
			idx=-1;
			Expr_Expr e = parseOr();
			if(e==null)throw new CompileException('Empty expression cannot be compiled');
			if(idx<(sz-1))throw new CompileException('Unexpected end of expression at index: '+(t==null ? 0 : t.idx));
			return e;
		}

		/**
			Checks whether the next token matches any of the supplied tokens
			@param t1 A token to check against
			@return Whether the next token matched any of the supplied tokens
		*/
		private Boolean match(Integer t1){
			if(tNext!=null && (tNext.tkn == t1)){
				advance();
				return true;
			}
			return false;
		}

		/**
			Checks whether the next token matches any of the supplied tokens
			@param t1 A token to check against
			@param t2 A token to check against
			@return Whether the next token matched any of the supplied tokens
		*/
		private Boolean match(Integer t1,Integer t2){
			if(tNext!=null && (tNext.tkn == t1 || tNext.tkn == t2)){
				advance();
				return true;
			}
			return false;
		}

		/**
			Checks whether the next token matches any of the supplied tokens
			@param t1 A token to check against
			@param t2 A token to check against
			@param t3 A token to check against
			@param t4 A token to check against
			@return Whether the next token matched any of the supplied tokens
		*/
		private Boolean match(Integer t1,Integer t2,Integer t3,Integer t4){
			if(tNext!=null && (tNext.tkn == t1 || tNext.tkn == t2 || tNext.tkn == t3 || tNext.tkn == t4)){
				advance();
				return true;
			}
			return false;
		}
		/**
			Advances one step in the token list
		*/
		private void advance(){
			idx++;
			t = tNext;
			tNext = idx+1<sz ? tList[idx+1] : null;
		}

		/**
			Hierarchical parse function, parsing or
		*/
		private Expr_Expr parseOr(){
			Expr_Expr e = parseAnd();
			while(match(T_OR)){
				e = new Expr_Expr(e,t,parseAnd());
			}
			return e;
		}

		/**
			Hierarchical parse function, parsing and
		*/
		private Expr_Expr parseAnd(){
			Expr_Expr e = parseEq();
			while(match(T_AND)){
				e = new Expr_Expr(e,t,parseEq());
			}
			return e;
		}

		/**
			Hierarchical parse function, parsing equality
		*/
		private Expr_Expr parseEq(){
			Expr_Expr e = parseComp();
			while(match(T_EQ,T_NEQ)){
				e = new Expr_Expr(e,t,parseComp());
			}
			return e;
		}

		/**
			Hierarchical parse function, parsing comparisons
		*/
		private Expr_Expr parseComp(){
			Expr_Expr e = parseAdd();
			while(match(T_LT,T_LEQT,T_GT,T_GEQT)){
				e = new Expr_Expr(e,t,parseAdd());
			}
			return e;
		}

		/**
			Hierarchical parse function, parsing additions
		*/
		private Expr_Expr parseAdd(){
			Expr_Expr e = parseMult();
			while(match(T_PLUS,T_MINUS,T_CONCAT,null)){
				e = new Expr_Expr(e,t,parseMult());
			}
			return e;
		}

		/**
			Hierarchical parse function, parsing multiplication
		*/
		private Expr_Expr parseMult(){
			Expr_Expr e = parseUnary();
			while(match(T_MULT,T_DIV)){
				e = new Expr_Expr(e,t,parseUnary());
			}
			return e;
		}

		/**
			Hierarchical parse function, parsing unary functions
		*/
		private Expr_Expr parseUnary(){
			if(tNext!=null && tNext.tkn==T_MINUS)tNext.tkn=T_NEG;
			if(match(T_NEG,T_NOT)){
				return new Expr_Expr(t,parseUnary());
			}
			return parsePrimary();
		}

		/**
			Hierarchical parse function, parsing primary values, fields and groups
		*/
		private Expr_Expr parsePrimary(){
			Expr_Expr e;
			Integer symType;
			if(match(T_BOOL,T_NUM,T_STRING,T_NULL))e=new Expr_Expr(t,t.val);
			else if(match(T_NAME)){
				ExprToken et = t;
				et.tkn = T_SYMBOL;
				List<Expr_Expr> paramList;
				if(match(T_LPAREN)){
					//Is a function
					paramList = new List<Expr_Expr>();
					Integer pStartIdx = t.idx;
					Boolean first = true;
					while(!match(T_RPAREN)){
						if(!first){
							if(!match(T_COMMA))throw new CompileException('Missing ")" or "," when evaluating function at index: '+pStartIdx);
						}
						else first=false;
						Expr_Expr p = parseOr();
						if(p==null)throw new CompileException('Cannot find match matching closing parenthesis for function from index: '+pStartIdx);
						paramList.add(p);
					}
				}
				List<SymbolSubReference> refPath = new List<SymbolSubReference>();
				//Match to retrieve data access parameter of root value
				while(match(T_FIELDACCESS,T_LSQBRACKET)){
					if(t.tkn==T_FIELDACCESS)refPath.add(new SymbolSubReference(t.val));
					else {
						Integer pStartIdx = t.idx;
						refPath.add(new SymbolSubReference(parseOr()));
						if(!match(T_RSQBRACKET))throw new CompileException('Cannot find match matching closing square brackets from index: '+pStartIdx);
					}
				}
				e = new Expr_Expr(et,paramList!=null ? new SymbolExpression(et.val,paramList,refPath) : new SymbolExpression(et.val,refPath));
			}
			else if(match(T_LPAREN)){
				Integer pStartIdx = t.idx;
				//Starts from beginning of hierarchy as a sub expression
				e = parseOr();
				if(e==null)throw new CompileException('Sub expression cannot be empty at index: '+pStartIdx);
				if(!match(T_RPAREN))throw new CompileException('Cannot find match matching closing parenthesis from index: '+pStartIdx);
			}
			return e;
		}
	}

	/**
		Base class for sub classes implementing an expression
	*/
	private abstract class ExprImpl{
		/**
			Evaluates the expression and returning the result
			@param e The expression to evaluate
			@return The result of the evaluation
		*/
		private abstract Object eval(Expr_Expr e);
		/**
			Retireves the type of the result
			@param e The expression to evaluate
			@return The type of the result of the expression
		*/
		private abstract Type getType(Expr_Expr e);
		/**
			Validates the expression tree and throws exceptions if any
			type errors are detected
			@param e The expression to evaluate
		*/
		private void validateTree(Expr_Expr e){
			if(e.eLeft!=null)e.eLeft.validate();
			if(e.eRight!=null)e.eRight.validate();
			validate(e);
		}
		/**
			Validates the expression and throws exceptions if any type errors are detected
			@param e The expression to evaluate
		*/
		private virtual void validate(Expr_Expr e){}
	}

	/**
		Implementation class for logical expressions: NOT,AND,OR
	*/
	private class ExprLOGIC extends ExprImpl{
		private override Object eval(Expr_Expr e){
			if(e.tkn==T_NOT)return !(Boolean)e.eRight.eval();
			if(e.tkn==T_AND)return (Boolean)e.eLeft.eval() && (Boolean)e.eRight.eval();
			return (Boolean)e.eLeft.eval() || (Boolean)e.eRight.eval();
		}
		private override Type getType(Expr_Expr e){return Boolean.class;}
		private override void validate(Expr_Expr e){
			if(e.tkn!=T_NOT && e.eLeft.getType()!=Boolean.class)throw new CompileException('Logic operator requires boolean expression on left side at index: '+e.idx);
			if(e.eRight.getType()!=Boolean.class)throw new CompileException('Logic operator requires boolean expression on left side at index: '+e.idx);
		}
	}
	/**
		Implementation class for equality expressions: EQ,NEQ
	*/
	private class ExprEQ extends ExprImpl{
		private override Object eval(Expr_Expr e){
			if(e.tkn==T_NEQ)return e.eLeft.eval() != e.eRight.eval();
			return e.eLeft.eval() == e.eRight.eval();
		}
		private override Type getType(Expr_Expr e){return Boolean.class;}
		private override void validate(Expr_Expr e){
			Type t1 = e.eLeft.getType();
			Type t2 = e.eRight.getType();
			if(t1!=null && t2!=null && t1!=t2)throw new CompileException('Equality operators requires the same types of expressions at both sides at index: '+e.idx);
		}
	}
	/**
		Implementation class for comparison expressions: LT,LEQT,GT,GEQT
	*/
	private class ExprCOMP extends ExprImpl{
		private override Object eval(Expr_Expr e){
			Object o1 = e.eLeft.eval();
			Object o2 = e.eRight.eval();
			Integer tkn = e.tkn;
			if(e.eLeft.getType()==Decimal.class){
				Decimal d1 = (Decimal)o1;
				Decimal d2 = (Decimal)o2;
				if(tkn==T_LT)return d1 < d2;
				if(tkn==T_LEQT)return d1 <= d2;
				if(tkn==T_GT)return d1 > d2;
				return d1 >= d2;
			}
			else{
				String s1 = (String)o1;
				String s2 = (String)o2;
				if(tkn==T_LT)return s1 < s2;
				if(tkn==T_LEQT)return s1 <= s2;
				if(tkn==T_GT)return s1 > s2;
				return s1 >= s2;
			}
		}
		private override Type getType(Expr_Expr e){return Boolean.class;}
		private override void validate(Expr_Expr e){
			Type t1 = e.eLeft.getType();
			Type t2 = e.eRight.getType();
			if(t1!=t2)throw new CompileException('Comparison operators requires the same types of expressions at both sides at index: '+e.idx);
			if(t1!=Decimal.class && t1!=String.class)throw new CompileException('Comparison operators only valid for number or string expressions at index: '+e.idx);
		}
	}

	/**
		Implementation class for math expressions: NEG,PLUS,MINUS,MULT,DIV
	*/
	private class ExprMATH extends ExprImpl{
		private override Object eval(Expr_Expr e){
			Integer tkn = e.tkn;
			Decimal d2 = (Decimal)e.eRight.eval();
			if(tkn==T_NEG)return -d2;
			Decimal d1 = (Decimal)e.eLeft.eval();
			if(tkn==T_PLUS)return d1+d2;
			if(tkn==T_MINUS)return d1-d2;
			if(tkn==T_MULT)return d1*d2;
			return d1/d2;
		}
		private override Type getType(Expr_Expr e){return Decimal.class;}
		private override void validate(Expr_Expr e){
			if((e.tkn!=T_NEG && e.eLeft.getType()!=Decimal.class) || e.eRight.getType()!=Decimal.class)throw new CompileException('Math operators only valid for number expressions at index: '+e.idx);
		}
	}

	/**
		Implementation class for string expressions: CONCAT
	*/
	private class ExprCONCAT extends ExprImpl{
		private override Object eval(Expr_Expr e){return (String)e.eLeft.eval() + (String)e.eRight.eval();}
		private override Type getType(Expr_Expr e){return String.class;}
		private override void validate(Expr_Expr e){
			if(e.eLeft.getType()!=String.class || e.eRight.getType()!=String.class)throw new CompileException('String operators only valid for string expressions at index: '+e.idx);
		}
	}

	/**
		Implementation class for boolean fixed value
	*/
	private class ExprBOOL extends ExprImpl{
		private override Object eval(Expr_Expr e){return e.val=='true';}
		private override Type getType(Expr_Expr e){return Boolean.class;}
	}

	/**
		Implementation class for string fixed value
	*/
	private class ExprSTRING extends ExprImpl{
		private override Object eval(Expr_Expr e){return e.val;}
		private override Type getType(Expr_Expr e){return String.class;}
	}

	/**
		Implementation class for number fixed value
	*/
	private class ExprNUM extends ExprImpl{
		private override Object eval(Expr_Expr e){return Decimal.valueOf(e.val);}
		private override Type getType(Expr_Expr e){return Decimal.class;}
	}

	/**
		Implementation class for null fixed value
	*/
	private class ExprNULL extends ExprImpl{
		private override Object eval(Expr_Expr e){return null;}
		private override Type getType(Expr_Expr e){return null;}
	}

	/**
	 * Implementation class for a symbol
	 */
	private class ExprSymbol extends ExprImpl{
		private override Object eval(Expr_Expr e){
			return e.sym.eval();
		}
		private override Type getType(Expr_Expr e){
			return e.sym.getType();
		}
	}

    /**
	 * Base class used for resolving symbols values in expressions
	 * Implementations should be able to provide values for data and function symbols
	 * @author Peter Södergren
	 */
    global abstract class SymbolValueResolver {
		/**
		 * Retrieves the value provider for the supplied data source reference and reference path
		 * @param sourceRef The data source reference
		 * @param path The reference path from which to retrieve the value
		 * @return The data value for the data source and reference path
		 */
		global abstract Object getDataValue(String sourceRef,SymbolSubReference[] path);

		/**
		 * Retrieves the value provider for the supplied function source reference and reference path
		 * @param sourceRef The function source reference
		 * @param exprParamList The expression used as parameters to the function 
		 * @param path The reference path from which to retrieve the value
		 * @return The data value for the data source and reference path
		 */
		global abstract Object getFunctionValue(String sourceRef,Expr_Expr[] exprParamList,SymbolSubReference[] path);

		global virtual void registerLocalVar(Object obj,String localVar) {
			//Not implemented
		}

		/**
		 * Retrieves data from the provided object source using the supplied 
		 * reference path. The method assumes that the object is either a List<Object>,
		 * a Map<String,Object>, or an SObject to enable retrieving the data from the source.
		 * If the data cannot be reached, null is returned
		 * @param o The source object
		 * @param path The reference path
		 * @return The data value of the reference path in the source object
		 */
		global Object getData(Object o,SymbolSubReference[] path){
			try{
				for(Integer i=0,sz=path.size();i<sz;i++){
					SymbolSubReference ref = path[i];	
					if(ref.field!=null){
						if(o instanceof SObject){
							Boolean err = false;
							SObject so = (SObject)o;
							try{o = so.get(ref.field);}catch(Exception e){err=true;}
							if(err){err=false; try{o = so.getSObject(ref.field);}catch(Exception e){err=true;}}
							if(err)o = so.getSObjects(ref.field);
						}
						else {
							o = ((Map<String,Object>)o).get(ref.field);
						}
						
					}
					if(ref.e!=null)o = ((List<Object>)o).get((Integer)((Decimal)ref.e.eval()));
				}
			}
			catch(Exception e){
				return null;
			}
			return o;
		}

		/**
		 * Evaluates the result of the provided expression
		 * @param e The expression to evaluate
		 * @return The value being evaluated
		 */
		protected Object eval(Expr_Expr e){
			return e.eval();
		}
	}

	/**
	 * Base class used for resolving the model for symbol values and expressions
	 * Implementations should be able to provide the type of a symbol as well as 
	 * well as define the required composite expressions
	 * @author Peter Södergren
	 */
	global abstract class SymbolModelResolver {
		/**
		 * Retrieves the data type of the referenced data source with the provided reference path
		 * @param sourceRef The data source reference
		 * @param path The reference path from which to retrieve the type
		 * @return The data type for the data source and reference path
		 */
		global abstract Type getDataType(String sourceRef,SymbolSubReference[] path);

		/**
		 * Retrieves the resulting data type from the function
		 * @param sourceRef The function source reference
		 * @param exprParamList The expressions used as parameters to the function 
		 * @param path The reference path from which to retrieve the type
		 * @return The type of the function
		 */
		global abstract Type getFunctionType(String sourceRef,Expr_Expr[] exprParamList,SymbolSubReference[] path);

		/**
		 * Retrieves any eventual composite symbol expressions generated by the function. I.e. where the returned 
		 * value is composed from a combination sub fields of its parameters and thus requires additional data to
		 * be fetched.
		 * @param sourceRef The function source reference
		 * @param exprParamList The expressions used as parameters to the function 
		 * @param path The reference path used to build the composite expressions
		 * @return Any eventual composite symbool expressions required from running the function
		 */
		global abstract SymbolExpression[] getCompositeSymbols(String sourceRef,Expr_Expr[] exprParamList,SymbolSubReference[] path);

		/**
		 * Creates composite expressions from the root expression and the reference path
		 * @param root The root expression
		 * @param path The reference path to append to the root path
		 * @return The composite symbol expression
		 */
		protected SymbolExpression[] createRootCompositeExpressions(Expr_Expr root,SymbolSubReference[] path){
			if(root.sym!=null){
				List<SymbolExpression> symList = new List<SymbolExpression>();
				if(root.sym.sourceType==SYM_SOURCE_DATA){
					List<SymbolSubReference> compPath = new List<SymbolSubReference>();
					compPath.addAll(root.sym.path);
					compPath.addAll(path);
					symList.add(new SymbolExpression(root.sym.sourceRef,compPath));
				}
				else {
					SymbolExpression[] cSymList = getCompositeSymbols(root.sym.sourceRef,root.sym.parameterList,root.sym.path);
					if(cSymList!=null){
						for(SymbolExpression csym : cSymList){
							List<SymbolSubReference> compPath = new List<SymbolSubReference>();
							compPath.addAll(csym.path);
							compPath.addAll(path);
							symList.add(new SymbolExpression(cSym.sourceRef,compPath));
						}
					}
				}
				return symList;
			}
			return null;
		}
	}

	/**
	 * Represents a reference to a symbol
	 * The reference contains a base reference as fields and array access which
	 * is used to resolve the end node variable
	 */
	global class SymbolExpression{
		/**
		 * The source reference, used to access the base symbol
		 */
		global final String sourceRef;
		/**
		 * The source type, used to access the base symbol
		 */
		global final Integer sourceType;
		/**
		 * The list of sub references to evaluate in order to arrive at the final data
		 */
		global final SymbolSubReference[] path;
		/**
		 * The parameters of the symbol expression, in case that the source symbol is a function
		 */
		global final Expr_Expr[] parameterList;
		/**
		 * The type of value of the fully resolved symbol
		 */
		global Integer typeVal;
		/**
		 * Wheter the symbol has been typed
		 */
		Boolean isTyped;
		/**
		 * THe display name of the symbol
		 */
		String displayName;
		/**
		 * Creates a data symbol expressions
		 * @param sourceRef The source reference used to access the symbol
		 * @param path The list of sub references to evaluate in order to arrive at the final data
		 */
		global SymbolExpression(String sourceRef,SymbolSubReference[] path){
			this.sourceRef = sourceRef;
			this.sourceType = SYM_SOURCE_DATA;
			this.path = path;
		}
		/**
		 * Creates a function symbol expressions
		 * @param sourceRef The source reference used to access the symbol
		 * @param path The list of sub references to evaluate in order to arrive at the final data
		 */
		global SymbolExpression(String sourceRef,Expr_Expr[] parameterList,SymbolSubReference[] path){
			this.sourceRef = sourceRef;
			this.sourceType = SYM_SOURCE_FUNCTION;
			this.parameterList = parameterList;
			this.path = path;
		}
		/**
		 * Returns whether the type of the source symbol is a data reference
		 * @return Whether the type of the source symbol is a data reference
		 */
		global Boolean isDataSource(){
			return sourceType == SYM_SOURCE_DATA;
		}

		/**
		 * Returns whether the type of the source symbol is a function reference
		 * @return Whether the type of the source symbol is a function reference
		 */
		global Boolean isFunctionSource(){
			return sourceType == SYM_SOURCE_FUNCTION;
		}

		/**
		 * Returns a display name for the entire symbol including the sub references
		 * @return A display name for the entire symbol including the sub references
		 */
		global String getDisplayName(){
			if(displayName!=null)return displayName;
			displayName = sourceRef;
			for(Integer i=0,sz=path.size();i<sz;i++){
				SymbolSubReference ssr = path[i];
				if(ssr.field!=null)displayName+='.'+ssr.field;
				else displayName+='[]';
			}
			return displayName;
		}

		/**
            Sets the type of the value of this symbol
            @param t The type to set of this symbol
            @return Whether the type is supported
        */
        global Boolean setType(Type t){
            if(t==Boolean.class)typeVal = DATA_TYPE_BOOL;
            else if(t==Decimal.class)typeVal = DATA_TYPE_NUM;
			else if(t==String.class)typeVal = DATA_TYPE_STRING;
			else if(t==Object.class)typeVal = DATA_TYPE_OBJECT;
			else if(t==List<Object>.class)typeVal = DATA_TYPE_LIST;
            else typeVal = null;
			isTyped = true;
            return typeVal != null;
        }

        /**
            @return The type of value for this symbol
        */
        global Type getType(){
            Type t = null;
            if(typeVal == DATA_TYPE_BOOL)t = Boolean.class;
            else if(typeVal == DATA_TYPE_NUM)t = Decimal.class;
			else if(typeVal == DATA_TYPE_STRING)t = String.class;
			else if(typeVal == DATA_TYPE_OBJECT)t = Object.class;
			else if(typeVal == DATA_TYPE_LIST)t = List<Object>.class;
            return t;
        }
		/**
			@return Whether a type has been set for the symbol
		*/
		global Boolean isTyped(){
			return isTyped;
		}
		/**
		 * Sets the type of this symbol and any eventual referenced parameters
		 * by using the provided symbol model resolver.
		 * @param smr The symbol modle resolver
		 * @param idx The index of the expression being evaluated
		 */
		private void setDynamicTypes(SymbolModelResolver smr,Integer idx){
			if(parameterList!=null){
				for(Integer i=0,sz=parameterList.size();i<sz;i++){
					parameterList[i].setDynamicTypes(smr);
				}
			}
			if(path!=null){
				for(Integer i=0,sz=path.size();i<sz;i++){
					if(path[i].e!=null)path[i].e.setDynamicTypes(smr);
				}
			}
			Type t;
			if(sourceType==SYM_SOURCE_DATA){
				t = smr.getDataType(sourceRef, path);
			}
			else {
				t = smr.getFunctionType(sourceRef, parameterList, path);
			}
			if(t==null)throw new CompileException('Invalid type from resolver for symbol "'+getDisplayName()+'" at index: '+idx);
			setType(t);
		}
		/**
		 * Evaluates the symbol expression using the currently registered symbol resolver
		 * @return The evaluated value
		 */
		private Object eval(){
			return sourceType==SYM_SOURCE_DATA ? SYM_RESOLVER.getDataValue(sourceRef,path) : SYM_RESOLVER.getFunctionValue(sourceRef,parameterList,path);
		}
		/**
		 * Returns the hash code the display name of the function
		 * @return The hash code of the symbol expression
		 */
		public Integer hashCode(){
			return getDisplayName().hashCode();
		}
		/**
		 * Checks equality between this object and another symbol expression
		 * The expressions aare considered equal if the dispaly name is equal
		 * @return Whether the symbol expressions are equal
		 */
		public Boolean equals(Object obj) {
			return obj instanceof SymbolExpression && getDisplayName().equals(((SymbolExpression)obj).getDisplayName());
		}
	}
	/**
	 * Represents an reference used as a sub expression in a symbol expression
	 */
	global class SymbolSubReference{
		/**
		 * The field to access in case of a field access
		 */
		global final String field;
		/**
		 * The expression used to resolve accessed index in case of an index access
		 */
		global final Expr_Expr e;
		/**
		 * Creates a field reference
		 * @param field The field to access
		 */
		global SymbolSubReference(String field){
			this.field = field;
		}
		/**
		 * Creates an array index reference
		 * @param e The expression resolving the array to index access
		 */
		global SymbolSubReference(Expr_Expr e){
			this.e = e;
		}
	}

	/**
		Represents a set of symbols
		The collectrion is used to extract data and function symbols referenced i an expression
	*/
	global class SymbolCollection{
		/**
			Symbols of data type
		*/
		global Set<SymbolExpression> dataSymbols;
		/**
			Symbols of function type
		*/
		global Set<SymbolExpression> functionSymbols;
		/**
			Creates an empty symbol collection
		*/
		global SymbolCollection(){
			dataSymbols = new Set<SymbolExpression>();
			functionSymbols = new Set<SymbolExpression>();
		}
	}
}