(* lexer.mll *)
{
open Parser (* 确保能访问Parser模块定义的token类型 *)
}
rule read = parse
  | [' ' '\t' '\n'] { read lexbuf } (* 忽略空白字符 *)
  | ['0'-'9']+ as s { INT (int_of_string s) }
  | '+' { PLUS }
  | '-' { MINUS }
  | '*' { TIMES }
  | '/' { DIV }
  | '(' { LPAREN }
  | ')' { RPAREN }
  | "true" { TRUE }  (* 新增：布尔值 true *)
  | "false" { FALSE } (* 新增：布尔值 false *)
  | "<=" { LEQ }     (* 新增：小于等于操作符 *)
  | "if" { IF }      (* 新增：关键字 if *)
  | "then" { THEN }    (* 新增：关键字 then *)
  | "else" { ELSE }    (* 新增：关键字 else *)
  | "let" { LET }      (* 新增：关键字 let *)
  | "in" { IN }        (* 新增：关键字 in *)
  | "=" { EQ }         (* 新增：等号 *)
  | "fun"   { FUN }       (* 新增：匹配关键字 fun *)
  | "->"    { ARROW }     (* 新增：匹配箭头 -> *)
  | ['a'-'z' 'A'-'Z'] ['a'-'z' 'A'-'Z' '0'-'9' '_']* as s { ID s } (* 新增：标识符 (变量名) *)
  | eof { EOF }
  | _ { failwith (Printf.sprintf "Illegal character: %s" (Lexing.lexeme lexbuf)) }