`default_nettype none

module Driver#(parameter rom_size = 1<<8)(input logic[31:0] rom[rom_size], input logic clk, input logic rstn, output logic [15:0] ip);
	logic reg_we;
	logic [3:0] raddrw, raddr1, raddr2;
	logic [15:0] rdataw, rdata1, rdata2;
	RegFile#(
		.addr_size(4),
		.data_size(16)
	) regfile(.clk, .rstn,
		.wenable(reg_we),
		.waddr(raddrw),
		.wdata(rdataw),
		.raddr1,
		.raddr2,
		.rdata1,
		.rdata2
	);
	
	logic use_r1, use_r2;
	logic [15:0] default_a1, default_a2;
	logic [15:0] adata1, adata2;
	ArgumentBus#(
		.data_size(16)
	) a1bus(
		.use_reg(use_r1),
		.reg_data(rdata1),
		.default_data(default_a1),
		.bus_data(adata1)
	), a2bus(
		.use_reg(use_r2),
		.reg_data(rdata2),
		.default_data(default_a2),
		.bus_data(adata2)
	);
	
	logic [3:0] optype;
	
	logic [15:0] aluout;
	ALU #(
		.CELL_SIZE(16)
	) alu(
		.op(optype[3:1]),
		.lhs(adata1),
		.rhs(adata2),
		.result(aluout)
	);
	
	logic [15:0] compout;
	Comparator#(
		.data_size(16)
	) comp(
		.instr(optype[3:1]),
		.lhs(adata1),
		.rhs(adata2),
		.result(compout)
	);
	
	logic        misc_cs;
	logic [15:0] miscmanout;
	MiscManager#(
		.data_size(16)
	) miscman(.clk, .rstn,
		.cs(misc_cs),
		.op(optype),
		.port(adata1),
		.data(adata2),
		.result(miscmanout)
	);
	
	logic        ip_incr;
	logic        maybe_jmp;
	logic        ip_jmp;
	logic [15:0] jaddr;
	JumpComputer#(
		.addr_size(16),
		.data_size(16)
	) jumpcomputer(
		.maybe_jmp(maybe_jmp),
		.op(optype),
		.ip(ip),
		.arg1(adata1),
		.arg2(adata2),
		.do_jmp(ip_jmp),
		.jaddr(jaddr)
	);
	
	InstructionPointer#(
		.addr_size(16),
		.isize(0)
	) ipreg(.clk, .rstn,
		.incr(ip_incr),
		.jmp(ip_jmp),
		.jaddr(jaddr),
		.addr(ip)
	);
	
	logic alu_out, comp_out;
	OutputBus#(
		.data_size(16)
	) outbus(
		.alu_cs(alu_out),
		.comp_cs(comp_out),
		.misc_cs,
		.jmp_cs(maybe_jmp),
		.alu_out(aluout),
		.comp_out(compout),
		.misc_out(miscmanout),
		.bus_data(rdataw)
	);
	
	Decoder dec(
		.op(rom[ip]),
		.alu_out,
		.comp_out,
		.misc_cs,
		.ip_incr,
		.maybe_jmp,
		.use_r1,
		.use_r2,
		.reg_we,
		.r1_addr(raddr1),
		.r2_addr(raddr2),
		.default_a1,
		.default_a2,
		.rw_addr(raddrw),
		.optype
	);
	
	/* always @(negedge clk) begin
		$display("[ MAIN  ] Clock went to 0, IP=%b -> %b  ALU %b  COMP %b MISC %b JMP %b/%b  regdataw %16b jaddr %16b", ip, rom[ip], alu_out, comp_out, misc_cs, maybe_jmp, ip_jmp, rdataw, jaddr);
	end */
endmodule // Driver
