open Ast

(* 寄存器定义 *)
type reg =
  | A0 | A1 | A2 | A3 | A4 | A5 | A6 | A7  (* 参数/结果寄存器 *)
  | T0 | T1 | T2 | T3 | T4 | T5 | T6       (* 临时寄存器 *)
  | S0 | S1 | S2 | S3 | S4 | S5 | S6 | S7 | S8 | S9 | S10 | S11 (* 保存寄存器 *)
  | RA                                     (* 返回地址寄存器 *)
  | SP                                     (* 栈指针寄存器 *)
  | FP                                     (* 帧指针寄存器 *)
  | ZERO                                   (* 零寄存器 *)

(* 将寄存器转换为字符串 *)
let string_of_reg = function
  | A0 -> "a0" | A1 -> "a1" | A2 -> "a2" | A3 -> "a3"
  | A4 -> "a4" | A5 -> "a5" | A6 -> "a6" | A7 -> "a7"
  | T0 -> "t0" | T1 -> "t1" | T2 -> "t2" | T3 -> "t3"
  | T4 -> "t4" | T5 -> "t5" | T6 -> "t6"
  | S0 -> "s0" | S1 -> "s1" | S2 -> "s2" | S3 -> "s3"
  | S4 -> "s4" | S5 -> "s5" | S6 -> "s6" | S7 -> "s7"
  | S8 -> "s8" | S9 -> "s9" | S10 -> "s10" | S11 -> "s11"
  | RA -> "ra" | SP -> "sp" | FP -> "fp" | ZERO -> "zero"

(* 变量环境，存储变量名到栈偏移量的映射 *)
type var_env = {
  vars: (string * int) list;  (* 变量名 -> 相对于fp的偏移量 *)
  next_offset: int;           (* 下一个可用的栈偏移 *)
}

(* 创建一个新的变量环境 *)
let empty_env = {
  vars = [];
  next_offset = -4;  (* 从fp-4开始分配局部变量 *)
}

(* 在环境中添加一个新变量 *)
let add_var env name =
  let offset = env.next_offset in
  let env' = {
    vars = (name, offset) :: env.vars;
    next_offset = offset - 4;  (* 每个int变量占4字节 *)
  } in
  (env', offset)

(* 在环境中查找变量的偏移量 *)
let find_var env name =
  try List.assoc name env.vars
  with Not_found -> failwith ("Undefined variable: " ^ name)

(* 编译器环境 *)
type compile_env = {
  vars: var_env;                   (* 局部变量环境 *)
  mutable label_count: int;        (* 用于生成唯一标签 *)
  mutable current_loop: (string * string) option;  (* 当前循环的开始和结束标签 *)
  mutable current_func_return_label: string;       (* 当前函数的返回标签 *)
}

(* 创建初始编译环境 *)
let init_compile_env () = {
  vars = empty_env;
  label_count = 0;
  current_loop = None;
  current_func_return_label = ""; (* 将在编译每个函数时设置 *)
}

(* 生成一个新的唯一标签 *)
let fresh_label env prefix =
  let label = prefix ^ "_" ^ string_of_int env.label_count in
  env.label_count <- env.label_count + 1;
  label

(* 生成RISC-V汇编代码 *)
let generate_riscv program =
  let env = init_compile_env () in
  
  (* 用于收集生成的汇编代码 *)
  let output = Buffer.create 2048 in
  
  (* 向输出添加一行 *)
  let emit_line line =
    Buffer.add_string output line;
    Buffer.add_char output '\n'
  in

  (* 向输出添加一个标签 *)
  let emit_label label =
    Buffer.add_string output label;
    Buffer.add_string output ":\n"
  in
  
  (* 向输出添加一个指令 *)
  let emit instr =
    Buffer.add_string output "\t";
    Buffer.add_string output instr;
    Buffer.add_char output '\n'
  in

  (* 代码段 *)
  let emit_text_section () =
    emit_line ".text"
  in

  (* 表达式求值，返回存储结果的寄存器 *)
  let rec compile_expr env expr =
    match expr with
    | EInt n ->
        emit (Printf.sprintf "li a0, %d" n);
        A0
    
    | EVar name ->
        let offset = find_var env.vars name in
        emit (Printf.sprintf "lw a0, %d(fp)" offset);
        A0
    
    | EUnop (op, e) ->
        let _ = compile_expr env e in (* 结果在a0中 *)
        (match op with
        | Neg -> emit "neg a0, a0"
        | Not -> 
            emit "seqz a0, a0" (* 逻辑非：如果a0=0则置1，否则置0 *)
        | Plus -> ());
        A0
    
    | EBinop (op, e1, e2) ->
        let _ = compile_expr env e1 in
        (* 保存e1的结果 *)
        emit "mv t0, a0";
        let _ = compile_expr env e2 in
        (* 现在e2的结果在a0中，e1的结果在t0中 *)
        (match op with
        | Add -> emit "add a0, t0, a0"
        | Sub -> emit "sub a0, t0, a0"
        | Mul -> emit "mul a0, t0, a0"
        | Div -> emit "div a0, t0, a0"
        | Mod -> emit "rem a0, t0, a0"
        | Eq -> 
            emit "xor a0, t0, a0";
            emit "seqz a0, a0"  (* 如果相等(异或结果为0)则置1 *)
        | Neq -> 
            emit "xor a0, t0, a0";
            emit "snez a0, a0"  (* 如果不相等(异或结果不为0)则置1 *)
        | Lt -> emit "slt a0, t0, a0"
        | Le -> 
            emit "sgt a0, t0, a0";
            emit "seqz a0, a0"  (* 如果t0>a0则置0，否则置1 *)
        | Gt -> emit "sgt a0, t0, a0"
        | Ge -> 
            emit "slt a0, t0, a0";
            emit "seqz a0, a0"  (* 如果t0<a0则置0，否则置1 *)
        | And ->
            let label_false = fresh_label env "and_false" in
            let label_end = fresh_label env "and_end" in
            emit (Printf.sprintf "beqz t0, %s" label_false);
            emit (Printf.sprintf "beqz a0, %s" label_false);
            emit "li a0, 1";
            emit (Printf.sprintf "j %s" label_end);
            emit_label label_false;
            emit "li a0, 0";
            emit_label label_end
        | Or ->
            let label_true = fresh_label env "or_true" in
            let label_end = fresh_label env "or_end" in
            emit (Printf.sprintf "bnez t0, %s" label_true);
            emit (Printf.sprintf "bnez a0, %s" label_true);
            emit "li a0, 0";
            emit (Printf.sprintf "j %s" label_end);
            emit_label label_true;
            emit "li a0, 1";
            emit_label label_end
        );
        A0
    
    | ECall (func_name, args) ->
        (* 保存调用者保存的寄存器 *)
        emit "addi sp, sp, -4";
        emit "sw ra, 0(sp)";
        
        (* 计算并存储参数值 *)
        let arg_regs = [A0; A1; A2; A3; A4; A5; A6; A7] in
        
        (* 编译每个参数表达式，并将结果保存到对应的参数寄存器 *)
        let rec process_args args_left reg_list offset =
          match args_left, reg_list with
          | [], _ -> offset
          | arg :: rest, reg :: regs ->
              let _ = compile_expr env arg in
              (* 现在参数在a0，需要移到适当的参数寄存器 *)
              if reg <> A0 then
                emit (Printf.sprintf "mv %s, a0" (string_of_reg reg));
              process_args rest regs offset
          | arg :: rest, [] ->
              (* 剩余参数通过栈传递 *)
              let _ = compile_expr env arg in
              emit (Printf.sprintf "sw a0, %d(sp)" offset);
              process_args rest [] (offset - 4)
        in
        let _ = process_args args arg_regs (-4) in
        
        (* 调用函数 *)
        emit (Printf.sprintf "call %s" func_name);
        
        (* 恢复ra *)
        emit "lw ra, 0(sp)";
        emit "addi sp, sp, 4";
        
        (* 结果在a0寄存器中 *)
        A0
  in

  (* 编译语句 *)
  let rec compile_stmt env stmt =
    match stmt with
    | SEmpty ->
        env
    
    | SExpr e ->
        let _ = compile_expr env e in
        env
    
    | SReturn None ->
        emit "li a0, 0";  (* void函数返回0 *)
        emit (Printf.sprintf "j %s" env.current_func_return_label);
        env
    
    | SReturn (Some e) ->
        let _ = compile_expr env e in
        emit (Printf.sprintf "j %s" env.current_func_return_label);
        env
    
    | SIf (cond, then_stmt, None) ->
        let else_label = fresh_label env "else" in
        let end_label = fresh_label env "endif" in
        
        (* 计算条件 *)
        let _ = compile_expr env cond in
        
        (* 条件为假，跳转到else *)
        emit (Printf.sprintf "beqz a0, %s" else_label);
        
        (* 编译then部分 *)
        let env' = compile_stmt env then_stmt in
        
        (* 跳转到结束 *)
        emit (Printf.sprintf "j %s" end_label);
        
        (* else标签 *)
        emit_label else_label;
        
        (* 结束标签 *)
        emit_label end_label;
        
        env'
    
    | SIf (cond, then_stmt, Some else_stmt) ->
        let else_label = fresh_label env "else" in
        let end_label = fresh_label env "endif" in
        
        (* 计算条件 *)
        let _ = compile_expr env cond in
        
        (* 条件为假，跳转到else *)
        emit (Printf.sprintf "beqz a0, %s" else_label);
        
        (* 编译then部分 *)
        let env' = compile_stmt env then_stmt in
        
        (* 跳转到结束 *)
        emit (Printf.sprintf "j %s" end_label);
        
        (* else标签 *)
        emit_label else_label;
        
        (* 编译else部分 *)
        let env'' = compile_stmt env' else_stmt in
        
        (* 结束标签 *)
        emit_label end_label;
        
        env''
    
    | SWhile (cond, body) ->
        let start_label = fresh_label env "while_start" in
        let end_label = fresh_label env "while_end" in
        
        (* 保存旧的循环标签 *)
        let old_loop = env.current_loop in
        
        (* 设置当前循环的标签 *)
        env.current_loop <- Some (start_label, end_label);
        
        (* 循环开始标签 *)
        emit_label start_label;
        
        (* 计算条件 *)
        let _ = compile_expr env cond in
        
        (* 条件为假，跳出循环 *)
        emit (Printf.sprintf "beqz a0, %s" end_label);
        
        (* 编译循环体 *)
        let env' = compile_stmt env body in
        
        (* 跳回循环开始 *)
        emit (Printf.sprintf "j %s" start_label);
        
        (* 循环结束标签 *)
        emit_label end_label;
        
        (* 恢复旧的循环标签 *)
        env'.current_loop <- old_loop;
        
        env'
    
    | SBreak ->
        (match env.current_loop with
        | None -> failwith "Break statement outside loop"
        | Some (_, end_label) ->
            emit (Printf.sprintf "j %s" end_label)
        );
        env
    
    | SContinue ->
        (match env.current_loop with
        | None -> failwith "Continue statement outside loop"
        | Some (start_label, _) ->
            emit (Printf.sprintf "j %s" start_label)
        );
        env
    
    | SBlock stmts ->
        (* 为块创建新的作用域 *)
        let env_ref = ref env in
        
        (* 依次编译每条语句 *)
        List.iter (fun s -> env_ref := compile_stmt !env_ref s) stmts;
        
        !env_ref
    
    | SDeclare (name, init_expr) ->
        (* 计算初始值 *)
        let _ = compile_expr env init_expr in
        
        (* 为变量分配栈空间 *)
        let (vars', offset) = add_var env.vars name in
        
        (* 将初始值存入分配的空间 *)
        emit (Printf.sprintf "sw a0, %d(fp)" offset);
        
        { env with vars = vars' }
    
    | SAssign (name, expr) ->
        (* 计算赋值表达式的值 *)
        let _ = compile_expr env expr in
        
        (* 查找变量的栈偏移量 *)
        let offset = find_var env.vars name in
        
        (* 将值存入变量 *)
        emit (Printf.sprintf "sw a0, %d(fp)" offset);
        
        env
  in

  (* 编译函数定义 *)
  let compile_func env func_def =
    (* 函数开始标签 *)
    emit_label func_def.name;
    
    (* 函数序言 *)
    emit "addi sp, sp, -8";    (* 为fp和ra分配空间 *)
    emit "sw fp, 4(sp)";       (* 保存调用者的帧指针 *)
    emit "sw ra, 0(sp)";       (* 保存返回地址 *)
    emit "mv fp, sp";          (* 设置新的帧指针 *)
    
    (* 计算需要的栈空间（预先为局部变量估算空间） *)
    emit "addi sp, sp, -64";   (* 为局部变量分配64字节空间，后续可以根据需要调整 *)
    
    (* 创建一个函数特定的返回标签 *)
    let return_label = func_def.name ^ "_return" in
    env.current_func_return_label <- return_label;
    
    (* 初始化新的变量环境 *)
    let func_env = { env with vars = empty_env } in
    
    (* 处理参数 *)
    let param_regs = [A0; A1; A2; A3; A4; A5; A6; A7] in
    let rec process_params params regs env offset =
      match params, regs with
      | [], _ -> env
      | P name :: rest_params, reg :: rest_regs ->
          (* 分配栈空间给参数 *)
          let (vars', param_offset) = add_var env.vars name in
          let new_env = { env with vars = vars' } in
          
          (* 将参数寄存器的值存到栈上 *)
          emit (Printf.sprintf "sw %s, %d(fp)" (string_of_reg reg) param_offset);
          
          process_params rest_params rest_regs new_env offset
      | P name :: rest_params, [] ->
          (* 超出寄存器数量的参数是通过栈传递的 *)
          let (vars', param_offset) = add_var env.vars name in
          let new_env = { env with vars = vars' } in
          
          emit (Printf.sprintf "lw t0, %d(fp)" (8 + offset)); (* 8是为了跳过保存的fp和ra *)
          emit (Printf.sprintf "sw t0, %d(fp)" param_offset);
          
          process_params rest_params [] new_env (offset + 4)
    in
    let env_with_params = process_params func_def.params param_regs func_env 0 in
    
    (* 编译函数体 *)
    let _ = match func_def.body with
      | SBlock stmts -> 
          List.fold_left (fun env stmt -> compile_stmt env stmt) env_with_params stmts
      | _ -> failwith "Function body must be a block"
    in
    
    (* 添加函数返回标签 *)
    emit_label return_label;
    
    (* 函数结尾 *)
    emit "lw ra, 0(fp)";       (* 恢复返回地址 *)
    emit "lw fp, 4(fp)";       (* 恢复调用者的帧指针 *)
    emit "addi sp, fp, 8";     (* 恢复栈指针 *)
    emit "ret";                (* 返回 *)
    
    (* 返回原始环境 *)
    env
  in

  (* 开始生成汇编 *)
  emit_line ".globl main";  (* main函数是全局的 *)
  
  (* 导入可能需要的库函数 *)
  emit_text_section ();
  
  (* 编译所有函数 *)
  let Program funcs = program in
  let _ = List.fold_left (fun env func_def -> compile_func env func_def) env funcs in
  
  (* 生成最终的汇编代码 *)
  Buffer.contents output 