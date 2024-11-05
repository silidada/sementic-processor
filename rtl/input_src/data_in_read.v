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

module data_in_read#(
	parameter   DATA_WIDTH = 64
)(
	input wire 						clk,
	input wire 						rst,
	input wire 						start,
	input wire  [2:0]				layer,
	input wire						oneslice_wr_done,   
	output reg						is_dma_write,     // trigger DMA transmission data
	output reg 						read_continue,
	output reg						read_pause,
	input wire						is_WrFastRd_obuf,
	
	input wire  [7:0]				row_deep,		  // without pad
	input wire  [5:0]				block_deep,
	input wire  [4:0]				loop_deep,
	input wire  [9:0]				tile_deep,
	
	output wire [2:0] 				order_rd,
	//output wire [5:0]				en_bram_rd,
	output wire 					en_bram_rd,
	output wire [8:0]				addr_rd_0,
	output wire [8:0]				addr_rd_1,
	output wire [8:0]				addr_rd_2,
	output wire [8:0]				addr_rd_3,
	output wire [8:0]				addr_rd_4,
	output wire [8:0]				addr_rd_5,
	input wire [DATA_WIDTH*5-1:0]	data_bram_in,
	
	output wire						en_out,
	output reg [DATA_WIDTH*5-1:0]	data_out
);
	localparam InputReuseTimes		= 3;
	localparam BaseAddrRomLy1	    = 0,	// base address in template of layer 1 
			   BaseAddrRomLy2Part0 	= 6,	// base address of part 0 in template
			   BaseAddrRomLy2Part2 	= 18,
			   BaseAddrRomLy3Part0 	= 30,
			   BaseAddrRomLy3Part4 	= 54,
			   BaseAddrRomLy4Part0 	= 78,
			   BaseAddrRomLy4Part8 	= 126;
	localparam TemplateDeepLayer1	= 5,  // 6-1	
			   TemplateDeepLayer2	= 11, // 12-1  address number in 1 part
			   TemplateDeepLayer3	= 23, // 24-1
			   TemplateDeepLayer4	= 47; // 48-1
			   
	localparam IDLE 	= 7'b000_0001,
			   CONFIG 	= 7'b000_0010,  // last 2 clk
			   INIT		= 7'b000_0100,
			   PREREAD 	= 7'b000_1000,  // last 2 clk
			   READ 	= 7'b001_0000,
			   ROWLAST 	= 7'b010_0000,  // the last data in a row
			   WAIT		= 7'b100_0000;
	reg [6:0] state_c, state_n;
	reg 		config2init;
	reg [3:0] 	init2preread;
	reg 		preread2read;
	reg 		rowlast2preread_reg; // delay 1 clk to ensure 4 clk distance
	reg 		rowlast2wait;
	wire read2rowlast, rowlast2preread, wait2preread, rowlast2idle;
	
	reg [2:0] 				layer_reg;
	reg						oneslice_wr_done_flag;
	reg						dma_write;
	reg						dma_write_flag;
	reg						is_dma_write_flag; // just usd for layer 1
	reg						is_WrFastRd_obuf_reg;
	
	reg [7:0]				ROW_DEEP_MAX;
	reg [9:0]				TILE_DEEP_MAX;	// different! the num of slices used to conv in a tile(each slice has overlap)
	reg [5:0]				BLOCK_DEEP_MAX;
	reg [4:0]				LOOP_DEEP_MAX;
	reg	[5:0]				TMPL_DEEP_MAX;	// template deep current layer
	
	// enable read bram while cnt_stage=2'd3
	reg [1:0]				cnt_stage;
	
	// rom: store order and address template
	// high->low:{{0},order[2:0],en_bram{5:0},addr_5[8:0],addr_4[8:0],addr_3[8:0],addr_2[8:0],addr_1[8:0],addr_0[8:0]}
	// order[2:0],en_bram{5:0} not use in fact
	reg						en_rom;
	reg	 					en_rom_delay;
	reg  [7:0]				base_addr_rom;
	reg	 [7:0]				addr_rom;
	wire [DATA_WIDTH-1:0]	dout_rom;
	
	// 6 bram base address
	reg [8:0]				base_addr_0,base_addr_1,base_addr_2,base_addr_3,base_addr_4,base_addr_5;
	reg [8:0]				cnt_addr_0,cnt_addr_1,cnt_addr_2,cnt_addr_3,cnt_addr_4,cnt_addr_5;
	wire					add_cnt_addr, end_cnt_addr;
	reg [2:0]				order_cur_5row;
	reg [5:0]				en_bram_cur_5row;
	
	reg 					en_rd; 		  // enable read bram 
	reg [2:0]				en_rd_delay;  // en_rd_delay[1]: data_bram_in is valuable; en_rd_delay[2]: data_out is valuable

	reg						pingpong;
	reg [1:0]				pingpong_flip;
	
	// some counters
	reg [7:0]				cnt_row_deep;
	reg [9:0]				cnt_tile_deep;
	reg [5:0]				cnt_block_deep;
	reg [4:0]				cnt_loop_deep;
	reg [5:0]				cnt_tmpl_deep;	  
	reg [1:0]				cnt_input_reuse;
	reg [1:0]				cnt_order;		  // 3 order: 001,010,100)
	wire					add_cnt_row_deep, end_cnt_row_deep;
	wire					add_cnt_tile_deep, end_cnt_tile_deep;
	wire					add_cnt_block_deep, end_cnt_block_deep;
	wire					add_cnt_loop_deep, end_cnt_loop_deep;
	wire					add_cnt_tmpl_deep, end_cnt_tmpl_deep;
	wire					add_cnt_input_reuse, end_cnt_input_reuse;
	wire					add_cnt_order, end_cnt_order;
	
	reg						end_cnt_row_deep_reg;
	
	assign addr_rd_0  =	cnt_addr_0;
	assign addr_rd_1  =	cnt_addr_1;
	assign addr_rd_2  =	cnt_addr_2;
	assign addr_rd_3  =	cnt_addr_3;
	assign addr_rd_4  =	cnt_addr_4;
	assign addr_rd_5  =	cnt_addr_5;
	
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
	
	// dma_write
	always@(posedge clk)begin
		if(rst_d1)begin
			dma_write <= 1'b0;
		end
		else if((state_c==CONFIG)&&(layer_reg != 3'd1))begin
			dma_write <= 1'b1;
		end
		else begin
			if(add_cnt_block_deep)begin
				dma_write <= 1'b1;
			end
			else if(((cnt_tile_deep==10'd5)||((cnt_tile_deep==10'd11)&&(~((cnt_block_deep==BLOCK_DEEP_MAX)&&(cnt_loop_deep==LOOP_DEEP_MAX)))))&&add_cnt_tile_deep)begin
				dma_write <= 1'b1;
			end
			else begin
				dma_write <= 1'b0;
			end
		end
	end
	// dma_write_flag
	always@(posedge clk)begin
		if((state_c==IDLE)||is_dma_write)begin
			dma_write_flag <= 1'b0;
		end
		else if(dma_write)begin
			dma_write_flag <= 1'b1;
		end
	end
	// is_dma_write
	always@(posedge clk)begin
		if(rst_d1)begin
			is_dma_write <= 1'b0;
		end
		else if(oneslice_wr_done_flag&&dma_write_flag&&(~end_cnt_loop_deep))begin
			is_dma_write <= 1'b1;
		end
		else begin
			is_dma_write <= 1'b0;
		end
	end
	// is_dma_write_flag
	always@(posedge clk)begin
		if(rst_d1)begin
			is_dma_write_flag <= 1'b0;
		end
		else if((is_dma_write_flag&&add_cnt_tile_deep)||(state_c==IDLE))begin
			is_dma_write_flag <= 1'b0;
		end
		else if(is_dma_write)begin
			is_dma_write_flag <= 1'b1;
		end
	end
	
	// is_WrFastRd_obuf_reg
	always@(posedge clk)begin
		if(rst_d1)begin
			is_WrFastRd_obuf_reg <= 1'b0;
		end
		else begin
			is_WrFastRd_obuf_reg <= is_WrFastRd_obuf;
		end
	end
	
	// read_continue
	always@(posedge clk)begin
		if(rst_d1)begin
			read_continue <= 1'b0;
		end
		else if(wait2preread)begin
			read_continue <= 1'b1;
		end
		else begin
			read_continue <= 1'b0;
		end
	end
	
	// read_pause
	always@(posedge clk)begin
		if(rst_d1)begin
			read_pause <= 1'b0;
		end
		else if(state_c==IDLE)begin
			read_pause <= 1'b0;
		end
		else if(rowlast2wait)begin
			read_pause <= 1'b1;
		end
		else begin
			read_pause <= 1'b0;
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
			CONFIG:begin
				if(config2init)begin
					state_n = INIT;
				end
				else begin
					state_n = CONFIG;
				end
			end
			INIT: begin
				if(init2preread[3])begin
					state_n = PREREAD;
				end
				else begin
					state_n = INIT;
				end
			end
			PREREAD:begin
				if(preread2read)begin
					state_n = READ;
				end
				else begin
					state_n = PREREAD;
				end
			end
			READ:begin
				if(read2rowlast)begin
					state_n = ROWLAST;
				end
				else begin
					state_n = READ;
				end
			end
			ROWLAST:begin
				if(rowlast2idle)begin
					state_n = IDLE;
				end
				else if(rowlast2wait)begin
					state_n = WAIT;
				end
				else if(rowlast2preread_reg)begin
					state_n = PREREAD;
				end
				else begin
					state_n = ROWLAST;
				end
			end
			WAIT:begin
				if(wait2preread)begin
					state_n = PREREAD;
				end
				else begin
					state_n = WAIT;
				end
			end
			default: state_n = IDLE;
		endcase
	end
	// config2init
	always@(posedge clk)begin
		if((~config2init)&&(state_c==CONFIG))begin
			config2init <= 1'b1;
		end
		else begin
			config2init <= 1'b0;
		end
	end
	// init2preread
	always@(posedge clk)begin
		if(state_c == CONFIG)begin
			init2preread[0] <= 1'b1;
		end
		else begin
			init2preread[0] <= 1'b0;
		end
	end
	always@(posedge clk)begin
		init2preread[1] <= init2preread[0];
		init2preread[2] <= init2preread[1];
		init2preread[3] <= init2preread[2];
	end
	// preread2read
	always@(posedge clk)begin
		if(state_c==PREREAD)begin
			preread2read <= 1'b1;
		end
		else begin
			preread2read <= 1'b0;
		end
	end
	// rowlast2preread_reg
	always@(posedge clk)begin
		if(rowlast2preread)begin
			rowlast2preread_reg <= 1'b1;
		end
		else begin
			rowlast2preread_reg <= 1'b0;
		end
	end
	// rowlast2wait
	always@(posedge clk)begin
		if((state_c==ROWLAST)&&end_cnt_row_deep&&((~oneslice_wr_done_flag)||is_WrFastRd_obuf_reg))begin
			if((cnt_tile_deep==10'd3)||(cnt_tile_deep==10'd9)||(cnt_tile_deep==10'd14))begin
				rowlast2wait <= 1'b1;
			end
			else begin
				rowlast2wait <= 1'b0;
			end
		end
		else begin
			rowlast2wait <= 1'b0;
		end
	end
	assign read2rowlast 	= (state_c==READ)&&(cnt_row_deep==ROW_DEEP_MAX);
	assign rowlast2preread 	= (state_c==ROWLAST)&&end_cnt_row_deep_reg&&(cnt_stage==2'd3);
	assign wait2preread		= (state_c==WAIT)&&oneslice_wr_done_flag&&(~is_WrFastRd_obuf_reg);
	assign rowlast2idle		= (state_c==ROWLAST)&&end_cnt_loop_deep;
	
	// layer_reg
	always@(posedge clk)begin
		if(rst_d1)begin
			layer_reg <= 'd0;
		end
		else if(start&&(state_c == IDLE))begin
			layer_reg <= layer;
		end
	end
	
	// oneslice_wr_done_flag
	always@(posedge clk)begin
		if(rst_d1)begin
			oneslice_wr_done_flag <= 1'b0;
		end
		else if(rowlast2idle)begin
			oneslice_wr_done_flag <= 1'b0;
		end
		else if(is_dma_write)begin
			oneslice_wr_done_flag <= 1'b0;
		end
		else if(oneslice_wr_done)begin
			oneslice_wr_done_flag <= 1'b1;
		end
	end
	
	//================== config hyperparam ================== 
	// ROW/BLOCK/LOOP_DEEP_MAX constant
	always@(posedge clk)begin
		if(rst_d1)begin
			ROW_DEEP_MAX 	<= 'd0;
			BLOCK_DEEP_MAX 	<= 'd0;
			LOOP_DEEP_MAX 	<= 'd0;
			TILE_DEEP_MAX   <= 10'd0;
		end
		else if(state_c == CONFIG)begin
			ROW_DEEP_MAX 	 <= row_deep;
			BLOCK_DEEP_MAX 	 <= block_deep 	- 1'b1;
			LOOP_DEEP_MAX 	 <= loop_deep	- 1'b1;
			TILE_DEEP_MAX 	 <= tile_deep;
		end
	end
	// TMPL_DEEP_MAX
	always@(posedge clk)begin
		if(rst_d1)begin
			TMPL_DEEP_MAX <= 6'd0;
		end
		else begin
			case(layer_reg)
				3'd1: TMPL_DEEP_MAX <= TemplateDeepLayer1;
				3'd2: TMPL_DEEP_MAX <= TemplateDeepLayer2;
				3'd3: TMPL_DEEP_MAX <= TemplateDeepLayer3;
				3'd4: TMPL_DEEP_MAX <= TemplateDeepLayer4;
				default: TMPL_DEEP_MAX <= 6'd0;
			endcase
		end
	end

	// base_addr_rom
	always@(posedge clk)begin
		if(rst_d1)begin
			base_addr_rom <= 8'd0;
		end
		else begin
			case(layer_reg)
				3'd1: base_addr_rom <= BaseAddrRomLy1;
				3'd2: begin
					case(pingpong) // cnt_bram_part
						1'b0: base_addr_rom <= BaseAddrRomLy2Part0;
						1'b1: base_addr_rom <= BaseAddrRomLy2Part2;
						default: base_addr_rom <= 8'd0;
					endcase
				end
				3'd3: begin
					case(pingpong)
						1'b0: base_addr_rom <= BaseAddrRomLy3Part0;
						1'b1: base_addr_rom <= BaseAddrRomLy3Part4;
						default: base_addr_rom <= 8'd0;						
					endcase
				end
				3'd4: begin
					case(pingpong)
						1'b0: base_addr_rom <= BaseAddrRomLy4Part0;
						1'b1: base_addr_rom <= BaseAddrRomLy4Part8;
						default: base_addr_rom <= 8'd0;	
					endcase
				end
				default: base_addr_rom <= 8'd0;
			endcase
		end
	end
	// en_rom
	always@(posedge clk)begin
		if(rst_d1)begin
			en_rom <= 1'b0;
		end
		else if((config2init)||(read2rowlast&&(cnt_input_reuse==InputReuseTimes)))begin 
			en_rom <= 1'b1;
		end
		else begin
			en_rom <= 1'b0;
		end
	end
	// addr_rom
	always@(posedge clk)begin
		if(rst_d1)begin
			addr_rom <= 8'd0;
		end
		else begin
			if((state_c==CONFIG)||end_cnt_tmpl_deep||pingpong_flip[1])begin
				addr_rom <= base_addr_rom;
			end
			else if(add_cnt_tmpl_deep)begin
				addr_rom <= addr_rom + 1'b1;
			end
		end
	end
	// en_rom_delay
	always@(posedge clk)begin
		if(rst_d1)begin
			en_rom_delay <= 1'b0;
		end
		else if(en_rom)begin
			en_rom_delay <= 1'd1;
		end
		else begin
			en_rom_delay <= 1'b0;
		end
	end
	// base_addr_0/1/2/3/4/5
	always@(posedge clk)begin
		if(rst_d1)begin
			base_addr_0 <= 9'd0;
			base_addr_1 <= 9'd0;
			base_addr_2 <= 9'd0;
			base_addr_3 <= 9'd0;
			base_addr_4 <= 9'd0;
			base_addr_5 <= 9'd0;
		end
		else if(en_rom_delay)begin
			base_addr_0	<= dout_rom[8 : 0];
			base_addr_1	<= dout_rom[17: 9];
			base_addr_2	<= dout_rom[26:18];
			base_addr_3	<= dout_rom[35:27];
			base_addr_4	<= dout_rom[44:36];
			base_addr_5	<= dout_rom[53:45];
		end
	end
	
	// cnt_stage
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_stage <= 2'd0;
		end
		else if((state_c==READ)||(state_c==ROWLAST)||end_cnt_row_deep_reg)begin
			cnt_stage <= cnt_stage + 1'b1;
		end
		else begin
			cnt_stage <= 2'd0;
		end
	end
	
	// order_cur_5row
	always@(posedge clk)begin
		if(rst_d1)begin
			order_cur_5row <= 3'b001;
		end
		else begin
			if(end_cnt_tile_deep)begin
				order_cur_5row <= 3'b001;
			end
			else if(end_cnt_input_reuse)begin
				order_cur_5row <= {order_cur_5row[1:0],order_cur_5row[2]};
			end
		end
	end
	assign order_rd	= order_cur_5row;
	
	// en_rd
	always@(posedge clk)begin
		if(rst_d1)begin
			en_rd <= 1'b0;
		end
		else if(state_c==PREREAD)begin
			en_rd <= 1'b1;
		end
		else if(((state_c==READ)||(state_c==ROWLAST))&&(cnt_stage==2'd3)&&(~end_cnt_row_deep_reg))begin
			en_rd <= 1'b1;
		end
		else begin
			en_rd <= 6'd0;
		end
	end
	assign en_bram_rd = en_rd;
	
	// en_rd_delay
	always@(posedge clk)begin
		if(en_rd)begin
			en_rd_delay[0] <= 1'b1; 
		end
		else begin
			en_rd_delay[0] <= 1'b0; 
		end
	end
	always@(posedge clk)begin
		en_rd_delay[1] <= en_rd_delay[0];
		en_rd_delay[2] <= en_rd_delay[1];
	end
	
	// data_out
	always@(posedge clk)begin
		if(en_rd_delay[1])begin
			data_out <= data_bram_in;
		end
		else begin
			data_out <= data_out;
		end
	end
	assign en_out = en_rd_delay[2];
	
	// cnt_addr_0/1/2/3/4/5
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_addr_0 <= 9'd0;
		end
		else begin
			if(end_cnt_addr)begin
				cnt_addr_0 <= base_addr_0;
			end
			else if(add_cnt_addr)begin
				cnt_addr_0 <= cnt_addr_0 + 1'b1;
			end
		end
	end
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_addr_1 <= 9'd0;
		end
		else begin
			if(end_cnt_addr)begin
				cnt_addr_1 <= base_addr_1;
			end
			else if(add_cnt_addr)begin
				cnt_addr_1 <= cnt_addr_1 + 1'b1;
			end
		end
	end
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_addr_2 <= 9'd0;
		end
		else begin
			if(end_cnt_addr)begin
				cnt_addr_2 <= base_addr_2;
			end
			else if(add_cnt_addr)begin
				cnt_addr_2 <= cnt_addr_2 + 1'b1;
			end
		end
	end
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_addr_3 <= 9'd0;
		end
		else begin
			if(end_cnt_addr)begin
				cnt_addr_3 <= base_addr_3;
			end
			else if(add_cnt_addr)begin
				cnt_addr_3 <= cnt_addr_3 + 1'b1;
			end
		end
	end
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_addr_4 <= 9'd0;
		end
		else begin
			if(end_cnt_addr)begin
				cnt_addr_4 <= base_addr_4;
			end
			else if(add_cnt_addr)begin
				cnt_addr_4 <= cnt_addr_4 + 1'b1;
			end
		end
	end
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_addr_5 <= 9'd0;
		end
		else begin
			if(end_cnt_addr)begin
				cnt_addr_5 <= base_addr_5;
			end
			else if(add_cnt_addr)begin
				cnt_addr_5 <= cnt_addr_5 + 1'b1;
			end
		end
	end
	assign add_cnt_addr = en_bram_rd;
	assign end_cnt_addr = end_cnt_row_deep||init2preread[2];
	
	// cnt_tmpl_deep
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_tmpl_deep <= 6'd0;
		end
		else if(state_c==IDLE)begin
			cnt_tmpl_deep <= 6'd0;
		end
		else begin
			if(end_cnt_tmpl_deep||pingpong_flip[0])begin
				cnt_tmpl_deep <= 6'd0;
			end
			else if(add_cnt_tmpl_deep)begin
				cnt_tmpl_deep <= cnt_tmpl_deep + 1'b1;
			end
		end
	end
	assign add_cnt_tmpl_deep = en_rom;
	assign end_cnt_tmpl_deep = ((cnt_tmpl_deep==TMPL_DEEP_MAX)&&add_cnt_tmpl_deep);
	
	// pingpong
	always@(posedge clk)begin
		if(rst_d1)begin
			pingpong <= 1'b0;
		end
		else if(state_c == IDLE)begin
			pingpong <= 1'b0;
		end
		else if((cnt_tile_deep==(TILE_DEEP_MAX-1))&&en_rom)begin
			pingpong <= ~pingpong;
		end
	end
	// pingpong_flip
	always@(posedge clk)begin
		if((cnt_tile_deep==(TILE_DEEP_MAX-1))&&en_rom)begin
			pingpong_flip[0] <= 1'b1;
		end
		else begin
			pingpong_flip[0] <= 1'b0;
		end
	end
	always@(posedge clk)begin
		pingpong_flip[1] <= pingpong_flip[0];
	end	
	
	// cnt_order
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_order <= 2'd0;
		end
		else begin
			if(end_cnt_order)begin
				cnt_order <= 2'd0;
			end
			else if(add_cnt_order)begin
				cnt_order <= cnt_order + 1'b1;
			end
		end
	end
	assign add_cnt_order = en_rom_delay;
	assign end_cnt_order = ((cnt_order==2'd3)&&en_rom)||add_cnt_block_deep;  // one tile end reset cnt_order
	
	// cnt_row_deep
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_row_deep <= 'd0;
		end
		else begin
			if(end_cnt_row_deep)begin
				cnt_row_deep <= 'd0;
			end
			else if(add_cnt_row_deep)begin
				cnt_row_deep <= cnt_row_deep + 1'b1;
			end
		end
	end
	assign add_cnt_row_deep = en_bram_rd;
	assign end_cnt_row_deep = (cnt_row_deep==ROW_DEEP_MAX)&&add_cnt_row_deep;

	// end_cnt_row_deep_reg
	always@(posedge clk)begin
		if(rst_d1)begin
			end_cnt_row_deep_reg <= 1'b0;
		end
		else if(state_c==PREREAD)begin
			end_cnt_row_deep_reg <= 1'b0;
		end
		else if(end_cnt_row_deep)begin
			end_cnt_row_deep_reg <= 1'b1;
		end
	end
	
	// cnt_input_reuse
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_input_reuse <= 2'd0;
		end
		else begin
			if(end_cnt_input_reuse)begin
				cnt_input_reuse <= 2'd0;
			end
			else if(add_cnt_input_reuse)begin
				cnt_input_reuse <= cnt_input_reuse + 1'b1;
			end
		end
	end
	assign add_cnt_input_reuse = end_cnt_row_deep;
	assign end_cnt_input_reuse = (cnt_input_reuse==InputReuseTimes)&&add_cnt_input_reuse;

	// cnt_tile_deep
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_tile_deep <= 'd0;
		end
		else begin
			if(end_cnt_tile_deep)begin
				cnt_tile_deep <= 'd0;
			end
			else if(add_cnt_tile_deep)begin
				cnt_tile_deep <= cnt_tile_deep + 1'b1;
			end
		end
	end
	assign add_cnt_tile_deep = end_cnt_input_reuse;
	assign end_cnt_tile_deep = (cnt_tile_deep==TILE_DEEP_MAX)&&add_cnt_tile_deep;
	
	// cnt_block_deep
	always@(posedge clk)begin
		if(rst_d1)begin
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
	assign add_cnt_block_deep = end_cnt_tile_deep;
	assign end_cnt_block_deep = (cnt_block_deep==BLOCK_DEEP_MAX)&&add_cnt_block_deep;
	
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
	assign add_cnt_loop_deep = end_cnt_block_deep;
	assign end_cnt_loop_deep = (cnt_loop_deep==LOOP_DEEP_MAX)&&add_cnt_loop_deep;


	Data_in_addr_template_lut Data_in_addr_template_inst(
		.clk(clk),
		.en(en_rom),
		.addr(addr_rom),
		.dout(dout_rom)
	);
endmodule