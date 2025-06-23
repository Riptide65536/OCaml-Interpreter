%{
    open Ast
    let rec make_apply e = function
  | [] -> failwith "precondition violated"
  | [e'] -> App (e, e')
	| h :: ((_ :: _) as t) -> make_apply (App (e, h)) t
%}

%token <int> INT
%token <string> ID              
%token PLUS MINUS TIMES DIV EOF
%token TRUE FALSE IF THEN ELSE LET IN EQ LEQ
%token LPAREN RPAREN
%token FUN ARROW  
// (* 新增：FUN 和 ARROW token *)
%left PLUS MINUS
%left TIMES DIV
%left LEQ
%nonassoc IN
%right ARROW                 
//  (* -> 通常是右结合的，例如 fun x -> fun y -> e *)
%nonassoc IF THEN ELSE LET EQ 
// (* 将 let 和 if 放在较低的优先级 *)




%start main
%type <Ast.expr> main
%%
main:
    exp EOF { $1 }
;
exp:
    | INT { Int $1 }
    | ID { Var $1 }
    | exp TIMES exp { Binop (Mul, $1, $3) }
    | exp DIV exp  { Binop (Div, $1, $3) }
    | exp PLUS exp  { Binop (Add, $1, $3) }
    | exp MINUS exp { Binop (Sub, $1, $3) }
    | exp LEQ exp { Binop (Leq, $1, $3) }
    | TRUE { Bool true }
    | FALSE { Bool false }
    | IF exp THEN exp ELSE exp { If ($2, $4, $6) }
    | LET ID EQ exp IN exp { Let ($2, $4, $6) }
    | LPAREN exp RPAREN { $2 }
//     (* --- 新增 Lambda 演算的语法规则 --- *)
//   (* Lambda 抽象: fun x -> e *)
//   (* 我们需要确保它的范围正确，通常它会扩展到尽可能右边，除非被括号或更高优先级的结构打断 *)
//   (* 给予 ARROW 较低的优先级有助于实现 "fun x -> fun y -> ..." 的正确解析 *)
  | FUN ID ARROW exp { Func ($2, $4) }

//   (* 函数应用: e1 e2 *)
//   (* 函数应用通常是左结合的，并且优先级很高 *)
//   (* 将其放在所有二元操作符之后，但在原子表达式和括号之后，
//      可以使其具有比二元操作符更高的优先级 *)
  | exp exp { App ($1, $2) }
//   (* --- 结束新增 --- *)
;