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


module data_in_write#(
	parameter   DATA_WIDTH = 64
)(
	input wire 						clk,
	input wire 						rst,
	input wire 						start,
	input wire [2:0]				layer,
	
	input wire [7:0]				row_deep,
	input wire [5:0]				block_deep,
	input wire [4:0]				loop_deep,
	input wire [9:0]				tile_deep,
	
	// 1 clk signal
	output reg 						oneslice_done,   // reserved signal
	
	//(S_AXIS) INPUT
    input  wire         			S_AXIS_TVALID,
	output wire          			S_AXIS_TREADY,
	input  wire[DATA_WIDTH-1: 0]	S_AXIS_TDATA,
	input  wire						S_AXIS_TLAST,
	
	//(BRAM) DATA OUT
	output wire [5:0]				en_wr,
	output wire [8:0]				addr_wr,
	output wire [DATA_WIDTH-1: 0]	data_wr
);
	localparam MidAddressBram	= 256;
	localparam AddrOffsetLayer1 = 256, // 2part
			   AddrOffsetLayer2 = 128, // 4part
			   AddrOffsetLayer3 = 64,  // 8part
			   AddrOffsetLayer4 = 32;  // 16part
	localparam OneChannelBramNum = 5; // 6-1 used to end_cnt_xxx
	localparam IDLE		= 3'b001,
			   CONFIG	= 3'b010,
			   RUN  	= 3'b100;  
	reg [2:0] state_c, state_n;
	wire run2idle;
	
	reg [2:0] 				layer_reg;
	reg						pingpong; // 0:ping 1:pong
	
	reg [7:0]				ROW_DEEP_MAX;
	reg [7:0]				TILE_DEEP_MAX;
	reg [5:0]				BLOCK_DEEP_MAX;
	reg [4:0]				LOOP_DEEP_MAX;
	reg [7:0]				ADDR_OFFSET;
	
	reg [DATA_WIDTH- 1: 0] 	data_in;
	
	// write the current row data to the base address of bram
	reg [8:0]				base_addr;
	wire					add_base_addr, end_base_addr;
	
	// determine which bram the data should be written to in current channel
	reg [2:0]				cnt_stage;
	wire 					add_cnt_stage, end_cnt_stage;
	reg 					add_cnt_stage_reg;
	
	// row/tile/block/loop_deep counter
	reg [7:0]				cnt_row_deep;
	reg [5:0]				cnt_slice_deep; // add 2023-8-29, use for oneslice_almost_done
	reg [7:0]				cnt_tile_deep;
	reg [5:0]				cnt_block_deep;
	reg [4:0]				cnt_loop_deep;
	wire					add_cnt_row_deep, end_cnt_row_deep;
	wire					add_cnt_slice_deep, end_cnt_slice_deep;
	wire					add_cnt_tile_deep, end_cnt_tile_deep;
	wire					add_cnt_block_deep, end_cnt_block_deep;
	wire					add_cnt_loop_deep, end_cnt_loop_deep;
	
	reg 					s_axis_tready;    // 4 channel tready
	reg [1:0] 				s_axis_tlast_delay; // delay
	
	reg [5:0]				en_out; 	// en_wr
	reg [8:0]				addr_out; 	// addr_out
	
	assign S_AXIS_TREADY 	= s_axis_tready;
	assign en_wr			= en_out;
	assign addr_wr			= addr_out;
	assign data_wr			= data_in;
	
	//rst_d1
	(* keep = "true" *)
	reg   rst_d1;
	always@(posedge clk)begin
		if(rst)begin
			rst_d1 <= 1'b1;
		end
		else begin
			rst_d1 <= 1'b0;
		end
	end
	
	//============== Done signal ==============
	// oneslice_done
	always@(posedge clk)begin
		if(rst_d1)begin
			oneslice_done <= 1'b0;
		end
		else if(s_axis_tlast_delay[0])begin
			oneslice_done <= 1'b1;
		end
		else begin
			oneslice_done <= 1'b0;
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
				state_n = RUN;
			end
			RUN: begin
				if(run2idle)begin
					state_n = IDLE;
				end
				else begin
					state_n = RUN;
				end
			end
			default: state_n = IDLE;
		endcase
	end
	assign run2idle	= end_cnt_loop_deep;
	
	// layer_reg
	always@(posedge clk)begin
		if(rst_d1)begin
			layer_reg <= 'd0;
		end
		else if(start&&(state_c == IDLE))begin
			layer_reg <= layer;
		end
	end
	
	//================== config hyperparam ================== 
	// ROW/BLOCK/LOOP_DEEP_MAX constant
	always@(posedge clk)begin
		if(rst_d1)begin
			ROW_DEEP_MAX 	<= 'd0;
			BLOCK_DEEP_MAX 	<= 'd0;
			LOOP_DEEP_MAX 	<= 'd0;
			TILE_DEEP_MAX 	<= 'd0;
		end
		else if(state_c == CONFIG)begin
			ROW_DEEP_MAX 	 <= row_deep;
			BLOCK_DEEP_MAX 	 <= block_deep 	- 1'b1;
			LOOP_DEEP_MAX 	 <= loop_deep	- 1'b1;
			TILE_DEEP_MAX 	 <= tile_deep;
		end
	end
	// ADDR_OFFSET
	always@(posedge clk)begin
		if(rst_d1)begin
			ADDR_OFFSET <= 8'd0;
		end
		else if(state_c == CONFIG)begin
			case(layer_reg)
				3'd1: ADDR_OFFSET <= AddrOffsetLayer1;
				3'd2: ADDR_OFFSET <= AddrOffsetLayer2;
				3'd3: ADDR_OFFSET <= AddrOffsetLayer3;
				3'd4: ADDR_OFFSET <= AddrOffsetLayer4;
				default: ADDR_OFFSET <= 8'd0;
			endcase
		end
	end

	// s_axis_tready
	always@(posedge clk)begin
		if(rst_d1)begin
			s_axis_tready <= 1'b0;
		end
		else if(end_cnt_loop_deep)begin
			s_axis_tready <= 1'b0;
		end
		else if(state_c == RUN)begin
			if((S_AXIS_TLAST&&S_AXIS_TVALID)||end_cnt_row_deep)begin
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

	// s_axis_tlast_delay
	always@(posedge clk)begin
		if(rst_d1)begin
			s_axis_tlast_delay[0] <= 1'b0;
		end
		else if(S_AXIS_TLAST&&s_axis_tready&&S_AXIS_TVALID)begin
			s_axis_tlast_delay[0] <= 1'b1;
		end
		else begin
			s_axis_tlast_delay[0] <= 1'b0;
		end	
	end
	always@(posedge clk)begin
		s_axis_tlast_delay[1] <= s_axis_tlast_delay[0];
	end

	// addr_out
	always@(posedge clk)begin
		if(rst_d1)begin
			addr_out <= 9'd0;
		end
		else if(state_c == RUN)begin
			if(add_cnt_stage_reg||s_axis_tlast_delay[1])begin
				addr_out <= base_addr;
			end
			else if(en_out)begin
				addr_out <= addr_out + 1'b1;
			end
		end
		else begin
			addr_out <= 9'd0;
		end
	end

	// en_out
	always@(posedge clk)begin
		if(rst_d1)begin
			en_out <= 6'd0;
		end
		else if((state_c==RUN)&&s_axis_tready&&S_AXIS_TVALID)begin
			case(cnt_stage)
				3'd0: en_out <= 6'b00_0001;
				3'd1: en_out <= 6'b00_0010;
				3'd2: en_out <= 6'b00_0100;
				3'd3: en_out <= 6'b00_1000;
				3'd4: en_out <= 6'b01_0000;
				3'd5: en_out <= 6'b10_0000;
				default: en_out <= 6'd0;
			endcase
		end
		else begin
			en_out <= 6'd0;
		end
	end

	//data_in
	always@(posedge clk)begin
		if(rst_d1)begin
			data_in <= 64'd0;
		end
		else if(s_axis_tready&&S_AXIS_TVALID)begin
			data_in <= S_AXIS_TDATA;
		end
	end

	//pingpong
	always@(posedge clk)begin
		if(rst_d1)begin
			pingpong <= 1'b0;
		end
		else if(state_c==IDLE)begin
			pingpong <= 1'b0;
		end
		else if(S_AXIS_TLAST&&s_axis_tready&&S_AXIS_TVALID)begin
			pingpong <= ~pingpong;
		end
	end
	
	// base_addr
	always@(posedge clk)begin
		if(rst_d1)begin
			base_addr <= 9'd0;
		end
		else if(state_c == RUN)begin
			if(end_base_addr)begin
				case(pingpong)
					1'b0: base_addr <= 9'd0;
					1'b1: base_addr <= MidAddressBram;
					default: base_addr <= 9'd0;
				endcase
			end
			else if(add_base_addr)begin
				base_addr <= base_addr + ADDR_OFFSET;
			end
		end
		else begin
			base_addr <= 9'd0;
		end
	end
	assign add_base_addr = (cnt_stage==(OneChannelBramNum))&&add_cnt_stage;
	assign end_base_addr = s_axis_tlast_delay[0];

	// cnt_stage
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_stage <= 3'd0;
		end
		else begin
			if(end_cnt_stage)begin
				cnt_stage <= 3'd0;
			end
			else if(add_cnt_stage)begin
				cnt_stage <= cnt_stage + 1'b1;
			end
		end
	end
	assign add_cnt_stage = end_cnt_row_deep;
	assign end_cnt_stage = ((cnt_stage==OneChannelBramNum)&&add_cnt_stage)||s_axis_tlast_delay[0];
	
	// add_cnt_stage_reg
	always@(posedge clk)begin
		if(rst_d1)begin
			add_cnt_stage_reg <= 1'd0;
		end
		else if(add_cnt_stage)begin
			add_cnt_stage_reg <= 1'd1;
		end
		else begin
			add_cnt_stage_reg <= 1'd0;
		end
	end
	
	// cnt_row_deep
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_row_deep <= 8'd0;
		end
		else if(state_c == RUN)begin
			if(end_cnt_row_deep)begin
				cnt_row_deep <= 8'd0;
			end
			else if(add_cnt_row_deep)begin
				cnt_row_deep <= cnt_row_deep + 1'b1;
			end
		end
	end
	assign add_cnt_row_deep = S_AXIS_TREADY&&S_AXIS_TVALID;
	assign end_cnt_row_deep = (cnt_row_deep==ROW_DEEP_MAX)&&add_cnt_row_deep;
	
	// cnt_tile_deep
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_tile_deep <= 8'd0;
		end
		else if(state_c == RUN)begin
			if(end_cnt_tile_deep)begin
				cnt_tile_deep <= 8'd0;
			end
			else if(add_cnt_tile_deep)begin
				cnt_tile_deep <= cnt_tile_deep + 1'b1;
			end
		end
	end
	assign add_cnt_tile_deep = s_axis_tlast_delay[0];
	assign end_cnt_tile_deep = (cnt_tile_deep==TILE_DEEP_MAX)&&add_cnt_tile_deep;

	// cnt_block_deep
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_block_deep <= 8'd0;
		end
		else if(state_c == RUN)begin
			if(end_cnt_block_deep)begin
				cnt_block_deep <= 8'd0;
			end
			else if(add_cnt_block_deep)begin
				cnt_block_deep <= cnt_block_deep + 1'b1;
			end
		end
	end
	assign add_cnt_block_deep = end_cnt_tile_deep;
	assign end_cnt_block_deep = (cnt_block_deep==BLOCK_DEEP_MAX)&&add_cnt_block_deep;
	
	// cnt_loop_deep
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_loop_deep <= 8'd0;
		end
		else if(state_c == RUN)begin
			if(end_cnt_loop_deep)begin
				cnt_loop_deep <= 8'd0;
			end
			else if(add_cnt_loop_deep)begin
				cnt_loop_deep <= cnt_loop_deep + 1'b1;
			end
		end
	end
	assign add_cnt_loop_deep = end_cnt_block_deep;
	assign end_cnt_loop_deep = (cnt_loop_deep==LOOP_DEEP_MAX)&&add_cnt_loop_deep;
	
endmodule