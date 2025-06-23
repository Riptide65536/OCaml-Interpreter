%{
    open Ast
    let rec make_apply e = function
  | [] -> failwith "precondition violated"
  | [e'] -> App (e, e')
	| h :: ((_ :: _) as t) -> make_apply (App (e, h)) t
%}

%token <int> INT
%token <string> ID
%token EOF
%token INT_KEYWORD VOID_KEYWORD
%token IF ELSE WHILE BREAK CONTINUE RETURN
%token LPAREN RPAREN LBRACE RBRACE SEMI COMMA
%token ASSIGN
%token PLUS MINUS TIMES DIV MOD
%token EQ NEQ LT LE GT GE
%token AND OR NOT

%right ASSIGN
%left OR
%left AND
%left EQ NEQ
%left LT LE GT GE
%left PLUS MINUS
%left TIMES DIV MOD
%right NOT
%precedence ELSE

%start <Ast.program> program

%%

program:
  | fun_def_list EOF { Program($1) }
  ;

fun_def_list:
  | f = fun_def; l = fun_def_list { f :: l }
  | f = fun_def { [f] }
  ;

fun_def:
  | t = typ; n = ID; LPAREN; p = params_opt; RPAREN; LBRACE; b = stmt_list; RBRACE {
      { return_type = t; name = n; params = p; body = b }
    }
  ;

typ:
  | INT_KEYWORD { TInt }
  | VOID_KEYWORD { TVoid }
  ;

params_opt:
  | /* empty */ { [] }
  | p = params { p }
  ;

params:
  | p = param { [p] }
  | p = param; COMMA; ps = params { p :: ps }
  ;

param:
  | INT_KEYWORD; n = ID { P(n) }
  ;

stmt_list:
    | /* empty */ { [] }
    | s = stmt; ss = stmt_list { s :: ss }
    ;

stmt:
  | SEMI { SExpr(None) }
  | e = expr; SEMI { SExpr(Some(e)) }
  | RETURN; SEMI { SReturn(None) }
  | RETURN; e = expr; SEMI { SReturn(Some(e)) }
  | INT_KEYWORD; n = ID; ASSIGN; e = expr; SEMI { SDeclare(n, e) }
  | n = ID; ASSIGN; e = expr; SEMI { SAssign(n, e) }
  | IF; LPAREN; c = expr; RPAREN; t = stmt; e = else_opt { SIf(c, t, e) }
  | WHILE; LPAREN; c = expr; RPAREN; b = stmt { SWhile(c, b) }
  | BREAK; SEMI { SBreak }
  | CONTINUE; SEMI { SContinue }
  | LBRACE; s = stmt_list; RBRACE { SBlock(s) }
  ;

else_opt:
    | /* empty */ { None }
    | ELSE; s = stmt { Some(s) }
    ;

expr:
  | i = INT { EInt(i) }
  | id = ID { EVar(id) }
  | id = ID; LPAREN; args = separated_list(COMMA, expr); RPAREN { ECall(id, args) }
  | e1 = expr; op = binop; e2 = expr { EBinop(op, e1, e2) }
  | op = unop; e = expr { EUnop(op, e) }
  | LPAREN; e = expr; RPAREN { e }
  ;

binop:
    | PLUS { Add } | SUB { Sub } | TIMES { Mul } | DIV { Div } | MOD { Mod }
    | EQ { Eq } | NEQ { Neq } | LT { Lt } | LE { Le } | GT { Gt } | GE { Ge }
    | AND { And } | OR { Or }
    ;

unop:
    | MINUS { Neg }
    | NOT { Not }
    ;

%%