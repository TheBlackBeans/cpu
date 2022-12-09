use crate::ast::{
    Arg, ExprBinOp, ExprMonOp, Expression, Immediate, InstrOrLabel,
    Instruction, Label, LabelImmediate, Statement, StmtBinOp, StmtMonOp,
};
use anyhow::Result;
use beans::{
    include_parser,
    parser::{Parser, Value, AST as BeansAST},
    span::Span,
    stream::StringStream,
};
use std::collections::HashMap;
use std::path::Path;
use std::process::exit;
use std::rc::Rc;

use crate::ast::AST;

macro_rules! error {
    ($($tok:tt)*) => {{
	eprintln!(
	    "File \"{}\", line {}, character {}:\nInternal error:",
	    std::file!(),
	    std::line!(),
	    std::column!(),
	);
	eprintln!($($tok)*);
	::std::process::exit(2);
    }};
}

macro_rules! get {
    ($node:expr, $key:literal) => {
        $node.attributes.remove($key).unwrap_or_else(|| {
            error!("expected to find {}, got\n{:?}", $key, $node)
        })
    };
}

macro_rules! node {
    ($node:expr) => {
        if let BeansAST::Node {
            attributes, span, ..
        } = $node
        {
            ASTNode { attributes, span }
        } else {
            error!("expected to find node");
        }
    };
}

macro_rules! value {
    ($node:expr) => {
	value!($node => "value")
    };
    ($node:expr => $key:literal) => {
        if let BeansAST::Literal {
            value: Value::Str(result),
            ..
        } = get!($node, $key)
        {
            result
        } else {
            error!("expected to find value, got\n{:?}", $node);
        }
    };
}

macro_rules! match_variant {
    (($node:expr) {
	$($variant:literal => $code:expr),* $(,)?
    }) => {{
	let variant = value!($node => "variant");
	match &*variant {
	    $($variant => $code,)*
		found_variant => error!("Unexpected variant {}", found_variant),
	}
    }};
}

#[derive(Debug)]
struct ASTNode {
    attributes: HashMap<Rc<str>, BeansAST>,
    span: Span,
}

enum BinOp {
    Add,
    Sub,
    Mul,
    Div,
}

fn read_nonempty_list<T>(
    f: impl Fn(BeansAST) -> Result<T>,
    mut ast: BeansAST,
) -> Result<Vec<T>> {
    let mut result = Vec::new();
    loop {
        let mut node = node!(ast);
        result.push(f(get!(node, "head"))?);
        match_variant! {(node) {
            "Cons" => ast = get!(node, "tail"),
            "Nil" => break,
        }}
    }
    Ok(result)
}

fn read_option<T>(
    f: impl Fn(BeansAST) -> Result<T>,
    ast: BeansAST,
) -> Result<Option<T>> {
    let mut node = node!(ast);
    Ok(match_variant! {(node) {
    "None" => None,
    "Some" => Some(f(get!(node, "value"))?),
    }})
}

fn read_list<T>(
    f: impl Fn(BeansAST) -> Result<T>,
    ast: BeansAST,
) -> Result<Vec<T>> {
    let mut node = node!(ast);
    Ok(
        read_option(|ast| read_nonempty_list(&f, ast), get!(node, "value"))?
            .unwrap_or_default(),
    )
}

fn read_expr_mon_op(ast: BeansAST) -> ExprMonOp {
    let mut node = node!(ast);
    match_variant! {(node) {
    "Load" => ExprMonOp::Load,
    }}
}

fn read_binop(ast: BeansAST) -> BinOp {
    let mut node = node!(ast);
    match_variant! {(node) {
    "Add" => BinOp::Add,
    "Sub" => BinOp::Sub,
    "Mul" => BinOp::Mul,
    "Div" => BinOp::Div,
    }}
}

fn read_calc(ast: BeansAST) -> Result<i16> {
    let mut node = node!(ast);
    Ok(match_variant! {(node) {
    "Literal" => value!(node).parse()?,
    "Through" => read_calc(get!(node, "this"))?,
    "BinOp" => {
        let left = read_calc(get!(node, "left"))?;
        let right = read_calc(get!(node, "right"))?;
        match read_binop(get!(node, "op")) {
        BinOp::Add => left + right,
        BinOp::Sub => left - right,
        BinOp::Mul => left * right,
        BinOp::Div => left / right,
        }
    }
    }})
}

fn read_jmp_arg(ast: BeansAST) -> Result<Arg> {
    let mut node = node!(ast);
    Ok(match_variant! {(node) {
    "Arg" => read_arg(get!(node, "arg"))?,
    "Global" => Arg::Immediate(
        Immediate::Label(LabelImmediate::Global(value!(node)))
    ),
    "Forward" => Arg::Immediate(
        Immediate::Label(LabelImmediate::Forward(value!(node).parse()?))
    ),
    "Backward" => Arg::Immediate(
        Immediate::Label(LabelImmediate::Backward(value!(node).parse()?))
    ),
    }})
}

fn read_arg(ast: BeansAST) -> Result<Arg> {
    let mut node = node!(ast);
    Ok(match_variant! {(node) {
    "Register" => {
        let register = value!(node).parse()?;
        if register >= 16 {
        eprintln!("Error: there are only 16 registers, {}", node.span);
        exit(1);
        }
        Arg::Register(register)
    },
    "Immediate" => Arg::Immediate(Immediate::Immediate(read_calc(get!(node, "value"))?)),
    }})
}

fn read_expr_bin_op(ast: BeansAST) -> (ExprBinOp, bool) {
    let mut node = node!(ast);
    match_variant! {(node) {
    "Add" => (ExprBinOp::Add, false),
    "Sub" => (ExprBinOp::Sub, false),
    "Mul" => (ExprBinOp::Mul, false),
    "Div" => (ExprBinOp::Div, false),
    "Mod" => (ExprBinOp::Mod, false),
    "And" => (ExprBinOp::And, false),
    "Or" => (ExprBinOp::Or, false),
    "Xor" => (ExprBinOp::Xor, false),
    "CmpEq" => (ExprBinOp::CmpEq, false),
    "CmpNeq" => (ExprBinOp::CmpNeq, false),
    "CmpLt" => (ExprBinOp::CmpLt, false),
    "CmpLeq" => (ExprBinOp::CmpGeq, true),
    "CmpGt" => (ExprBinOp::CmpLt, true),
	"CmpGeq" => (ExprBinOp::CmpGeq, false),
	"CmpAb" => (ExprBinOp::CmpAb, false),
	"CmpBe" => (ExprBinOp::CmpBe, false),
    }}
}

fn read_expression(ast: BeansAST) -> Result<Expression> {
    let mut node = node!(ast);
    Ok(match_variant! {(node) {
    "Monadic" => Expression::Monadic {
        op: read_expr_mon_op(get!(node, "op")),
        a1: read_arg(get!(node, "arg"))?
    },
    "Diadic" => {
        let a1 = read_arg(get!(node, "left"))?;
        let a2 = read_arg(get!(node, "right"))?;
        if matches!((&a1, &a2), (Arg::Immediate(_), Arg::Immediate(_))) {
        eprintln!(
            "Error: cannot have two immediates in a single instruction, {}",
            node.span
        );
        exit(1);
        }
    let (op, swap) = read_expr_bin_op(get!(node, "op"));
    let (a1, a2) = if swap {
        (a2, a1)
    } else {
        (a1, a2)
    };
        Expression::Diadic {
        op,
        a1,
        a2,
        }
    }
    }})
}

fn read_stmt_mon_jmp(ast: BeansAST) -> StmtMonOp {
    let mut node = node!(ast);
    match_variant! {(node) {
    "Jmp" => StmtMonOp::Jmp,
    }}
}

fn read_stmt_bin_jmp(ast: BeansAST) -> StmtBinOp {
    let mut node = node!(ast);
    match_variant! {(node) {
        "Jz" => StmtBinOp::Jz,
    "Jzo" => StmtBinOp::Jzo,
    "Jnz" => StmtBinOp::Jnz,
    "Jnzo" => StmtBinOp::Jnzo,
    }}
}

fn read_stmt_bin_op(ast: BeansAST) -> StmtBinOp {
    let mut node = node!(ast);
    match_variant! {(node) {
    "Store" => StmtBinOp::Store,
    }}
}

fn read_stmt_mon_op(ast: BeansAST) -> StmtMonOp {
    let mut node = node!(ast);
    match_variant! {(node) {
    "Jo" => StmtMonOp::Jo,
    }}
}

fn read_statement(ast: BeansAST) -> Result<Statement> {
    let mut node = node!(ast);
    Ok(match_variant! {(node) {
    "MonadicJump" => Statement::Monadic {
        op: read_stmt_mon_jmp(get!(node, "op")),
        a1: read_jmp_arg(get!(node, "arg"))?,
    },
    "DiadicJump" => Statement::Diadic {
        op: read_stmt_bin_jmp(get!(node, "op")),
        a1: read_jmp_arg(get!(node, "left"))?,
        a2: read_arg(get!(node, "right"))?,
    },
    "Monadic" => Statement::Monadic {
        op: read_stmt_mon_op(get!(node, "op")),
        a1: read_arg(get!(node, "arg"))?,
    },
    "Diadic" => Statement::Diadic {
        op: read_stmt_bin_op(get!(node, "op")),
        a1: read_arg(get!(node, "left"))?,
        a2: read_arg(get!(node, "right"))?,
    }
    }})
}

fn read_instruction(ast: BeansAST) -> Result<Instruction> {
    let mut node = node!(ast);
    Ok(match_variant! {(node) {
    "Assignment" => {
            let register = value!(node => "dest").parse::<u8>().unwrap();
            if register >= 16 {
        eprintln!("Error: there are only 16 registers, {}", node.span);
        exit(1);
            }
        let value = read_expression(get!(node, "value"))?;
        Instruction::Assignment(register, value)
    },
    "Statement" => Instruction::Statement(read_statement(get!(node, "stmt"))?),
    }})
}

fn read_label(ast: BeansAST) -> Result<Label> {
    let mut node = node!(ast);
    Ok(match_variant! {(node) {
    "Global" => Label::Global(value!(node)),
    "Local" => Label::Local(value!(node).parse()?),
    }})
}

fn read_instr_or_label(ast: BeansAST) -> Result<InstrOrLabel> {
    let mut node = node!(ast);
    Ok(match_variant! {(node) {
    "Instruction" => InstrOrLabel::Instruction(read_instruction(get!(node, "instr"))?),
    "Label" => InstrOrLabel::Label(read_label(get!(node, "label"))?),
    }})
}

fn read_ast(ast: BeansAST) -> Result<AST> {
    let mut node = node!(ast);
    Ok(AST {
        instr_or_label: read_list(
            read_instr_or_label,
            get!(node, "instrlbls"),
        )?,
    })
}

pub(crate) fn parse_to_ast(source: &Path) -> Result<AST> {
    let (lexer, parser) = include_parser!(
    lexer => compiled "asj.clx",
    parser => compiled "asj.cgr",
    )
    .unwrap()
    .unwrap();
    let mut input = StringStream::from_file(source).unwrap().unwrap();
    let ast = parser.parse(&mut lexer.lex(&mut input)).unwrap().unwrap();
    read_ast(ast.tree)
}
