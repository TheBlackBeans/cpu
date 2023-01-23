`timescale   1ns / 1ps

module cpu(
    input clk,
    input reset,
    input select_hhmmss_button,
    input select_yymmdd_button,
    input select_yyyymm_button,
    input turbo,
    output [6:0] display0,
    output [5:0] display1,
    output [6:0] display2,
    output [6:0] display3,
    output [6:0] display4,
    output [6:0] display5
    );
    
	wire rstn;
	logic [31:0] rom[2**8];
	
	logic [15:0] ip;
	
	assign rstn = ~reset;
	
	logic [32:0] clock_counter;
	
	wire write_out;
	wire [3:0] out_port;
	wire [15:0] out_data;
	
	// wire divided_clock = clock_counter == 0;
	
	Driver#(.rom_size(2**8)) driver(.rom, .clk, .rstn, .ip, .write_out, .out_port, .out_data);
	
    logic [7:0] seconds;
    logic [7:0] minutes;
    logic [7:0] hours;
    logic [7:0] days;
    logic [7:0] months;
    logic [15:0] years;
   
    wire [3:0] years_thousands = years / 1000;
    wire [3:0] years_hundreds  = (years / 'd100) % 'd10;
    wire [3:0] years_tens      = (years /  'd10) % 'd10;
    wire [3:0] years_ones      = years   % 'd10;
    wire [3:0] months_tens     = months  / 'd10;
    wire [3:0] months_ones     = months  % 'd10;
    wire [3:0] days_tens       = days    / 'd10;
    wire [3:0] days_ones       = days    % 'd10;
    wire [3:0] hours_tens      = hours   / 'd10;
    wire [3:0] hours_ones      = hours   % 'd10;
    wire [3:0] minutes_tens    = minutes / 'd10;
    wire [3:0] minutes_ones    = minutes % 'd10;
    wire [3:0] seconds_tens    = seconds / 'd10;
    wire [3:0] seconds_ones    = seconds % 'd10;
    
    logic select_yyyymm;
    logic select_yymmdd;
    logic select_hhmmss;
    
    logic [3:0] digit0, digit1, digit2, digit3, digit4, digit5;
    
    // assign display0 = to_7_segment(ip % 10);
    // assign display1 = to_reduced_7_segment (ip / 10);
    assign display0 = to_7_segment(digit0);
    assign display1 = to_reduced_7_segment (digit1);
    assign display2 = to_7_segment(digit2);
    assign display3 = to_7_segment(digit3);
    assign display4 = to_7_segment(digit4);
    assign display5 = to_7_segment(digit5);
    
    assign rom[22] = turbo ? 'h0001e010 : 'h00051141;
    
    always @(posedge clk) begin
        clock_counter = clock_counter == 'd99999 ? 0 : clock_counter + 1;
    
        if (write_out) begin
            case (out_port)
            0: begin
                seconds = out_data;
            end
            1: begin
                minutes = out_data;
            end
            2: begin
                hours = out_data;
            end
            3: begin
                days = out_data;
            end
            4: begin
                months = out_data;
            end
            5: begin
                years = out_data;
            end
            endcase
        end
        
        if (select_yyyymm_button) begin
            select_yyyymm = 1;
            select_yymmdd = 0;
            select_hhmmss = 0;
        end
        if (select_yymmdd_button) begin
            select_yyyymm = 0;
            select_yymmdd = 1;
            select_hhmmss = 0;
        end
        if (select_hhmmss_button) begin
            select_yyyymm = 0;
            select_yymmdd = 0;
            select_hhmmss = 1;
        end
        
        if (select_yyyymm) begin
            digit5 = years_thousands;
            digit4 = years_hundreds;
            digit3 = years_tens;
            digit2 = years_ones;
            digit1 = months_tens;
            digit0 = months_ones;
        end
        if (select_yymmdd) begin
            digit5 = years_tens;
            digit4 = years_ones;
            digit3 = months_tens;
            digit2 = months_ones;
            digit1 = days_tens;
            digit0 = days_ones;
        end
        if (select_hhmmss) begin
            digit5 = hours_tens;
            digit4 = hours_ones;
            digit3 = minutes_tens;
            digit2 = minutes_ones;
            digit1 = seconds_tens;
            digit0 = seconds_ones;
        end
    end
    
    function logic [6:0] to_7_segment(input logic [3:0] digit);
        return digit == 0 ? 'b1000000 :
               digit == 1 ? 'b1111001 :
               digit == 2 ? 'b0100100 :
               digit == 3 ? 'b0110000 :
               digit == 4 ? 'b0011001 :
               digit == 5 ? 'b0010010 :
               digit == 6 ? 'b0000010 :
               digit == 7 ? 'b1111000 :
               digit == 8 ? 'b0000000 :
               digit == 9 ? 'b0010000 :
                            'b0000110 ;
    endfunction
    
    function logic [5:0] to_reduced_7_segment(input logic [3:0] digit);
        return digit == 0 ? 'b100000 :
               digit == 1 ? 'b111100 :
               digit == 2 ? 'b010010 :
               digit == 3 ? 'b011000 :
               digit == 4 ? 'b001100 :
               digit == 5 ? 'b001001 :
               digit == 6 ? 'b000001 :
               digit == 7 ? 'b111100 :
               digit == 8 ? 'b000000 :
               digit == 9 ? 'b001000 :
                            'b000011 ;
    endfunction
    
    initial begin
        rom[0] = 'h001f0241;
        rom[1] = 'h000d0341;
        rom[2] = 'h00150441;
        rom[3] = 'h00170541;
        rom[4] = 'h00010641;
        rom[5] = 'h07e70741;
        rom[6] = 'h001c0b41;
        rom[7] = 'h00040c41;
        rom[8] = 'h00140d41;
        rom[9] = 'h00010e41;
        rom[10] = 'h001f0f41;
        rom[11] = 'h00000141;
        rom[12] = 'h00000941;
        rom[13] = 'h200000a3;
        rom[14] = 'h300010a3;
        rom[15] = 'h400020a3;
        rom[16] = 'h500030a3;
        rom[17] = 'h600040a3;
        rom[18] = 'h700050a3;
        rom[19] = 'h00016010;
        rom[20] = 'h00021141;
        rom[21] = 'h001c0b41;
        // rom[22] = 'h00051141;
        rom[23] = 'h00051873;
        rom[24] = 'h800099c1;
        rom[25] = 'h00b7987b;
        rom[26] = 'h80016091;
        rom[27] = 'h00031141;
        rom[28] = 'h1b00187b; // <- here
        rom[29] = 'h8001b091;
        rom[30] = 'h1afa1143; // we have now passed 12_000_000 cycles
        rom[31] = 'h00b79943;
        rom[32] = 'h00012241;
        rom[33] = 'h200000a3;
        rom[34] = 'h003c287b;
        rom[35] = 'h80016091;
        rom[36] = 'h00071141;
        rom[37] = 'h003c2243;
        rom[38] = 'h200000a3;
        rom[39] = 'h00013341;
        rom[40] = 'h300010a3;
        rom[41] = 'h003c387b;
        rom[42] = 'h80016091;
        rom[43] = 'h00071141;
        rom[44] = 'h003c3343;
        rom[45] = 'h300010a3;
        rom[46] = 'h00014441;
        rom[47] = 'h400020a3;
        rom[48] = 'h0018487b;
        rom[49] = 'h80016091;
        rom[50] = 'h00071141;
        rom[51] = 'h00184443;
        rom[52] = 'h400020a3;
        rom[53] = 'h00015541;
        rom[54] = 'h500030a3;
        rom[55] = 'h5000f8f3;
        rom[56] = 'h80016091;
        rom[57] = 'h00071141;
        rom[58] = 'hf00055c3;
        rom[59] = 'h500030a3;
        rom[60] = 'h00016641;
        rom[61] = 'h600040a3;
        rom[62] = 'h00026871;
        rom[63] = 'h80049095;
        rom[64] = 'h00031141;
        rom[65] = 'h6000c8b3;
        rom[66] = 'h8004c095;
        rom[67] = 'h00061141;
        rom[68] = 'h600088b3;
        rom[69] = 'h800068c3;
        rom[70] = 'h0001884b;
        rom[71] = 'h8001ef81;
        rom[72] = 'h00016010;
        rom[73] = 'h00031141;
        rom[74] = 'hb0000fc1;
        rom[75] = 'h00016010;
        rom[76] = 'h00081141;
        rom[77] = 'h000c6643;
        rom[78] = 'h600040a3;
        rom[79] = 'h00017741;
        rom[80] = 'h700050a3;
        rom[81] = 'h001f0f41;
        rom[82] = 'h0001ee43;
        rom[83] = 'he0014095;
        rom[84] = 'h00041141;
        rom[85] = 'h00040e41;
        rom[86] = 'h0001dd43;
        rom[87] = 'hd005e095;
        rom[88] = 'h00041141;
        rom[89] = 'h00190d41;
        rom[90] = 'h0001cc43;
        rom[91] = 'hc0014095;
        rom[92] = 'h00021141;
        rom[93] = 'h00040c41;
        rom[94] = 'h00031141;
        rom[95] = 'h001d0b41;
        rom[96] = 'h00016010;

    end
endmodule
