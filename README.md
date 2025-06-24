# ToyC 编译器

这是一个将 ToyC 语言编译成 RISC-V 汇编代码的简单编译器。

## 项目结构

- `lib/`: 编译器核心库
  - `ast.ml`: 抽象语法树定义
  - `lexer.mll`: 词法分析器
  - `parser.mly`: 语法分析器
  - `codegen.ml`: 代码生成器（RISC-V 汇编）
- `bin/`: 编译器可执行文件
  - `main.ml`: 主程序
- `test/`: 测试文件
  - `simple.tc`: 简单的 ToyC 程序
  - `complex.tc`: 更复杂的 ToyC 程序

## ToyC 语言

ToyC 是 C 语言的一个简化子集，支持以下特性：

- 基本类型：`int` 和 `void`
- 函数定义和调用
- 变量声明和赋值
- 控制流语句：`if-else` 和 `while`
- `break` 和 `continue` 语句
- 表达式：算术运算、逻辑运算、关系运算等

## 构建和使用

### 依赖项

- OCaml (5.3.0 或更新版本)
- Dune 构建系统

### 构建项目

```bash
dune build
```

### 使用编译器

```bash
dune exec interpreter_project <input-file.tc> [-ast]
```

参数说明：
- `<input-file.tc>`: 输入的 ToyC 源文件
- `-ast`: 可选参数，输出抽象语法树而不是生成汇编代码

编译器会生成与输入文件同名但扩展名为 `.s` 的 RISC-V 汇编代码文件。

### 示例

编译简单的测试文件：

```bash
dune exec interpreter_project test/simple.tc
```

输出文件将是 `test/simple.s`。

## 代码生成

代码生成器 (`codegen.ml`) 将抽象语法树转换为 RISC-V 汇编代码。主要功能包括：

1. 寄存器分配：使用固定的寄存器分配方案
2. 栈帧管理：为局部变量和函数调用分配栈空间
3. 控制流翻译：将 ToyC 的控制流语句翻译为 RISC-V 的跳转指令
4. 表达式求值：将表达式翻译为 RISC-V 指令序列

生成的 RISC-V 汇编代码遵循标准的 RISC-V 调用约定，并可以使用标准的 RISC-V 工具链进行进一步的处理。
- Clarkson, M. R. (2021–2025). [OCaml Programming: Correct + Efficient + Beautiful](https://cs3110.github.io/textbook/)