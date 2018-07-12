%{
	#include "ASTNodes.h"
	#include <stdio.h>
	NBlock* programBlock;
	extern int yylex();
	extern void yyerror(const char *msg);
%}

%union
{
	NBlock* block;
	NExpression* expr;
	NStatement* stmt;
	NIdentifier* ident;
	NVariableDeclaration* var_decl;
	NArrayIndex* index;
	std::vector<shared_ptr<NVariableDeclaration>>* varvec;
	std::vector<shared_ptr<NExpression>>* exprvec;
	std::string* str;
	int token;
}

/* terminal symbols (tokens) */
/* T means token */
%token <str> TIDENTIFIER TINTEGER TDOUBLE TYINT TYDOUBLE TYFLOAT TYCHAR TYBOOL TYVOID TYSTRING TEXTERN TLITERAL
%token <token> TCEQ TCNE TCLT TCLE TCGT TCGE TASSIGN
%token <token> TLPAREN TRPAREN TLSQUARE TRSQUARE TLBRACKET TRBRACKET TCOMMA TDOT TSEMICOLON TQUOTATION
%token <token> TPLUS TMINUS TMUL TDIV TAND TOR TXOR TMOD TNOT TSHIFTL TSHIFTR
%token <token> TIF TELSE TFOR TWHILE TRETURN TSTRUCT

/* nonterminal symbols */
/* the types refer to the %union declaration above */
%type <index> array_index
%type <ident> ident primary_typename array_typename struct_typename typename
%type <expr> numeric expr assign
%type <varvec> func_decl_args struct_members struct_member_list
%type <exprvec> call_args
%type <block> program stmts block
%type <stmt> stmt var_decl func_decl struct_decl if_stmt for_stmt while_stmt

/* operator precedence */
%left TASSIGN
%left TOR TXOR
%left TAND
%left TCEQ TCNE
%left TCGE TCLE TCGT TCLT
%left TSHIFTL TSHIFTR
%left TPLUS TMINUS
%left TMUL TDIV TMOD
%left TNOT UMINUS

/* start symbol */
%start program

%%

program : 
  stmts { programBlock = $1; }
;

stmts : 
  stmt { $$ = new NBlock(); $$->statements->push_back(shared_ptr<NStatement>($1)); }
| stmts stmt { $1->statements->push_back(shared_ptr<NStatement>($2)); }
;

stmt : 
  var_decl TSEMICOLON { $$ = $1; }
| func_decl { $$ = $1; }
| struct_decl TSEMICOLON { $$ = $1; }
| expr TSEMICOLON { $$ = new NExpressionStatement(shared_ptr<NExpression>($1)); }
| TRETURN expr TSEMICOLON { $$ = new NReturnStatement(shared_ptr<NExpression>($2)); }
| if_stmt { $$ = $1; }
| for_stmt { $$ = $1; }
| while_stmt { $$ = $1; }
;

block : 
  TLBRACKET stmts TRBRACKET { $$ = $2; }
| TLBRACKET TRBRACKET { $$ = new NBlock(); }
;

primary_typename : 
  TYINT { $$ = new NIdentifier(*$1); $$->isType = true;  delete $1; }
| TYDOUBLE { $$ = new NIdentifier(*$1); $$->isType = true; delete $1; }
| TYFLOAT { $$ = new NIdentifier(*$1); $$->isType = true; delete $1; }
| TYCHAR { $$ = new NIdentifier(*$1); $$->isType = true; delete $1; }
| TYBOOL { $$ = new NIdentifier(*$1); $$->isType = true; delete $1; }
| TYVOID { $$ = new NIdentifier(*$1); $$->isType = true; delete $1; }
| TYSTRING { $$ = new NIdentifier(*$1); $$->isType = true; delete $1; }
;

array_typename : 
  primary_typename TLSQUARE TINTEGER TRSQUARE { 
    $1->isArray = true; 
    $1->arraySize->push_back(make_shared<NInteger>(atol($3->c_str()))); 
    $$ = $1; 
  }
| array_typename TLSQUARE TINTEGER TRSQUARE {
    $1->arraySize->push_back(make_shared<NInteger>(atol($3->c_str())));
    $$ = $1;
  }
;

struct_typename : 
  TSTRUCT ident { $2->isType = true; $$ = $2; }
;

typename : 
  primary_typename { $$ = $1; }
| array_typename { $$ = $1; }
| struct_typename { $$ = $1; }
;

var_decl : 
  typename ident { $$ = new NVariableDeclaration(shared_ptr<NIdentifier>($1), shared_ptr<NIdentifier>($2), nullptr); }
| typename ident TASSIGN expr { $$ = new NVariableDeclaration(shared_ptr<NIdentifier>($1), 
    shared_ptr<NIdentifier>($2), shared_ptr<NExpression>($4)); }
| typename ident TASSIGN TLSQUARE call_args TRSQUARE {
    $$ = new NArrayInitialization(make_shared<NVariableDeclaration>(shared_ptr<NIdentifier>($1), shared_ptr<NIdentifier>($2), 
      nullptr), shared_ptr<ExpressionList>($5));
  }
;

func_decl : 
  typename ident TLPAREN func_decl_args TRPAREN block { $$ = new NFunctionDeclaration(shared_ptr<NIdentifier>($1), 
    shared_ptr<NIdentifier>($2), shared_ptr<VariableList>($4), shared_ptr<NBlock>($6));  }
| TEXTERN typename ident TLPAREN func_decl_args TRPAREN TSEMICOLON { $$ = new NFunctionDeclaration(shared_ptr<NIdentifier>($2), 
    shared_ptr<NIdentifier>($3), shared_ptr<VariableList>($5), nullptr, true); }
;

func_decl_args : 
  /* blank */ { $$ = new VariableList(); }
| var_decl { $$ = new VariableList(); $$->push_back(shared_ptr<NVariableDeclaration>($<var_decl>1)); }
| func_decl_args TCOMMA var_decl { $1->push_back(shared_ptr<NVariableDeclaration>($<var_decl>3)); }
;

ident : 
  TIDENTIFIER { $$ = new NIdentifier(*$1); delete $1; }
;

numeric : 
  TINTEGER { $$ = new NInteger(atol($1->c_str())); }
| TDOUBLE { $$ = new NDouble(atof($1->c_str())); }
;

expr :
  assign { $$ = $1; }
| expr TPLUS expr { $$ = new NBinaryOperator(shared_ptr<NExpression>($1), $2, shared_ptr<NExpression>($3)); }
| expr TMINUS expr { $$ = new NBinaryOperator(shared_ptr<NExpression>($1), $2, shared_ptr<NExpression>($3)); } 
| expr TMUL expr { $$ = new NBinaryOperator(shared_ptr<NExpression>($1), $2, shared_ptr<NExpression>($3)); } 
| expr TDIV expr { $$ = new NBinaryOperator(shared_ptr<NExpression>($1), $2, shared_ptr<NExpression>($3)); } 
| expr TMOD expr { $$ = new NBinaryOperator(shared_ptr<NExpression>($1), $2, shared_ptr<NExpression>($3)); }
| expr TCEQ expr { $$ = new NBinaryOperator(shared_ptr<NExpression>($1), $2, shared_ptr<NExpression>($3)); } 
| expr TCNE expr { $$ = new NBinaryOperator(shared_ptr<NExpression>($1), $2, shared_ptr<NExpression>($3)); } 
| expr TCLT expr { $$ = new NBinaryOperator(shared_ptr<NExpression>($1), $2, shared_ptr<NExpression>($3)); } 
| expr TCLE expr { $$ = new NBinaryOperator(shared_ptr<NExpression>($1), $2, shared_ptr<NExpression>($3)); } 
| expr TCGT expr { $$ = new NBinaryOperator(shared_ptr<NExpression>($1), $2, shared_ptr<NExpression>($3)); } 
| expr TCGE expr { $$ = new NBinaryOperator(shared_ptr<NExpression>($1), $2, shared_ptr<NExpression>($3)); }		 
| expr TAND expr { $$ = new NBinaryOperator(shared_ptr<NExpression>($1), $2, shared_ptr<NExpression>($3)); } 
| expr TOR expr { $$ = new NBinaryOperator(shared_ptr<NExpression>($1), $2, shared_ptr<NExpression>($3)); } 
| expr TXOR expr { $$ = new NBinaryOperator(shared_ptr<NExpression>($1), $2, shared_ptr<NExpression>($3)); } 
| expr TSHIFTL expr { $$ = new NBinaryOperator(shared_ptr<NExpression>($1), $2, shared_ptr<NExpression>($3)); } 
| expr TSHIFTR expr { $$ = new NBinaryOperator(shared_ptr<NExpression>($1), $2, shared_ptr<NExpression>($3)); }
| TMINUS expr %prec UMINUS { $$ = nullptr; /* TODO */ }
| TNOT expr { $$ = nullptr; /* TODO */ }
| ident TLPAREN call_args TRPAREN { $$ = new NMethodCall(shared_ptr<NIdentifier>($1), shared_ptr<ExpressionList>($3)); }
| ident { $<ident>$ = $1; }
| ident TDOT ident { $$ = new NStructMember(shared_ptr<NIdentifier>($1), shared_ptr<NIdentifier>($3)); }
| numeric { $$ = $1; }
| TLPAREN expr TRPAREN { $$ = $2; }
| array_index { $$ = $1; }
| TLITERAL { $$ = new NLiteral(*$1); delete $1; }
;

array_index : 
  ident TLSQUARE expr TRSQUARE { $$ = new NArrayIndex(shared_ptr<NIdentifier>($1), shared_ptr<NExpression>($3)); }
| array_index TLSQUARE expr TRSQUARE { $1->expressions->push_back(shared_ptr<NExpression>($3)); $$ = $1; }
;

assign : 
  ident TASSIGN expr { $$ = new NAssignment(shared_ptr<NIdentifier>($1), shared_ptr<NExpression>($3)); }
| array_index TASSIGN expr { $$ = new NArrayAssignment(shared_ptr<NArrayIndex>($1), shared_ptr<NExpression>($3)); }
| ident TDOT ident TASSIGN expr {
	auto member = make_shared<NStructMember>(shared_ptr<NIdentifier>($1), shared_ptr<NIdentifier>($3)); 
	$$ = new NStructAssignment(member, shared_ptr<NExpression>($5)); 
  }
;

call_args : 
  /* blank */ { $$ = new ExpressionList(); }
| expr { $$ = new ExpressionList(); $$->push_back(shared_ptr<NExpression>($1)); }
| call_args TCOMMA expr { $1->push_back(shared_ptr<NExpression>($3)); }
;
					 
if_stmt : 
  TIF expr block { $$ = new NIfStatement(shared_ptr<NExpression>($2), shared_ptr<NBlock>($3)); }
| TIF expr block TELSE block { $$ = new NIfStatement(shared_ptr<NExpression>($2), shared_ptr<NBlock>($3), shared_ptr<NBlock>($5)); }
| TIF expr block TELSE if_stmt { 
    auto blk = new NBlock(); blk->statements->push_back(shared_ptr<NStatement>($5)); 
	$$ = new NIfStatement(shared_ptr<NExpression>($2), shared_ptr<NBlock>($3), shared_ptr<NBlock>(blk)); 
  }
;

for_stmt : 
  TFOR TLPAREN expr TSEMICOLON expr TSEMICOLON expr TRPAREN block { $$ = new NForStatement(shared_ptr<NBlock>($9), 
    shared_ptr<NExpression>($3), shared_ptr<NExpression>($5), shared_ptr<NExpression>($7)); }
;
		
while_stmt : 
  TWHILE TLPAREN expr TRPAREN block { $$ = new NForStatement(shared_ptr<NBlock>($5), nullptr, 
    shared_ptr<NExpression>($3), nullptr); }
;

struct_decl : 
  TSTRUCT ident struct_member_list {$$ = new NStructDeclaration(shared_ptr<NIdentifier>($2), 
    shared_ptr<VariableList>($3)); }
;

struct_member_list :
  TLBRACKET TRBRACKET { $$ = new VariableList(); }
| TLBRACKET struct_members TRBRACKET { $$ = $2; }
;

struct_members : 
  var_decl TSEMICOLON { $$ = new VariableList(); $$->push_back(shared_ptr<NVariableDeclaration>($<var_decl>1)); }
| struct_members var_decl TSEMICOLON { $1->push_back(shared_ptr<NVariableDeclaration>($<var_decl>2)); }
;

%%
