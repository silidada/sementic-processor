`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: GDUT
// Engineer: JFeng Lee
// 
// Create Date: 2023-9-4
// Design Name:
// Module Name: 
// Project Name: 
// Taget Devices: zcu104
// Tool Versions: 2018.2
// Description:
// 
// Dependencies:
// 
// Revision: 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module weight_read#(
	parameter DATA_WIDTH_I 	= 256,
	parameter DATA_WIDTH_O 	= 200
)(
	input wire 						clk,
	input wire 						rst,
	input wire 						start,
	input wire [2:0]				layer,
	output reg						read_done,
	input wire [3:0]				read_continue,
	input wire [3:0]				read_pause,
	
	output reg [7:0]				en_rd,
	output reg [11:0]				addr_rd,
	input wire [DATA_WIDTH_I-1:0]   din_b0,
	input wire [DATA_WIDTH_I-1:0]   din_b1,
	input wire [DATA_WIDTH_I-1:0]   din_b2,
	input wire [DATA_WIDTH_I-1:0]   din_b3,
	input wire [DATA_WIDTH_I-1:0]   din_b4,
	input wire [DATA_WIDTH_I-1:0]   din_b5,
	input wire [DATA_WIDTH_I-1:0]   din_b6,
	input wire [DATA_WIDTH_I-1:0]   din_b7,
	
	output wire	[7:0]				en_out,
	output wire [DATA_WIDTH_O-1:0]  dout_b0,
	output wire [DATA_WIDTH_O-1:0]  dout_b1,
	output wire [DATA_WIDTH_O-1:0]  dout_b2,
	output wire [DATA_WIDTH_O-1:0]  dout_b3,
	output wire [DATA_WIDTH_O-1:0]  dout_b4,
	output wire [DATA_WIDTH_O-1:0]  dout_b5,
	output wire [DATA_WIDTH_O-1:0]  dout_b6,
	output wire [DATA_WIDTH_O-1:0]  dout_b7
);
	localparam InputReuseTimes = 3;	// 4-1, 8batch*4
	localparam BramHalfAddress = 512; // half of read address
	localparam IDLE   = 4'b0001,
	           CONFIG = 4'b0010,
			   WORK   = 4'b0100,
			   WAIT	  = 4'b1000;
	reg [3:0]  state_n, state_c;
	reg work2wait, wait2work;
	wire work2idle;
	
	reg 					start_d1;   // just use in wait2work
	reg [2:0]				layer_reg;
	reg	[3:0]				read_continue_reg;
	reg 					read_pause_reg;
	
	reg [7:0]				WIDTH_OUT;   // output width
	reg [9:0]				HEIGHT_OUT;
	reg [5:0]				BLOCK_DEEP_MAX;
	reg [4:0]				LOOP_DEEP_MAX;
	
	reg [7:0]				cnt_width_out;
	reg [9:0]				cnt_height_out;
	reg [5:0]				cnt_block_deep;
	reg [4:0]				cnt_loop_deep;
	reg [1:0]   			cnt_trans_times;
	wire					add_cnt_width_out, end_cnt_width_out;
	wire					add_cnt_height_out, end_cnt_height_out;
	wire					add_cnt_block_deep, end_cnt_block_deep;
	wire					add_cnt_loop_deep, end_cnt_loop_deep;
	wire        			add_cnt_trans_times, end_cnt_trans_times;
	reg [1:0]				end_cnt_width_out_d2;
	
	reg 					pingpong;
	reg [1:0]				TransferTimes;
	reg 					en_in;
	
	reg [1:0]				cnt_reuse; // input reuse times
	reg [1:0]				cnt_stage;

	
	(* keep = "true" *)
	reg [2:0] rst_d1;
	//rst_d1
	always@(posedge clk)begin
		if(rst)begin
			rst_d1 <= 3'b111;
		end
		else begin
			rst_d1 <= 3'b000;
		end
	end
	
	// read_done
	always@(posedge clk)begin
		if(rst_d1[0])begin
			read_done <= 1'b0;
		end
		else if(end_cnt_loop_deep)begin
			read_done <= 1'b1;
		end
		else begin
			read_done <= 1'b0;
		end
	end
	
	// start_d1
	always@(posedge clk)begin
		if(rst_d1[0])begin
			start_d1 <= 'd0;
		end
		else begin
			start_d1 <= start;
		end
	end
	
	// read_continue_reg
	always@(posedge clk)begin
		if(rst_d1[0])begin
			read_continue_reg[0] <= 1'b0;
		end
		else if(state_c==WORK)begin
			read_continue_reg[0] <= 1'b0;
		end
		else if(read_continue==4'b1111)begin
			read_continue_reg[0] <= 1'b1;
		end
	end
	always@(posedge clk)begin
		read_continue_reg[1] <= read_continue_reg[0];
	end
	always@(posedge clk)begin
		read_continue_reg[2] <= read_continue_reg[1];
	end
	always@(posedge clk)begin
		read_continue_reg[3] <= read_continue_reg[2];
	end
	
	// read_pause_reg
	always@(posedge clk)begin
		if(rst_d1[0])begin
			read_pause_reg <= 1'b0;
		end
		else if(read_continue_reg[3])begin
			read_pause_reg <= 1'b0;
		end
		else if(read_pause == 4'b1111)begin
			read_pause_reg <= 1'b1;
		end
	end
	
	//================== FSM ================== 
	always@(posedge clk)begin
		if(rst_d1[0])begin
			state_c <= IDLE;
		end
		else begin
			state_c <= state_n;
		end
	end
	always@(*)begin
		case(state_c)
			IDLE: begin
				if(start)begin
					state_n = CONFIG;
				end
				else begin
					state_n = IDLE;
				end
			end
			CONFIG: begin
				state_n = WORK;
			end
			WORK: begin
				if(work2idle)begin
					state_n = IDLE;
				end
				else if(work2wait)begin
					state_n = WAIT;
				end
				else begin
					state_n = WORK;
				end
			end
			WAIT: begin
				if(wait2work)begin
					state_n = WORK;
				end
				else begin
					state_n = WAIT;
				end
			end
			default: state_n = IDLE;
		endcase
	end
	// work2wait
	always@(*)begin
		if(state_c==WORK)begin
			if(add_cnt_trans_times)begin
				work2wait = 1'b1;
			end
			//else if(add_cnt_height_out&&read_pause_reg)begin
			else if(end_cnt_width_out&&read_pause_reg)begin
				work2wait = 1'b1;
			end
			else begin
				work2wait = 1'b0;
			end
		end
		else begin
			work2wait = 1'b0;
		end
	end
	// wait2work
	always@(*)begin
		if(state_c==WAIT)begin
			if(start_d1||read_continue_reg[3])begin
				wait2work = 1'b1;
			end
			else begin
				wait2work = 1'b0;
			end
		end
		else begin
			wait2work = 1'b0;
		end
	end
	assign work2idle = (state_c==WORK)&&end_cnt_trans_times;
	
	// layer_reg
	always@(posedge clk)begin
		if(rst_d1)begin
			layer_reg <= 3'd0;
		end
		else if(start&&(state_c==IDLE))begin
			layer_reg <= layer;
		end
	end
	
	//================== config hyperparam ================== 
	// TransferTimes
	always@(posedge clk)begin
		if(rst_d1[0])begin
			TransferTimes <= 'd0;
		end
		else if(state_c==CONFIG)begin
			TransferTimes <= 2'd3; // 4-1
		end
	end
	// WIDTH_OUT
	always@(posedge clk)begin
		if(rst_d1[0])begin
			WIDTH_OUT <= 8'd0;
		end
		else if(state_c==CONFIG)begin
			case(layer_reg)
				3'd1: WIDTH_OUT <= 8'd239; // 960/4-1
				3'd2: WIDTH_OUT <= 8'd119; // 480/4-1
				3'd3: WIDTH_OUT <= 8'd59;  // 240/4-1
				3'd4: WIDTH_OUT <= 8'd29;  // 120/4-1
				default: WIDTH_OUT <= 8'd0;
			endcase
		end
	end
	// HEIGHT_OUT
	always@(posedge clk)begin
		if(rst_d1[0])begin
			HEIGHT_OUT <= 10'd0;
		end
		else if(state_c==IDLE)begin
			HEIGHT_OUT <= 10'd0;
		end
		else begin
			case(layer_reg)
				3'd1: begin
					HEIGHT_OUT <= 10'd539; // 540-1
				end
				3'd2: begin
					HEIGHT_OUT <= 10'd14;   // 15-1;
				end
				3'd3: begin
					if(cnt_loop_deep==LOOP_DEEP_MAX)begin
						HEIGHT_OUT <= 10'd32;	// 33-1
					end
					else begin
						HEIGHT_OUT <= 10'd33;	// 34-1
					end
				end
				3'd4: begin
					HEIGHT_OUT <= 10'd67;  // 68-1
				end
				default: HEIGHT_OUT <= 10'd0;
			endcase
		end
	end
	// BLOCK_DEEP_MAX
	always@(posedge clk)begin
		if(rst_d1[0])begin
			BLOCK_DEEP_MAX <= 6'd0;
		end
		else if(state_c==CONFIG)begin
			if(layer_reg == 3'd1)begin
				BLOCK_DEEP_MAX <= 6'd0; // 1-1
			end
			else begin
				BLOCK_DEEP_MAX <= 6'd31; // 32-1
			end
		end	
	end
	// LOOP_DEEP_MAX
	always@(posedge clk)begin
		if(rst_d1[0])begin
			LOOP_DEEP_MAX <= 5'd0;
		end
		else if(state_c==CONFIG)begin
			case(layer_reg)
				3'd1, 3'd4: LOOP_DEEP_MAX <= 5'd0;  // 1-1
				3'd2: LOOP_DEEP_MAX <= 5'd17; // 18-1
				3'd3: LOOP_DEEP_MAX <= 5'd3;  // 4-1	
				default: LOOP_DEEP_MAX <= 5'd0;
			endcase
		end
	end

	// pingpong
	always@(posedge clk)begin
		if(rst_d1[0])begin
			pingpong <= 1'b0;
		end
		else if(state_c==IDLE)begin
			pingpong <= 1'b0;
		end
		else if(end_cnt_loop_deep)begin
			pingpong <= ~pingpong;
		end
	end
	
	// cnt_reuse
	always@(posedge clk)begin
		if(rst_d1[0])begin
			cnt_reuse <= 2'd0;
		end
		else if(state_c==IDLE)begin
			cnt_reuse <= 2'd0;
		end
		else if(end_cnt_width_out)begin
			cnt_reuse <= cnt_reuse + 1'b1;
		end
	end
	
	// cnt_stage
	always@(posedge clk)begin
		if(rst_d1[0])begin
			cnt_stage <= 2'd0;
		end
		else if(state_c==IDLE)begin
			cnt_stage <= 2'd0;
		end
		else if(en_rd)begin
			cnt_stage <= cnt_stage + 1'b1;
		end
	end
	
	// en_rd
	always@(posedge clk)begin
		if(rst_d1[0])begin
			en_rd <= 8'd0;
		end
		else if(state_c==WORK)begin
			//if((~ifmslice_wr_done)||end_cnt_width_out||(end_cnt_width_out_d2 != 2'b00))begin
			if(end_cnt_width_out||(end_cnt_width_out_d2 != 2'b00))begin
				en_rd <= 8'd0;
			end
			else begin
				en_rd <= 8'b1111_1111;
			end
		end
		else begin
			en_rd <= 8'd0;
		end
	end
	
	// debug
	/*
	reg [23:0] cnt_debug;
	always@(posedge clk)begin
		if(rst_d1[0])begin
			cnt_debug <= 'd0;
		end
		else if(en_rd)begin
			cnt_debug <= cnt_debug + 1'b1;
		end
	end
	*/
	
	// addr_rd
	always@(posedge clk)begin
		if(rst_d1[0])begin
			addr_rd <= 12'd0;
		end
		else if(state_c==IDLE)begin
			addr_rd <= 12'd0;
		end
		else if((state_c==WAIT)&&(~read_pause_reg))begin
			case(pingpong)
				1'b0: addr_rd <= 12'd0;
				1'b1: addr_rd <= BramHalfAddress;
				default: addr_rd <= 12'd0;
			endcase
		end
		else if(add_cnt_block_deep)begin  // one block end
			if(end_cnt_block_deep)begin   // one loop end  -----something wrong here!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				case(pingpong)
					1'b0: addr_rd <= 12'd0;
					1'b1: addr_rd <= BramHalfAddress;
					default: addr_rd <= 12'd0;
				endcase
			end
			else begin
				addr_rd <= addr_rd + 1'b1;
			end
		end
		else if(end_cnt_width_out)begin  // one row end
			if(cnt_reuse==InputReuseTimes)begin
				addr_rd <= addr_rd - 15;
			end
			else begin
				addr_rd <= addr_rd + 1'b1;
			end
		end
		else if((state_c==WORK)&&en_rd)begin
			if(cnt_stage==2'd3)begin
				addr_rd <= addr_rd - 3;
			end
			else begin
				addr_rd <= addr_rd + 1'b1;
			end
		end
	end
	
	
	// cnt_width_out
	always@(posedge clk)begin
		if(rst_d1[0])begin
			cnt_width_out <= 'd0;
		end
		else begin
			if(end_cnt_width_out)begin
				cnt_width_out <= 'd0;
			end
			else if(add_cnt_width_out)begin
				cnt_width_out <= cnt_width_out + 1'b1;
			end
		end
	end
	assign add_cnt_width_out = (cnt_stage==2'd3)&&en_rd;
	assign end_cnt_width_out = (cnt_width_out==WIDTH_OUT)&&add_cnt_width_out;
	
	// end_cnt_width_out_d2
	always@(posedge clk)begin
		end_cnt_width_out_d2[0] <= end_cnt_width_out;
	end
	always@(posedge clk)begin
		end_cnt_width_out_d2[1] <= end_cnt_width_out_d2[0];
	end

	// cnt_height_out
	always@(posedge clk)begin
		if(rst_d1[0])begin
			cnt_height_out <= 'd0;
		end
		else begin
			if(end_cnt_height_out)begin
				cnt_height_out <= 'd0;
			end
			else if(add_cnt_height_out)begin
				cnt_height_out <= cnt_height_out + 1'b1;
			end
		end
	end
	assign add_cnt_height_out = end_cnt_width_out&&(cnt_reuse==InputReuseTimes);
	assign end_cnt_height_out = (cnt_height_out==HEIGHT_OUT)&&add_cnt_height_out;
	
	// cnt_block_deep
	always@(posedge clk)begin
		if(rst_d1[0])begin
			cnt_block_deep <= 'd0;
		end
		else begin
			if(end_cnt_block_deep)begin
				cnt_block_deep <= 'd0;
			end
			else if(add_cnt_block_deep)begin
				cnt_block_deep <= cnt_block_deep + 1'b1;
			end
		end
	end
	assign add_cnt_block_deep = end_cnt_height_out;
	assign end_cnt_block_deep = (cnt_block_deep==BLOCK_DEEP_MAX)&&add_cnt_block_deep;

	// cnt_loop_deep
	always@(posedge clk)begin
		if(rst_d1[0])begin
			cnt_loop_deep <= 'd0;
		end
		else begin
			if(end_cnt_loop_deep)begin
				cnt_loop_deep <= 'd0;
			end
			else if(add_cnt_loop_deep)begin
				cnt_loop_deep <= cnt_loop_deep + 1'b1;
			end
		end
	end
	assign add_cnt_loop_deep = end_cnt_block_deep;
	assign end_cnt_loop_deep = (cnt_loop_deep==LOOP_DEEP_MAX)&&add_cnt_loop_deep;
	
	// cnt_trans_times
	always@(posedge clk)begin
		if(rst_d1[0])begin
			cnt_trans_times <= 'd0;
		end
		else begin
			if(end_cnt_trans_times)begin
				cnt_trans_times <= 'd0;
			end
			else if(add_cnt_trans_times)begin
				cnt_trans_times <= cnt_trans_times + 1'b1;
			end
		end
	end
	assign add_cnt_trans_times = end_cnt_loop_deep;
	assign end_cnt_trans_times = (cnt_trans_times==TransferTimes)&&add_cnt_trans_times;
	
	// en_in
	always@(posedge clk)begin
		if(rst_d1[0])begin
			en_in <= 1'b0;
		end
		else if(en_rd)begin
			en_in <= 1'b1;
		end
		else begin
			en_in <= 1'b0;
		end
	end
	
weight_array#(
	.DATA_WIDTH(DATA_WIDTH_O)
)weight_array_inst_0(
	.clk(clk),
	.rst(rst_d1[1]),
	
	.en_in(en_in),
	.din_b0(din_b0[199:0]),
	.din_b1(din_b2[199:0]),
	.din_b2(din_b4[199:0]),
	.din_b3(din_b6[199:0]),

	.en_out(en_out[3:0]),
	.dout_b0(dout_b0),
	.dout_b1(dout_b2),
	.dout_b2(dout_b4),
	.dout_b3(dout_b6)
);

weight_array#(
	.DATA_WIDTH(DATA_WIDTH_O)
)weight_array_inst_1(
	.clk(clk),
	.rst(rst_d1[2]),
	
	.en_in(en_in),
	.din_b0(din_b1[199:0]),
	.din_b1(din_b3[199:0]),
	.din_b2(din_b5[199:0]),
	.din_b3(din_b7[199:0]),

	.en_out(en_out[7:4]),
	.dout_b0(dout_b1),
	.dout_b1(dout_b3),
	.dout_b2(dout_b5),
	.dout_b3(dout_b7)
);

endmodule