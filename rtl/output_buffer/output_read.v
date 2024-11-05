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


module output_read#(
	parameter DATA_WIDTH_I = 8,
	parameter DATA_WIDTH_U = 64,
	parameter DATA_WIDTH_O = 64,
	parameter ADDR_WIDTH   = 12
)(
	input wire 					    clk,
	input wire 					    rst,
	input wire 					    start,
	input wire [2:0]			    layer,
	input wire 						next_batch,
	output reg						onebatch_done,
	output reg						onetranstime_done,
	output reg						read_done,

	output reg 						en_rd,
	output reg [ADDR_WIDTH-1:0]		addr_rd,
	
	input wire [DATA_WIDTH_U-1:0]	din_b0,din_b1,
	input wire [DATA_WIDTH_U-1:0]	din_b2,din_b3,
	input wire [DATA_WIDTH_U-1:0]	din_b4,din_b5,
	input wire [DATA_WIDTH_U-1:0]	din_b6,din_b7,
	
	input wire						m_axis_tready,
	output reg						m_axis_tvalid,
	output wire	[DATA_WIDTH_O-1:0]	m_axis_tdata,
	output reg						m_axis_tlast
);
	localparam InputReuseTimes = 3;	
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
	
	parameter IDLE 	 = 5'b0_0001,
              CONFIG = 5'b0_0010,
			  WAIT   = 5'b0_0100,
			  LOAD   = 5'b0_1000,
			  WORK   = 5'b1_0000;
	reg [4:0]	state_c, state_n;
	reg [2:0]	layer_reg;
	
	reg								next_batch_dl;
	
	reg [6:0]						WIDTH_OUT;
	reg [6:0]						HEIGHT_OUT;
	reg [7:0]						LOOP_DEEP;
	reg [1:0]						TransferTimes;
	
	reg [6:0]						cnt_width_rd;
	reg [6:0]						cnt_height_rd;
	reg [6:0]						cnt_width_out;
	reg [6:0]						cnt_height_out;
	reg [1:0]   					cnt_reuse;
	reg [7:0]						cnt_loop_deep;
	reg [1:0]   					cnt_trans_times;
	wire							add_cnt_width_rd, end_cnt_width_rd;
	wire							add_cnt_height_rd, end_cnt_height_rd;
	wire							add_cnt_width_out, end_cnt_width_out;
	wire							add_cnt_height_out, end_cnt_height_out;
	wire        					add_cnt_reuse, end_cnt_reuse;
	wire							add_cnt_loop_deep, end_cnt_loop_deep;	
	wire        					add_cnt_trans_times, end_cnt_trans_times;
	reg 							end_cnt_height_rd_reg;
	
	reg 							pingpong;
	reg [2:0]						ram_idx;
	reg [1:0]						en_rd_dl;
	reg [ADDR_WIDTH-1:0]			base_addr;
	
	// fifo_outbuf
	reg								fifo_wr;
	reg [3:0]						cnt_fifo_wr;
	reg [DATA_WIDTH_O-1:0]			fifo_din;
	reg								fifo_rd;
	reg	[1:0]						fifo_rd_dl;
	wire [DATA_WIDTH_O-1:0]			fifo_dout;
	reg [DATA_WIDTH_O-1:0]			fifo_dout_reg[0:1];
	wire							fifo_empty;
	wire							fifo_full;
	wire							fifo_prog_full;
	wire 							wr_rst_busy,rd_rst_busy;
	
	reg [2:0]						en_load;
	reg 							en_fifo_rd_flag;
	reg								en_send_out;
	
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
	
	// onebatch_done
	always@(posedge clk)begin
		if(rst_d1)begin
			onebatch_done <= 1'b0;
		end
		else if(m_axis_tlast&&m_axis_tvalid&&m_axis_tready)begin
			onebatch_done <= 1'b1;
		end
		else begin
			onebatch_done <= 1'b0;
		end
	end
	// onetranstime_done
	always@(posedge clk)begin
		if(rst_d1)begin
			onetranstime_done <= 1'b0;
		end
		else if(add_cnt_trans_times)begin
			onetranstime_done <= 1'b1;
		end
		else begin
			onetranstime_done <= 1'b0;
		end
	end
	// read_done
	always@(posedge clk)begin
		if(rst_d1)begin
			read_done <= 1'b0;
		end
		else if(end_cnt_trans_times)begin
			read_done <= 1'b1;
		end
		else begin
			read_done <= 1'b0;
		end
	end
	
	
	// next_batch_dl
	always@(posedge clk)begin
		if(rst_d1)begin
			next_batch_dl <= 1'b0;
		end
		else begin
			next_batch_dl <= next_batch;
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
				state_n = WAIT;
			end
			WAIT: begin
				if(end_cnt_trans_times)begin
					state_n = IDLE;
				end
				else if(next_batch_dl)begin
					state_n = LOAD;
				end
				else begin
					state_n = WAIT;
				end
			end
			LOAD: begin
				if(en_load[1])begin
					state_n = WORK;
				end
				else begin
					state_n = LOAD;
				end
			end
			WORK: begin
				if(end_cnt_height_rd)begin
					state_n = WAIT;
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
			TransferTimes <= 'd3;  // 4-1
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
	
	// base_addr
	always@(posedge clk)begin
		if(rst_d1)begin
			base_addr <= 'd0;
		end
		else if(state_c==WAIT)begin
			case(pingpong)
				1'b0: begin
					case(cnt_reuse)
						2'd0: base_addr <= BaseAddrPart0;
						2'd1: base_addr <= BaseAddrPart1;
						2'd2: base_addr <= BaseAddrPart2;
						2'd3: base_addr <= BaseAddrPart3;
						default: base_addr <= 'd0;
					endcase
				end
				1'b1: begin
					case(cnt_reuse)
						2'd0: base_addr <= BaseAddrPart4;
						2'd1: base_addr <= BaseAddrPart5;
						2'd2: base_addr <= BaseAddrPart6;
						2'd3: base_addr <= BaseAddrPart7;
						default: base_addr <= 'd0;
					endcase
				end
				default: base_addr <= 'd0;
			endcase
		end
	end
	
	// addr_rd
	always@(posedge clk)begin
		if(rst_d1)begin
			addr_rd <= 'd0;
		end
		else if(state_c==WAIT)begin
			addr_rd <= base_addr;
		end
		else if(en_rd)begin
			addr_rd <= addr_rd + 1'b1;
		end
	end
	
	// en_rd
	always@(posedge clk)begin
		if(rst_d1)begin
			en_rd <= 1'b0;
		end
		else if(end_cnt_height_rd||end_cnt_height_rd_reg||fifo_prog_full)begin
			en_rd <= 1'b0;
		end
		else if((state_c==LOAD)||(state_c==WORK))begin
			en_rd <= 1'b1;
		end
		else begin
			en_rd <= 1'b0;
		end
	end
	// en_rd_dl
	always@(posedge clk)begin
		if(rst_d1)begin
			en_rd_dl <= 'd0;
		end
		else begin
			en_rd_dl <= {en_rd_dl[0], en_rd};
		end
	end
	

// ============ fifo ===========
	// fifo_wr
	always@(posedge clk)begin
		if(rst_d1)begin
			fifo_wr <= 1'b0;
		end
		else begin
			fifo_wr <= en_rd_dl[1];
		end
	end
	
	// cnt_fifo_wr
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_fifo_wr <= 'd0;
		end
		else if(en_fifo_rd_flag)begin
			cnt_fifo_wr <= 'd0;
		end
		else if((~en_fifo_rd_flag)&&fifo_wr)begin
			cnt_fifo_wr <= cnt_fifo_wr + 1'b1;
		end
	end
	
	// en_fifo_rd_flag
	always@(posedge clk)begin
		if(rst_d1)begin
			en_fifo_rd_flag <= 1'b0;
		end
		else if(fifo_empty||end_cnt_height_out)begin
			en_fifo_rd_flag <= 1'b0;
		end
		else if((cnt_fifo_wr==4'b1111)||end_cnt_height_rd)begin
			en_fifo_rd_flag <= 1'b1;
		end
	end
	
	// en_send_out
	always@(posedge clk)begin
		if(rst_d1)begin
			en_send_out <= 1'b0;
		end
		else if(end_cnt_height_out)begin
			en_send_out <= 1'b0;
		end
		else if(en_load[1])begin
			en_send_out <= 1'b1;
		end
	end
	
	// fifo_din
	always@(posedge clk)begin
		if(rst_d1)begin
			fifo_din <= 'd0;
		end
		else if(en_rd_dl[1])begin
			case(ram_idx)
				3'd0: fifo_din <= din_b0[71:8];
				3'd1: fifo_din <= din_b1[71:8];
				3'd2: fifo_din <= din_b2[71:8];
				3'd3: fifo_din <= din_b3[71:8];
				3'd4: fifo_din <= din_b4[71:8];
				3'd5: fifo_din <= din_b5[71:8];
				3'd6: fifo_din <= din_b6[71:8];
				3'd7: fifo_din <= din_b7[71:8];
				default: fifo_din <= 'd0;
			endcase
		end
		else begin
			fifo_din <= fifo_din;
		end
	end

	// fifo_rd
	always@(*)begin
		if(rst_d1)begin
			fifo_rd <= 1'b0;
		end
		else if(((state_c==LOAD)&&en_fifo_rd_flag&&(~en_load[2]))||(m_axis_tready&&m_axis_tvalid))begin
			fifo_rd <= 1'b1;
		end
		else begin
			fifo_rd <= 1'b0;
		end
	end
	// fifo_rd_dl
	always@(posedge clk)begin
		if(rst_d1)begin
			fifo_rd_dl <= 'd0;
		end
		else begin
			fifo_rd_dl <= {fifo_rd_dl[0], fifo_rd};
		end
	end
	
	// en_load
	always@(posedge clk)begin
		if(rst_d1)begin
			en_load <= 'd0;
		end
		else if(state_c==LOAD)begin
			en_load <= {en_load[1:0], fifo_rd};
		end
		else begin
			en_load <= 'd0;
		end
	end
	
	// fifo_dout_reg
	always@(posedge clk)begin
		if(rst_d1)begin
			fifo_dout_reg[0] <= 'd0;
		end
		else if(((state_c==LOAD)&&en_load[0])||m_axis_tready&&m_axis_tvalid)begin
			fifo_dout_reg[0] <= fifo_dout; 
		end
	end
	always@(posedge clk)begin
		if(rst_d1)begin
			fifo_dout_reg[1] <= 'd0;
		end
		else if(((state_c==LOAD)&&en_load[0])||m_axis_tready&&m_axis_tvalid)begin
			fifo_dout_reg[1] <= fifo_dout_reg[0]; 
		end
	end
	assign m_axis_tdata = fifo_dout_reg[1];
	
	// m_axis_tvalid
	always@(posedge clk)begin
		if(rst_d1)begin
			m_axis_tvalid <= 1'b0;
		end
		else if(m_axis_tlast&&m_axis_tvalid&&m_axis_tready)begin
			m_axis_tvalid <= 1'b0;
		end
		else if(en_send_out)begin
			m_axis_tvalid <= 1'b1;
		end
		else begin
			m_axis_tvalid <= 1'b0;
		end
	end
	
	// m_axis_tlast
	always@(posedge clk)begin
		if(rst_d1)begin
			m_axis_tlast <= 1'b0;
		end
		else if(m_axis_tlast&&m_axis_tvalid&&m_axis_tready)begin
			m_axis_tlast <= 1'b0;
		end
		else if((cnt_height_out==HEIGHT_OUT)&&(cnt_width_out==(WIDTH_OUT-1))&&add_cnt_width_out)begin
			m_axis_tlast <= 1'b1;
		end
	end
	
	// ram_idx
	always@(posedge clk)begin
		if(rst_d1)begin
			ram_idx <= 'd0;
		end
		else begin
			if((ram_idx==3'd7)&&end_cnt_height_out)begin
				ram_idx <= 'd0;
			end
			else if(end_cnt_height_out)begin
				ram_idx <= ram_idx + 1'b1;
			end
		end
	end
	
	// cnt_width_rd
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_width_rd <= 'd0;
		end
		else begin
			if(end_cnt_width_rd)begin
				cnt_width_rd <= 'd0;
			end
			else if(add_cnt_width_rd)begin
				cnt_width_rd <= cnt_width_rd + 1'b1;
			end
		end
	end
	assign add_cnt_width_rd = en_rd;
	assign end_cnt_width_rd = (cnt_width_rd==WIDTH_OUT)&&add_cnt_width_rd;
	
	// cnt_height_rd
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_height_rd <= 'd0;
		end
		else begin
			if(end_cnt_height_rd)begin
				cnt_height_rd <= 'd0;
			end
			else if(add_cnt_height_rd)begin
				cnt_height_rd <= cnt_height_rd + 1'b1;
			end
		end
	end
	assign add_cnt_height_rd = end_cnt_width_rd;
	assign end_cnt_height_rd = (cnt_height_rd==HEIGHT_OUT)&&add_cnt_height_rd;
	
	// end_cnt_height_rd_reg
	always@(posedge clk)begin
		if(rst_d1)begin
			end_cnt_height_rd_reg <= 1'b0;
		end
		else if(state_c==WAIT)begin
			end_cnt_height_rd_reg <= 1'b0;
		end
		else if(end_cnt_height_rd)begin
			end_cnt_height_rd_reg <= 1'b1;
		end
	end
	
	// cnt_width_out
	always@(posedge clk)begin
		if(rst_d1)begin
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
	assign add_cnt_width_out = m_axis_tvalid&&m_axis_tready;
	assign end_cnt_width_out = (cnt_width_out==WIDTH_OUT)&&add_cnt_width_out;
	
	// cnt_height_out
	always@(posedge clk)begin
		if(rst_d1)begin
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
	assign add_cnt_height_out = end_cnt_width_out;
	assign end_cnt_height_out = (cnt_height_out==HEIGHT_OUT)&&add_cnt_height_out;
	
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
	assign add_cnt_reuse = (ram_idx==3'd7)&&end_cnt_height_out;
	assign end_cnt_reuse = (cnt_reuse==InputReuseTimes)&&add_cnt_reuse;
	
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
	assign add_cnt_loop_deep = end_cnt_reuse;
	assign end_cnt_loop_deep = (cnt_loop_deep==LOOP_DEEP)&&add_cnt_loop_deep;
	
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
	
	fifo_outbuf fifo_outbuf_inst(
		.clk(clk),
		.srst(rst_d1),
		.din(fifo_din),
		.wr_en(fifo_wr),
		.rd_en(fifo_rd),
		.dout(fifo_dout),
		.full(fifo_full),
		.empty(fifo_empty),	
		.prog_full(fifo_prog_full),
		.wr_rst_busy(wr_rst_busy),
		.rd_rst_busy(rd_rst_busy)
	);

endmodule