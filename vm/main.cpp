#include <array>
#include <bitset>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <unordered_map>
#include <vector>

using Register = std::uint16_t;
using SReg = std::uint16_t;
using UReg = std::int16_t;
using Registers = std::array<Register, 15>;
using Instruction = std::uint32_t;
using Instructions = std::vector<Instruction>;
using RAM = std::unordered_map<Register, Instruction>;

Register get_reg(Registers &regs, std::uint8_t idx) {
// std::cout << "Getting " << static_cast<unsigned>(idx) << "\n";
	if (idx) return regs[idx - 1];
	else return 0;
}
void set_reg(Registers &regs, std::uint8_t idx, Register val) {
// std::cout << "Setting " << static_cast<unsigned>(idx) << " to " << val << "\n";
	if (idx) regs[idx - 1] = val;
}

void set_dest(Instruction insn, Registers &regs, Register val) {
	return set_reg(regs, (insn >> 8) & 0xF, val);
}
Register get_arg1(Instruction insn, Registers &regs) {
// std::cout << "Getting arg1: " << insn << "\n";
	if (insn & 0b01000000) {
		return get_reg(regs, (insn >> 12) & 0xF);
	} else {
		return (insn >> 12) & 0xFFFF;
	}
}
Register get_arg2(Instruction insn, Registers &regs) {
// std::cout << "Getting arg2: " << insn << "\n";
	if (insn & 0b10000000) {
		return get_reg(regs, (insn >> 28) & 0xF);
	} else {
		return (insn >> 16) & 0xFFFF;
	}
}

int main(int argc, char **argv) {
	if (argc != 3) {
		std::cout << "Usage: " << argv[0] << " <binary blob> <n. executions>" << std::endl;
		return (argc == 0) ? 0 : 1;
	}
	if (!strcmp(argv[1], "-h") || !strcmp(argv[1], "--help")) {
		std::cout << "Usage: " << argv[0] << " <binary blob> <n. executions>" << std::endl;
		return 0;
	}
	
	char *endp = nullptr;
	unsigned long long maxiter = std::strtoull(argv[2], &endp, 0);
	if (*endp) {
		std::cout << "Usage: " << argv[0] << " <binary blob> <n. executions>" << std::endl;
		return 1;
	}
	
	Registers regs = {0};
	Register ip = 0;
	Instructions rom;
	RAM ram;
	
	std::fstream f{ argv[1], std::ios_base::in | std::ios_base::binary };
	if (!f) {
		std::cout << "Usage: " << argv[0] << " <binary blob> <n. executions>\nCouldn't open file '" << argv[1] << "'" << std::endl;
		return 1;
	}
	char inp[sizeof(Instruction)];
	while (f.read(inp, sizeof(Instruction))) {
		rom.emplace_back(*reinterpret_cast<std::int32_t*>(&inp)); // type punning
// std::cout << "Instruction: " << std::setw(8) << std::setfill('0') << std::hex << rom.back() << "\n";
	}
// std::cout << std::dec;
	f.close();
	
	std::cout << "Read " /* << std::dec */ << rom.size() << " instructions" << std::endl;
	
	bool failed = false;
	for (unsigned long long niter = 0; (niter < maxiter) && !failed; ++niter) {
		if (ip >= rom.size()) {
			std::cout << "IP " << std::dec << ip << " (0x"
			          << std::hex << ip << ") is outside of the program array, stopping execution" << std::endl;
			break;
		}
		const Instruction &insn = rom[ip++]; // Note that the current instruction is at ip - 1
		switch (insn & 0b111111) {
		case 0b000001: set_dest(insn, regs, get_arg1(insn, regs) + get_arg2(insn, regs)); break; // add
		case 0b000011: set_dest(insn, regs, get_arg1(insn, regs) - get_arg2(insn, regs)); break; // sub
		case 0b000101: set_dest(insn, regs, get_arg1(insn, regs) * get_arg2(insn, regs)); break; // mul
		case 0b000111: {
			Register tmp = get_arg2(insn, regs);
			if (tmp) set_dest(insn, regs, get_arg1(insn, regs) / get_arg2(insn, regs));
			else {
				std::cout << "Division by zero at IP " << std::dec << (ip - 1) << " (0x"
				          << std::hex << (ip - 1) << "): setting destination to 0" << std::endl;
				set_dest(insn, regs, 0);
			}
			break; } // div
		case 0b001001: {
			Register tmp = get_arg2(insn, regs);
			if (tmp) set_dest(insn, regs, get_arg1(insn, regs) % get_arg2(insn, regs));
			else {
				std::cout << "Division by zero at IP " << std::dec << (ip - 1) << " (0x"
				          << std::hex << (ip - 1) << "): setting destination to 0" << std::endl;
				set_dest(insn, regs, 0);
			}
			break; } // mod
		case 0b001011: set_dest(insn, regs, get_arg1(insn, regs) & get_arg2(insn, regs)); break; // and
		case 0b001101: set_dest(insn, regs, get_arg1(insn, regs) | get_arg2(insn, regs)); break; // or
		case 0b001111: set_dest(insn, regs, get_arg1(insn, regs) ^ get_arg2(insn, regs)); break; // xor
		
		case 0b010000:                                ip  = get_arg1(insn, regs)    ; break; // jmp
		case 0b010010:                                ip += get_arg1(insn, regs) - 1; break; // jo
		case 0b010001: if (get_arg2(insn, regs) == 0) ip  = get_arg1(insn, regs)    ; break; // jz
		case 0b010011: if (get_arg2(insn, regs) == 0) ip += get_arg1(insn, regs) - 1; break; // jzo
		case 0b010101: if (get_arg2(insn, regs) != 0) ip  = get_arg1(insn, regs)    ; break; // jnz
		case 0b010111: if (get_arg2(insn, regs) != 0) ip += get_arg1(insn, regs) - 1; break; // jnzo
		
		case 0b110001: set_dest(insn, regs, (                  get_arg1(insn, regs)  ==                   get_arg2(insn, regs) ) ? 1 : 0); break; // cmpeq
		case 0b111001: set_dest(insn, regs, (                  get_arg1(insn, regs)  !=                   get_arg2(insn, regs) ) ? 1 : 0); break; // cmpne
		case 0b110011: set_dest(insn, regs, (static_cast<SReg>(get_arg1(insn, regs)) <  static_cast<SReg>(get_arg2(insn, regs))) ? 1 : 0); break; // cmplt
		case 0b111011: set_dest(insn, regs, (static_cast<SReg>(get_arg1(insn, regs)) >= static_cast<SReg>(get_arg2(insn, regs))) ? 1 : 0); break; // cmpge
		case 0b110111: set_dest(insn, regs, (static_cast<UReg>(get_arg1(insn, regs)) <  static_cast<UReg>(get_arg2(insn, regs))) ? 1 : 0); break; // cmpab
		case 0b111111: set_dest(insn, regs, (static_cast<UReg>(get_arg1(insn, regs)) >= static_cast<UReg>(get_arg2(insn, regs))) ? 1 : 0); break; // cmpbe
		
		case 0b100000: set_dest(insn, regs, ram[get_arg1(insn, regs)]);  break; // load
		case 0b100001: ram[get_arg1(insn, regs)] = get_arg2(insn, regs); break; // store
		
		default:
			std::cout << "IP " << std::dec << ip << " (0x" << std::hex << ip << ") has instruction "
			          << insn << " (0b" << std::bitset<sizeof(Instruction) * 8>(insn) << "), which is invalid" << std::endl;
			failed = true;
			break;
		}
	}
	
	std::cout << std::setfill('0');
	for (std::uint8_t i = 0; i < regs.size() + 1; ++i) {
		std::cout << "r" << std::setw(1) << std::dec << static_cast<unsigned>(i) << " = 0x" << std::setw(sizeof(Register) * 2) << std::hex << get_reg(regs, i) << "\n";
	}
	// Unordered display
	for (const auto &r : ram) {
		std::cout << "RAM[" << std::setw(1) << std::dec << r.first << "] = 0x" << std::setw(sizeof(Register) * 2) << std::hex << r.second << "\n";
	}
	
	return 0;
}
