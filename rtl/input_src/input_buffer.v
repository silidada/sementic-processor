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
// Description: Reference demo2
// 
// Dependencies: 
// 
// Revision: 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "hyperparam.vh"

module input_buffer#(
	parameter DATA_WIDTH 	= 64,
	parameter DATA_WIDTH_O  = 200  // 5*5*8
)(
	input wire 				clk,
	input wire 				rst,
	input wire [2:0]		layer,
	input wire				start,
	input wire				start_read,
	output reg				oneslice_wr_done,
	output reg				is_dma_write,
	output wire [3:0]		read_continue,
	output wire [3:0]		read_pause,
	input wire				is_WrFastRd_obuf,

	//CH0:
	//(S_AXIS) INPUT  CHANNEL
    input  wire       			S_AXIS_TVALID_C0,
	output wire       			S_AXIS_TREADY_C0,
	input  wire[DATA_WIDTH-1: 0]S_AXIS_TDATA_C0,
    input  wire       			S_AXIS_TLAST_C0,
	//CH1:
	//(S_AXIS) INPUT  CHANNEL
    input  wire       			S_AXIS_TVALID_C1,
	output wire       			S_AXIS_TREADY_C1,
	input  wire[DATA_WIDTH-1: 0]S_AXIS_TDATA_C1,
    input  wire       			S_AXIS_TLAST_C1,
	//CH2:
	//(S_AXIS) INPUT  CHANNEL
    input  wire       			S_AXIS_TVALID_C2,
	output wire       			S_AXIS_TREADY_C2,
	input  wire[DATA_WIDTH-1: 0]S_AXIS_TDATA_C2,
    input  wire       			S_AXIS_TLAST_C2,
	//CH3:
	//(S_AXIS) INPUT  CHANNEL
    input  wire       			S_AXIS_TVALID_C3,
	output wire       			S_AXIS_TREADY_C3,
	input  wire[DATA_WIDTH-1: 0]S_AXIS_TDATA_C3,
    input  wire       			S_AXIS_TLAST_C3,
	
	output wire[3:0]			en_out,
	output wire[DATA_WIDTH_O-1:0]
								dout_c0,
	output wire[DATA_WIDTH_O-1:0]
								dout_c1,
	output wire[DATA_WIDTH_O-1:0]
								dout_c2,
	output wire[DATA_WIDTH_O-1:0]
								dout_c3
);
	localparam IDLE 	= 3'b001,
			   CONFIG	= 3'b010,
			   WORK		= 3'b100;
	reg [2:0]  	state_c, state_n;
	reg [2:0]  	layer_reg;
	reg		   	start_all;
	reg	[3:0]	allzero;
	
	reg [7:0]	row_deep;
	reg [5:0]	block_deep;
	reg [4:0]	loop_deep;
	reg [9:0]	tile_deep;
	
	wire 					oneslice_done_wr_c0;
	wire 					oneslice_done_wr_c1;
	wire 					oneslice_done_wr_c2;
	wire 					oneslice_done_wr_c3;
	
	reg [3:0]				oneslice_done_wr_flag;
	
	//(M_AXIS) OUTPUT CHANNEL 0
	wire					m_axis_tvalid_c0;
	wire				 	m_axis_tready_c0;
	wire[DATA_WIDTH-1:0]	m_axis_tdata_c0;
	wire					m_axis_tlast_c0;
	//(M_AXIS) OUTPUT CHANNEL 1
	wire					m_axis_tvalid_c1;
	wire				 	m_axis_tready_c1;
	wire[DATA_WIDTH-1:0]	m_axis_tdata_c1;
	wire					m_axis_tlast_c1;
	//(M_AXIS) OUTPUT CHANNEL 2
	wire					m_axis_tvalid_c2;
	wire				 	m_axis_tready_c2;
	wire[DATA_WIDTH-1:0]	m_axis_tdata_c2;
	wire					m_axis_tlast_c2;
	//(M_AXIS) OUTPUT CHANNEL 3
	wire					m_axis_tvalid_c3;
	wire				 	m_axis_tready_c3;
	wire[DATA_WIDTH-1:0]	m_axis_tdata_c3;
	wire					m_axis_tlast_c3;
	
	
	wire [5:0]				en_wr_c0,   en_wr_c1,   en_wr_c2,   en_wr_c3;
	wire [8:0]				addr_wr_c0, addr_wr_c1, addr_wr_c2, addr_wr_c3;
	wire [DATA_WIDTH-1:0]	data_wr_c0, data_wr_c1, data_wr_c2, data_wr_c3;
	
	wire					is_dma_write_c0,is_dma_write_c1,is_dma_write_c2,is_dma_write_c3;
	reg  [3:0]				is_dma_write_flag;
	
	wire [2:0]				order_rd_c0,order_rd_c1,order_rd_c2,order_rd_c3;
	//wire [5:0]			en_bram_rd_c0,en_bram_rd_c1,en_bram_rd_c2,en_bram_rd_c3;
	wire 					en_bram_rd_c0,en_bram_rd_c1,en_bram_rd_c2,en_bram_rd_c3;
	wire [8:0]				addr_rd_0_c0,addr_rd_0_c1,addr_rd_0_c2,addr_rd_0_c3;
	wire [8:0]				addr_rd_1_c0,addr_rd_1_c1,addr_rd_1_c2,addr_rd_1_c3;
	wire [8:0]				addr_rd_2_c0,addr_rd_2_c1,addr_rd_2_c2,addr_rd_2_c3;
	wire [8:0]				addr_rd_3_c0,addr_rd_3_c1,addr_rd_3_c2,addr_rd_3_c3;
	wire [8:0]				addr_rd_4_c0,addr_rd_4_c1,addr_rd_4_c2,addr_rd_4_c3;
	wire [8:0]				addr_rd_5_c0,addr_rd_5_c1,addr_rd_5_c2,addr_rd_5_c3;
	wire [DATA_WIDTH*5-1:0]	data_bram_in_c0,data_bram_in_c1,data_bram_in_c2,data_bram_in_c3;
	wire 					en_out_c0,en_out_c1,en_out_c2,en_out_c3;
	wire [DATA_WIDTH*5-1:0]	data_out_c0,data_out_c1,data_out_c2,data_out_c3;
	
	(* keep = "true" *)
	reg [13:0]  rst_d1;
	always@(posedge clk)begin
		if(rst)begin
			rst_d1 <= 14'b11_1111_1111_1111;
		end
		else begin
			rst_d1 <= 14'b00_0000_0000_0000;
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
				state_n = IDLE;
			end
			default: state_n = IDLE;
		endcase
	end
	
	// layer_reg
	always@(posedge clk)begin
		if(rst_d1[0])begin
			layer_reg <= 'd0;
		end
		else if(start&&(state_c == IDLE))begin
			layer_reg <= layer;
		end
	end
	
	// start_all
	always@(posedge clk)begin
		if(state_c == WORK)begin
			start_all <= 1'b1;
		end
		else begin
			start_all <= 1'b0;
		end
	end

	//================== hyperparam ================== 
	// row_deep
	always@(posedge clk)begin
		if(rst_d1[0])begin
			row_deep <= 8'd0;
		end
		else if(state_c == CONFIG)begin
			case(layer_reg)
				3'd1: row_deep <= ROW_DEEP_LY1;
				3'd2: row_deep <= ROW_DEEP_LY2;
				3'd3: row_deep <= ROW_DEEP_LY3;
				3'd4: row_deep <= ROW_DEEP_LY4;
				default: row_deep <= 8'd0;
			endcase
		end
	end
	// block_deep
	always@(posedge clk)begin
		if(rst_d1[0])begin
			block_deep <= 6'd0;
		end
		else if(state_c == CONFIG)begin
			case(layer_reg)
				3'd1: block_deep <= BLOCK_DEEP_LY1;
				3'd2: block_deep <= BLOCK_DEEP_LY2;
				3'd3: block_deep <= BLOCK_DEEP_LY3;
				3'd5: block_deep <= BLOCK_DEEP_LY;
				default: block_deep <= 6'd0;
			endcase
		end
	end
	// loop_deep
	always@(posedge clk)begin
		if(rst_d1[0])begin
			loop_deep <= 5'd0;
		end
		else if(state_c == CONFIG)begin
			case(layer_reg)
				3'd1: loop_deep <= LOOP_DEEP_LY1;
				3'd2: loop_deep <= LOOP_DEEP_LY2;
				3'd3: loop_deep <= LOOP_DEEP_LY3;
				3'd4: loop_deep <= LOOP_DEEP_LY4;
				default: loop_deep <= 5'd0;
			endcase
		end
	end
	// tile_deep
	always@(posedge clk)begin
		if(rst_d1[0])begin
			tile_deep <= 'd0;
		end
		else if(state_c == CONFIG)begin
			case(layer_reg)
				3'd1: tile_deep <= TILE_DEEP_LY1;
				3'd2: tile_deep <= TILE_DEEP_LY2;
				3'd3: tile_deep <= TILE_DEEP_LY3;
				3'd4: tile_deep <= TILE_DEEP_LY4;
				default: tile_deep <= 'd0;
			endcase
		end
	end
	
	// allzero
	always@(posedge clk)begin
		if(state_c == IDLE)begin
			allzero <= 4'b0;
		end
		else if((state_c==CONFIG)&&(layer_reg==3'd1))begin
			allzero <= 4'b1000;
		end
	end
	
	// oneslice_done_wr_flag
	always@(posedge clk)begin
		if(rst_d1[0])begin
			oneslice_done_wr_flag[0] <= 1'b0;
		end
		else if(oneslice_done_wr_flag == 4'b1111)begin
			oneslice_done_wr_flag[0] <= 1'b0;
		end
		else if(oneslice_done_wr_c0)begin
			oneslice_done_wr_flag[0] <= 1'b1;
		end
	end
	always@(posedge clk)begin
		if(rst_d1[0])begin
			oneslice_done_wr_flag[1] <= 1'b0;
		end
		else if(oneslice_done_wr_flag == 4'b1111)begin
			oneslice_done_wr_flag[1] <= 1'b0;
		end
		else if(oneslice_done_wr_c1)begin
			oneslice_done_wr_flag[1] <= 1'b1;
		end
	end
	always@(posedge clk)begin
		if(rst_d1[0])begin
			oneslice_done_wr_flag[2] <= 1'b0;
		end
		else if(oneslice_done_wr_flag == 4'b1111)begin
			oneslice_done_wr_flag[2] <= 1'b0;
		end
		else if(oneslice_done_wr_c2)begin
			oneslice_done_wr_flag[2] <= 1'b1;
		end
	end
	always@(posedge clk)begin
		if(rst_d1[0])begin
			oneslice_done_wr_flag[3] <= 1'b0;
		end
		else if((oneslice_done_wr_flag == 4'b1111)&&(layer_reg != 3'd1))begin // layer 1 allzero mode
			oneslice_done_wr_flag[3] <= 1'b0;
		end
		else if(oneslice_done_wr_c3)begin
			oneslice_done_wr_flag[3] <= 1'b1;
		end
	end
	// oneslice_wr_done
	always@(posedge clk)begin
		if(rst_d1[0])begin
			oneslice_wr_done <= 1'b0;
		end
		else if(oneslice_done_wr_flag == 4'b1111)begin
			oneslice_wr_done <= 1'b1;
		end
		else begin
			oneslice_wr_done <= 1'b0;
		end
	end
	
	// is_dma_write_flag
	always@(posedge clk)begin
		if(rst_d1[0])begin
			is_dma_write_flag[0] <= 1'b0;
		end
		else if(is_dma_write_flag == 4'b1111)begin
			is_dma_write_flag[0] <= 1'b0;
		end
		else if(is_dma_write_c0)begin
			is_dma_write_flag[0] <= 1'b1;
		end
	end
	always@(posedge clk)begin
		if(rst_d1[0])begin
			is_dma_write_flag[1] <= 1'b0;
		end
		else if(is_dma_write_flag == 4'b1111)begin
			is_dma_write_flag[1] <= 1'b0;
		end
		else if(is_dma_write_c1)begin
			is_dma_write_flag[1] <= 1'b1;
		end
	end
	always@(posedge clk)begin
		if(rst_d1[0])begin
			is_dma_write_flag[2] <= 1'b0;
		end
		else if(is_dma_write_flag == 4'b1111)begin
			is_dma_write_flag[2] <= 1'b0;
		end
		else if(is_dma_write_c2)begin
			is_dma_write_flag[2] <= 1'b1;
		end
	end
	always@(posedge clk)begin
		if(rst_d1[0])begin
			is_dma_write_flag[3] <= 1'b0;
		end
		else if(is_dma_write_flag == 4'b1111)begin
			is_dma_write_flag[3] <= 1'b0;
		end
		else if(is_dma_write_c3)begin
			is_dma_write_flag[3] <= 1'b1;
		end
	end
	// is_dma_write
	always@(posedge clk)begin
		if(rst_d1[0])begin
			is_dma_write <= 1'b0;
		end
		else if(is_dma_write_flag == 4'b1111)begin
			is_dma_write <= 1'b1;
		end
		else begin
			is_dma_write <= 1'b0;
		end
	end
	

// channel 0
padding_fifo #(
	.DATA_WIDTH(DATA_WIDTH)
)padding_fifo_inst_c0(
	.clk(clk),
	.rst(rst_d1[1]),
	.start(start_all),
	.layer(layer_reg),
	.allzero(allzero[0]),
	
	.row_deep(row_deep),
	.block_deep(block_deep),
	.loop_deep(loop_deep),
	.tile_deep(tile_deep),
	
	//(S_AXIS) INPUT  CHANNEL
	.S_AXIS_TVALID(S_AXIS_TVALID_C0),
	.S_AXIS_TREADY(S_AXIS_TREADY_C0),
	.S_AXIS_TDATA(S_AXIS_TDATA_C0),
	.S_AXIS_TLAST(S_AXIS_TLAST_C0),
	//(M_AXIS) OUTPUT CHANNEL
	.M_AXIS_TVALID(m_axis_tvalid_c0),
	.M_AXIS_TREADY(m_axis_tready_c0),
	.M_AXIS_TDATA(m_axis_tdata_c0),
	.M_AXIS_TLAST(m_axis_tlast_c0)
);
data_in_write#(
	.DATA_WIDTH(DATA_WIDTH)
)data_in_write_inst_c0(
	.clk(clk),
	.rst(rst_d1[2]),
	.start(start_all),
	.layer(layer_reg),
	
	.row_deep(row_deep),	// without pad
	.block_deep(block_deep),
	.loop_deep(loop_deep),
	.tile_deep(tile_deep),
	
	// 1 clk signal
	.oneslice_done(oneslice_done_wr_c0),
	
	//(S_AXIS) INPUT  CHANNEL 0
    .S_AXIS_TVALID(m_axis_tvalid_c0),
	.S_AXIS_TREADY(m_axis_tready_c0),
	.S_AXIS_TDATA(m_axis_tdata_c0),
	.S_AXIS_TLAST(m_axis_tlast_c0),

	//(BRAM) DATA OUT
	.en_wr(en_wr_c0),
	.addr_wr(addr_wr_c0),
	.data_wr(data_wr_c0)
);
data_in_read#(
	.DATA_WIDTH(DATA_WIDTH)
)data_in_read_inst_c0(
	.clk(clk),
	.rst(rst_d1[3]),
	.start(start_read),
	.layer(layer_reg),
	.oneslice_wr_done(oneslice_wr_done),// input 
	.is_dma_write(is_dma_write_c0),		// output
	.read_continue(read_continue[0]),
	.read_pause(read_pause[0]),
	.is_WrFastRd_obuf(is_WrFastRd_obuf),
	
	.row_deep(row_deep),	// without pad
	.block_deep(block_deep),
	.loop_deep(loop_deep),
	.tile_deep(tile_deep),
	
	.order_rd(order_rd_c0),		 // output
	.en_bram_rd(en_bram_rd_c0),  // output
	.addr_rd_0(addr_rd_0_c0),       // output
	.addr_rd_1(addr_rd_1_c0),		 // output
	.addr_rd_2(addr_rd_2_c0),       // output
	.addr_rd_3(addr_rd_3_c0),       // output
	.addr_rd_4(addr_rd_4_c0),       // output
	.addr_rd_5(addr_rd_5_c0),       // output
	.data_bram_in(data_bram_in_c0), // input 
	
	.en_out(en_out_c0),		     // output
	.data_out(data_out_c0)          // output
);
one_channel_bram#(
	.DATA_WIDTH(DATA_WIDTH)
)one_channel_bram_inst_c0(
	.clk(clk),
	// write
	.en_wr(en_wr_c0),
	.addr_wr(addr_wr_c0),
	.data_wr(data_wr_c0),
	// read
	.order(order_rd_c0),
	.en_rd(en_bram_rd_c0),
	.addr_rd_0(addr_rd_0_c0),
	.addr_rd_1(addr_rd_1_c0),
	.addr_rd_2(addr_rd_2_c0),
	.addr_rd_3(addr_rd_3_c0),
	.addr_rd_4(addr_rd_4_c0),
	.addr_rd_5(addr_rd_5_c0),
	.data_rd(data_bram_in_c0)
);

// channel 1
padding_fifo #(
	.DATA_WIDTH(DATA_WIDTH)
)padding_fifo_inst_c1(
	.clk(clk),
	.rst(rst_d1[4]),
	.start(start_all),
	.layer(layer_reg),
	.allzero(allzero[1]),
	
	.row_deep(row_deep),
	.block_deep(block_deep),
	.loop_deep(loop_deep),
	.tile_deep(tile_deep),
	
	//(S_AXIS) INPUT  CHANNEL
	.S_AXIS_TVALID(S_AXIS_TVALID_C1),
	.S_AXIS_TREADY(S_AXIS_TREADY_C1),
	.S_AXIS_TDATA(S_AXIS_TDATA_C1),
	.S_AXIS_TLAST(S_AXIS_TLAST_C1),
	//(M_AXIS) OUTPUT CHANNEL
	.M_AXIS_TVALID(m_axis_tvalid_c1),
	.M_AXIS_TREADY(m_axis_tready_c1),
	.M_AXIS_TDATA(m_axis_tdata_c1),
	.M_AXIS_TLAST(m_axis_tlast_c1)
);
data_in_write#(
	.DATA_WIDTH(DATA_WIDTH)
)data_in_write_inst_c1(
	.clk(clk),
	.rst(rst_d1[5]),
	.start(start_all),
	.layer(layer_reg),
	
	.row_deep(row_deep),
	.block_deep(block_deep),
	.loop_deep(loop_deep),
	.tile_deep(tile_deep),
	
	// 1 clk signal
	.oneslice_done(oneslice_done_wr_c1),   // reserved signal
	
	//(S_AXIS) INPUT  CHANNEL 0
    .S_AXIS_TVALID(m_axis_tvalid_c1),
	.S_AXIS_TREADY(m_axis_tready_c1),
	.S_AXIS_TDATA(m_axis_tdata_c1),
	.S_AXIS_TLAST(m_axis_tlast_c1),

	//(BRAM) DATA OUT
	.en_wr(en_wr_c1),
	.addr_wr(addr_wr_c1),
	.data_wr(data_wr_c1)
);
data_in_read#(
	.DATA_WIDTH(DATA_WIDTH)
)data_in_read_inst_c1(
	.clk(clk),
	.rst(rst_d1[6]),
	.start(start_read),
	.layer(layer_reg),
	.oneslice_wr_done(oneslice_wr_done),// input 
	.is_dma_write(is_dma_write_c1),		// output
	.read_continue(read_continue[1]),
	.read_pause(read_pause[1]),
	.is_WrFastRd_obuf(is_WrFastRd_obuf),
	
	.row_deep(row_deep),
	.block_deep(block_deep),
	.loop_deep(loop_deep),
	.tile_deep(tile_deep),
	
	.order_rd(order_rd_c1),		 // output
	.en_bram_rd(en_bram_rd_c1),  // output
	.addr_rd_0(addr_rd_0_c1),       // output
	.addr_rd_1(addr_rd_1_c1),		 // output
	.addr_rd_2(addr_rd_2_c1),       // output
	.addr_rd_3(addr_rd_3_c1),       // output
	.addr_rd_4(addr_rd_4_c1),       // output
	.addr_rd_5(addr_rd_5_c1),       // output
	.data_bram_in(data_bram_in_c1), // input 
	
	.en_out(en_out_c1),		     // output
	.data_out(data_out_c1)          // output
);
one_channel_bram#(
	.DATA_WIDTH(DATA_WIDTH)
)one_channel_bram_inst_c1(
	.clk(clk),
	// write
	.en_wr(en_wr_c1),
	.addr_wr(addr_wr_c1),
	.data_wr(data_wr_c1),
	// read
	.order(order_rd_c1),
	.en_rd(en_bram_rd_c1),
	.addr_rd_0(addr_rd_0_c1),
	.addr_rd_1(addr_rd_1_c1),
	.addr_rd_2(addr_rd_2_c1),
	.addr_rd_3(addr_rd_3_c1),
	.addr_rd_4(addr_rd_4_c1),
	.addr_rd_5(addr_rd_5_c1),
	.data_rd(data_bram_in_c1)
);

// channel 2
padding_fifo #(
	.DATA_WIDTH(DATA_WIDTH)
)padding_fifo_inst_c2(
	.clk(clk),
	.rst(rst_d1[7]),
	.start(start_all),
	.layer(layer_reg),
	.allzero(allzero[2]),
	
	.row_deep(row_deep),
	.block_deep(block_deep),
	.loop_deep(loop_deep),
	.tile_deep(tile_deep),
	
	//(S_AXIS) INPUT  CHANNEL
	.S_AXIS_TVALID(S_AXIS_TVALID_C2),
	.S_AXIS_TREADY(S_AXIS_TREADY_C2),
	.S_AXIS_TDATA(S_AXIS_TDATA_C2),
	.S_AXIS_TLAST(S_AXIS_TLAST_C2),
	//(M_AXIS) OUTPUT CHANNEL
	.M_AXIS_TVALID(m_axis_tvalid_c2),
	.M_AXIS_TREADY(m_axis_tready_c2),
	.M_AXIS_TDATA(m_axis_tdata_c2),
	.M_AXIS_TLAST(m_axis_tlast_c2)
);
data_in_write#(
	.DATA_WIDTH(DATA_WIDTH)
)data_in_write_inst_c2(
	.clk(clk),
	.rst(rst_d1[8]),
	.start(start_all),
	.layer(layer_reg),
	
	.row_deep(row_deep),
	.block_deep(block_deep),
	.loop_deep(loop_deep),
	.tile_deep(tile_deep),
	
	// 1 clk signal
	.oneslice_done(oneslice_done_wr_c2),   // reserved signal
	
	//(S_AXIS) INPUT  CHANNEL 0
    .S_AXIS_TVALID(m_axis_tvalid_c2),
	.S_AXIS_TREADY(m_axis_tready_c2),
	.S_AXIS_TDATA(m_axis_tdata_c2),
	.S_AXIS_TLAST(m_axis_tlast_c2),

	//(BRAM) DATA OUT
	.en_wr(en_wr_c2),
	.addr_wr(addr_wr_c2),
	.data_wr(data_wr_c2)
);
data_in_read#(
	.DATA_WIDTH(DATA_WIDTH)
)data_in_read_inst_c2(
	.clk(clk),
	.rst(rst_d1[9]),
	.start(start_read),
	.layer(layer_reg),
	.oneslice_wr_done(oneslice_wr_done),// input 
	.is_dma_write(is_dma_write_c2),		// output
	.read_continue(read_continue[2]),
	.read_pause(read_pause[2]),
	.is_WrFastRd_obuf(is_WrFastRd_obuf),
	
	.row_deep(row_deep),
	.block_deep(block_deep),
	.loop_deep(loop_deep),
	.tile_deep(tile_deep),
	
	.order_rd(order_rd_c2),		 // output
	.en_bram_rd(en_bram_rd_c2),  // output
	.addr_rd_0(addr_rd_0_c2),       // output
	.addr_rd_1(addr_rd_1_c2),		 // output
	.addr_rd_2(addr_rd_2_c2),       // output
	.addr_rd_3(addr_rd_3_c2),       // output
	.addr_rd_4(addr_rd_4_c2),       // output
	.addr_rd_5(addr_rd_5_c2),       // output
	.data_bram_in(data_bram_in_c2), // input 
	
	.en_out(en_out_c2),		     // output
	.data_out(data_out_c2)          // output
);
one_channel_bram#(
	.DATA_WIDTH(DATA_WIDTH)
)one_channel_bram_inst_c2(
	.clk(clk),
	// write
	.en_wr(en_wr_c2),
	.addr_wr(addr_wr_c2),
	.data_wr(data_wr_c2),
	// read
	.order(order_rd_c2),
	.en_rd(en_bram_rd_c2),
	.addr_rd_0(addr_rd_0_c2),
	.addr_rd_1(addr_rd_1_c2),
	.addr_rd_2(addr_rd_2_c2),
	.addr_rd_3(addr_rd_3_c2),
	.addr_rd_4(addr_rd_4_c2),
	.addr_rd_5(addr_rd_5_c2),
	.data_rd(data_bram_in_c2)
);

// channel 3
padding_fifo #(
	.DATA_WIDTH(DATA_WIDTH)
)padding_fifo_inst_c3(
	.clk(clk),
	.rst(rst_d1[10]),
	.start(start_all),
	.layer(layer_reg),
	.allzero(allzero[3]),
	
	.row_deep(row_deep),
	.block_deep(block_deep),
	.loop_deep(loop_deep),
	.tile_deep(tile_deep),
	
	//(S_AXIS) INPUT  CHANNEL
	.S_AXIS_TVALID(S_AXIS_TVALID_C3),
	.S_AXIS_TREADY(S_AXIS_TREADY_C3),
	.S_AXIS_TDATA(S_AXIS_TDATA_C3),
	.S_AXIS_TLAST(S_AXIS_TLAST_C3),
	//(M_AXIS) OUTPUT CHANNEL
	.M_AXIS_TVALID(m_axis_tvalid_c3),
	.M_AXIS_TREADY(m_axis_tready_c3),
	.M_AXIS_TDATA(m_axis_tdata_c3),
	.M_AXIS_TLAST(m_axis_tlast_c3)
);
data_in_write#(
	.DATA_WIDTH(DATA_WIDTH)
)data_in_write_inst_c3(
	.clk(clk),
	.rst(rst_d1[11]),
	.start(start_all),
	.layer(layer_reg),
	
	.row_deep(row_deep),
	.block_deep(block_deep),
	.loop_deep(loop_deep),
	.tile_deep(tile_deep),
	
	// 1 clk signal
	.oneslice_done(oneslice_done_wr_c3),   // reserved signal
	
	//(S_AXIS) INPUT  CHANNEL 0
    .S_AXIS_TVALID(m_axis_tvalid_c3),
	.S_AXIS_TREADY(m_axis_tready_c3),
	.S_AXIS_TDATA(m_axis_tdata_c3),
	.S_AXIS_TLAST(m_axis_tlast_c3),

	//(BRAM) DATA OUT
	.en_wr(en_wr_c3),
	.addr_wr(addr_wr_c3),
	.data_wr(data_wr_c3)
);
data_in_read#(
	.DATA_WIDTH(DATA_WIDTH)
)data_in_read_inst_c3(
	.clk(clk),
	.rst(rst_d1[12]),
	.start(start_read),
	.layer(layer_reg),
	.oneslice_wr_done(oneslice_wr_done),// input 
	.is_dma_write(is_dma_write_c3),		// output
	.read_continue(read_continue[3]),
	.read_pause(read_pause[3]),
	.is_WrFastRd_obuf(is_WrFastRd_obuf),
	
	.row_deep(row_deep),
	.block_deep(block_deep),
	.loop_deep(loop_deep),
	.tile_deep(tile_deep),
	
	.order_rd(order_rd_c3),		 // output
	.en_bram_rd(en_bram_rd_c3),  // output
	.addr_rd_0(addr_rd_0_c3),       // output
	.addr_rd_1(addr_rd_1_c3),		 // output
	.addr_rd_2(addr_rd_2_c3),       // output
	.addr_rd_3(addr_rd_3_c3),       // output
	.addr_rd_4(addr_rd_4_c3),       // output
	.addr_rd_5(addr_rd_5_c3),       // output
	.data_bram_in(data_bram_in_c3), // input 
	
	.en_out(en_out_c3),		     // output
	.data_out(data_out_c3)          // output
);
one_channel_bram#(
	.DATA_WIDTH(DATA_WIDTH)
)one_channel_bram_inst_c3(
	.clk(clk),
	// write
	.en_wr(en_wr_c3),
	.addr_wr(addr_wr_c3),
	.data_wr(data_wr_c3),
	// read
	.order(order_rd_c3),
	.en_rd(en_bram_rd_c3),
	.addr_rd_0(addr_rd_0_c3),
	.addr_rd_1(addr_rd_1_c3),
	.addr_rd_2(addr_rd_2_c3),
	.addr_rd_3(addr_rd_3_c3),
	.addr_rd_4(addr_rd_4_c3),
	.addr_rd_5(addr_rd_5_c3),
	.data_rd(data_bram_in_c3)
);	


data_segment_in data_segment_in_inst(
	.clk(clk),
	.rst(rst_d1[13]),
	.start(start_read),
	.row_deep(row_deep),
	
	//DATA IN CHANNEL_0
	.en_c0(en_out_c0),
	.din_c0(data_out_c0), // 5 row
	//DATA IN CHANNEL_1
	.en_c1(en_out_c1),
	.din_c1(data_out_c1),
	//DATA IN CHANNEL_2
	.en_c2(en_out_c2),
	.din_c2(data_out_c2),
	//DATA IN CHANNEL_3
	.en_c3(en_out_c3),
	.din_c3(data_out_c3),
	
	//DATA OUT ENABLE
	.en_out(en_out),
	//DATA OUT CHANNEL_0
	.dout_c0(dout_c0),
	//DATA OUT CHANNEL_1            
	.dout_c1(dout_c1),
	//DATA OUT CHANNEL_2            
	.dout_c2(dout_c2),
	//DATA OUT CHANNEL_3            
	.dout_c3(dout_c3)
);


endmodule