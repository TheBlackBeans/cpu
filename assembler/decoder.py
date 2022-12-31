import enum
from typing import Optional

@enum.unique
class Arity(enum.Enum):
	Unary = 1
	Binary = 2
	
	def __lt__(self, o: 'Arity') -> bool:
		return self.value < o.value
	def __le__(self, o: 'Arity') -> bool:
		return self.value <= o.value
	def __gt__(self, o: 'Arity') -> bool:
		return self.value > o.value
	def __ge__(self, o: 'Arity') -> bool:
		return self.value >= o.value

@enum.unique
class Category(enum.Enum):
	ArithmeticLogic = 0b00
	ControlFlow = 0b01
	Comparison = 0b11
	Misc = 0b10
	
	Unknown = -1

@enum.unique
class InstructionType(enum.Enum):
	Add   = 0b000001
	Sub   = 0b000011
	Mul   = 0b000101
	Div   = 0b000111
	Mod   = 0b001001
	And   = 0b001011
	Or    = 0b001101
	Xor   = 0b001111
	
	Jmp   = 0b010000
	Jo    = 0b010010
	Jz    = 0b010001
	Jzo   = 0b010011
	Jnz   = 0b010101
	Jnzo  = 0b010111
	
	Cmpeq = 0b110001
	Cmpne = 0b111001
	Cmpbl = 0b110011
	Cmpae = 0b111011
	Cmplt = 0b110111
	Cmpge = 0b111111
	
	Load  = 0b100000
	Recv  = 0b100010
	Store = 0b100001
	Send  = 0b100011
	
	Unknown = -1
	
	def __init__(self, i: int) -> None:
		self._arity = Arity.Unary if self.value & 0b1 == 0 else Arity.Binary
		self._cat = Category.Unknown
		for cat in Category:
			if cat.value == (self.value >> 4) & 0b11:
				self._cat = cat
				break
		self._has_dest = (self._cat == Category.ArithmeticLogic) or (self._cat == Category.Comparison) or (i & 0b111101 == 0b100000)
	
	@property
	def arity(self) -> Arity:
		return self._arity
	@property
	def category(self) -> Category:
		return self._cat
	
	@property
	def has_dest(self) -> bool:
		return self._has_dest
	
	def __str__(self) -> str:
		return instructionTypeMap[self]
instructionTypeMap = {
	InstructionType.Add:   "add",
	InstructionType.Sub:   "sub",
	InstructionType.Mul:   "mul",
	InstructionType.Div:   "div",
	InstructionType.Mod:   "mod",
	InstructionType.And:   "and",
	InstructionType.Or:    "or",
	InstructionType.Xor:   "xor",
	
	InstructionType.Jmp:   "jmp",
	InstructionType.Jo:    "jo",
	InstructionType.Jz:    "jz",
	InstructionType.Jzo:   "jzo",
	InstructionType.Jnz:   "jnz",
	InstructionType.Jnzo:  "jnzo",
	
	InstructionType.Cmpeq: "cmpeq",
	InstructionType.Cmpne: "cmpne",
	InstructionType.Cmpbl: "cmpbl",
	InstructionType.Cmpae: "cmpae",
	InstructionType.Cmplt: "cmplt",
	InstructionType.Cmpge: "cmpge",
	
	InstructionType.Load:  "load",
	InstructionType.Recv:  "recv",
	InstructionType.Store: "store",
	InstructionType.Send:  "send",
	
	InstructionType.Unknown: "???"
}

class Register:
	value_size = 16
	
	def __init__(self):
		self._curvalue = 0
	
	@property
	def value(self) -> int:
		return self._curvalue
	@value.setter
	def value(self, v: int) -> None:
		self._curvalue = v & ((1 << Register.value_size) - 1)
class Registers:
	def __init__(self):
		self._regs = [Register() for _ in range(15)]
	
	def __getitem__(self, i: int) -> int:
		return self._regs[i - 1].value if i != 0 else 0
	def __setitem__(self, i: int, v: int) -> None:
		if i != 0:
			self._regs[i - 1].value = v

class Argument:
	@enum.unique
	class Type(enum.Enum):
		Immediate = 0
		Register = 1
	def __init__(self, t: Type, v: int) -> None:
		self._t = t
		if (self._t == Argument.Type.Immediate) and (v >= 1 << (Register.value_size - 1)):
			self._v = v - (1 << Register.value_size)
		else:
			self._v = v
	
	@property
	def argtype(self) -> 'Argument.Type':
		return self._t
	@property
	def argval(self) -> int:
		return self._v
	
	def get_current_value(self, registers: Registers) -> int:
		if self._t == Argument.Type.Immediate:
			return self._v
		else: # Register
			return registers[self._v]
	
	def __str__(self) -> str:
		if self._t == Argument.Type.Immediate:
			return str(self._v)
		else:
			return "r" + str(self._v)

class Instruction:
	binary_length = 32
	
	def __init__(self, insn: int) -> None:
		self._type = InstructionType.Unknown
		for insnt in InstructionType:
			if insnt.value == insn & 0b111111:
				self._type = insnt
		
		self._dest = Argument(Argument.Type.Register, (insn >> 8) & 0xF)
		if (insn & 0b01000000) != 0:
			self._arg1 = Argument(Argument.Type.Register, (insn >> 12) & 0xF)
		else:
			self._arg1 = Argument(Argument.Type.Immediate, (insn >> 12) & 0xFFFF)
		if (insn & 0b10000000) != 0:
			self._arg2 = Argument(Argument.Type.Register, (insn >> 28) & 0xF)
		else:
			self._arg2 = Argument(Argument.Type.Immediate, (insn >> 16) & 0xFFFF)
	
	@property
	def arity(self) -> Arity:
		return self._type.arity
	@property
	def category(self) -> Category:
		return self._type.category
	@property
	def type(self) -> InstructionType:
		return self._type
	@property
	def dest(self) -> Optional[Argument]:
		return self._dest if self._type.has_dest else None
	@property
	def arg1(self) -> Optional[Argument]:
		return self._arg1 if self._type.arity >= Arity.Unary else None
	@property
	def arg2(self) -> Optional[Argument]:
		return self._arg2 if self._type.arity >= Arity.Binary else None
	
	def __str__(self) -> str:
		pre = (str(self._dest) + " = ") if self._type.has_dest else ""
		if self.arity == Arity.Unary:
			return pre + str(self._type) + " " + str(self._arg1)
		else: # Binary
			return pre + str(self._type) + " " + str(self._arg1) + ", " + str(self._arg2)

def generateInstruction(
  it: InstructionType, dest: Optional[Argument] = None, arg1: Optional[Argument] = None, arg2: Optional[Argument] = None) -> Instruction:
	if it == InstructionType.Unknown:
		raise ValueError("instruction type cannot be unknown")
	insn = it.value
	if dest is None:
		if it.has_dest:
			raise ValueError("instruction type requires a destination")
	elif dest.argtype != Argument.Type.Register:
		raise ValueError("destination must be a register")
	else:
		insn = insn | (dest.argval << 8)
	if arg1 is None:
		if it.arity >= Arity.Unary:
			raise ValueError("instruction type requires a first argument")
		else:
			arg1 = Argument(Argument.Type.Register, 0)
	else:
		if arg1.argtype == Argument.Type.Immediate:
			insn = insn | 0b00000000 | (arg1.argval << 12)
		else:
			insn = insn | 0b01000000 | (arg1.argval << 12)
	if arg2 is None:
		if it.arity >= Arity.Binary:
			raise ValueError("instruction type requires a second argument")
		else:
			arg2 = Argument(Argument.Type.Register, 0)
	else:
		if arg2.argtype == Argument.Type.Immediate:
			insn = insn | 0b00000000 | (arg2.argval << 16)
		else:
			insn = insn | 0b10000000 | (arg2.argval << 28)
	return Instruction(insn)

if __name__ == '__main__':
	import sys
	for insn in sys.argv[1:]:
		try:
			real_insn = int(insn, base=2)
			if (real_insn < 0) or (real_insn >= 0x100000000):
				print(insn, "Not a valid binary instruction")
			else:
				bin_insn = bin(real_insn)[2:]
				if len(bin_insn) < Instruction.binary_length:
					bin_insn = "0" * (Instruction.binary_length - len(bin_insn)) + bin_insn
				print(bin_insn, Instruction(real_insn))
		except ValueError:
			print(insn, "Not a valid binary instruction")
