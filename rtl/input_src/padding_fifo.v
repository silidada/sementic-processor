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

module padding_fifo#(
	parameter   DATA_WIDTH = 64
)(
	input wire 						clk,
	input wire 						rst,
	input wire 						start,
	input wire [2:0]				layer,
	input wire						allzero,
	
	input wire [7:0]				row_deep,
	input wire [5:0]				block_deep,
	input wire [4:0]				loop_deep,
	input wire [9:0]				tile_deep,

	
	//(S_AXIS) INPUT  CHANNEL
    input  wire         			S_AXIS_TVALID,
	output wire          			S_AXIS_TREADY,
	input  wire[DATA_WIDTH-1: 0]	S_AXIS_TDATA,
	input  wire						S_AXIS_TLAST,
	//(M_AXIS) OUTPUT CHANNEL
    output wire          			M_AXIS_TVALID,
    input  wire         			M_AXIS_TREADY,
    output wire[DATA_WIDTH-1: 0]	M_AXIS_TDATA,
	output wire         			M_AXIS_TLAST
);
	localparam UPPERPAD = 4'b0001,
			   LOWERPAD = 4'b0010,
			   NORMPAD  = 4'b0100, // just pad left and right side
			   ALLZERO  = 4'b1000; 
	localparam IDLE		= 6'b00_0001,
			   CONFIG	= 6'b00_0010,
			   TRANSIT	= 6'b00_0100,
			   WAIT     = 6'b00_1000,
			   PAD		= 6'b01_0000,
			   RUN  	= 6'b10_0000; // transit state
			   
	reg [5:0] state_c, state_n;
	reg transit2wait;
	reg wait2pad, wait2run;
	wire config2transit, pad2transit, run2transit, transit2idle;
	
	reg [2:0] 				layer_reg;
	reg						allzero_reg;
	reg [3:0]				work_mod;
	
	// fifo 
	// Designed fifo as a chase game, chasers(rd) are always slower than pioneers(wr)
	wire [DATA_WIDTH-1: 0]	fifo_dout;
	reg  [DATA_WIDTH-1: 0]	fifo_dout_reg; // maybe not use
	wire 					fifo_wr_en, fifo_rd_en;
	reg						fifo_rd_en_reg;
	reg						en_fifo_rd;
	wire					wr_slice_last_data;
	reg						start_fifo_rd_pulse; // 1 clk pulse indicates that start read fifo
	reg						rd_follow_wr_flag;	// cnt_fifo_rd < cnt_fifo_wr
	reg 					rd_unfollow_wr_flag;
	wire					fifo_empty, fifo_full, fifo_prog_full;
	wire 					wr_rst_busy, rd_rst_busy;
	
	reg [3:0]				PAD_ROW_MAX;  // number of rows to be padded
	reg 					pad_done;
	reg						pad_done_flag;
	
	reg [7:0]				ROW_DEEP_MAX;
	reg [7:0]				TILE_DEEP_MAX;
	reg [5:0]				BLOCK_DEEP_MAX;
	reg [4:0]				LOOP_DEEP_MAX;
	
	reg [7:0]				cnt_row_deep;
	reg [7:0]				cnt_tile_deep;
	reg [5:0]				cnt_block_deep;
	reg [4:0]				cnt_loop_deep;
	reg [3:0]				cnt_pad_row_max;
	reg [10:0]				cnt_fifo_wr;
	reg [10:0]				cnt_fifo_rd;
	reg [10:0]				cnt_fifo_rd_add2; //pre add to ensure cnt_fifo_rd_add2 < cnt_fifo_wr;
	reg [7:0]				cnt_fifo_rd_row_deep;

	
	reg						row_last_data_pulse;
	reg 					row_last_data_pulse_reg;
	reg						rx_slice_last_data_flag; // flag for receiving the last data in a slice	
	reg						rx_last_data_lowermod;  // flag for receiving the last data in a slice when workmod == LOWERPAD
	
	wire 					add_cnt_row_deep, end_cnt_row_deep;
	reg 					end_cnt_row_deep_reg;
	wire 					add_cnt_tile_deep, end_cnt_tile_deep;
	wire 					add_cnt_block_deep, end_cnt_block_deep;
	wire 					add_cnt_loop_deep, end_cnt_loop_deep;
	wire 					add_cnt_pad_row_max, end_cnt_pad_row_max;
	wire					add_cnt_fifo_wr, end_cnt_fifo_wr;
	wire					add_cnt_fifo_rd, end_cnt_fifo_rd;
	wire					add_cnt_fifo_rd_row_deep, end_cnt_fifo_rd_row_deep;
	
	reg						s_axis_tready;
	reg						s_axis_tlast_flag;
	
	reg 					m_axis_tvalid;
	reg [DATA_WIDTH-1: 0]	m_axis_tdata;
	reg 					m_axis_tlast;
	
	wire 					en_data_out; // enable m_axis_tdata output if state_c == RUN
	
	assign S_AXIS_TREADY = s_axis_tready;
	assign M_AXIS_TVALID = m_axis_tvalid;
	assign M_AXIS_TDATA  = m_axis_tdata;
	assign M_AXIS_TLAST	 = m_axis_tlast;
	
	(* keep = "true" *)
	reg        rst_d1;
	always@(posedge clk)begin
		rst_d1 <= rst;
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
			IDLE:begin
				if(start)begin
					state_n = CONFIG;
				end
				else begin
					state_n = IDLE;
				end
			end
			CONFIG:begin
				if(config2transit)begin
					state_n = TRANSIT;
				end
				else begin
					state_n = CONFIG;
				end
			end
			TRANSIT:begin
				if(transit2idle)begin
					state_n = IDLE;
				end
				else if(transit2wait)begin
					state_n = WAIT;
				end
				else begin
					state_n = TRANSIT;
				end
			end
			WAIT: begin
				if(wait2pad)begin
					state_n = PAD;
				end
				else if(wait2run)begin
					state_n = RUN;
				end
				else begin
					state_n = WAIT;
				end
			end
			PAD: begin
				if(pad2transit)begin
					state_n = TRANSIT;
				end
				else begin
					state_n = PAD;
				end
			end
			RUN:begin
				if(run2transit)begin
					state_n = TRANSIT;
				end
				else begin
					state_n = RUN;
				end
			end
			default:begin
				state_n = IDLE;
			end
		endcase
	end
	// transit2wait
	always@(posedge clk)begin
		if(state_c==TRANSIT)begin
			transit2wait <= 1'b1;
		end
		else begin
			transit2wait <= 1'b0;
		end
	end
	// wait2pad
	always@(*)begin
		if(rst_d1)begin
			wait2pad = 1'b0;
		end
		else begin
			case(work_mod)
				ALLZERO:  wait2pad = 1'b1;
				UPPERPAD: wait2pad = (state_c == WAIT)&&(~pad_done_flag)&&S_AXIS_TVALID;
				LOWERPAD: wait2pad = (state_c == WAIT)&&(~pad_done_flag)&&(rx_last_data_lowermod);
				NORMPAD:  wait2pad = 1'b0;
				default: wait2pad = 1'b0;
			endcase
		end
	end
	// wait2run
	always@(*)begin
		if(rst_d1)begin
			wait2run = 1'b0;
		end
		else begin
			case(work_mod)
				ALLZERO:  wait2run = 1'b0;
				UPPERPAD: wait2run = (state_c == WAIT)&&pad_done_flag;
				LOWERPAD: wait2run = (state_c == WAIT)&&(~pad_done_flag)&&(~rx_last_data_lowermod);
				NORMPAD:  wait2run = (state_c == WAIT);
				default: wait2run = 1'b0;
			endcase
		end
	end
	assign config2transit = (state_c == CONFIG)&&(~wr_rst_busy);
	assign pad2transit	  = (state_c == PAD)&&(pad_done||(work_mod==ALLZERO&&add_cnt_loop_deep));
	assign run2transit 	  = (state_c == RUN)&&((m_axis_tlast||(rx_slice_last_data_flag&&(cnt_fifo_rd==cnt_fifo_wr)))&&m_axis_tvalid&&M_AXIS_TREADY);
	assign transit2idle	  = (state_c == TRANSIT)&&(cnt_loop_deep==(LOOP_DEEP_MAX+1));
	
	// layer_reg
	always@(posedge clk)begin
		if(rst_d1)begin
			layer_reg <= 'd0;
		end
		else if(start&&(state_c == IDLE))begin
			layer_reg <= layer;
		end
	end
	
	// allzero_reg
	always@(posedge clk)begin
		if(rst_d1)begin
			allzero_reg <= 'd0;
		end
		else if(start&&(state_c==IDLE))begin
			allzero_reg <= allzero;
		end
	end

	// ROW/TILE/BLOCK/LOOP_DEEP_MAX ...
	always@(posedge clk)begin
		if(rst_d1)begin
			ROW_DEEP_MAX 	<= 'd0;
			BLOCK_DEEP_MAX 	<= 'd0;
			LOOP_DEEP_MAX 	<= 'd0;
			TILE_DEEP_MAX   <= 8'd0;
		end
		else if(state_c == CONFIG)begin
			ROW_DEEP_MAX 	 <= row_deep 	- 1'b1;
			BLOCK_DEEP_MAX 	 <= block_deep 	- 1'b1;
			LOOP_DEEP_MAX 	 <= loop_deep	- 1'b1;
			TILE_DEEP_MAX 	 <= tile_deep   - 1'b1;
		end
	end
	
	// work_mod
	always@(posedge clk)begin
		if(rst_d1)begin
			work_mod <= 4'd0;
		end
		else if(state_c == TRANSIT)begin
			if(allzero_reg)begin
				work_mod <= ALLZERO;
			end
			else if((cnt_loop_deep==0)&&(cnt_tile_deep==0))begin  // block 1 and slice 1
				work_mod <= UPPERPAD;
			end
			else if((cnt_loop_deep==LOOP_DEEP_MAX)&&(cnt_tile_deep==TILE_DEEP_MAX))begin // the last block and the last slice
				work_mod <= LOWERPAD;
			end
			else begin
				work_mod <= NORMPAD;
			end
		end
	end
	
	// PAD_ROW_MAX
	always@(posedge clk)begin
		if(rst_d1)begin
			PAD_ROW_MAX <= 3'd0;
		end
		else begin
			case(work_mod)
				ALLZERO:begin
					case(layer_reg)
						'd1: PAD_ROW_MAX <= 3'd6;
						default: PAD_ROW_MAX <= 3'd0;
					endcase
				end
				UPPERPAD: PAD_ROW_MAX <= 3'd2;
				LOWERPAD: begin
					case(layer_reg)
						3'd1, 3'd2,
						3'd3: PAD_ROW_MAX <= 3'd1;
						3'd4: PAD_ROW_MAX <= 3'd2;
						default: PAD_ROW_MAX <= 3'd0;
					endcase
				end
				NORMPAD: PAD_ROW_MAX <= 3'd0;
				default: PAD_ROW_MAX <= 3'd0;
			endcase
		end
	end

	// s_axis_tlast_flag
	always@(posedge clk)begin
		if(rst_d1)begin
			s_axis_tlast_flag <= 1'b0;
		end
		else begin
			if(run2transit)begin
				s_axis_tlast_flag <= 1'b0;
			end
			else if(S_AXIS_TLAST)begin
				s_axis_tlast_flag <= 1'b1;
			end
		end
	end

	// s_axis_tready
	always@(posedge clk)begin
		if(rst_d1)begin
			s_axis_tready <= 1'b0;
		end
		else if(wr_slice_last_data||s_axis_tlast_flag)begin
			s_axis_tready <= 1'b0;
		end
		else if((~fifo_prog_full)&&(state_c==RUN))begin
			s_axis_tready <= 1'b1;
		end
		else begin
			s_axis_tready <= 1'b0;
		end
	end
	assign fifo_wr_en = s_axis_tready&&S_AXIS_TVALID;
	assign wr_slice_last_data = S_AXIS_TLAST&&S_AXIS_TVALID&&s_axis_tready;
	
	// fifo_rd_en_reg
	always@(posedge clk)begin
		if(fifo_rd_en)begin
			fifo_rd_en_reg <= 1'b1;
		end
		else begin
			fifo_rd_en_reg <= 1'b0;
		end
	end
	
	// start_fifo_rd_flag
	reg start_fifo_rd_flag;
	always@(posedge clk)begin
		if(state_c == TRANSIT)begin
			start_fifo_rd_flag <= 1'b0;
		end
		else if(start_fifo_rd_pulse)begin
			start_fifo_rd_flag <= 1'b1;
		end
	end
	
	// rd_unfollow_wr_flag
	always@(posedge clk)begin
		if(rst)begin
			rd_unfollow_wr_flag <= 1'b0;
		end
		else if(~rd_follow_wr_flag)begin
			rd_unfollow_wr_flag <= 1'b1;
		end
		else begin
			rd_unfollow_wr_flag <= 1'b0;
		end
	end
	
	// start_fifo_rd_pulse
	always@(posedge clk)begin
		if(rst_d1)begin
			start_fifo_rd_pulse <= 1'b0;
		end
		else if(((cnt_fifo_wr==5)&&add_cnt_fifo_wr)||(rd_follow_wr_flag&&rd_unfollow_wr_flag&&start_fifo_rd_flag))begin
			start_fifo_rd_pulse <= 1'b1;
		end
		else begin
			start_fifo_rd_pulse <= 1'b0;
		end
	end
	
	// cnt_fifo_rd_add2
	always@(posedge clk)begin
		if(start_fifo_rd_flag)begin
			cnt_fifo_rd_add2 <= cnt_fifo_rd + 2'd3;
		end
		else begin
			cnt_fifo_rd_add2 <= 'd0;
		end
	end
	
	// rd_follow_wr_flag
	always@(posedge clk)begin
		if(rst_d1)begin
			rd_follow_wr_flag <= 1'b0;
		end
		else if(start_fifo_rd_flag&&((cnt_fifo_rd_add2 < cnt_fifo_wr)||s_axis_tlast_flag))begin
			rd_follow_wr_flag <= 1'b1;
		end
		else begin
			rd_follow_wr_flag <= 1'b0;
		end
	end
	
	//end_cnt_row_deep_reg
	always@(posedge clk)begin
		if(end_cnt_row_deep&&state_c==RUN)begin
			end_cnt_row_deep_reg <= 1'b1;
		end
		else begin
			end_cnt_row_deep_reg <= 1'b0;
		end
	end

	// en_fifo_rd
	always@(posedge clk)begin
		if(rst_d1)begin
			en_fifo_rd <= 1'b0;
		end
		else if(run2transit||end_cnt_fifo_rd_row_deep||(~rd_follow_wr_flag))begin
			en_fifo_rd <= 1'b0;
		end
		else if(start_fifo_rd_pulse||(end_cnt_row_deep_reg&&state_c==RUN))begin
			en_fifo_rd <= 1'b1;
		end
	end
	assign fifo_rd_en = en_fifo_rd;
	
	// row_last_data_pulse; fifo read the last data in a row
	always@(posedge clk)begin
		if((cnt_fifo_rd_row_deep==ROW_DEEP_MAX)&&fifo_rd_en)begin
			row_last_data_pulse <= 1'b1;
		end
		else begin
			row_last_data_pulse <= 1'b0;
		end
	end 
	
	// row_last_data_pulse_reg
	always@(posedge clk)begin
		if(row_last_data_pulse)begin
			row_last_data_pulse_reg <= 1'b1;
		end
		else begin
			row_last_data_pulse_reg <= 1'b0;
		end
	end
	
	// fifo_dout_reg
	always@(posedge clk)begin
		if(rst_d1)begin
			fifo_dout_reg <= 'd0;
		end
		else if(fifo_rd_en_reg)begin
			fifo_dout_reg <= fifo_dout;
		end
	end
	
	// m_axis_tvalid
	always@(posedge clk)begin
		if(rst_d1)begin
			m_axis_tvalid <= 1'b0;
		end
		else if(state_c == PAD)begin
			if(pad_done||pad_done_flag||((cnt_tile_deep==TILE_DEEP_MAX)&&pad2transit))begin
				m_axis_tvalid <= 1'b0;
			end
			else begin
				m_axis_tvalid <= 1'b1;
			end
		end
		else if(state_c == RUN)begin
			if(en_data_out)begin
				m_axis_tvalid <= 1'b1;
			end
			else if(m_axis_tvalid&&M_AXIS_TREADY)begin // waiting for next data read
				m_axis_tvalid <= 1'b0;
			end
		end
		else begin
			m_axis_tvalid <= 1'b0;
		end
	end
	
	// m_axis_tdata
	always@(posedge clk)begin
		if(rst_d1)begin
			m_axis_tdata <= 'd0;
		end
		else if(state_c == PAD)begin
			m_axis_tdata <= 'd0;
		end
		else if(state_c == RUN)begin
			if(en_data_out)begin
				case(layer_reg)
					3'd1: begin
						case(cnt_row_deep)
							'd0: m_axis_tdata <= {fifo_dout[47:0], 16'd0};
							'd240: m_axis_tdata <= {48'd0, fifo_dout_reg[63:48]};
							default: m_axis_tdata <= {fifo_dout[47:0], fifo_dout_reg[63:48]};
						endcase
					end
					3'd2: begin
						case(cnt_row_deep)
							'd0: m_axis_tdata <= {fifo_dout[47:0], 16'd0};
							'd120: m_axis_tdata <= {48'd0, fifo_dout_reg[63:48]};
							default: m_axis_tdata <= {fifo_dout[47:0], fifo_dout_reg[63:48]};
						endcase
					end
					3'd3: begin
						case(cnt_row_deep)
							'd0: m_axis_tdata <= {fifo_dout[47:0], 16'd0};
							'd60: m_axis_tdata <= {48'd0, fifo_dout_reg[63:48]};
							default: m_axis_tdata <= {fifo_dout[47:0], fifo_dout_reg[63:48]};
						endcase
					end
					3'd4: begin
						case(cnt_row_deep)
							'd0: m_axis_tdata <= {fifo_dout[47:0], 16'd0};
							'd30: m_axis_tdata <= {48'd0, fifo_dout_reg[63:48]};
							default: m_axis_tdata <= {fifo_dout[47:0], fifo_dout_reg[63:48]};
						endcase
					end
					default: m_axis_tdata <= 'd0;
				endcase
			end
		end
	end
	assign en_data_out = fifo_rd_en_reg||row_last_data_pulse_reg;
	
	// rx_slice_last_data_flag
	always@(posedge clk)begin
		if(rst_d1)begin
			rx_slice_last_data_flag <= 1'b0;
		end
		else if(state_c == TRANSIT)begin
			rx_slice_last_data_flag <= 1'b0;
		end
		else if(s_axis_tlast_flag&&(cnt_fifo_rd==cnt_fifo_wr))begin
			rx_slice_last_data_flag <= 1'b1;
		end
	end
	
	// rx_last_data_lowermod
	always@(posedge clk)begin
		if(rst_d1)begin
			rx_last_data_lowermod <= 1'b0;
		end
		else if(pad_done_flag)begin
			rx_last_data_lowermod <= 1'b0;
		end
		else if((work_mod==LOWERPAD)&&rx_slice_last_data_flag)begin
			rx_last_data_lowermod <= 1'b1;
		end
	end
	
	// m_axis_tlast
	always@(posedge clk)begin
		if(rst_d1)begin
			m_axis_tlast <= 1'b0;
		end
		else if(m_axis_tlast&&m_axis_tvalid&&M_AXIS_TREADY)begin
			m_axis_tlast <= 1'b0;
		end
		else begin
			case(work_mod)
				ALLZERO: begin
					if((cnt_row_deep==ROW_DEEP_MAX)&&(cnt_pad_row_max==(PAD_ROW_MAX-1))&&m_axis_tvalid&&M_AXIS_TREADY)begin
						m_axis_tlast <= 1'b1;
					end
				end
				UPPERPAD, NORMPAD: begin
					if(s_axis_tlast_flag&&(cnt_fifo_rd==cnt_fifo_wr)&&end_cnt_row_deep)begin
						m_axis_tlast <= 1'b1;
					end
				end
				LOWERPAD: begin
					if((state_c==PAD)&&(cnt_pad_row_max==(PAD_ROW_MAX-1))&&(cnt_row_deep==ROW_DEEP_MAX)&&add_cnt_row_deep)begin
						m_axis_tlast <= 1'b1;
					end
				end
				default: m_axis_tlast <= 1'b0;
			endcase
		end
	end
	
	// cnt_pad_row_max
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_pad_row_max <= 2'b0;
		end
		else begin
			if(end_cnt_pad_row_max)begin
				cnt_pad_row_max <= 2'b0;
			end
			else if(add_cnt_pad_row_max)begin
				cnt_pad_row_max <= cnt_pad_row_max + 1'b1;
			end
		end
	end
	assign add_cnt_pad_row_max = (state_c == PAD)&&end_cnt_row_deep;
	assign end_cnt_pad_row_max = cnt_pad_row_max == PAD_ROW_MAX;
	
	// pad_done
	always@(posedge clk)begin
		if(rst_d1)begin
			pad_done <= 1'b0;
		end
		else if((state_c==PAD)&&(cnt_pad_row_max==(PAD_ROW_MAX-1))&&(cnt_row_deep==ROW_DEEP_MAX)&&add_cnt_row_deep)begin
			pad_done <= 1'b1;
		end
		else begin
			pad_done <= 1'b0;
		end
	end
	// pad_done_flag
	always@(posedge clk)begin
		if(rst_d1)begin
			pad_done_flag <= 1'b0;
		end
		else if((work_mod==LOWERPAD)&&pad_done_flag)begin
			pad_done_flag <= 1'b0;
		end
		else if((pad_done_flag&&M_AXIS_TLAST&&M_AXIS_TREADY&&m_axis_tvalid)||(work_mod==ALLZERO))begin
			pad_done_flag <= 1'b0;
		end
		else if(pad_done)begin
			pad_done_flag <= 1'b1;
		end
	end

	// cnt_fifo_wr
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_fifo_wr <= 'd0;
		end
		else begin
			if(end_cnt_fifo_wr)begin
				cnt_fifo_wr <= 'd0;
			end
			else if(s_axis_tlast_flag)begin
				cnt_fifo_wr <= cnt_fifo_wr;
			end
			else if(add_cnt_fifo_wr)begin
				cnt_fifo_wr <= cnt_fifo_wr + 1'b1;
			end
		end
	end
	assign add_cnt_fifo_wr = fifo_wr_en;
	assign end_cnt_fifo_wr = (state_c == TRANSIT);
	
	// cnt_fifo_rd
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_fifo_rd <= 'd0;
		end
		else begin
			if(end_cnt_fifo_rd)begin
				cnt_fifo_rd <= 'd0;
			end
			else if(add_cnt_fifo_rd)begin
				cnt_fifo_rd <= cnt_fifo_rd + 1'b1;
			end
		end
	end
	assign add_cnt_fifo_rd = en_fifo_rd;
	assign end_cnt_fifo_rd = (state_c == TRANSIT);
	
	// cnt_fifo_rd_row_deep
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_fifo_rd_row_deep <= 'd0;
		end
		else begin
			if(end_cnt_fifo_rd_row_deep)begin
				cnt_fifo_rd_row_deep <= 'd0;
			end
			else if(add_cnt_fifo_rd_row_deep)begin
				cnt_fifo_rd_row_deep <= cnt_fifo_rd_row_deep + 1'b1;
			end
		end
	end
	assign add_cnt_fifo_rd_row_deep = fifo_rd_en;
	assign end_cnt_fifo_rd_row_deep = (cnt_fifo_rd_row_deep==ROW_DEEP_MAX)&&add_cnt_fifo_rd_row_deep;
	
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
	assign add_cnt_row_deep = ((state_c==PAD)&&m_axis_tvalid&&M_AXIS_TREADY)||((state_c==RUN)&&en_data_out);
	assign end_cnt_row_deep = (cnt_row_deep==(ROW_DEEP_MAX+1))&&add_cnt_row_deep;
	
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
	assign add_cnt_tile_deep = m_axis_tlast&&m_axis_tvalid&&M_AXIS_TREADY;
	assign end_cnt_tile_deep = (cnt_tile_deep == TILE_DEEP_MAX)&&add_cnt_tile_deep;
	
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
	assign end_cnt_block_deep = (cnt_block_deep == BLOCK_DEEP_MAX)&&add_cnt_block_deep;
	
	// cnt_loop_deep
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_loop_deep <= 'd0;
		end
		else begin
			if(transit2idle)begin
				cnt_loop_deep <= 'd0;
			end
			else if(add_cnt_loop_deep)begin
				cnt_loop_deep <= cnt_loop_deep + 1'b1;
			end
		end
	end
	assign add_cnt_loop_deep = end_cnt_block_deep;
	
	padding_fifo_64_512 padding_fifo_64_512_inst(
		.clk(clk),
		.srst(rst_d1),
		.din(S_AXIS_TDATA),
		.wr_en(fifo_wr_en),
		.rd_en(fifo_rd_en),
		.dout(fifo_dout),
		.full(fifo_full),
		.empty(fifo_empty),
		.prog_full(fifo_prog_full),
		.wr_rst_busy(wr_rst_busy),
		.rd_rst_busy(rd_rst_busy)
	);

endmodule