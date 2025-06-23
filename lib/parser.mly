%{
open Ast
%}

/* Tokens */
%token <int> NUMBER
%token <string> ID
%token EOF
%token INT VOID
%token IF ELSE WHILE BREAK CONTINUE RETURN
%token LPAREN RPAREN LBRACE RBRACE SEMI COMMA
%token ASSIGN
%token PLUS MINUS TIMES DIV MOD
%token EQ NEQ LT LE GT GE
%token AND OR NOT

/* Precedence and associativity */
%right ASSIGN
%left OR
%left AND
%left EQ NEQ
%left LT LE GT GE
%left PLUS MINUS
%left TIMES DIV MOD
%right NOT
%right UMINUS
%nonassoc IFX
%nonassoc ELSE

%start comp_unit
%type <Ast.program> comp_unit
%%

comp_unit:
  nonempty_fun_def_list EOF { Program($1) }

nonempty_fun_def_list:
  fun_def { [$1] }
| nonempty_fun_def_list fun_def { $2 :: $1 }

fun_def:
  func_type ID LPAREN params_opt RPAREN block_stmt
  { { return_type = $1; name = $2; params = $4; body = $6 } }

func_type:
  INT { TInt }
| VOID { TVoid }

params_opt:
  /* empty */ { [] }
| separated_nonempty_param_list { List.rev $1 }

separated_nonempty_param_list:
  param { [$1] }
| separated_nonempty_param_list COMMA param { $3 :: $1 }

param:
  INT ID { P($2) }

stmt:
  block_stmt { $1 }
| SEMI { SEmpty }
| expr SEMI { SExpr($1) }
| ID ASSIGN expr SEMI { SAssign($1, $3) }
| INT ID ASSIGN expr SEMI { SDeclare($2, $4) }
| IF LPAREN expr RPAREN stmt %prec IFX { SIf($3, $5, None) }
| IF LPAREN expr RPAREN stmt ELSE stmt { SIf($3, $5, Some($7)) }
| WHILE LPAREN expr RPAREN stmt { SWhile($3, $5) }
| BREAK SEMI { SBreak }
| CONTINUE SEMI { SContinue }
| RETURN option_expr SEMI { SReturn($2) }

option_expr:
  /* empty */ { None }
| expr { Some($1) }

block_stmt:
  LBRACE stmt_list RBRACE { SBlock(List.rev $2) }

stmt_list:
  /* empty */ { [] }
| stmt_list stmt { $2 :: $1 }

expr:
  lor_expr { $1 }

lor_expr:
  land_expr { $1 }
| lor_expr OR land_expr { EBinop(Or, $1, $3) }

land_expr:
  rel_expr { $1 }
| land_expr AND rel_expr { EBinop(And, $1, $3) }

rel_expr:
  add_expr { $1 }
| rel_expr rel_op add_expr { EBinop($2, $1, $3) }

rel_op:
  LT { Lt } 
| GT { Gt } 
| LE { Le } 
| GE { Ge } 
| EQ { Eq } 
| NEQ { Neq }

add_expr:
  mul_expr { $1 }
| add_expr add_op mul_expr { EBinop($2, $1, $3) }

add_op:
  PLUS { Add } 
| MINUS { Sub }

mul_expr:
  unary_expr { $1 }
| mul_expr mul_op unary_expr { EBinop($2, $1, $3) }

mul_op:
  TIMES { Mul } 
| DIV { Div } 
| MOD { Mod }

unary_expr:
  primary_expr { $1 }
| unary_op unary_expr { EUnop($1, $2) }

unary_op:
  PLUS { Plus }
| MINUS { Neg } %prec UMINUS
| NOT { Not }

primary_expr:
  ID { EVar($1) }
| NUMBER { EInt($1) }
| LPAREN expr RPAREN { $2 }
| ID LPAREN args_opt RPAREN { ECall($1, $3) }

args_opt:
  /* empty */ { [] }
| separated_nonempty_expr_list { List.rev $1 }

separated_nonempty_expr_list:
  expr { [$1] }
| separated_nonempty_expr_list COMMA expr { $3 :: $1 }
%% 