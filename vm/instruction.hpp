#pragma once

#include <array>
#include <cstdint>
#include <ostream>
#include <string>
#include <unordered_map>
#include <vector>

enum class Arity {
	Unary = 1,
	Binary = 2,
};
constexpr bool operator<(Arity l, Arity r)  { return static_cast<int>(l) <  static_cast<int>(r); }
constexpr bool operator<=(Arity l, Arity r) { return static_cast<int>(l) <= static_cast<int>(r); }
constexpr bool operator>(Arity l, Arity r)  { return static_cast<int>(l) >  static_cast<int>(r); }
constexpr bool operator>=(Arity l, Arity r) { return static_cast<int>(l) >= static_cast<int>(r); }

enum class Category {
	ArithmeticLogic = 0b00,
	ControlFlow = 0b01,
	Comparison = 0b11,
	Misc = 0b10,
	
	Unknown = -1
};

enum class InstructionType {
	Add   = 0b000001,
	Sub   = 0b000011,
	Mul   = 0b000101,
	Div   = 0b000111,
	Mod   = 0b001001,
	And   = 0b001011,
	Or    = 0b001101,
	Xor   = 0b001111,
	
	Jmp   = 0b010000,
	Jo    = 0b010010,
	Jz    = 0b010001,
	Jzo   = 0b010011,
	Jnz   = 0b010101,
	Jnzo  = 0b010111,
	
	Cmpeq = 0b110001,
	Cmpne = 0b111001,
	Cmpbl = 0b110011,
	Cmpae = 0b111011,
	Cmplt = 0b110111,
	Cmpge = 0b111111,
	
	Load  = 0b100000,
	Store = 0b100001,
	
	Unknown = -1
};
constexpr Arity getArity(InstructionType it) {
	return (it == InstructionType::Unknown) ? Arity::Binary : static_cast<Arity>(((static_cast<int>(it) >> 0) & 0b1) + 1);
}
constexpr Category getCategory(InstructionType it) {
	return (it == InstructionType::Unknown) ? Category::Unknown : static_cast<Category>((static_cast<int>(it) >> 4) & 0b11);
}
constexpr bool hasDestination(InstructionType it) {
	Category cat = getCategory(it);
	return (cat == Category::Unknown) || (cat == Category::ArithmeticLogic) || (cat == Category::Comparison) || (it == InstructionType::Load);
}
constexpr const char *to_string(InstructionType it) {
	switch (it) {
	case InstructionType::Add:   return "add";
	case InstructionType::Sub:   return "sub";
	case InstructionType::Mul:   return "mul";
	case InstructionType::Div:   return "div";
	case InstructionType::Mod:   return "mod";
	case InstructionType::And:   return "and";
	case InstructionType::Or:    return "or";
	case InstructionType::Xor:   return "xor";
	
	case InstructionType::Jmp:   return "jmp";
	case InstructionType::Jo:    return "jo";
	case InstructionType::Jz:    return "jz";
	case InstructionType::Jzo:   return "jzo";
	case InstructionType::Jnz:   return "jnz";
	case InstructionType::Jnzo:  return "jnzo";
	
	case InstructionType::Cmpeq: return "cmpeq";
	case InstructionType::Cmpne: return "cmpne";
	case InstructionType::Cmpbl: return "cmpbl";
	case InstructionType::Cmpae: return "cmpae";
	case InstructionType::Cmplt: return "cmplt";
	case InstructionType::Cmpge: return "cmpge";
	
	case InstructionType::Load:  return "load";
	case InstructionType::Store: return "store";
	
	case InstructionType::Unknown:
	default: return "???";
	}
}
std::ostream &operator<<(std::ostream &os, const InstructionType &it) {
	return os << to_string(it);
}
constexpr InstructionType to_instructiontype(int it) {
	switch (it) {
	case static_cast<int>(InstructionType::Add):   return InstructionType::Add;
	case static_cast<int>(InstructionType::Sub):   return InstructionType::Sub;
	case static_cast<int>(InstructionType::Mul):   return InstructionType::Mul;
	case static_cast<int>(InstructionType::Div):   return InstructionType::Div;
	case static_cast<int>(InstructionType::Mod):   return InstructionType::Mod;
	case static_cast<int>(InstructionType::And):   return InstructionType::And;
	case static_cast<int>(InstructionType::Or):    return InstructionType::Or;
	case static_cast<int>(InstructionType::Xor):   return InstructionType::Xor;
	
	case static_cast<int>(InstructionType::Jmp):   return InstructionType::Jmp;
	case static_cast<int>(InstructionType::Jo):    return InstructionType::Jo;
	case static_cast<int>(InstructionType::Jz):    return InstructionType::Jz;
	case static_cast<int>(InstructionType::Jzo):   return InstructionType::Jzo;
	case static_cast<int>(InstructionType::Jnz):   return InstructionType::Jnz;
	case static_cast<int>(InstructionType::Jnzo):  return InstructionType::Jnzo;
	
	case static_cast<int>(InstructionType::Cmpeq): return InstructionType::Cmpeq;
	case static_cast<int>(InstructionType::Cmpne): return InstructionType::Cmpne;
	case static_cast<int>(InstructionType::Cmpbl): return InstructionType::Cmpbl;
	case static_cast<int>(InstructionType::Cmpae): return InstructionType::Cmpae;
	case static_cast<int>(InstructionType::Cmplt): return InstructionType::Cmplt;
	case static_cast<int>(InstructionType::Cmpge): return InstructionType::Cmpge;
	
	case static_cast<int>(InstructionType::Load):  return InstructionType::Load;
	case static_cast<int>(InstructionType::Store): return InstructionType::Store;
	
	default: return InstructionType::Unknown;
	}
}

using Register = std::uint16_t;
using SReg = std::uint16_t;
using UReg = std::int16_t;
constexpr const std::size_t register_size = sizeof(Register) * 8;
static_assert(sizeof(Register) == sizeof(SReg), "Signed register and register must have the same data size");
static_assert(sizeof(Register) == sizeof(UReg), "Unsigned register and register must have the same data size");

using Registers = std::array<Register, 15>;

constexpr Register get_reg(const Registers &regs, std::uint8_t idx) {
// std::cout << "Getting " << static_cast<unsigned>(idx) << "\n";
	if (idx) return regs[idx - 1];
	else return 0;
}
inline void set_reg(Registers &regs, std::uint8_t idx, Register val) {
// std::cout << "Setting " << static_cast<unsigned>(idx) << " to " << val << "\n";
	if (idx) regs[idx - 1] = val;
}

struct Argument {
	enum class Type {
		Immediate = 0,
		Register = 1
	} type;
	SReg val;
	
	Argument() : Argument(Type::Immediate, 0) {}
	Argument(Type t, UReg v) {
		type = t;
		switch (t) {
		case Type::Immediate: val = (v >= 1 << (register_size - 1)) ? (static_cast<SReg>(v - (1 << register_size))) : static_cast<SReg>(v); break;
		case Type::Register: val = v & 0xF; break;
		default: val = -1;
		}
	}
	
	Register getCurrentValue(const Registers &regs) const {
		switch (type) {
		case Type::Immediate: return val;
		case Type::Register: return get_reg(regs, val);
		default: return val;
		}
	}
	
	inline operator std::string() const {
		switch (type) {
		case Type::Immediate: return std::to_string(val);
		case Type::Register:  return "r" + std::to_string(val);
		default: return "?" + std::to_string(val);
		}
	}
};
std::ostream &operator<<(std::ostream &os, const Argument &arg) {
	switch (arg.type) {
	case Argument::Type::Immediate: return os << arg.val;
	case Argument::Type::Register:  return os << "r" << arg.val;
	default: return os << "?" << arg.val;
	}
}

using Instruction = std::uint32_t;
constexpr const std::size_t instruction_size = sizeof(Instruction) * 8;
using Instructions = std::vector<Instruction>;
using RAM = std::unordered_map<Register, Instruction>;

struct DecodedInstruction {
	InstructionType it;
	Argument dest, arg1, arg2;
	
	DecodedInstruction(Instruction insn) {
		it = to_instructiontype(insn & 0b111111);
		dest = Argument(Argument::Type::Register, (insn >> 8) & 0xF);
		if (insn & 0b01000000) {
			arg1 = Argument(Argument::Type::Register, (insn >> 12) & 0xF);
		} else {
			arg1 = Argument(Argument::Type::Immediate, (insn >> 12) & 0xFFFF);
		}
		if (insn & 0b10000000) {
			arg2 = Argument(Argument::Type::Register, (insn >> 28) & 0xF);
		} else {
			arg2 = Argument(Argument::Type::Immediate, (insn >> 16) & 0xFFFF);
		}
	}
	
	constexpr Arity getArity() const { return ::getArity(it); }
	constexpr Category getCategory() const { return ::getCategory(it); }
	
	inline operator std::string() const {
		std::string pre = hasDestination(it) ? (std::string(dest) + " = ") : "";
		switch (getArity()) {
		case Arity::Unary:  return pre + to_string(it) + " " + std::string(arg1);
		case Arity::Binary: return pre + to_string(it) + " " + std::string(arg1) + ", " + std::string(arg2);
		default: return pre + to_string(it) + "? " + std::string(arg1) + ", " + std::string(arg2);
		}
	}
};
std::ostream &operator<<(std::ostream &os, const DecodedInstruction &di) {
	if (hasDestination(di.it)) os << di.dest << " = ";
	switch (di.getArity()) {
	case Arity::Unary:  return os << di.it << " " << di.arg1;
	case Arity::Binary: return os << di.it << " " << di.arg1 << ", " << di.arg2;
	default: return os << di.it << "? " << di.arg1 << ", " << di.arg2;
	}
}
