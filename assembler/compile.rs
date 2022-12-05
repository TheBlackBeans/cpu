use crate::ast::{
    Arg, Expression, Immediate, InstrOrLabel, Instruction, Label,
    LabelImmediate, Statement, AST,
};
use anyhow::Result;
use std::{
    collections::HashMap,
    fs::File,
    io::Write,
    ops::{Index, IndexMut, Range},
    path::Path,
    rc::Rc,
};

#[derive(Default)]
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
        for (i, dest) in destination.iter_mut().enumerate().take(size) {
            *dest = value & (1 << i) != 0;
        }
    }
}

struct Labels {
    backward: HashMap<u8, usize>,
    forward: HashMap<u8, Vec<usize>>,
    label_place: HashMap<usize, Vec<u8>>,
    global_labels: HashMap<Rc<str>, usize>,
    current: usize,
}

impl Labels {
    fn new() -> Self {
        Self {
            backward: HashMap::new(),
            forward: HashMap::new(),
            label_place: HashMap::new(),
            global_labels: HashMap::new(),
            current: 0,
        }
    }

    fn add_global_label(&mut self, label: Rc<str>, position: usize) {
        self.global_labels.insert(label, position);
    }

    fn add_local_label(&mut self, label: u8, position: usize) {
	if position == 0 {
	    self.backward.insert(label, position);
	} else {
            self.label_place.entry(position).or_default().push(label);
            self.forward.entry(label).or_default().push(position);
	}
    }

    fn end_setup(&mut self) {
        for (_, v) in self.forward.iter_mut() {
            v.reverse();
        }
    }

    fn incr_instruction(&mut self) {
        self.current += 1;
        if let Some(locals) = self.label_place.get(&self.current) {
            for local in locals.iter().copied() {
                self.backward.insert(
                    local,
                    self.forward.get_mut(&local).unwrap().pop().unwrap(),
                );
            }
        }
    }

    fn get_global(&self, label: Rc<str>) -> Option<usize> {
        self.global_labels.get(&label).copied()
    }

    fn get_forward(&self, label: u8) -> Option<usize> {
        self.forward.get(&label)?.last().copied()
    }

    fn get_backward(&self, label: u8) -> Option<usize> {
        self.backward.get(&label).copied()
    }

    fn resolve_immediate(&self, imm: &Immediate) -> Option<u32> {
        Some(match imm {
            Immediate::Immediate(imm) => *imm as u32,
            Immediate::Label(LabelImmediate::Global(label)) => {
                self.get_global(label.clone())? as u32
            }
            Immediate::Label(LabelImmediate::Forward(label)) => {
                self.get_forward(*label)? as u32
            }
            Immediate::Label(LabelImmediate::Backward(label)) => {
                self.get_backward(*label)? as u32
            }
        })
    }
}

pub fn to_blob(ast: &AST, output: &Path) -> Result<()> {
    let mut instructions = Vec::new();
    let mut labels = Labels::new();
    for instr_or_label in ast.instr_or_label.iter() {
        match instr_or_label {
            InstrOrLabel::Instruction(instr) => instructions.push(instr),
            InstrOrLabel::Label(Label::Global(label)) => {
                labels.add_global_label(label.clone(), instructions.len())
            }
            InstrOrLabel::Label(Label::Local(label)) => {
                labels.add_local_label(*label, instructions.len())
            }
        }
    }
    labels.end_setup();
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
                    }
                    Expression::Diadic { op, a1, a2 } => {
                        encoded_instr[0] = true;
                        op_code = op.code();
                        a_1 = a1;
                        a_2 = Some(a2);
                    }
                };
            }
            Instruction::Statement(statement) => match statement {
                Statement::Monadic { op, a1 } => {
                    encoded_instr[0] = false;
                    op_code = op.code();
                    a_1 = a1;
                    a_2 = None;
                }
                Statement::Diadic { op, a1, a2 } => {
                    encoded_instr[0] = true;
                    op_code = op.code();
                    a_1 = a1;
                    a_2 = Some(a2);
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
                encoded_instr
                    .set_range(12..28, labels.resolve_immediate(imm).unwrap())
            }
        }
        match a_2 {
            Some(Arg::Register(reg)) => {
                encoded_instr[7] = true;
                encoded_instr.set_range(28..32, *reg as u32)
            }
            Some(Arg::Immediate(imm)) => {
                encoded_instr[7] = false;
                encoded_instr
                    .set_range(16..32, labels.resolve_immediate(imm).unwrap())
            }
            None => {}
        }

        encoded_instr.set_range(1..6, op_code);
        code.extend(Into::<u32>::into(encoded_instr).to_le_bytes());
        labels.incr_instruction();
    }
    let mut file = File::create(output)?;
    file.write_all(&code)?;
    Ok(())
}
