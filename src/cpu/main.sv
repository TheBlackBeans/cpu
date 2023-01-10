`default_nettype none
`timescale 10ms/100ns // #1 = 10±0.1μs

module Main;
	parameter integer rom_size = 2**8;
	parameter integer STDIN = 32'h8000_0000;
	
	logic clk;
	logic rstn;
	logic [31:0] rom[rom_size];
	
	logic [15:0] ip;
	
	Driver#(.rom_size(rom_size)) driver(.rom, .clk, .rstn, .ip);
	
	initial begin
		// Read the ROM
		static int fd = $fopen("out/clock", "rb");
		static int ignore = $fread(rom, fd);
		for (int i = 0; i < rom_size; ++i)
			rom[i] <= {rom[i][7:0], rom[i][15:8], rom[i][23:16], rom[i][31:24]}; // Update the ROM (the file is read in reverse)
		
		clk = 0; // Reset the clock
		
		// Reset the CPU
		rstn = 1;
		#1 rstn = 0;
		#1 // $display("[ MAIN  ] rstn will go to 1, ALU %b  COMP %b MISC %b JMP %b/%b", alu_out, comp_out, misc_cs, maybe_jmp, ip_jmp);
		rstn = 1;
	end
	
	always #50 begin // 0.5ms, so the clock runs at 1kHz.
		$display("WAIT"); // Don't try to understand...
		$fflush();
		$fgetc(STDIN);
		
		clk = ~clk;
		if (clk) begin
			#0 if (ip <= 256)
				; // $display("[ MAIN  ] %3d | %b", ip, rom[ip]);
			else begin
				$display("IP is too big: %016b = %d, exiting", ip, ip);
				$finish;
			end
		end else begin
			// $display("[ MAIN  ] Clock went to 0, ALU %b  COMP %b MISC %b JMP %b/%b  regdataw %16b", alu_out, comp_out, misc_cs, maybe_jmp, ip_jmp, rdataw);
		end
	end
endmodule
