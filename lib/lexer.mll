(* lexer.mll *)
{
open Parser (* 确保能访问Parser模块定义的token类型 *)
}

let digit = ['0'-'9']
let letter = ['a'-'z' 'A'-'Z']
let ident = (letter | '_') (letter | digit | '_')*
let integer = '0' | ['1'-'9'] digit*

rule token = parse
  [' ' '\t' '\r'] { token lexbuf } (* Whitespace *)
| '\n'            { Lexing.new_line lexbuf; token lexbuf } (* Newline *)
| "/*"            { comment lexbuf } (* Multi-line comment *)
| "//"            { line_comment lexbuf } (* Single-line comment *)
| '('             { LPAREN }
| ')'             { RPAREN }
| '{'             { LBRACE }
| '}'             { RBRACE }
| ';'             { SEMI }
| ','             { COMMA }
| "int"           { INT }
| "void"          { VOID }
| "if"            { IF }
| "else"          { ELSE }
| "while"         { WHILE }
| "break"         { BREAK }
| "continue"      { CONTINUE }
| "return"        { RETURN }
| "&&"            { AND }
| "||"            { OR }
| "=="            { EQ }
| "!="            { NEQ }
| "<="            { LE }
| ">="            { GE }
| '<'             { LT }
| '>'             { GT }
| '='             { ASSIGN }
| '+'             { PLUS }
| '-'             { MINUS }
| '*'             { TIMES }
| '/'             { DIV }
| '%'             { MOD }
| '!'             { NOT }
| ident as lxm    { ID lxm }
| integer as lxm  { NUMBER (int_of_string lxm) }
| eof             { EOF }
| _ as char       { failwith ("Unknown token: " ^ Char.escaped char) }

and comment = parse
  "*/" { token lexbuf }
| '\n' { Lexing.new_line lexbuf; comment lexbuf }
| eof  { failwith "Unterminated comment" }
| _    { comment lexbuf }

and line_comment = parse
  '\n' { Lexing.new_line lexbuf; token lexbuf }
| eof  { EOF }
| _    { line_comment lexbuf }