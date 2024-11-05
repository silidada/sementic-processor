

module post_process#(
	parameter DATA_WIDTH_I = 22,
	parameter DATA_WIDTH_O = 8
)(
	input wire 					    clk,
	input wire 					    rst,
	input wire 					    start,
	input wire [2:0]			    layer,
	
	input wire [15:0]				en_in,
	input wire [DATA_WIDTH_I-1:0]	din0_pe00,din0_pe01,din0_pe02,din0_pe03,
	input wire [DATA_WIDTH_I-1:0]	din0_pe10,din0_pe11,din0_pe12,din0_pe13,
	input wire [DATA_WIDTH_I-1:0]   din0_pe20,din0_pe21,din0_pe22,din0_pe23,
	input wire [DATA_WIDTH_I-1:0]   din0_pe30,din0_pe31,din0_pe32,din0_pe33,
	
	input wire [DATA_WIDTH_I-1:0]   din1_pe00,din1_pe01,din1_pe02,din1_pe03,
	input wire [DATA_WIDTH_I-1:0]   din1_pe10,din1_pe11,din1_pe12,din1_pe13,
	input wire [DATA_WIDTH_I-1:0]   din1_pe20,din1_pe21,din1_pe22,din1_pe23,
	input wire [DATA_WIDTH_I-1:0]   din1_pe30,din1_pe31,din1_pe32,din1_pe33,
	
	output wire	[3:0]				en_out,
	output wire [DATA_WIDTH_O-1:0]	dout_bn0_b01, dout_bn1_b01, 
	output wire [DATA_WIDTH_O-1:0]	dout_bn0_b23, dout_bn1_b23, 
	output wire [DATA_WIDTH_O-1:0]	dout_bn0_b45, dout_bn1_b45, 
	output wire [DATA_WIDTH_O-1:0]	dout_bn0_b67, dout_bn1_b67
);
	localparam InputReuseTimes = 3;
	localparam IDLE   = 2'b01,
	           CONFIG = 2'b10;
	reg [1:0] state_c;
	reg [2:0] layer_reg;
	reg		  start_d1;
	
	reg								NEED_DEQUANT;
	reg [3:0]						DEQUANT_SHIFT;  // constant
	
	reg								IS_ACT;
	reg [3:0]						SCALE_SHIFT; // to quant

	reg [7:0]						WIDTH_OUT;
	reg [9:0]						HEIGHT_OUT;
	reg [1:0]						TransferTimes;
	reg [9:0]						BASE_ADDR;

	wire [9:0]						addr_rd_b01,addr_rd_b23,addr_rd_b45,addr_rd_b67;
	wire [31:0]						bias_batch01,bias_batch23,bias_batch45,bias_batch67;
	
	(* keep = "true" *)
	reg [4:0] rst_d1;
	always@(posedge clk)begin
		if(rst)begin
			rst_d1 <= 5'b1_1111;
		end
		else begin
			rst_d1 <= 5'b0_0000;
		end
	end
	
	// ========================= FSM ========================= 
	always@(posedge clk)begin
		if(rst_d1[0])begin
			state_c <= IDLE;
		end
		else begin
			case(state_c)
				IDLE: begin
					if(start)begin
						state_c <= CONFIG;
					end
					else begin
						state_c <= IDLE;
					end
				end
				CONFIG: begin
					state_c <= IDLE;
				end
				default: state_c <= IDLE;
			endcase
		end
	end
	
	// layer_reg
	always@(posedge clk)begin
		if(rst_d1[0])begin
			layer_reg <= 'd0;
		end
		else if(start&&(state_c==IDLE))begin
			layer_reg <= layer;
		end
	end
	
	// IS_ACT
	// NEED_DEQUANT
	always@(posedge clk)begin
		if(rst_d1[0])begin
			IS_ACT 		 <= 1'b0;
			NEED_DEQUANT <= 1'b0;
		end
		else if((state_c==CONFIG)&&(layer_reg==3'd4))begin
			IS_ACT 		 <= 1'b0;
			NEED_DEQUANT <= 1'b1;
		end
		else begin
			IS_ACT 		 <= 1'b1;
			NEED_DEQUANT <= 1'b0;
		end
	end
	// SCALE_SHIFT
	always@(posedge clk)begin
		if(rst_d1[0])begin
			SCALE_SHIFT <= 4'd0;
		end
		else if(state_c==CONFIG)begin
			case(layer_reg)
				3'd1, 3'd2,
				3'd3: SCALE_SHIFT <= 4'd7;
				3'd4: SCALE_SHIFT <= 4'd10;
				default: SCALE_SHIFT <= 4'd0;
			endcase
		end
	end
	// DEQUANT_SHIFT
	always@(posedge clk)begin
		DEQUANT_SHIFT <= 3;
	end
	// WIDTH_OUT
	always@(posedge clk)begin
		if(rst_d1[0])begin
			WIDTH_OUT <= 8'd0;
		end
		else if(state_c==CONFIG)begin
			case(layer_reg)
				3'd1: WIDTH_OUT <= 8'd239;
				3'd2: WIDTH_OUT <= 8'd119;
				3'd3: WIDTH_OUT <= 8'd59;
				3'd4: WIDTH_OUT <= 8'd29;
				default: WIDTH_OUT <= 8'd0;
			endcase
		end
	end
	// HEIGHT_OUT
	always@(posedge clk)begin
		if(rst_d1[0])begin
			HEIGHT_OUT <= 10'd0;
		end
		else begin
			case(layer_reg)
				3'd1: HEIGHT_OUT <= 10'd539;
				3'd2: HEIGHT_OUT <= 10'd269;
				3'd3: HEIGHT_OUT <= 10'd134;
				3'd4: HEIGHT_OUT <= 10'd67;
				default: HEIGHT_OUT <= 10'd0;
			endcase
		end
	end
	// TransferTimes
	always@(posedge clk)begin
		if(rst_d1[0])begin
			TransferTimes <= 'd0;
		end
		else if(state_c==CONFIG)begin
			TransferTimes <= 'd3;  // 4-1
		end
	end
	// BASE_ADDR
	always@(posedge clk)begin
		if(rst_d1[0])begin
			BASE_ADDR <= 10'd0;
		end
		else if(state_c==CONFIG)begin
			case(layer_reg)
				3'd1: BASE_ADDR <= 10'd0;
				3'd2: BASE_ADDR <= 10'd16;
				3'd3: BASE_ADDR <= 10'd32;
				3'd4: BASE_ADDR <= 10'd48;
				default: BASE_ADDR <= 10'd0;
			endcase
		end
	end
	
	// start_d1
	always@(posedge clk)begin
		if(rst_d1[0])begin
			start_d1 <= 1'b0;
		end
		else if(state_c==CONFIG)begin
			start_d1 <= 1'b1;
		end
		else begin
			start_d1 <= 1'b0;
		end
	end
	

	rom_bias_batch01_lut rom_bias_batch01_inst(
		.addr(addr_rd_b01),
		.dout(bias_batch01)
	);
	bn_act_quant#(
		.DATA_WIDTH_I(DATA_WIDTH_I),
		.DATA_WIDTH_O(DATA_WIDTH_O)
	)bn_act_quant_inst_batch01(
		.clk(clk),
		.rst(rst_d1[1]),
		.start(start_d1),
		
		.need_dequant(NEED_DEQUANT),
		.dequant_shift(DEQUANT_SHIFT),
		
		.is_act(IS_ACT),
		.width_out(WIDTH_OUT),
		.height_out(HEIGHT_OUT),
		.transfertimes(TransferTimes),
		.scale_shift(SCALE_SHIFT),
		.base_addr(BASE_ADDR),

		.addr_rd(addr_rd_b01),
		.bias(bias_batch01),
		
		.en_out(en_out[0]),
		.dout0(dout_bn0_b01),.dout1(dout_bn1_b01),
	
		.en_in({en_in[12],en_in[8],en_in[4],en_in[0]}),
		.din0_pe0x(din0_pe00),.din0_pe1x(din0_pe10),.din0_pe2x(din0_pe20),.din0_pe3x(din0_pe30),
		.din1_pe0x(din1_pe00),.din1_pe1x(din1_pe10),.din1_pe2x(din1_pe20),.din1_pe3x(din1_pe30)
	);
	
	rom_bias_batch23_lut rom_bias_batch23_inst(
		.addr(addr_rd_b23),
		.dout(bias_batch23)
	);
	bn_act_quant#(
		.DATA_WIDTH_I(DATA_WIDTH_I),
		.DATA_WIDTH_O(DATA_WIDTH_O)
	)bn_act_quant_inst_batch23(
		.clk(clk),
		.rst(rst_d1[2]),
		.start(start_d1),
		
		.need_dequant(NEED_DEQUANT),
		.dequant_shift(DEQUANT_SHIFT),
		
		.is_act(IS_ACT),
		.width_out(WIDTH_OUT),
		.height_out(HEIGHT_OUT),
		.transfertimes(TransferTimes),
		.scale_shift(SCALE_SHIFT),
		.base_addr(BASE_ADDR),

		.addr_rd(addr_rd_b23),
		.bias(bias_batch23),
		
		.en_out(en_out[1]),
		.dout0(dout_bn0_b23),.dout1(dout_bn1_b23),
	
		.en_in({en_in[13],en_in[9],en_in[5],en_in[1]}),
		.din0_pe0x(din0_pe01),.din0_pe1x(din0_pe11),.din0_pe2x(din0_pe21),.din0_pe3x(din0_pe31),
		.din1_pe0x(din1_pe01),.din1_pe1x(din1_pe11),.din1_pe2x(din1_pe21),.din1_pe3x(din1_pe31)
	);
	
	
	rom_bias_batch45_lut rom_bias_batch45_inst(
		.addr(addr_rd_b45),
		.dout(bias_batch45)
	);
	bn_act_quant#(
		.DATA_WIDTH_I(DATA_WIDTH_I),
		.DATA_WIDTH_O(DATA_WIDTH_O)
	)bn_act_quant_inst_batch45(
		.clk(clk),
		.rst(rst_d1[3]),
		.start(start_d1),
		
		.need_dequant(NEED_DEQUANT),
		.dequant_shift(DEQUANT_SHIFT),
		
		.is_act(IS_ACT),
		.width_out(WIDTH_OUT),
		.height_out(HEIGHT_OUT),
		.transfertimes(TransferTimes),
		.scale_shift(SCALE_SHIFT),
		.base_addr(BASE_ADDR),
		
		.addr_rd(addr_rd_b45),
		.bias(bias_batch45),
		
		.en_out(en_out[2]),
		.dout0(dout_bn0_b45),.dout1(dout_bn1_b45),
	
		.en_in({en_in[14],en_in[10],en_in[6],en_in[2]}),
		.din0_pe0x(din0_pe02),.din0_pe1x(din0_pe12),.din0_pe2x(din0_pe22),.din0_pe3x(din0_pe32),
		.din1_pe0x(din1_pe02),.din1_pe1x(din1_pe12),.din1_pe2x(din1_pe22),.din1_pe3x(din1_pe32)
	);
	
	rom_bias_batch67_lut rom_bias_batch67_inst(
		.addr(addr_rd_b67),
		.dout(bias_batch67)
	);
	bn_act_quant#(
		.DATA_WIDTH_I(DATA_WIDTH_I),
		.DATA_WIDTH_O(DATA_WIDTH_O)
	)bn_act_quant_inst_batch67(
		.clk(clk),
		.rst(rst_d1[4]),
		.start(start_d1),
		
		.need_dequant(NEED_DEQUANT),
		.dequant_shift(DEQUANT_SHIFT),
		
		.is_act(IS_ACT),
		.width_out(WIDTH_OUT),
		.height_out(HEIGHT_OUT),
		.transfertimes(TransferTimes),
		.scale_shift(SCALE_SHIFT),
		.base_addr(BASE_ADDR),

		.addr_rd(addr_rd_b67),
		.bias(bias_batch67),
		
		.en_out(en_out[3]),
		.dout0(dout_bn0_b67),.dout1(dout_bn1_b67),
	
		.en_in({en_in[15],en_in[11],en_in[7],en_in[3]}),
		.din0_pe0x(din0_pe03),.din0_pe1x(din0_pe13),.din0_pe2x(din0_pe23),.din0_pe3x(din0_pe33),
		.din1_pe0x(din1_pe03),.din1_pe1x(din1_pe13),.din1_pe2x(din1_pe23),.din1_pe3x(din1_pe33)
	);
	
endmodule