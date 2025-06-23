open Mathlib
open Interpreterlib
open Ast

let rec string_of_expr (e : expr) : string =
  match e with
  | Int n -> Printf.sprintf "Int %d" n
  | Bool b -> Printf.sprintf "Bool %b" b
  | Var id -> Printf.sprintf "Var %s" id
  | Let (id, e1, e2) ->
    Printf.sprintf "Let (%s, %s, %s)" id (string_of_expr e1) (string_of_expr e2)
  | If (cond, e1, e2) ->
    Printf.sprintf
      "If (%s, %s, %s)"
      (string_of_expr cond)
      (string_of_expr e1)
      (string_of_expr e2)
  | Func (var, e) -> Printf.sprintf "Func (%s, %s)" var (string_of_expr e)
  | App (e1, e2) -> Printf.sprintf "App (%s, %s)" (string_of_expr e1) (string_of_expr e2)
  | Binop (binop, e1, e2) ->
    let binop_str =
      match binop with
      | Add -> "Add"
      | Mul -> "Mul"
      | Sub -> "Sub"
      | Div -> "Div"
      | Leq -> "Leq"
    in
    Printf.sprintf "Binop (%s, %s, %s)" binop_str (string_of_expr e1) (string_of_expr e2)
;;

let parse s : expr =
  let lexbuf = Lexing.from_string s in
  let ast = Parser.main Lexer.read lexbuf in
  ast
;;

let gensym =
  let counter = ref 0 in
  fun () ->
    incr counter; "$x" ^ string_of_int !counter

(* check if an expression is a value (i.e., fully evaluated) *)
  let is_value : expr -> bool = function
| Int _ | Bool _ | Func _ -> true (* 函数现在是值了！ *)
| Var _ | Binop _ | If _ | Let _ | App _ -> false (* 应用不是值 *)
(* main.ml *)

(* --- 新增辅助函数 --- *)
(* Generates a fresh variable name.
   To make it truly fresh across multiple top-level interpretations,
   this counter should ideally be global or managed in a way that persists.
   For a single interp run, a simple ref is fine.
*)
let gensym_counter = ref 0

let gensym () =
  incr gensym_counter;
  "$fresh_var_" ^ string_of_int !gensym_counter
;;

(* Calculates the set of free variables in an expression.
   Using a Set data structure would be more efficient for removal and membership testing.
   Here, we use a list and List.filter/List.mem for simplicity.
*)
module VarSet = Set.Make(String)
let singleton = VarSet.singleton
let union = VarSet.union
let diff = VarSet.diff
let mem = VarSet.mem
let rec fv : expr -> VarSet.t = function
  | Var x -> singleton x
  | App (e1, e2) -> union (fv e1) (fv e2) (* 自由变量是子表达式自由变量的并集 *)
  | Func (x, e) -> diff (fv e) (singleton x) (* 函数体的自由变量除去被绑定的参数 x *)
  (* 你还需要为 Int, Bool, Binop, If, Let 添加匹配分支 *)
  | Int _ | Bool _ -> VarSet.empty
  | Binop (_, e1, e2) -> union (fv e1) (fv e2)
  | If (e1, e2, e3) -> union (fv e1) (union (fv e2) (fv e3))
  | Let (x, e1, e2) -> union (fv e1) (diff (fv e2) (singleton x))

(* --- 结束新增 --- *)

let rec replace e y x = match e with
  | Var z -> if z = x then Var y else e
  | App (e1, e2) -> App (replace e1 y x, replace e2 y x)
  | Func (z, e') -> Func ((if z = x then y else z), replace e' y x)
  (* 也需要为其他 expr 类型添加分支 *)
  | Int _ | Bool _ -> e
  | Binop (op, e1, e2) -> Binop (op, replace e1 y x, replace e2 y x)
  | If (e1, e2, e3) -> If (replace e1 y x, replace e2 y x, replace e3 y x)
  | Let (z, e1, e2) ->
      let e1' = replace e1 y x in
      if z = x then Let(y, e1', e2) (* 如果 let 绑定的 z 就是 x，那么新的绑定变量是 y *)
      else Let(z, e1', replace e2 y x)
(* main.ml *)

(* [subst target_expr value_to_sub var_name_to_replace] is [target_expr{value_to_sub/var_name_to_replace}] *)
(* Example: subst (Var "x") (Int 1) "x"  should result in Int 1 *)
let rec subst (e : expr) (v : expr) (x : string) : expr =
  match e with
  | Int _ -> e
  | Bool _ -> e
  | Var y -> if x = y then v else Var y
  | Binop (binop, e1, e2) -> Binop (binop, subst e1 v x, subst e2 v x)
  | If (cond, e1, e2) -> If (subst cond v x, subst e1 v x, subst e2 v x)
  | Let (id, e1, e2) ->
    if id = x then Let (id, subst e1 v x, e2) else Let (id, subst e1 v x, subst e2 v x)
    | Func (y, e') ->
      if x = y then (* Case 1: 替换的变量 x 与函数参数 y同名 *)
        e (* (fun y -> e'){v/y} = fun y -> e'.  x 被 y 遮蔽，不进入函数体替换 *)
      else if not (mem y (fv v)) then (* Case 2: y 不是 v 的自由变量 (安全条件) *)
        Func (y, subst e' v x) (* (fun y -> e'){v/x} = fun y -> (e'{v/x}) *)
      else (* Case 3: 潜在捕获！ y 是 v 的自由变量。需要重命名 y *)
        let fresh_y = gensym () in (* a. 生成一个新的、新鲜的变量名 fresh_y *)
        (* b. 将函数体 e' 中的所有 y 替换为 fresh_y。
           这里使用 e'{fresh_y/y} 来表示这个操作，对应函数 replace e' fresh_y y *)
        let new_body = replace e' fresh_y y in
        (* c. 现在函数是 (fun fresh_y -> new_body)，在这个新函数上进行原始的替换 *)
        Func (fresh_y, subst new_body v x)
  ;;


(* takes a single step of evaluation of [e] *)
let rec step : expr -> expr = function
  | Int _ -> failwith "Does not step on a number"
  | Var _ -> failwith "Does not step on a Id"
  | Bool _ -> failwith "Does not step on a boolean"
  | Let (id, v1, e2) when is_value v1 -> subst e2 v1 id
  | Let (id, e1, e2) -> Let (id, step e1, e2)
  | If (Bool true, e1, e2) -> e1
  | If (Bool false, e1, e2) -> e2
  | If (cond, e1, e2) -> If (step cond, e1, e2)
  (* No need for further stepping if both sides are already values *)
  | Binop (binop, e1, e2) when is_value e1 && is_value e2 -> step_binop binop e1 e2
  (* Evaluate the right side of the binop if the left side is a value *)
  | Binop (binop, e1, e2) when is_value e1 -> Binop (binop, e1, step e2)
  (* Leftmost step for binop *)
  | Binop (binop, e1, e2) -> Binop (binop, step e1, e2)

(* implement the primitive operation [v1 binop v2].
   Requires: [v1] and [v2] are both values. *)
and step_binop binop v1 v2 =
  match binop, v1, v2 with
  | Add, Int a, Int b -> Int (a + b)
  | Sub, Int a, Int b -> Int (a - b)
  | Mul, Int a, Int b -> Int (a * b)
  | Div, Int a, Int b when b <> 0 -> Int (a / b)
  | Div, Int _, Int 0 -> failwith "Division by zero"
  | Leq, Int a, Int b -> Bool (a <= b)
  | _ -> failwith "Operator and operand type mismatch"
;;

(* fully evaluate [e] to a value [v] *)
let rec eval (e : expr) : expr = if is_value e then e else e |> step |> eval

(* interpret [s] by lexing -> parsing -> evaluating and converting the result to a string *)
let interp (s : string) : string = s |> parse |> eval |> string_of_expr

let rec eval_big (e : expr) : expr =
  match e with
  | Int _ -> e
  | Bool _ -> e
  | Var _ -> e
  | Binop (binop, e1, e2) -> eval_bop binop e1 e2
  | If (cond, e1, e2) -> eval_if cond e1 e2
  | Let (id, e1, e2) -> eval_let id e1 e2

and eval_let id e1 e2 = subst e2 (eval_big e1) id |> eval_big

and eval_if cond e1 e2 =
  match eval_big cond with
  | Bool true -> e1
  | Bool false -> e2
  | _ -> failwith "eval_if"

and eval_bop binop e1 e2 =
  match binop, eval_big e1, eval_big e2 with
  | Add, Int a, Int b -> Int (a + b)
  | Sub, Int a, Int b -> Int (a - b)
  | Mul, Int a, Int b -> Int (a * b)
  | Div, Int a, Int b when b <> 0 -> Int (a / b)
  | Div, Int _, Int 0 -> failwith "Division by zero"
  | Leq, Int a, Int b -> Bool (a <= b)
  | _ -> failwith "Operator and operand type mismatch"
;;

let interp_big (s : string) : string = s |> parse |> eval_big |> string_of_expr

let () =
  let filename = "test/math_test2.in" in
  let in_channel = open_in filename in
  let file_content = really_input_string in_channel (in_channel_length in_channel) in
  close_in in_channel;
  let res = interp file_content in
  Printf.printf "Result of interpreting %s:\n%s\n\n" filename res;
  let res = interp_big file_content in
  Printf.printf "Result of interpreting %s with big-step model:\n%s\n\n" filename res;
  let ast = parse file_content in
  Printf.printf "AST: %s\n" (string_of_expr ast)
;;
