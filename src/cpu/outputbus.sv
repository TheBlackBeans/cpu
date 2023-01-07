`default_nettype none

module OutputBus#(parameter
	 data_size = 16
	) (
	 input  logic                alu_cs,
	 input  logic                comp_cs,
	 input  logic                misc_cs,
	 input  logic                jmp_cs,
	 input  logic[data_size-1:0] alu_out,
	 input  logic[data_size-1:0] comp_out,
	 input  logic[data_size-1:0] misc_out,
	 output logic[data_size-1:0] bus_data
	);
	
	assign bus_data =
		 alu_cs ?  alu_out : (
		comp_cs ? comp_out : (
		misc_cs ? misc_out : (
		 jmp_cs ?        0 : 0)));
endmodule // OutputBus
