`default_nettype none

module ArgumentBus#(parameter
	 data_size = 16
	) (
	 input  logic                use_reg,
	 input  logic[data_size-1:0] reg_data,
	 input  logic[data_size-1:0] default_data,
	 output logic[data_size-1:0] bus_data
	);
	
	assign bus_data = use_reg ? reg_data : default_data;
endmodule // ArgumentBus
