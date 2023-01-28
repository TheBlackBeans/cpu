`timescale   1ns / 1ps

module cpu(
	 input  logic      clk,
	 input  logic      reset,
	 input  logic      select_hhmmss,
	 input  logic      select_yymmdd,
	 input  logic      select_yyyymm,
	 input  logic[2:0] buttons,
	 output logic[6:0] display0,
	 output logic[5:0] display1,
	 output logic[6:0] display2,
	 output logic[6:0] display3,
	 output logic[6:0] display4,
	 output logic[6:0] display5
	);
	
	wire rstn;
	logic [31:0] rom[1<<9];
	
	logic [15:0] ip;
	
	assign rstn = ~reset;
	
	wire write_out;
	wire [3:0] out_port;
	wire [15:0] out_data;
	
	Driver#(.rom_size(1<<9)) driver(.rom, .clk, .rstn, .ip, .write_out, .out_port, .out_data, .in_data(buttons));
	
	logic [7:0] seconds;
	logic [7:0] minutes;
	logic [7:0] hours;
	logic [7:0] days;
	logic [7:0] months;
	logic [15:0] years;
   
	wire [3:0] years_thousands = years / 'd1000;
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
	
	logic [3:0] digit0, digit1, digit2, digit3, digit4, digit5;
	
	assign display0 = to_7_segment(digit0);
	assign display1 = to_reduced_7_segment (digit1);
	assign display2 = to_7_segment(digit2);
	assign display3 = to_7_segment(digit3);
	assign display4 = to_7_segment(digit4);
	assign display5 = to_7_segment(digit5);
	
	assign digit5 = select_yyyymm ? years_thousands : select_yymmdd ? years_tens  : select_hhmmss ? hours_tens   : 'd10;
	assign digit4 = select_yyyymm ? years_hundreds  : select_yymmdd ? years_ones  : select_hhmmss ? hours_ones   : 'd10;
	assign digit3 = select_yyyymm ? years_tens      : select_yymmdd ? months_tens : select_hhmmss ? minutes_tens : 'd10;
	assign digit2 = select_yyyymm ? years_ones      : select_yymmdd ? months_ones : select_hhmmss ? minutes_ones : 'd10;
	assign digit1 = select_yyyymm ? months_tens     : select_yymmdd ? days_tens   : select_hhmmss ? seconds_tens : 'd10;
	assign digit0 = select_yyyymm ? months_ones     : select_yymmdd ? days_ones   : select_hhmmss ? seconds_ones : 'd10;
	always @(negedge clk) begin
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
		return to_7_segment(digit)[6:1];
	endfunction
	
	initial begin
		rom[0] = 'h0000e010;
		rom[1] = 'h0004e87b;
		rom[2] = 'h00048b45;
		rom[3] = 'hb000eec3;
		rom[4] = 'hd000ddc1;
		rom[5] = 'h8000ddc1;
		rom[6] = 'h0019d87b;
		rom[7] = 'h00198b45;
		rom[8] = 'hb000ddc3;
		rom[9] = 'hc000ccc1;
		rom[10] = 'h8000ccc1;
		rom[11] = 'h0004c87b;
		rom[12] = 'h00048b45;
		rom[13] = 'hb000ccc3;
		rom[14] = 'h700050a3;
		rom[15] = 'h00000822;
		rom[16] = 'h8001c095;
		rom[17] = 'h00001822;
		rom[18] = 'h8000f091;
		rom[19] = 'h00000822;
		rom[20] = 'h80023095;
		rom[21] = 'h00001822;
		rom[22] = 'h80013095;
		rom[23] = 'h700077c1;
		rom[24] = 'h00017741;
		rom[25] = 'he000eec1;
		rom[26] = 'h0001ee41;
		rom[27] = 'h00001010;
		rom[28] = 'h00001822;
		rom[29] = 'h80023095;
		rom[30] = 'h00000822;
		rom[31] = 'h8001c095;
		rom[32] = 'h700077c1;
		rom[33] = 'he000eec1;
		rom[34] = 'h00001010;
		rom[35] = 'h00001822;
		rom[36] = 'h80023095;
		rom[37] = 'h00000822;
		rom[38] = 'h80023095;
		rom[39] = 'hc0004c83;
		rom[40] = 'hd0019d83;
		rom[41] = 'he0004e83;
		rom[42] = 'h0004c871;
		rom[43] = 'h0019db79;
		rom[44] = 'h8000bbcd;
		rom[45] = 'h0004e871;
		rom[46] = 'hb00088cb;
		rom[47] = 'h8001cb81;
		rom[48] = 'h00010641;
		rom[49] = 'h6000c8b3;
		rom[50] = 'h80034091;
		rom[51] = 'h00010641;
		rom[52] = 'h600040a3;
		rom[53] = 'h00000822;
		rom[54] = 'h80040095;
		rom[55] = 'h00001822;
		rom[56] = 'h80035091;
		rom[57] = 'h00000822;
		rom[58] = 'h80046095;
		rom[59] = 'h00001822;
		rom[60] = 'h80039095;
		rom[61] = 'h600066c1;
		rom[62] = 'h00016641;
		rom[63] = 'h00031010;
		rom[64] = 'h00001822;
		rom[65] = 'h80046095;
		rom[66] = 'h00000822;
		rom[67] = 'h80040095;
		rom[68] = 'h600066c1;
		rom[69] = 'h00031010;
		rom[70] = 'h00001822;
		rom[71] = 'h80046095;
		rom[72] = 'h00000822;
		rom[73] = 'h80046095;
		rom[74] = 'h00026871;
		rom[75] = 'h8004e091;
		rom[76] = 'hb0000fc1;
		rom[77] = 'h00052010;
		rom[78] = 'h0008687b;
		rom[79] = 'h800068c3;
		rom[80] = 'h0001884b;
		rom[81] = 'h8001ef81;
		rom[82] = 'h00010541;
		rom[83] = 'h5000f8f3;
		rom[84] = 'h80056091;
		rom[85] = 'h00010541;
		rom[86] = 'h500030a3;
		rom[87] = 'h00000822;
		rom[88] = 'h80062095;
		rom[89] = 'h00001822;
		rom[90] = 'h80057091;
		rom[91] = 'h00000822;
		rom[92] = 'h80068095;
		rom[93] = 'h00001822;
		rom[94] = 'h8005b095;
		rom[95] = 'h500055c1;
		rom[96] = 'h00015541;
		rom[97] = 'h00053010;
		rom[98] = 'h00001822;
		rom[99] = 'h80068095;
		rom[100] = 'h00000822;
		rom[101] = 'h80062095;
		rom[102] = 'h500055c1;
		rom[103] = 'h00053010;
		rom[104] = 'h00001822;
		rom[105] = 'h80068095;
		rom[106] = 'h00000822;
		rom[107] = 'h80068095;
		rom[108] = 'h0018487b;
		rom[109] = 'h8006f091;
		rom[110] = 'h00000441;
		rom[111] = 'h400020a3;
		rom[112] = 'h00000822;
		rom[113] = 'h8007b095;
		rom[114] = 'h00001822;
		rom[115] = 'h80070091;
		rom[116] = 'h00000822;
		rom[117] = 'h80081095;
		rom[118] = 'h00001822;
		rom[119] = 'h80074095;
		rom[120] = 'h400044c1;
		rom[121] = 'h00014441;
		rom[122] = 'h0006c010;
		rom[123] = 'h00001822;
		rom[124] = 'h80081095;
		rom[125] = 'h00000822;
		rom[126] = 'h8007b095;
		rom[127] = 'h400044c1;
		rom[128] = 'h0006c010;
		rom[129] = 'h00001822;
		rom[130] = 'h80081095;
		rom[131] = 'h00000822;
		rom[132] = 'h80081095;
		rom[133] = 'h003c387b;
		rom[134] = 'h80088091;
		rom[135] = 'h00000341;
		rom[136] = 'h300010a3;
		rom[137] = 'h00000822;
		rom[138] = 'h80094095;
		rom[139] = 'h00001822;
		rom[140] = 'h80089091;
		rom[141] = 'h00000822;
		rom[142] = 'h8009a095;
		rom[143] = 'h00001822;
		rom[144] = 'h8008d095;
		rom[145] = 'h300033c1;
		rom[146] = 'h00013341;
		rom[147] = 'h00085010;
		rom[148] = 'h00001822;
		rom[149] = 'h8009a095;
		rom[150] = 'h00000822;
		rom[151] = 'h80094095;
		rom[152] = 'h300033c1;
		rom[153] = 'h00085010;
		rom[154] = 'h00001822;
		rom[155] = 'h8009a095;
		rom[156] = 'h00000822;
		rom[157] = 'h8009a095;
		rom[158] = 'h003c287b;
		rom[159] = 'h800a1091;
		rom[160] = 'h00000241;
		rom[161] = 'h200000a3;
		rom[162] = 'h00000822;
		rom[163] = 'h800ad095;
		rom[164] = 'h00001822;
		rom[165] = 'h800a2091;
		rom[166] = 'h00000822;
		rom[167] = 'h800b3095;
		rom[168] = 'h00001822;
		rom[169] = 'h800a6095;
		rom[170] = 'h200022c1;
		rom[171] = 'h00012241;
		rom[172] = 'h0009e010;
		rom[173] = 'h00001822;
		rom[174] = 'h800b3095;
		rom[175] = 'h00000822;
		rom[176] = 'h800ad095;
		rom[177] = 'h200022c1;
		rom[178] = 'h0009e010;
		rom[179] = 'h00000141;
		rom[180] = 'h00000941;
		rom[181] = 'h000b8010;
		rom[182] = 'h00021141;
		rom[183] = 'h001c0b41;
		rom[184] = 'h00002822;
		rom[185] = 'h80108095;
		rom[186] = 'h00071141;
		rom[187] = 'h00071873;
		rom[188] = 'h800099c1;
		rom[189] = 'h00b7987b;
		rom[190] = 'h800b8091;
		rom[191] = 'h00002822;
		rom[192] = 'h80108095;
		rom[193] = 'h00051141;
		rom[194] = 'h1b00187b;
		rom[195] = 'h800bf091;
		rom[196] = 'h1afa1143;
		rom[197] = 'h00b79943;
		rom[198] = 'h00012241;
		rom[199] = 'h200000a3;
		rom[200] = 'h003c287b;
		rom[201] = 'h800b8091;
		rom[202] = 'h00071141;
		rom[203] = 'h003c2243;
		rom[204] = 'h200000a3;
		rom[205] = 'h00013341;
		rom[206] = 'h300010a3;
		rom[207] = 'h003c387b;
		rom[208] = 'h800b8091;
		rom[209] = 'h00071141;
		rom[210] = 'h003c3343;
		rom[211] = 'h300010a3;
		rom[212] = 'h00014441;
		rom[213] = 'h400020a3;
		rom[214] = 'h0018487b;
		rom[215] = 'h800b8091;
		rom[216] = 'h00071141;
		rom[217] = 'h00184443;
		rom[218] = 'h400020a3;
		rom[219] = 'h00015541;
		rom[220] = 'h500030a3;
		rom[221] = 'h5000f8f3;
		rom[222] = 'h800b8091;
		rom[223] = 'h00071141;
		rom[224] = 'hf00055c3;
		rom[225] = 'h500030a3;
		rom[226] = 'h00016641;
		rom[227] = 'h600040a3;
		rom[228] = 'h00026871;
		rom[229] = 'h800ef095;
		rom[230] = 'h00031141;
		rom[231] = 'h6000c8b3;
		rom[232] = 'h800f2095;
		rom[233] = 'h00061141;
		rom[234] = 'h600088b3;
		rom[235] = 'h800068c3;
		rom[236] = 'h0001884b;
		rom[237] = 'h8001ef81;
		rom[238] = 'h000b8010;
		rom[239] = 'h00031141;
		rom[240] = 'hb0000fc1;
		rom[241] = 'h000b8010;
		rom[242] = 'h00081141;
		rom[243] = 'h000c6643;
		rom[244] = 'h600040a3;
		rom[245] = 'h00017741;
		rom[246] = 'h700050a3;
		rom[247] = 'h001f0f41;
		rom[248] = 'h0001ee43;
		rom[249] = 'he00b6095;
		rom[250] = 'h00041141;
		rom[251] = 'h00040e41;
		rom[252] = 'h0001dd43;
		rom[253] = 'hd013d095;
		rom[254] = 'h00041141;
		rom[255] = 'h00190d41;
		rom[256] = 'h0001cc43;
		rom[257] = 'hc00b6095;
		rom[258] = 'h00021141;
		rom[259] = 'h00040c41;
		rom[260] = 'h00031141;
		rom[261] = 'h001d0b41;
		rom[262] = 'h000b8010;
		rom[263] = 'h001c0b41;
		rom[264] = 'h00002822;
		rom[265] = 'h800b8091;
		rom[266] = 'h00012241;
		rom[267] = 'h200000a3;
		rom[268] = 'h003c287b;
		rom[269] = 'h80108091;
		rom[270] = 'h003c2243;
		rom[271] = 'h200000a3;
		rom[272] = 'h00013341;
		rom[273] = 'h300010a3;
		rom[274] = 'h003c387b;
		rom[275] = 'h80108091;
		rom[276] = 'h003c3343;
		rom[277] = 'h300010a3;
		rom[278] = 'h00014441;
		rom[279] = 'h400020a3;
		rom[280] = 'h0018487b;
		rom[281] = 'h80108091;
		rom[282] = 'h00184443;
		rom[283] = 'h400020a3;
		rom[284] = 'h00015541;
		rom[285] = 'h500030a3;
		rom[286] = 'h5000f8f3;
		rom[287] = 'h80108091;
		rom[288] = 'hf00055c3;
		rom[289] = 'h500030a3;
		rom[290] = 'h00016641;
		rom[291] = 'h600040a3;
		rom[292] = 'h00026871;
		rom[293] = 'h8012d095;
		rom[294] = 'h6000c8b3;
		rom[295] = 'h8012f095;
		rom[296] = 'h600088b3;
		rom[297] = 'h800068c3;
		rom[298] = 'h0001884b;
		rom[299] = 'h8001ef81;
		rom[300] = 'h00108010;
		rom[301] = 'hb0000fc1;
		rom[302] = 'h00108010;
		rom[303] = 'h000c6643;
		rom[304] = 'h600040a3;
		rom[305] = 'h00017741;
		rom[306] = 'h700050a3;
		rom[307] = 'h001f0f41;
		rom[308] = 'h0001ee43;
		rom[309] = 'he00b6095;
		rom[310] = 'h00040e41;
		rom[311] = 'h0001dd43;
		rom[312] = 'hd013d095;
		rom[313] = 'h00190d41;
		rom[314] = 'h0001cc43;
		rom[315] = 'hc00b6095;
		rom[316] = 'h00040c41;
		rom[317] = 'h001d0b41;
		rom[318] = 'h00108010;
	end
endmodule
