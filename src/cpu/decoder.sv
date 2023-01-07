`default_nettype none

module Decoder
	(
	 input  logic[31:0] op,
	 output logic       alu_out,
	 output logic       comp_out,
	 output logic       misc_cs,
	 output logic       ip_incr,
	 output logic       maybe_jmp,
	 output logic       use_r1,
	 output logic       use_r2,
	 output logic       reg_we,
	 output logic[3:0]  r1_addr,
	 output logic[3:0]  r2_addr,
	 output logic[15:0] default_a1,
	 output logic[15:0] default_a2,
	 output logic[3:0]  rw_addr,
	 output logic[3:0]  optype
	 // NOTE : si il faut arrêter le CPU tant que l'IO ne s'est pas terminé, rajouter un signal de Misc vers ici
	 // et changer la valeur de ip_incr (mettre à 0 pour ne pas incrémenter le CPU)
	 // NE PAS mettre l'horloge en dépendance ici
	);
	
	logic [1:0] opkind;
	assign opkind = op[5:4];
	assign optype = op[3:0];
	assign use_r1 = op[6];
	assign use_r2 = op[7];
	
	assign ip_incr = 1;
	
	assign alu_out = opkind == 2'b00;
	assign maybe_jmp = opkind == 2'b01;
	assign misc_cs = opkind == 2'b10;
	assign comp_out = opkind == 2'b11;
	
	assign r1_addr    = op[15:12];
	assign r2_addr    = op[31:28];
	assign default_a1 = op[27:12];
	assign default_a2 = op[31:16];
	assign rw_addr    = op[11: 8];
	
	// has_dest = (cat == Category.ArithmeticLogic) or (cat == Category.Comparison) or (i & 0b111101 == 0b100000)
	//  knowing that misc_cs === i & 0b110000 == 0b100000
	//  and that if misc_cs is true, i & 0b001100 = 0
	assign reg_we = (opkind[0] == opkind[1]) || (misc_cs && !optype[0]);
endmodule
