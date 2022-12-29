#include <bitset>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <thread>

#include "instruction.hpp"
#include "io_interface.h"

using used_clock = std::chrono::steady_clock;

void set_dest(Instruction insn, Registers &regs, Register val) {
	return set_reg(regs, (insn >> 8) & 0xF, val);
}
Register *get_dest_ptr(Instruction insn, Registers &regs) {
	return get_reg_ptr(regs, (insn >> 8) & 0xF);
}
Register get_arg1(Instruction insn, Registers &regs) {
	if (insn & 0b01000000) {
		return get_reg(regs, (insn >> 12) & 0xF);
	} else {
		return (insn >> 12) & 0xFFFF;
	}
}
Register get_arg2(Instruction insn, Registers &regs) {
	if (insn & 0b10000000) {
		return get_reg(regs, (insn >> 28) & 0xF);
	} else {
		return (insn >> 16) & 0xFFFF;
	}
}

void help(const char *arg0) {
	std::cout << "Usage: " << arg0 << "\n"
	             "  * -f      --file <filename>                Binary blob filename\n"
	             "  * -n      --ncycles <n>                    Number of clock cycles to execute\n"
	             "    -F      --freq <n>                       Limit on the frequency of the clock, in Hertz (must be at least 1)\n"
	             "    -h      --help                           Display this help\n"
	             "    -q      --no-init-msg                    Don't display the \"Read .. instructions\" message\n"
	             "    -r      --init-regs <r1> ... <r15> <ip>  Set the initial register values\n"
	             "    --ifmt  --instruction-format <fmt>       Set the per-instruction and exit string format\n"
	             "    --fmt   --format <fmt>                   Set the exit string format\n"
	             "\n"
	             "Option marked with a * are mandatory.\n"
	             "\n"
	             "The format string is copied byte per byte, unless one of the following string is matched, in which case it is substituted:\n"
	             "%b     Write the next values in binary form\n"
	             "%d     Write the next values in decimal form\n"
	             "%x     Write the next values in hexadecimal form\n"
	             "%r0    Replaced by the value of register r0\n"
	             "%r1    Replaced by the value of register r1\n"
	             "%r2    Replaced by the value of register r2\n"
	             "%r3    Replaced by the value of register r3\n"
	             "%r4    Replaced by the value of register r4\n"
	             "%r5    Replaced by the value of register r5\n"
	             "%r6    Replaced by the value of register r6\n"
	             "%r7    Replaced by the value of register r7\n"
	             "%r8    Replaced by the value of register r8\n"
	             "%r9    Replaced by the value of register r9\n"
	             "%r10   Replaced by the value of register r10\n"
	             "%r11   Replaced by the value of register r11\n"
	             "%r12   Replaced by the value of register r12\n"
	             "%r13   Replaced by the value of register r13\n"
	             "%r14   Replaced by the value of register r14\n"
	             "%r15   Replaced by the value of register r15\n"
	             "%ip    Replaced by the value of register ip\n"
	             "%insn  Replaced by the binary representation of the current instruction, followed by a disassembly of it\n"
	             "%ram   Replaced by a list of \"RAM[<key>] = <value>\" pairs (the key being always written in hexadecimal form)\n"
	             "\n"
	             "If both --ifmt and --fmt are provided, the format string given by --fmt takes precedence as the exit string." << std::endl;
}

void display_formatted(const char *fmt, const Registers &regs, const Register &ip, const Instructions &insns, const RAM &ram) {
	std::cout << std::setfill('0');
	bool show_bin = false, show_hex = false;
	
	for (std::size_t i = 0; fmt[i]; ++i) {
		if (fmt[i] == '%') {
#define TEST(s) !strncmp(fmt + i + 1, #s, std::strlen(#s))
#define SHOW_VAL(v) do { \
	if (show_bin) std::cout << "0b" << std::bitset<sizeof(v) * 8>(v); \
	else if (show_hex) std::cout << "0x" << std::hex << std::setw(sizeof(v) * 2) << v; \
	else std::cout << std::dec << std::setw(1) << v; \
} while (false)
			if (TEST(b)) {
				show_bin = true;
				++i;
			} else if (TEST(d)) {
				show_hex = show_bin = false;
				++i;
			} else if (TEST(x)) {
				show_bin = false; show_hex = true;
				++i;
#define OUTPUT(n) SHOW_VAL(get_reg(regs, n))
			} else if (TEST(r0)) { OUTPUT(0); i += 2; }
			else if (TEST(r10)) { OUTPUT(10); i += 3; }
			else if (TEST(r11)) { OUTPUT(11); i += 3; }
			else if (TEST(r12)) { OUTPUT(12); i += 3; }
			else if (TEST(r13)) { OUTPUT(13); i += 3; }
			else if (TEST(r14)) { OUTPUT(14); i += 3; }
			else if (TEST(r15)) { OUTPUT(15); i += 3; }
			else if (TEST(r1))  { OUTPUT(1);  i += 2; }
			else if (TEST(r2))  { OUTPUT(2);  i += 2; }
			else if (TEST(r3))  { OUTPUT(3);  i += 2; }
			else if (TEST(r4))  { OUTPUT(4);  i += 2; }
			else if (TEST(r5))  { OUTPUT(5);  i += 2; }
			else if (TEST(r6))  { OUTPUT(6);  i += 2; }
			else if (TEST(r7))  { OUTPUT(7);  i += 2; }
			else if (TEST(r8))  { OUTPUT(8);  i += 2; }
			else if (TEST(r9))  { OUTPUT(9);  i += 2; }
#undef OUTPUT
			else if (TEST(ip)) { SHOW_VAL(ip); i += 2; }
			else if (TEST(insn)) {
				std::cout << std::bitset<sizeof(Instruction) * 8>(insns[ip]) << " | " << std::dec << DecodedInstruction(insns[ip]);
				i += 4;
			}
			else if (TEST(ram)) {
				// Unordered display
				for (const auto &r : ram) {
					std::cout << "RAM[" << std::setw(1) << std::dec << r.first << "] = ";
					SHOW_VAL(r.second);
					std::cout << "\n";
				}
				i += 3;
#undef TEST
#undef SHOW_VAL
			} else {
				std::cout << fmt[i];
			}
		} else {
			std::cout << fmt[i];
		}
	}
	std::cout << std::flush;
}

bool failed; // Can be considered atomic

extern "C" void request_stop(void) {
	failed = true;
}

int main(int argc, char **argv) {
	if (argc == 1) {
		help(argv[0]);
		return 0;
	}
	
	Registers regs = {0};
	Register ip = 0;
	RAM ram;
	
	unsigned long long maxiter = static_cast<unsigned long long>(-1);
	used_clock::duration wait_delay = used_clock::duration(0);
	
	bool init_regs = false, show_initialized = true;
	const char *filename = nullptr;
	const char *format = nullptr, *iformat = nullptr;
	for (int i = 1; i < argc; ++i) {
		if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help")) {
			help(argv[0]);
			return 0;
		} else if (!strcmp(argv[i], "-q") || !strcmp(argv[i], "--no-init-msg")) {
			show_initialized = false;
		} else if (!strcmp(argv[i], "-r") || !strcmp(argv[i], "--init-regs")) {
			if (argc <= i + static_cast<int>(regs.size()) + 1) {
				std::cout << "Not enough values given\n\n";
				help(argv[0]);
				return 1;
			} else if (init_regs) {
				std::cout << "Registers already initialized\n\n";
				help(argv[0]);
				return 1;
			} else {
				init_regs = true;
				for (std::size_t j = 0; j < regs.size(); ++j) {
					char *endp = nullptr;
					unsigned long long val = std::strtoull(argv[i + 1 + j], &endp, 0);
					if (!endp || *endp || (val >= (1 << register_size) << sizeof(regs[j]))) {
						std::cout << "Invalid value for register r" << (j + 1) << " given\n\n";
						help(argv[0]);
						return 1;
					}
					regs[j] = static_cast<Register>(val);
				}
				char *endp = nullptr;
				unsigned long long val = std::strtoull(argv[i + 1 + regs.size()], &endp, 0);
				if (!endp || *endp || (val >= (1 << 8) << sizeof(ip))) {
					std::cout << "Invalid value for register ip given\n\n";
					help(argv[0]);
					return 1;
				}
				ip = static_cast<Register>(val);
				
				i += regs.size() + 1;
			}
		} else if (!strcmp(argv[i], "-n") || !strcmp(argv[i], "--ncycles")) {
			if (argc <= i + 1) {
				std::cout << "No number of cycle given\n\n";
				help(argv[0]);
				return 1;
			} else if (maxiter != static_cast<unsigned long long>(-1)) {
				std::cout << "Number of cycle already given\n\n";
				help(argv[0]);
				return 1;
			} else {
				char *endp = nullptr;
				maxiter = std::strtoull(argv[i + 1], &endp, 0);
				if (!endp || *endp) {
					std::cout << "Invalid number of cycles given\n\n";
					help(argv[0]);
					return 1;
				}
				++i;
			}
		} else if (!strcmp(argv[i], "-f") || !strcmp(argv[i], "--file")) {
			if (argc <= i + 1) {
				std::cout << "No filename given\n\n";
				help(argv[0]);
				return 1;
			} else if (filename) {
				std::cout << "Filename already given\n\n";
				help(argv[0]);
				return 1;
			} else {
				filename = argv[i + 1];
				++i;
			}
		} else if (!strcmp(argv[i], "-F") || !strcmp(argv[i], "--freq")) {
			if (argc <= i + 1) {
				std::cout << "No frequency given\n\n";
				help(argv[0]);
				return 1;
			} else if (wait_delay.count() != 0) {
				std::cout << "Clock frequency already given\n\n";
				help(argv[0]);
				return 1;
			} else {
				char *endp = nullptr;
				unsigned long long fq = std::strtoull(argv[i + 1], &endp, 0);
				if (!endp || *endp || !fq) {
					std::cout << "Invalid clock frequency given\n\n";
					help(argv[0]);
					return 1;
				}
				wait_delay = used_clock::duration(used_clock::duration::period::den / (fq * used_clock::duration::period::num));
				if (!wait_delay.count()) {
					wait_delay = used_clock::duration(1);
				}
				if (used_clock::duration::period::den % (fq * used_clock::duration::period::num)) {
					std::cout << "Warning: cannot have the requested frequency; a frequency of approximately "
					          << static_cast<long double>(used_clock::duration::period::den)
					               / (wait_delay.count() * used_clock::duration::period::num)
					               - fq << " Hz has been added to it." << std::endl;
				}
				++i;
			}
		} else if (!strcmp(argv[i], "--fmt") || !strcmp(argv[i], "--format")) {
			if (argc <= i + 1) {
				std::cout << "No format given\n\n";
				help(argv[0]);
				return 1;
			} else if (format && (format != iformat)) {
				std::cout << "Format already given\n\n";
				help(argv[0]);
				return 1;
			} else {
				format = argv[i + 1];
				++i;
			}
		} else if (!strcmp(argv[i], "--ifmt") || !strcmp(argv[i], "--instruction-format")) {
			if (argc <= i + 1) {
				std::cout << "No per-instruction format given\n\n";
				help(argv[0]);
				return 1;
			} else if (iformat) {
				std::cout << "Per-instruction format already given\n\n";
				help(argv[0]);
				return 1;
			} else {
				iformat = argv[i + 1];
				if (!format) format = iformat;
				++i;
			}
		} else {
			std::cout << "Unknown argument " << argv[i] << "\n\n";
			help(argv[0]);
			return 1;
		}
	}
	if (!filename) {
		std::cout << "No filename provided\n\n";
		help(argv[0]);
		return 1;
	}
	if (maxiter == static_cast<unsigned long long>(-1)) {
		std::cout << "No cycle count provided\n\n";
		help(argv[0]);
		return 1;
	}
	
	Instructions rom;
	
	std::fstream f{ filename, std::ios_base::in | std::ios_base::binary };
	if (!f) {
		std::cout << "Couldn't open file '" << filename << "'\n\n";
		help(argv[0]);
		return 1;
	}
	char inp[sizeof(Instruction)];
	while (f.read(inp, sizeof(Instruction))) {
		rom.emplace_back(*reinterpret_cast<std::int32_t*>(&inp)); // type punning
	}
	f.close();
	
	if (!format) {
		format = default_format(iformat);
	}
	
	if (show_initialized) std::cout << "Read " << std::dec << rom.size() << " instructions" << std::endl;
	
	failed = false;
	if (!io_init(format, iformat)) {
		std::cout << "Failed to initialize I/O" << std::endl;
		return 1;
	}
	
	used_clock::time_point wait_end_time = used_clock::now();
	for (unsigned long long niter = 0; (niter < maxiter) && !failed; ++niter) {
		if (iformat) display_formatted(iformat, regs, ip, rom, ram);
		
		wait_end_time += wait_delay;
		std::this_thread::sleep_until(wait_end_time);
		
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
			if (tmp) set_dest(insn, regs, get_arg1(insn, regs) / tmp);
			else {
				std::cout << "Division by zero at IP " << std::dec << (ip - 1) << " (0x"
				          << std::hex << (ip - 1) << "): setting destination to 0" << std::endl;
				set_dest(insn, regs, 0);
			}
			break; } // div
		case 0b001001: {
			Register tmp = get_arg2(insn, regs);
			if (tmp) set_dest(insn, regs, get_arg1(insn, regs) % tmp);
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
		case 0b110011: set_dest(insn, regs, (static_cast<UReg>(get_arg1(insn, regs)) <  static_cast<UReg>(get_arg2(insn, regs))) ? 1 : 0); break; // cmpbl
		case 0b111011: set_dest(insn, regs, (static_cast<UReg>(get_arg1(insn, regs)) >= static_cast<UReg>(get_arg2(insn, regs))) ? 1 : 0); break; // cmpae
		case 0b110111: set_dest(insn, regs, (static_cast<SReg>(get_arg1(insn, regs)) <  static_cast<SReg>(get_arg2(insn, regs))) ? 1 : 0); break; // cmplt
		case 0b111111: set_dest(insn, regs, (static_cast<SReg>(get_arg1(insn, regs)) >= static_cast<SReg>(get_arg2(insn, regs))) ? 1 : 0); break; // cmpge
		
		case 0b100000: set_dest(insn, regs, ram[get_arg1(insn, regs)]);  break; // load
		case 0b100001: ram[get_arg1(insn, regs)] = get_arg2(insn, regs); break; // store
		case 0b100010: // recv
			if (!io_recv(get_arg1(insn, regs), get_dest_ptr(insn, regs))) {
				std::cout << "Unsupported recv " << std::dec << get_arg1(insn, regs) << " instruction (at IP = " << std::dec << (ip - 1) << " = 0x" << std::hex << (ip - 1) << ")" << std::endl;
			}
			break;
		case 0b100011: // send
			if (!io_send(get_arg1(insn, regs), get_arg2(insn, regs))) {
				std::cout << "Unsupported send " << std::dec << get_arg1(insn, regs) << ", " << get_arg2(insn, regs)
				          << " instruction (at IP = " << std::dec << (ip - 1) << " = 0x" << std::hex << (ip - 1) << ")" << std::endl;
			}
			break;
		
		default:
			std::cout << "IP " << std::dec << (ip - 1) << " (0x" << std::hex << (ip - 1) << ") has instruction "
			          << insn << " (0b" << std::bitset<sizeof(Instruction) * 8>(insn) << "), which is invalid" << std::endl;
			failed = true;
			break;
		}
	}
	
	io_close();
	
	display_formatted(format, regs, ip, rom, ram);
	std::cout << std::flush;
	
	return 0;
}
