open Interpreter_lib.Ast
open Interpreter_lib.Codegen

(* Helper function to convert a list of items to a string *)
let string_of_list ?(sep=", ") f l =
  "[" ^ (String.concat sep (List.map f l)) ^ "]"

let string_of_typ = function
  | TInt -> "int"
  | TVoid -> "void"

let string_of_unop = function
  | Neg -> "-"
  | Not -> "!"
  | Plus -> "+"

let string_of_binop = function
  | Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/" | Mod -> "%"
  | Eq -> "==" | Neq -> "!=" | Lt -> "<" | Le -> "<=" | Gt -> ">" | Ge -> ">="
  | And -> "&&" | Or -> "||"

let rec string_of_expr = function
  | EInt i -> string_of_int i
  | EVar v -> v
  | EUnop (op, e) -> "(" ^ string_of_unop op ^ " " ^ string_of_expr e ^ ")"
  | EBinop (op, e1, e2) -> "(" ^ string_of_expr e1 ^ " " ^ string_of_binop op ^ " " ^ string_of_expr e2 ^ ")"
  | ECall (name, args) -> name ^ "(" ^ String.concat ", " (List.map string_of_expr args) ^ ")"

let rec string_of_stmt indent = function
  | SEmpty -> indent ^ ";"
  | SExpr e -> indent ^ string_of_expr e ^ ";"
  | SReturn None -> indent ^ "return;"
  | SReturn (Some e) -> indent ^ "return " ^ string_of_expr e ^ ";"
  | SIf (cond, then_s, else_s_opt) ->
      let if_str = indent ^ "if (" ^ string_of_expr cond ^ ")\n" ^ string_of_stmt (indent ^ "  ") then_s in
      if_str ^
      (match else_s_opt with
      | None -> ""
      | Some else_s -> "\n" ^ indent ^ "else\n" ^ string_of_stmt (indent ^ "  ") else_s)
  | SWhile (cond, body) ->
      indent ^ "while (" ^ string_of_expr cond ^ ")\n" ^ string_of_stmt (indent ^ "  ") body
  | SBlock stmts ->
      indent ^ "{\n" ^
      String.concat "\n" (List.map (string_of_stmt (indent ^ "  ")) stmts) ^
      "\n" ^ indent ^ "}"
  | SBreak -> indent ^ "break;"
  | SContinue -> indent ^ "continue;"
  | SDeclare (name, expr) -> indent ^ "int " ^ name ^ " = " ^ string_of_expr expr ^ ";"
  | SAssign (name, expr) -> indent ^ name ^ " = " ^ string_of_expr expr ^ ";"

let string_of_param = function
  | P name -> "int " ^ name

let string_of_func_def (f: func_def) =
  let return_type_str = string_of_typ f.return_type in
  let params_str = String.concat ", " (List.map string_of_param f.params) in
  let body_str = string_of_stmt "  " f.body in
  return_type_str ^ " " ^ f.name ^ "(" ^ params_str ^ ") {\n" ^
  body_str ^
  "\n}\n"

let string_of_program (Program funcs) =
  String.concat "\n" (List.map string_of_func_def funcs)

let parse_file (filename : string) : program =
  let in_channel = open_in filename in
  let lexbuf = Lexing.from_channel in_channel in
  Lexing.set_filename lexbuf filename;
  try
    let ast = Interpreter_lib.Parser.comp_unit Interpreter_lib.Lexer.token lexbuf in
    close_in in_channel;
    ast
  with
  | Parsing.Parse_error ->
    let pos = lexbuf.lex_curr_p in
    Printf.eprintf "Syntax error at %s:%d:%d\n"
      pos.pos_fname pos.pos_lnum (pos.pos_cnum - pos.pos_bol);
    exit 1
  | Failure msg ->
    let pos = lexbuf.lex_curr_p in
    Printf.eprintf "Lexical error at %s:%d:%d: %s\n"
        pos.pos_fname pos.pos_lnum (pos.pos_cnum - pos.pos_bol) msg;
    exit 1

let generate_output filename ast =
  (* 生成AST字符串表示 *)
  let ast_str = string_of_program ast in
  
  (* 生成RISC-V汇编代码 *)
  let asm_code = generate_riscv ast in
  
  (* 创建.s文件名 *)
  let output_filename = 
    let base_name = Filename.basename filename in
    let dir_name = Filename.dirname filename in
    Filename.concat dir_name (Filename.remove_extension base_name ^ ".s")
  in
  
  (* 将汇编代码写入.s文件 *)
  let out_channel = open_out output_filename in
  output_string out_channel asm_code;
  close_out out_channel;
  
  (* 返回生成的文件名，用于打印信息 *)
  output_filename

let () =
  let filename =
    if Array.length Sys.argv > 1 then
      Sys.argv.(1)
    else
      (Printf.eprintf "Usage: %s <file.tc>\n" Sys.argv.(0); exit 1)
  in
  let ast = parse_file filename in
  
  (* 输出AST信息 *)
  if Array.length Sys.argv > 2 && Sys.argv.(2) = "-ast" then
    print_endline (string_of_program ast)
  else
    (* 生成汇编代码并输出到.s文件 *)
    let output_file = generate_output filename ast in
    Printf.printf "Generated RISC-V assembly: %s\n" output_file
