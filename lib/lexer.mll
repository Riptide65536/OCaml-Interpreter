(* lexer.mll *)
{
open Parser (* 确保能访问Parser模块定义的token类型 *)
}

let newline =
  [%sedlex.regexp? '\n' | '\r' | "\r\n"]

let white_space =
  [%sedlex.regexp? Plus (' ' | '\t' | '\r')]

rule token = parse
  | white_space -> token lexbuf
  | newline -> Lexing.new_line lexbuf; token lexbuf
  | "/*" -> comment lexbuf
  | "//" -> line_comment lexbuf
  | '(' -> LPAREN
  | ')' -> RPAREN
  | '{' -> LBRACE
  | '}' -> RBRACE
  | ';' -> SEMI
  | ',' -> COMMA
  | "int" -> INT_KEYWORD
  | "void" -> VOID_KEYWORD
  | "if" -> IF
  | "else" -> ELSE
  | "while" -> WHILE
  | "break" -> BREAK
  | "continue" -> CONTINUE
  | "return" -> RETURN
  | "&&" -> AND
  | "||" -> OR
  | "==" -> EQ
  | "!=" -> NEQ
  | "<" -> LT
  | "<=" -> LE
  | ">" -> GT
  | ">=" -> GE
  | "=" -> ASSIGN
  | "+" -> PLUS
  | "-" -> MINUS
  | "*" -> TIMES
  | "/" -> DIV
  | "%" -> MOD
  | "!" -> NOT
  | [%sedlex.regexp? ('_A-Za-z' | 'a'-'z'), Star ('_A-Za-z' | '0'-'9' | 'a'-'z')] -> ID (Lexing.Utf8.lexeme lexbuf)
  | [%sedlex.regexp? ('0'-'9'), Star ('0'-'9')] -> INT (int_of_string (Lexing.Utf8.lexeme lexbuf))
  | eof -> EOF
  | _ -> failwith ("Unknown token: " ^ Lexing.lexeme lexbuf)

and comment = parse
  | "*/" -> token lexbuf
  | any -> comment lexbuf
  | eof -> failwith "Unterminated comment"

and line_comment = parse
  | newline -> Lexing.new_line lexbuf; token lexbuf
  | any -> line_comment lexbuf
  | eof -> EOF