`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: GDUT
// Engineer: JFeng Lee
// 
// Create Date:
// Design Name:
// Module Name: 
// Project Name: 
// Taget Devices: zcu104
// Tool Versions: 2018.3
// Description:
// 
// Dependencies:
// 
// Revision: 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module output_write#(
	parameter DATA_WIDTH_I = 8,
	parameter DATA_WIDTH_O = 64,
	parameter ADDR_WIDTH   = 13
)(
	input wire 					    clk,
	input wire 					    rst,
	input wire 					    start,
	input wire [2:0]			    layer,
	output reg						write_done,
	
	input wire						en_in,
	input wire [DATA_WIDTH_I-1:0]	din_b0, din_b1, 
	
	output reg						en_wr,
	output reg [ADDR_WIDTH-1:0]		addr_wr,
	output reg [DATA_WIDTH_O-1:0]	dout_b0, dout_b1
);
	localparam InputReuseTimes = 3;	// 4-1, 8batch*4
	// store mode
	localparam PingPong  = 1'b0,
			   FourParts = 1'b1; 
	localparam AddrOffsetLy1 = 360; 
	localparam BaseAddrPart0 = 0,
			   BaseAddrPart1 = 1024,
			   BaseAddrPart2 = 2048,
			   BaseAddrPart3 = 3072,
			   BaseAddrPart4 = 4096,
			   BaseAddrPart5 = 5120,
			   BaseAddrPart6 = 6144,
			   BaseAddrPart7 = 7168;
	
	parameter IDLE 	 = 3'b001,
              CONFIG = 3'b010,
			  WORK   = 3'b100;
	reg [2:0]	state_c;
	reg [2:0]	layer_reg;
	
	reg [6:0]						WIDTH_OUT;
	reg [6:0]						HEIGHT_OUT;
	reg [7:0]						LOOP_DEEP;
	reg [1:0]						TransferTimes;
	
	reg	[2:0]						cnt_stage;
	
	reg [6:0]						cnt_width;
	reg [1:0]   					cnt_reuse;
	reg [6:0]						cnt_height;
	reg [7:0]						cnt_loop_deep;
	reg [1:0]   					cnt_trans_times;
	wire							add_cnt_width, end_cnt_width;
	wire        					add_cnt_reuse, end_cnt_reuse;
	wire							add_cnt_height, end_cnt_height;
	wire							add_cnt_loop_deep, end_cnt_loop_deep;	
	wire        					add_cnt_trans_times, end_cnt_trans_times;
	reg 							end_cnt_width_d1;
	reg [1:0]						add_cnt_loop_deep_reg;
	
	reg 							en_in_d1;
	reg								pingpong;
	reg [ADDR_WIDTH-1:0]			base_addr;
	reg [ADDR_WIDTH-2:0]			addr_offset;
	

	(* keep = "true" *)
	reg  rst_d1;
	always@(posedge clk)begin
		if(rst)begin
			rst_d1 <= 1'b1;
		end
		else begin
			rst_d1 <= 1'b0;
		end
	end
	
	// write_done
	always@(posedge clk)begin
		if(rst_d1)begin
			write_done <= 1'b0;
		end
		else if(end_cnt_height)begin
			write_done <= 1'b1;
		end
		else begin
			write_done <= 1'b0;
		end
	end
	
	// FSM
	always@(posedge clk)begin
		if(rst_d1)begin
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
					state_c <= WORK;
				end
				WORK: begin
					if(end_cnt_trans_times)begin
						state_c <= IDLE;
					end
					else begin
						state_c <= WORK;
					end
				end
				default: state_c <= IDLE;
			endcase
		end
	end

	// layer_reg
	always@(posedge clk)begin
		if(rst_d1)begin
			layer_reg <= 'd0;
		end
		else if(start&&(state_c==IDLE))begin
			layer_reg <= layer;
		end
	end
	// WIDTH_OUT
	always@(posedge clk)begin
		if(rst_d1)begin
			WIDTH_OUT <= 7'd0;
		end
		else if(state_c==CONFIG)begin
			case(layer_reg)
				3'd1: WIDTH_OUT <= 7'd119; 
				3'd2: WIDTH_OUT <= 7'd59;
				3'd3: WIDTH_OUT <= 7'd29;
				3'd4: WIDTH_OUT <= 7'd14; 
				default: WIDTH_OUT <= 7'd0;
			endcase
		end
	end
	// HEIGHT_OUT
	always@(posedge clk)begin 
		if(rst_d1)begin
			HEIGHT_OUT <= 7'd0;
		end
		else begin
			HEIGHT_OUT <= 7'd5;
		end
	end
	// LOOP_DEEP
	always@(posedge clk)begin
		if(rst_d1)begin
			LOOP_DEEP <= 8'd0;
		end
		else if(state_c==CONFIG)begin
			LOOP_DEEP <= 8'd6;  
		end
	end
	// TransferTimes
	always@(posedge clk)begin
		if(rst_d1)begin
			TransferTimes <= 'd0;
		end
		else if(state_c==CONFIG)begin
			TransferTimes <= 'd3;
		end
	end

	// pingpong
	always@(posedge clk)begin
		if(rst_d1)begin
			pingpong <= 1'b0;
		end
		else if(state_c==IDLE)begin
			pingpong <= 1'b0;
		end
		else if(add_cnt_loop_deep)begin
			pingpong <= ~pingpong;
		end
	end

	// en_in_d1
	always@(posedge clk)begin
		if(rst_d1)begin
			en_in_d1 <= 1'b0;
		end
		else begin
			en_in_d1 <= en_in;
		end
	end
	
	// cnt_stage
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_stage <= 'd0;
		end
		else if(en_in_d1)begin
			cnt_stage <= cnt_stage + 1'b1;
		end
	end
	
	// addr_offset
	always@(posedge clk)begin
		if(rst_d1)begin
			 addr_offset <= 'd0;
		end
		else if(state_c==IDLE||add_cnt_loop_deep)begin
			addr_offset <= 'd0;
		end
		else if((cnt_reuse==(InputReuseTimes-1))&&add_cnt_reuse)begin
			addr_offset <= addr_offset + WIDTH_OUT;
		end
	end
	
	// base_addr
	always@(posedge clk)begin
		if(rst_d1)begin
			base_addr <= 'd0;
		end
		else if(add_cnt_loop_deep_reg[0])begin
			case(pingpong)
				1'b0: base_addr <= BaseAddrPart0;
				1'b1: base_addr <= BaseAddrPart4;
				default: base_addr <= 'd0;
			endcase
		end
		else if(end_cnt_width)begin
			case(pingpong)
				1'b0: begin
					case(cnt_reuse)
						2'd0: base_addr <= BaseAddrPart1 + addr_offset;
						2'd1: base_addr <= BaseAddrPart2 + addr_offset;
						2'd2: base_addr <= BaseAddrPart3 + addr_offset;
						2'd3: base_addr <= BaseAddrPart0 + addr_offset;
						default: base_addr <= 'd0;
					endcase
				end
				1'b1: begin
					case(cnt_reuse)
						2'd0: base_addr <= BaseAddrPart5 + addr_offset;
						2'd1: base_addr <= BaseAddrPart6 + addr_offset;
						2'd2: base_addr <= BaseAddrPart7 + addr_offset;
						2'd3: base_addr <= BaseAddrPart4 + addr_offset;
						default: base_addr <= 'd0;
					endcase
				end
				default: base_addr <= 'd0;
			endcase
		end
	end
	
	// addr_wr
	always@(posedge clk)begin
		if(rst_d1)begin
			addr_wr <= 'd0;
		end
		else if((state_c==CONFIG)||end_cnt_width_d1||add_cnt_loop_deep_reg[1])begin
			addr_wr <= base_addr;
		end
		else if(en_wr)begin
			addr_wr <= addr_wr + 1'b1;
		end
	end
	
	// en_wr
	always@(posedge clk)begin
		if(rst_d1)begin
			en_wr <= 1'b0;
		end
		else if(cnt_stage==3'd6)begin
			en_wr <= 1'b1;
		end
		else begin
			en_wr <= 1'b0;
		end
	end

	always@(posedge clk)begin
		if(rst_d1)begin
			dout_b0 <= 'd0;
		end
		else if(en_in)begin
			dout_b0 <= {din_b0, dout_b0[63:8]};
		end
	end
	always@(posedge clk)begin
		if(rst_d1)begin
			dout_b1 <= 'd0;
		end
		else if(en_in)begin
			dout_b1 <= {din_b1, dout_b1[63:8]};
		end
	end
	

	// cnt_width
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_width <= 'd0;
		end
		else begin
			if(end_cnt_width)begin
				cnt_width <= 'd0;
			end
			else if(add_cnt_width)begin
				cnt_width <= cnt_width + 1'b1;
			end
		end
	end
	assign add_cnt_width = (cnt_stage==3'd7);
	assign end_cnt_width = (cnt_width==(WIDTH_OUT-1))&&add_cnt_width;
	
	// end_cnt_width_d1
	always@(posedge clk)begin
		end_cnt_width_d1 <= end_cnt_width;
	end
	
	// cnt_reuse
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_reuse <= 'd0;
		end
		else begin
			if(end_cnt_reuse)begin
				cnt_reuse <= 'd0;
			end
			else if(add_cnt_reuse)begin
				cnt_reuse <= cnt_reuse + 1'b1;
			end
		end
	end
	assign add_cnt_reuse = end_cnt_width;
	assign end_cnt_reuse = (cnt_reuse==InputReuseTimes)&&add_cnt_reuse;
	
	// cnt_height
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_height <= 'd0;
		end
		else begin
			if(end_cnt_height)begin
				cnt_height <= 'd0;
			end
			else if(add_cnt_height)begin
				cnt_height <= cnt_height + 1'b1;
			end
		end
	end
	assign add_cnt_height = end_cnt_reuse;
	assign end_cnt_height = (cnt_height==HEIGHT_OUT)&&add_cnt_height;
	
	// cnt_loop_deep
	always@(posedge clk)begin
		if(rst_d1)begin
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
	assign add_cnt_loop_deep = end_cnt_height;
	assign end_cnt_loop_deep = (cnt_loop_deep==LOOP_DEEP)&&add_cnt_loop_deep;
	
	// add_cnt_loop_deep_reg
	always@(posedge clk)begin
		if(rst_d1)begin
			add_cnt_loop_deep_reg <= 'd0;
		end
		else begin
			add_cnt_loop_deep_reg <= {add_cnt_loop_deep_reg[0], add_cnt_loop_deep};
		end
	end
	
	// cnt_trans_times
	always@(posedge clk)begin
		if(rst_d1)begin
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

endmodule