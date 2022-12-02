use std::{
    collections::HashMap,
    ops::{Index, IndexMut, Range},
    path::Path, fs::File, io::Write,
};
use anyhow::Result;
use crate::ast::{Arg, Expression, InstrOrLabel, Instruction, AST, Statement};

#[derive(Default, Debug)]
struct EncodedInstr([bool; 32]);

impl From<EncodedInstr> for u32 {
    fn from(EncodedInstr(x): EncodedInstr) -> u32 {
        x.into_iter()
            .enumerate()
            .map(|(i, b)| if b { 1 << i } else { 0 })
            .sum()
    }
}

impl Index<usize> for EncodedInstr {
    type Output = bool;

    fn index(&self, index: usize) -> &bool {
        &self.0[index]
    }
}

impl Index<Range<usize>> for EncodedInstr {
    type Output = [bool];

    fn index(&self, range: Range<usize>) -> &Self::Output {
        &self.0[range]
    }
}

impl IndexMut<usize> for EncodedInstr {
    fn index_mut(&mut self, index: usize) -> &mut bool {
        &mut self.0[index]
    }
}

impl IndexMut<Range<usize>> for EncodedInstr {
    fn index_mut(&mut self, range: Range<usize>) -> &mut Self::Output {
        &mut self.0[range]
    }
}

impl EncodedInstr {
    fn set_range(&mut self, range: Range<usize>, value: u32) {
        let size = range.len();
        let destination = &mut self[range];
        for i in 0..size {
            destination[i] = value & (1 << i) != 0;
        }
    }
}

pub fn to_blob(ast: &AST, output: &Path) -> Result<()> {
    let mut instructions = Vec::new();
    let mut labels = HashMap::new();
    for instr_or_label in ast.instr_or_label.iter() {
        match instr_or_label {
            InstrOrLabel::Instruction(instr) => instructions.push(instr),
            InstrOrLabel::Label(label) => {
                drop(labels.insert(label, instructions.len()))
            }
        }
    }
    let mut code = Vec::new();
    for instr in instructions {
        let mut encoded_instr = EncodedInstr::default();
        let op_code;
	let a_1;
	let a_2;
        match instr {
            Instruction::Assignment(destination, expression) => {
                encoded_instr.set_range(8..12, *destination as u32);
                match expression {
                    Expression::Monadic { op, a1 } => {
                        encoded_instr[0] = false;
                        op_code = op.code();
			a_1 = a1;
                        a_2 = None;
                    },
                    Expression::Diadic { op, a1, a2 } => {
                        encoded_instr[0] = true;
                        op_code = op.code();
			a_1 = a1;
			a_2 = Some(a2);
                    },
                };
            }
            Instruction::Statement(statement) => {
		match statement {
		    Statement::Monadic { op, a1 } => {
			op_code = op.code();
			a_1 = a1;
			a_2 = None;
		    },
		    Statement::Diadic { op, a1, a2 } => {
			op_code = op.code();
			a_1 = a1;
			a_2 = Some(a2);
		    },
		}
	    },
        };
	match a_1 {
            Arg::Register(reg) => {
		encoded_instr[6] = true;
                encoded_instr.set_range(12..16, *reg as u32)
            }
            Arg::Immediate(imm) => {
		encoded_instr[6] = false;
                encoded_instr.set_range(12..28, *imm as u32)
            }
        }
	match a_2 {
	    Some(Arg::Register(reg)) => {
		encoded_instr[7] = true;
		encoded_instr.set_range(28..32, *reg as u32)
	    }
	    Some(Arg::Immediate(imm)) => {
		encoded_instr[7] = false;
		encoded_instr.set_range(16..32, *imm as u32)
	    }
	    None => {}
	}

        encoded_instr.set_range(1..6, op_code);
        code.extend(Into::<u32>::into(encoded_instr).to_be_bytes());
    }
    let mut file = File::create(output)?;
    file.write_all(&code)?;
    Ok(())
}
