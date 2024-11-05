`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: GDUT
// Engineer: JF Lee
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


module weight_write#(
	parameter DATA_WIDTH = 64
)(
	input wire 						clk,
	input wire 						rst,
	input wire 						start,
	input wire [2:0]				layer,
	
	//(S_AXIS) INPUT  CHANNEL
    input  wire         			S_AXIS_TVALID,
	output wire          			S_AXIS_TREADY,
	input  wire[DATA_WIDTH-1: 0]	S_AXIS_TDATA,
	input  wire						S_AXIS_TLAST,
	
	output reg [7:0]				en_out,
	output reg [11:0]				addr_out,
	output reg [DATA_WIDTH-1: 0]	dout
);
	localparam IDLE   = 3'b001,
			   CONFIG = 3'b010,
			   WORK   = 3'b100;
	reg [2:0]  state_c,state_n;
	
	reg [2:0]	layer_reg;  // reserved
	reg [10:0]	OneBramDataNum;  // The amount of data written to one BRAM in a single transmission
	reg [1:0]	TransferTimes;
	
	reg [10:0]	cnt_data_num;  // counter weight data to switch en_out 0-7
	reg [1:0]   cnt_trans_times;
	wire 		add_cnt_data_num, end_cnt_data_num;
	wire        add_cnt_trans_times, end_cnt_trans_times;
	reg 		end_cnt_data_num_d1;
		
	reg 		pingpong;
	
	reg [7:0]	bram_idx;
	
	reg 		s_axis_tready;
	assign		S_AXIS_TREADY = s_axis_tready;
	
	(* keep = "true" *)
	reg rst_d1;
	//rst_d1
	always@(posedge clk)begin
		if(rst)begin
			rst_d1 <= 1'b1;
		end
		else begin
			rst_d1 <= 1'b0;
		end
	end
	
	//================== FSM ================== 
	always@(posedge clk)begin
		if(rst_d1)begin
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
				if(end_cnt_trans_times)begin
					state_n = IDLE;
				end
				else begin
					state_n = WORK;
				end
			end
			default: state_n = IDLE;
		endcase
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
	
	// TransferTimes
	always@(posedge clk)begin
		if(rst_d1)begin
			TransferTimes <= 'd0;
		end
		else if(state_c==CONFIG)begin
			TransferTimes <= 2'd3;
		end
	end
	
	// OneBramDataNum
	always@(posedge clk)begin
		if(rst_d1)begin
			OneBramDataNum <= 'd0;
		end
		else if(state_c==CONFIG)begin
			if(layer_reg == 3'd1)begin
				OneBramDataNum <= 11'd63;
			end
			else begin
				OneBramDataNum <= 11'd2047;
			end
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
		else if(add_cnt_trans_times)begin
			pingpong <= ~pingpong;
		end
	end
	
	// s_axis_tready
	always@(posedge clk)begin
		if(rst_d1)begin
			s_axis_tready <= 1'b0;
		end
		else if(state_c==WORK)begin
			if(end_cnt_data_num)begin
				s_axis_tready <= 1'b0;
			end
			else begin
				s_axis_tready <= 1'b1;
			end
		end
		else begin
			s_axis_tready <= 1'b0;
		end
	end
	
	// bram_idx
	always@(posedge clk)begin
		if(rst_d1)begin
			bram_idx <= 8'b0000_0001;
		end
		else if(end_cnt_data_num)begin
			bram_idx <= {bram_idx[6:0], bram_idx[7]};
		end
	end
	
	// en_out
	always@(posedge clk)begin
		if(rst_d1)begin
			en_out <= 8'd0;
		end
		else if(S_AXIS_TVALID&&s_axis_tready)begin
			en_out <= bram_idx;
		end
		else begin
			en_out <= 8'd0;
		end
	end
	
	// addr_out
	always@(posedge clk)begin
		if(rst_d1)begin
			addr_out <= 12'd0;
		end
		else if(state_c==IDLE)begin
			addr_out <= 12'd0;
		end
		else begin
			if(end_cnt_data_num_d1)begin
				case(pingpong)
					1'b0: addr_out <= 12'd0;
					1'b1: addr_out <= 12'd2048;
					default: addr_out <= 12'd0;
				endcase
			end
			else if(en_out)begin
				addr_out <= addr_out + 1'b1;
			end
		end
	end
	
	// dout
	always@(posedge clk)begin
		if(rst_d1)begin
			dout <= 'd0;
		end
		else if(S_AXIS_TVALID&&s_axis_tready)begin
			dout <= S_AXIS_TDATA;
		end
	end
	
	// cnt_data_num
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_data_num <= 'd0;
		end
		else begin
			if(end_cnt_data_num)begin
				cnt_data_num <= 'd0;
			end
			else if(add_cnt_data_num)begin
				cnt_data_num <= cnt_data_num + 1'b1;
			end
		end
	end
	assign add_cnt_data_num = S_AXIS_TVALID&&s_axis_tready;
	assign end_cnt_data_num = (cnt_data_num==OneBramDataNum)&&add_cnt_data_num;
	
	// end_cnt_data_num_d1
	always@(posedge clk)begin
		if(end_cnt_data_num)begin
			end_cnt_data_num_d1 <= 1'b1;
		end
		else begin
			end_cnt_data_num_d1 <= 1'b0;
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
	assign add_cnt_trans_times = S_AXIS_TLAST&&S_AXIS_TVALID&&s_axis_tready;
	assign end_cnt_trans_times = (cnt_trans_times==TransferTimes)&&add_cnt_trans_times;
	
endmodule