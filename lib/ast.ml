(* ToyC a language's type *)
type typ = TInt | TVoid

(* Unary operators *)
type unop = Neg | Not

(* Binary operators *)
type binop =
  | Add | Sub | Mul | Div | Mod
  | Eq | Neq | Lt | Le | Gt | Ge
  | And | Or

(* Expressions *)
and expr =
  | EInt of int                     (* Integer constant *)
  | EVar of string                  (* Variable reference *)
  | EUnop of unop * expr            (* Unary operation *)
  | EBinop of binop * expr * expr   (* Binary operation *)
  | ECall of string * expr list     (* Function call *)

(* Statements *)
and stmt =
  | SExpr of expr option                      (* Expression statement: expr; or ; *)
  | SReturn of expr option                    (* return; or return expr; *)
  | SIf of expr * stmt * stmt option          (* if (e) s1 [else s2] *)
  | SWhile of expr * stmt                     (* while (e) s *)
  | SBlock of stmt list                       (* Block { s1; s2; ... } *)
  | SBreak                                    (* break; *)
  | SContinue                                 (* continue; *)
  | SDeclare of string * expr                 (* Variable declaration: int a = expr; *)
  | SAssign of string * expr                  (* Assignment: a = expr; *)


(* Function parameters *)
type param = P of string (* Parameter type is always int in ToyC *)

(* Function definition *)
type func_def = {
  return_type: typ;
  name: string;
  params: param list;
  body: stmt list; (* Body is a list of statements *)
}

(* A program is a list of function definitions *)
type program = Program of func_def list
