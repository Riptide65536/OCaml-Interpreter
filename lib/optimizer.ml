open Ast

(* 判断整数是否为2的幂 *)
let is_power_of_two n =
  n > 0 && (n land (n - 1)) = 0

(* 计算二元运算结果 *)
let eval_binop op n1 n2 =
  match op with
  | Add -> n1 + n2
  | Sub -> n1 - n2
  | Mul -> n1 * n2
  | Div -> if n2 = 0 then n1 / n2 else n1 / n2
  | Mod -> if n2 = 0 then n1 mod n2 else n1 mod n2
  | Eq  -> if n1 = n2 then 1 else 0
  | Neq -> if n1 <> n2 then 1 else 0
  | Lt  -> if n1 <  n2 then 1 else 0
  | Le  -> if n1 <= n2 then 1 else 0
  | Gt  -> if n1 >  n2 then 1 else 0
  | Ge  -> if n1 >= n2 then 1 else 0
  | And -> if (n1 <> 0 && n2 <> 0) then 1 else 0
  | Or  -> if (n1 <> 0 || n2 <> 0) then 1 else 0

(* 简化表达式 *)
let rec simplify_expr = function
  | EInt _ as c -> c
  | EVar _ as v -> v
  | EUnop (op, e) ->
      let se = simplify_expr e in
      (match op, se with
       | Plus, _ -> se
       | Neg, EInt n -> EInt (-n)
       | Not, EInt n -> EInt (if n = 0 then 1 else 0)
       | _, _ -> EUnop (op, se))
  | EBinop (op, e1, e2) ->
      let se1 = simplify_expr e1 in
      let se2 = simplify_expr e2 in
      (match se1, se2 with
       | EInt n1, EInt n2 -> EInt (eval_binop op n1 n2)
       | _, _ ->
           (* 强度削减：乘/除以2的幂 -> 位移 *)
           (match op, se1, se2 with
            | Mul, e, EInt n when is_power_of_two n ->
                EBinop (Mul, e, EInt n)  (* 保持不变，代码生成器可以识别 *)
            | Div, e, EInt n when is_power_of_two n ->
                EBinop (Div, e, EInt n)
            | _, _, _ -> EBinop (op, se1, se2)))
  | ECall (name, args) ->
      let sargs = List.map simplify_expr args in
      ECall (name, sargs)

(* 判断表达式是否无副作用（纯 *)
let rec is_pure_expr = function
  | EInt _ | EVar _ -> true
  | EUnop (_, e) -> is_pure_expr e
  | EBinop (_, e1, e2) -> is_pure_expr e1 && is_pure_expr e2
  | ECall _ -> false (* 函数调用视为有副作用 *)

(* 优化语句 *)
let rec optimize_stmt = function
  | SEmpty -> SEmpty
  | SExpr e ->
      let se = simplify_expr e in
      if is_pure_expr se then SEmpty else SExpr se
  | SReturn None -> SReturn None
  | SReturn (Some e) -> SReturn (Some (simplify_expr e))
  | SDeclare (name, e) -> SDeclare (name, simplify_expr e)
  | SAssign (name, e) -> SAssign (name, simplify_expr e)
  | SIf (cond, then_s, else_opt) ->
      let sc = simplify_expr cond in
      let st = optimize_stmt then_s in
      let se_opt = Option.map optimize_stmt else_opt in
      (match sc with
       | EInt n -> if n <> 0 then st else (match se_opt with Some s -> s | None -> SEmpty)
       | _ -> SIf (sc, st, se_opt))
  | SWhile (cond, body) ->
      let sc = simplify_expr cond in
      let sb = optimize_stmt body in
      (match sc with
       | EInt n -> if n = 0 then SEmpty else SWhile (sc, sb)
       | _ -> SWhile (sc, sb))
  | SBlock stmts ->
      let rec process acc = function
        | [] -> List.rev acc
        | s :: rest ->
            let os = optimize_stmt s in
            (match os with
             | SEmpty -> process acc rest
             | SReturn _ -> process (os :: acc) [] (* 后面的死代码删除 *)
             | _ -> process (os :: acc) rest)
      in
      let new_stmts = process [] stmts in
      (match new_stmts with
       | [] -> SEmpty
       | [single] -> single
       | _ -> SBlock new_stmts)
  | SBreak | SContinue as s -> s

(* 优化函数 *)
let optimize_func (f: func_def) : func_def =
  { f with body = optimize_stmt f.body }

let optimize_program (Program funcs) =
  Program (List.map optimize_func funcs) 