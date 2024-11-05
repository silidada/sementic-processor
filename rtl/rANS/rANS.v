

module rANS#(
	parameter DATA_WIDTH = 64,
	parameter PROBSCALE	 = 256
)(
	input wire					clk,
	input wire					rst,
	input wire					start,
	output reg					init_done,
	output reg					onetrans_rd_done,	// data in a single trans has read done
	output reg					all_rd_done,		// all data being encoded has read done
	output reg					next_trans_wr,		// begin the next data transfer(write data to ddr)
	input wire					start_next_trans_wr,
	output wire					enc_done,
	output reg					finish,
	
	output wire [		  63:0] debug_enc_byte,
	output wire	[		   7:0]	debug_valid,
	
	input wire [		   7:0]	trans_times,		// transfer times that read data from ddr using DMA
	input wire [		  15:0] dma_wr_num,			// the number of data write to ddr using DMA in a single transfer time
	
	input wire					tvalid_in,
	input wire [DATA_WIDTH-1:0]	tdata_in,
	input wire					tlast_in,
	
	input wire					s_axis_tvalid,
	output reg					s_axis_tready,
	input wire [DATA_WIDTH-1:0]	s_axis_tdata,
	input wire					s_axis_tlast,	
	
	output reg					m_axis_tvalid,
	input wire					m_axis_tready,
	output wire[DATA_WIDTH-1:0]	m_axis_tdata,
	output reg					m_axis_tlast	
);
	localparam DATAWIDTH_PDF   		= 20;
	localparam DATAWIDTH_CDF 		= 18;
	localparam DATAWIDTH_FREQ  		= 9;
	localparam DATAWIDTH_START 		= 8;
	localparam DATAWIDTH_XMAX		= 18;
	localparam DATAWIDTH_RCPFREQ	= 32;		
	localparam DATAWIDTH_BIAS		= 10;
	localparam DATAWIDTH_CMPLFREQ	= 9;
	localparam DATAWIDTH_RCPSHIFT	= 6;
	localparam SCALE_BITS	  		= 8;	
	localparam RANS_BYTE_L_SHIFT	= 8;	// RANS_BYTE_L = 1 << RANS_BYTE_L_SHIFT
	localparam RANS_BYTE_L			= 1 << RANS_BYTE_L_SHIFT;
	
	localparam BYTES_NUM_WIDTH		= 32;
	
	localparam IDLE 	 = 5'b0_0001,
			   BUILDTAB  = 5'b0_0010,    // build frequency table and cdf
			   SYMINIT	 = 5'b0_0100,
			   ENCODE    = 5'b0_1000,
			   HEADER	 = 5'b1_0000;
	reg [4:0] state_c, state_n;
	
	reg 	[		   			7:0]	TRANSTIMES;
	reg		[				   15:0]	DMAWrNum;
	reg 	[		   			7:0]	cnt_trans_times;
	wire								dma_rd_end;
	reg									dma_rd_end_flag;
	
	wire								finish_blttab;

	// ====================== RansEncSymbolInit ======================  
	wire								en_rd_pdf;
	wire	[					7:0]	addr_rd_pdf;
	wire								rd_valid_pdf;
	wire	[	  DATAWIDTH_PDF-1:0]	data_rd_pdf;
	
	wire								en_rd_cdf;
	wire	[					7:0]	addr_rd_cdf;
	wire								rd_valid_cdf;
	wire	[	  DATAWIDTH_CDF-1:0]	data_rd_cdf;
	
	wire								en_rd_pdf_init;
	wire	[					7:0]	addr_rd_pdf_init;
	wire								rd_valid_pdf_init;
	wire	[	  DATAWIDTH_PDF-1:0]	data_rd_pdf_init;
	
	wire								en_rd_cdf_init;
	wire	[					7:0]	addr_rd_cdf_init;
	wire								rd_valid_cdf_init;
	wire	[	  DATAWIDTH_CDF-1:0]	data_rd_cdf_init;
	
	wire								finish_init;
	
	wire	[	 DATAWIDTH_XMAX-1:0]	x_max;
	wire								x_max_valid;
	wire	[ DATAWIDTH_RCPFREQ-1:0]	rcp_freq;
	wire								rcp_freq_valid;
	wire	[	 DATAWIDTH_BIAS-1:0]	bias;
	wire								bias_valid;
	wire	[DATAWIDTH_CMPLFREQ-1:0]	cmpl_freq;
	wire								cmpl_freq_valid;
	wire	[DATAWIDTH_RCPSHIFT-1:0]	rcp_shift;
	wire								rcp_shift_valid;
	
	// ====================== Encode ====================== 
	reg									start_enc;
	wire	[					7:0]	finish_enc;
	reg									finish_enc_flag;
	reg									finish_enc_flag_d1;
	wire	[					7:0]	onebyte_end;
	reg									onebyte_end_flag;
	
	wire	[					7:0]	enc_out_valid;
	wire	[	 	 DATA_WIDTH-1:0]	enc_dout;
	
	
	reg		[	BYTES_NUM_WIDTH-1:0]	cnt_byte_in;
	reg									en_wr_fifo_in;
	reg		[	 	 DATA_WIDTH-1:0]	data_wr_fifo_in;
	
	reg									start_0_dly;
	reg									first_rd_fifo_in;	// the first time read fifo in
	reg									need_restart_rd_fifo_in;
	reg									restart_rd_fifo_in;	// restart rd fifo in
	reg									en_rd_fifo_in;
	reg									en_rd_fifo_in_d1;
	wire	[	 	 DATA_WIDTH-1:0]	data_rd_fifo_in;
	wire								almost_full_fifo_in;
	reg									almost_full_fifo_in_d1;
	reg									almost_full_fifo_in_flag;
	wire								almost_empty_fifo_in;
	wire								empty_fifo_in;
	reg		[					3:0]	cnt_finish_enc_delay;
	wire								enc_last;
	
	reg									rd_fifo_out_pause;
	reg									need_restart_rd_fifo_out;
	reg									restart_rd_fifo_out;
	
	wire	[	BYTES_NUM_WIDTH-1:0]	bytes_num;
	reg									start_1_dly;
	reg									first_rd_fifo_out;
	reg									en_rd_fifo_out;
	reg									en_rd_fifo_out_d1;
	reg									en_rd_fifo_out_flag;
	wire	[		 DATA_WIDTH-1:0]	data_rd_fifo_out;
	reg		[				    1:0]	en_send_out;
	reg		[		 DATA_WIDTH-1:0]	fifo_out_dout;
	
	wire								full_fifo_out;
	wire								empty_fifo_out;
	wire								almost_full_fifo_out;
	wire								almost_empty_fifo_out;
	reg									full_fifo_out_flag;
	reg									almost_empty_fifo_out_reg;
	reg									almost_full_fifo_out_reg;
	reg									almost_full_fifo_out_flag;
	reg									almost_full_fifo_out_flag_reg;
	
	reg		[	BYTES_NUM_WIDTH-1:0]	cnt_enc_byte_num;
	reg		[	BYTES_NUM_WIDTH-1:0]	cnt_enc_wr_out;
	reg		[				   15:0]	cnt_dma_wr_num;
	
	reg		[				    3:0]	enc_done_dly;
	reg									start_next_trans_wr_reg;
	reg									start_next_trans_wr_flag;
	
	// ====================== HEADER ====================== 
	reg		[				    1:0]	cnt_rd_head;
	reg		[				    1:0]	cnt_stage;
	reg									HEAD;
	reg									PROB_PDF;
	reg									PROB_CDF;
	reg									prob_pdf_end_d1;
	reg									prob_cdf_end_d1;
	
	reg		[		 DATA_WIDTH-1:0]	data_prob;
	reg									data_prob_valid;
	reg									en_rd_flag_head;
	
	reg									en_rd_pdf_head;
	reg		[					7:0]	addr_rd_pdf_head;
	wire	[	  DATAWIDTH_PDF-1:0]	data_rd_pdf_head;
	wire								rd_valid_pdf_head;
	
	reg									en_rd_cdf_head;
	reg		[					7:0]	addr_rd_cdf_head;
	wire	[	  DATAWIDTH_CDF-1:0]	data_rd_cdf_head;
	wire								rd_valid_cdf_head;

	(* keep = "true" *)
	reg  [12:0] rst_d1;
	always@(posedge clk)begin
		if(rst)begin
			rst_d1 <= 13'b1_1111_1111_1111;
		end
		else begin
			rst_d1 <= 13'b0_0000_0000_0000;
		end
	end
	
	// TRANSTIMES
	always@(posedge clk)begin
		if(start)begin
			TRANSTIMES <= trans_times;
		end
		else begin
			TRANSTIMES <= TRANSTIMES;
		end
	end
	// DMAWrNum
	always@(posedge clk)begin
		if(start)begin
			DMAWrNum <= dma_wr_num;
		end
		else begin
			DMAWrNum <= DMAWrNum;
		end
	end
	
	
	// FSM
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
					state_n = BUILDTAB;
				end
				else begin
					state_n = IDLE;
				end
			end
			BUILDTAB: begin
				if(finish_blttab)begin
					state_n = SYMINIT;
				end
				else begin
					state_n = BUILDTAB;
				end
			end
			SYMINIT: begin
				if(finish_init)begin
					state_n = ENCODE;
				end
				else begin
					state_n = SYMINIT;
				end
			end
			ENCODE: begin
				if(enc_done_dly[0])begin
					state_n = HEADER;
				end
				else begin
					state_n = ENCODE;
				end
			end
			HEADER: begin
				if(finish)begin
					state_n = IDLE;
				end
				else begin
					state_n = HEADER;
				end
			end
			default: state_n = IDLE;
		endcase
	end
	// start_enc
	always@(posedge clk)begin
		if(rst_d1[0])begin
			start_enc <= 1'b0;
		end
		else if(finish_init)begin
			start_enc <= 1'b1;
		end
		else begin
			start_enc <= 1'b0;
		end
	end
	
	// init_done
	always@(posedge clk)begin
		if(finish_init)begin
			init_done <= 1'b1;
		end
		else begin
			init_done <= 1'b0;
		end
	end
	// onetrans_rd_done
	always@(posedge clk)begin
		if(s_axis_tlast&&s_axis_tready&&s_axis_tvalid)begin
			onetrans_rd_done <= 1'b1;
		end
		else begin
			onetrans_rd_done <= 1'b0;
		end
	end
	// all_rd_done
	always@(posedge clk)begin
		if(dma_rd_end)begin
			all_rd_done <= 1'b1;
		end
		else begin
			all_rd_done <= 1'b0;
		end
	end
	// next_trans_wr
	always@(posedge clk)begin
		if(init_done||(m_axis_tlast&&m_axis_tvalid&&m_axis_tready&&(state_c==ENCODE)))begin
			next_trans_wr <= 1'b1;
		end
		else begin
			next_trans_wr <= 1'b0;
		end
	end
	// start_next_trans_wr_reg
	always@(posedge clk)begin
		if(start_next_trans_wr)begin
			start_next_trans_wr_reg <= 1'b1;
		end
		else begin
			start_next_trans_wr_reg <= 1'b0;
		end
	end
	// enc_done
	assign enc_done = enc_done_dly[0];
	// enc_done_dly
	always@(posedge clk)begin
		if(state_c==IDLE)begin
			enc_done_dly <= 'd0;
		end
		else begin
			enc_done_dly <= {enc_done_dly[2:0], (state_c==ENCODE)&&empty_fifo_out&&m_axis_tlast&&m_axis_tvalid&&m_axis_tready};
		end
	end
	// finish
	always@(posedge clk)begin
		if((state_c==HEADER)&&m_axis_tlast&&m_axis_tvalid&&m_axis_tready)begin
			finish <= 1'b1;
		end
		else begin
			finish <= 1'b0;
		end
	end
	
// =============================================================================
// 									FIFO IN
// =============================================================================
// ================= FIFO wr ================= 
	// s_axis_tready
	always@(posedge clk)begin
		if(rst_d1[0])begin
			s_axis_tready <= 1'b0;
		end
		else if(almost_full_fifo_in)begin
			s_axis_tready <= 1'b0;
		end
		else if((state_c==ENCODE)&&(~(dma_rd_end||dma_rd_end_flag)))begin
			s_axis_tready <= 1'b1;
		end
		else begin
			s_axis_tready <= s_axis_tready;
		end
	end
	// en_wr_fifo_in
	always@(posedge clk)begin
		if(s_axis_tready&&s_axis_tvalid)begin
			en_wr_fifo_in <= 1'b1;
		end
		else begin
			en_wr_fifo_in <= 1'b0;
		end
	end
	// data_wr_fifo_in
	always@(posedge clk)begin
		data_wr_fifo_in <= s_axis_tdata;
	end
	// cnt_trans_times
	always@(posedge clk)begin
		if(state_c==ENCODE)begin
			if(s_axis_tlast&&s_axis_tready&&s_axis_tvalid)begin
				cnt_trans_times <= cnt_trans_times + 1'b1;
			end
			else begin
				cnt_trans_times <= cnt_trans_times;
			end
		end
		else begin
			cnt_trans_times <= 'd0;
		end
	end
	// dma_rd_end
	assign dma_rd_end = (cnt_trans_times==(TRANSTIMES-1)&&s_axis_tlast&&s_axis_tready&&s_axis_tvalid);
	// dma_rd_end_flag
	always@(posedge clk)begin
		if(state_c==ENCODE)begin
			if(dma_rd_end)begin
				dma_rd_end_flag <= 1'b1;
			end
			else begin
				dma_rd_end_flag <= dma_rd_end_flag;
			end
		end
		else begin
			dma_rd_end_flag <= 1'b0;
		end
	end
	
	// cnt_byte_in
	always@(posedge clk)begin
		if(state_c==IDLE)begin
			cnt_byte_in <= 'd0;
		end
		else if((state_c==ENCODE)&&en_wr_fifo_in)begin
			cnt_byte_in <= cnt_byte_in + 1'b1;
		end
		else begin
			cnt_byte_in <= cnt_byte_in;
		end
	end

// ================= FIFO rd ================= 
	// almost_full_fifo_in_d1
	always@(posedge clk)begin
		almost_full_fifo_in_d1 <= almost_full_fifo_in;
	end
	// almost_full_fifo_in_flag
	always@(posedge clk)begin
		if(rst_d1[0])begin
			almost_full_fifo_in_flag <= 1'b0;
		end
		else if(first_rd_fifo_in||restart_rd_fifo_in)begin
			almost_full_fifo_in_flag <= 1'b0;
		end
		else if({almost_full_fifo_in, almost_full_fifo_in_d1}==2'b10)begin
			almost_full_fifo_in_flag <= 1'b1;
		end
		else begin
			almost_full_fifo_in_flag <= almost_full_fifo_in_flag;
		end
	end
	// start_0_dly
	always@(posedge clk)begin
		if(rst_d1[0])begin
			start_0_dly <= 1'b0;
		end	
		else if(almost_full_fifo_in_flag)begin
			start_0_dly <= 1'b0;
		end
		else if(start)begin
			start_0_dly <= 1'b1;
		end
		else begin
			start_0_dly <= start_0_dly;
		end
	end	
	// first_rd_fifo_in
	always@(posedge clk)begin
		if(start_0_dly&&almost_full_fifo_in_flag)begin
			first_rd_fifo_in <= 1'b1;
		end
		else begin
			first_rd_fifo_in <= 1'b0;
		end
	end	
	// onebyte_end_flag
	always@(posedge clk)begin
		if(rst_d1[0])begin
			onebyte_end_flag <= 1'b0;
		end
		else if(restart_rd_fifo_in||en_rd_fifo_in)begin
			onebyte_end_flag <= 1'b0;
		end
		else if(onebyte_end)begin
			onebyte_end_flag <= 1'b1;
		end
		else begin
			onebyte_end_flag <= onebyte_end_flag;
		end
	end	
	// need_restart_rd_fifo_in
	always@(posedge clk)begin
		if(state_c==IDLE)begin
			need_restart_rd_fifo_in <= 1'b0;
		end
		else if(restart_rd_fifo_in)begin
			need_restart_rd_fifo_in <= 1'b0;
		end
		else if(onebyte_end&&(empty_fifo_in||full_fifo_out))begin
			need_restart_rd_fifo_in <= 1'b1;
		end
		else begin
			need_restart_rd_fifo_in <= need_restart_rd_fifo_in;
		end
	end
	// restart_rd_fifo_in
	always@(posedge clk)begin
		if(need_restart_rd_fifo_in&&almost_full_fifo_out_flag_reg&&(~empty_fifo_in))begin
			restart_rd_fifo_in <= 1'b1;
		end
		else begin
			restart_rd_fifo_in <= 1'b0;
		end
	end

	// en_rd_fifo_in
	always@(posedge clk)begin
		if(first_rd_fifo_in||restart_rd_fifo_in||
		   (onebyte_end&&(~empty_fifo_in)&&(~full_fifo_out)))begin
			en_rd_fifo_in <= 1'b1;
		end
		else begin
			en_rd_fifo_in <= 1'b0;
		end
	end
	// en_rd_fifo_in_d1
	always@(posedge clk)begin
		en_rd_fifo_in_d1 <= en_rd_fifo_in;
	end
	
	
	
// =============================================================================
// 									FIFO OUT
// =============================================================================
	// finish_enc_flag
	always@(posedge clk)begin
		if(state_c==ENCODE)begin
			if(finish_enc==8'b1111_1111)begin
				finish_enc_flag <= 1'b1;
			end
			else begin
				finish_enc_flag <= finish_enc_flag;
			end
		end
		else begin
			finish_enc_flag <= 1'b0;
		end
	end
	// finish_enc_flag_d1
	always@(posedge clk)begin
		finish_enc_flag_d1 <= finish_enc_flag;
	end

	// almost_full_fifo_out_reg
	always@(posedge clk)begin
		almost_full_fifo_out_reg <= almost_full_fifo_out;
	end
	// almost_full_fifo_out_flag
	always@(posedge clk)begin
		if({almost_full_fifo_out_reg, almost_full_fifo_out}==2'b01)begin
			almost_full_fifo_out_flag <= 1'b1;
		end
		else begin
			almost_full_fifo_out_flag <= 1'b0;
		end
	end
	// almost_full_fifo_out_flag_reg
	always@(posedge clk)begin
		if(rst_d1[0])begin
			almost_full_fifo_out_flag_reg <= 1'b0;
		end
		else if(restart_rd_fifo_in)begin
			almost_full_fifo_out_flag_reg <= 1'b0;
		end
		else if(almost_full_fifo_out_flag)begin
			almost_full_fifo_out_flag_reg <= 1'b1;
		end
		else begin
			almost_full_fifo_out_flag_reg <= almost_full_fifo_out_flag_reg;
		end
	end
	
	// start_1_dly
	always@(posedge clk)begin
		if(rst_d1[0])begin
			start_1_dly <= 1'b0;
		end
		else if(first_rd_fifo_out)begin
			start_1_dly <= 1'b0;
		end
		else if(start)begin
			start_1_dly <= 1'b1;
		end
		else begin
			start_1_dly <= start_1_dly;
		end
	end
	// first_rd_fifo_out
	always@(posedge clk)begin
		if(start_1_dly&&almost_full_fifo_out_flag)begin
			first_rd_fifo_out <= 1'b1;
		end
		else begin
			first_rd_fifo_out <= 1'b0;
		end
	end
	
	// start_next_trans_wr_flag
	always@(posedge clk)begin
		if(({start_next_trans_wr_reg, start_next_trans_wr}==2'b01)&&(~start_1_dly))begin
			start_next_trans_wr_flag <= 1'b1;
		end
		else begin
			start_next_trans_wr_flag <= 1'b0;
		end
	end
	
	// rd_fifo_out_pause
	always@(posedge clk)begin
		if(rst_d1[0])begin
			rd_fifo_out_pause <= 1'b0;
		end
		else if(restart_rd_fifo_out)begin
			rd_fifo_out_pause <= 1'b0;
		end
		else if(en_rd_fifo_out_flag&&almost_empty_fifo_out&&(~finish_enc_flag))begin
			rd_fifo_out_pause <= 1'b1;
		end
		else begin
			rd_fifo_out_pause <= rd_fifo_out_pause;
		end
	end
	// need_restart_rd_fifo_out
	always@(posedge clk)begin
		if(rst_d1[0])begin
			need_restart_rd_fifo_out <= 1'b0;
		end
		else if(almost_full_fifo_out_flag||({finish_enc_flag_d1, finish_enc_flag}==2'b01))begin
			need_restart_rd_fifo_out <= 1'b0;
		end
		else if((almost_empty_fifo_out||rd_fifo_out_pause)&&m_axis_tready&&m_axis_tvalid)begin
			need_restart_rd_fifo_out <= 1'b1;
		end
		else begin
			need_restart_rd_fifo_out <= need_restart_rd_fifo_out;
		end
	end
	// restart_rd_fifo_out
	always@(posedge clk)begin
		if(need_restart_rd_fifo_out&&(almost_full_fifo_out_flag||({finish_enc_flag_d1, finish_enc_flag}==2'b01)))begin
			restart_rd_fifo_out <= 1'b1;
		end
		else begin
			restart_rd_fifo_out <= 1'b0;
		end
	end

	// en_rd_fifo_out_flag
	always@(posedge clk)begin
		if(rst_d1[0])begin
			en_rd_fifo_out_flag <= 1'b0;
		end
		else if((almost_empty_fifo_out&&(~finish_enc_flag))||empty_fifo_out)begin
			en_rd_fifo_out_flag <= 1'b0;
		end
		else if((state_c==ENCODE)&&(almost_full_fifo_out_flag||({finish_enc_flag_d1, finish_enc_flag}==2'b01)))begin
			en_rd_fifo_out_flag <= 1'b1;
		end
		else begin
			en_rd_fifo_out_flag <= en_rd_fifo_out_flag;
		end
	end
	// en_rd_fifo_out
	always@(posedge clk)begin
		if((en_rd_fifo_out_flag&&(first_rd_fifo_out||
								  (m_axis_tready&&m_axis_tvalid&&(~m_axis_tlast))||
								  restart_rd_fifo_out)
								 )||
		   ((state_c==ENCODE)&&start_next_trans_wr_flag)				
								)begin
			en_rd_fifo_out <= 1'b1;
		end
		else begin
			en_rd_fifo_out <= 1'b0;
		end
	end
	// en_rd_fifo_out_d1
	always@(posedge clk)begin
		en_rd_fifo_out_d1 <= en_rd_fifo_out;
	end
	// fifo_out_dout
	always@(posedge clk)begin
		fifo_out_dout <= data_rd_fifo_out;
	end
	
	// m_axis_tdata
	assign m_axis_tdata = (state_c==ENCODE) ? fifo_out_dout : data_prob;
	// m_axis_tvalid
	always@(posedge clk)begin
		if(rst_d1[0])begin
			m_axis_tvalid <= 1'b0;
		end
		else if(en_rd_fifo_out_d1||data_prob_valid)begin
			m_axis_tvalid <= 1'b1;
		end
		else if(m_axis_tvalid&&m_axis_tready)begin
			m_axis_tvalid <= 1'b0;
		end
		else begin
			m_axis_tvalid <= m_axis_tvalid;
		end
	end
	// m_axis_tlast
	always@(posedge clk)begin
		if(rst_d1[0])begin
			m_axis_tlast <= 1'b0;
		end
		else if(m_axis_tlast&&m_axis_tvalid&&m_axis_tready)begin
			m_axis_tlast <= 1'b0;
		end
		else if(prob_cdf_end_d1&&(~PROB_CDF))begin
			m_axis_tlast <= 1'b1;
		end
		else if((m_axis_tvalid&&m_axis_tready&&(cnt_dma_wr_num==(DMAWrNum-2)))||(empty_fifo_out&&en_rd_fifo_out_d1))begin
			m_axis_tlast <= 1'b1;
		end
		else begin
			m_axis_tlast <= m_axis_tlast;
		end
	end


	// cnt_enc_wr_out
	always@(posedge clk)begin
		if(state_c==ENCODE)begin
			if(en_rd_fifo_out)begin
				cnt_enc_wr_out <= cnt_enc_wr_out + 8;
			end
			else begin
				cnt_enc_wr_out <= cnt_enc_wr_out;
			end
		end
		else begin
			cnt_enc_wr_out <= 'd0;
		end
	end
	// cnt_dma_wr_num
	always@(posedge clk)begin
		if(state_c==ENCODE)begin
			if(m_axis_tvalid&&m_axis_tready)begin
				if(m_axis_tlast)begin
					cnt_dma_wr_num <= 'd0;
				end
				else begin
					cnt_dma_wr_num <= cnt_dma_wr_num + 1'b1;
				end
			end
			else begin
				cnt_dma_wr_num <= cnt_dma_wr_num;
			end
		end
		else begin
			cnt_dma_wr_num <= 'd0;
		end
	end
	
	
// =============================================================================
// 									HEADER
// =============================================================================	
	// HEAD
	always@(posedge clk)begin
		if(rst_d1[0])begin
			HEAD <= 1'b0;
		end
		else if(m_axis_tready&&m_axis_tvalid)begin
			HEAD <= 1'b0;
		end
		else if(enc_done_dly[2])begin
			HEAD <= 1'b1;
		end
		else begin
			HEAD <= HEAD;
		end
	end
	// PROB_PDF
	always@(posedge clk)begin
		if(rst_d1[0])begin
			PROB_PDF <= 1'b0;
		end
		else if(prob_pdf_end_d1)begin
			PROB_PDF <= 1'b0;
		end
		else if(HEAD&&m_axis_tready&&m_axis_tvalid)begin
			PROB_PDF <= 1'b1;
		end
		else begin
			PROB_PDF <= PROB_PDF;
		end
	end
	// prob_pdf_end_d1
	always@(posedge clk)begin
		if((addr_rd_pdf_head==0)&&rd_valid_pdf_head&&PROB_PDF)begin
			prob_pdf_end_d1 <= 1'b1;
		end
		else begin	
			prob_pdf_end_d1 <= 1'b0;
		end
	end
	// PROB_CDF
	always@(posedge clk)begin
		if(rst_d1[0])begin
			PROB_CDF <= 1'b0;
		end
		else if(prob_cdf_end_d1)begin
			PROB_CDF <= 1'b0;
		end
		else if(prob_pdf_end_d1)begin
			PROB_CDF <= 1'b1;
		end
		else begin
			PROB_CDF <= PROB_CDF;
		end
	end
	// prob_cdf_end_d1
	always@(posedge clk)begin
		if((addr_rd_cdf_head==0)&&rd_valid_cdf_head&&PROB_CDF)begin
			prob_cdf_end_d1 <= 1'b1;
		end
		else begin	
			prob_cdf_end_d1 <= 1'b0;
		end
	end	
	
	// en_rd_flag_head
	always@(posedge clk)begin
		if(state_c==HEADER)begin
			if(cnt_rd_head==3)begin
				en_rd_flag_head <= 1'b0;
			end
			else if(m_axis_tready&&m_axis_tvalid&&(~m_axis_tlast))begin
				en_rd_flag_head <= 1'b1;
			end
			else begin
				en_rd_flag_head <= en_rd_flag_head;
			end
		end
		else begin
			en_rd_flag_head <= 1'b0;
		end
	end
	// cnt_rd_head
	always@(posedge clk)begin
		if(state_c==HEADER)begin
			if(en_rd_flag_head)begin
				cnt_rd_head <= cnt_rd_head + 1'b1;
			end
			else begin
				cnt_rd_head <= cnt_rd_head;
			end
		end
		else begin
			cnt_rd_head <= 'd0;
		end
	end
	// cnt_stage
	always@(posedge clk)begin
		if(state_c==HEADER)begin
			if(rd_valid_cdf||rd_valid_pdf)begin
				cnt_stage <= cnt_stage + 1'b1;
			end
			else begin
				cnt_stage <= cnt_stage;
			end
		end
		else begin
			cnt_stage <= 'd0;
		end
	end
	
	// data_prob
	always@(posedge clk)begin
		if(state_c==IDLE)begin
			data_prob <= 'd0;
		end
		else if(HEAD&&start_next_trans_wr_flag)begin
			data_prob <= {bytes_num, cnt_byte_in};
		end
		else if(PROB_PDF&&rd_valid_pdf_head)begin
			case(cnt_stage)
				0: data_prob[16*1-1:16*0] <= data_rd_pdf_head[15:0];
				1: data_prob[16*2-1:16*1] <= data_rd_pdf_head[15:0];
				2: data_prob[16*3-1:16*2] <= data_rd_pdf_head[15:0];
				3: data_prob[16*4-1:16*3] <= data_rd_pdf_head[15:0];
				default: data_prob <= 'd0;
			endcase				
		end
		else if(PROB_CDF&&rd_valid_cdf_head)begin
			case(cnt_stage)
				0: data_prob[16*1-1:16*0] <= data_rd_cdf_head[15:0];
				1: data_prob[16*2-1:16*1] <= data_rd_cdf_head[15:0];
				2: data_prob[16*3-1:16*2] <= data_rd_cdf_head[15:0];
				3: data_prob[16*4-1:16*3] <= data_rd_cdf_head[15:0];
				default: data_prob <= 'd0;
			endcase		
		end
		else begin
			data_prob <= data_prob;
		end
	end
	// data_prob_valid
	always@(posedge clk)begin
		if((HEAD&&start_next_trans_wr_flag)||(cnt_stage==3))begin
			data_prob_valid <= 1'b1;
		end
		else begin
			data_prob_valid <= 1'b0;
		end
	end

	
	
//->read pdf<-
	// en_rd_pdf_head
	always@(posedge clk)begin
		if(PROB_PDF&&en_rd_flag_head)begin
			en_rd_pdf_head <= 1'b1;
		end
		else begin
			en_rd_pdf_head <= 1'b0;
		end
	end
	// addr_rd_pdf_head
	always@(posedge clk)begin
		if(PROB_PDF)begin
			if(en_rd_pdf_head)begin
				addr_rd_pdf_head <= addr_rd_pdf_head + 1'b1;
			end
			else begin
				addr_rd_pdf_head <= addr_rd_pdf_head;
			end
		end
		else begin
			addr_rd_pdf_head <= 'd0;
		end
	end
	
//->read cdf<-
	// en_rd_cdf_head
	always@(posedge clk)begin
		if(PROB_CDF&&en_rd_flag_head)begin
			en_rd_cdf_head <= 1'b1;
		end
		else begin
			en_rd_cdf_head <= 1'b0;
		end
	end
	// addr_rd_pdf_head
	always@(posedge clk)begin
		if(PROB_CDF)begin
			if(en_rd_cdf_head)begin
				addr_rd_cdf_head <= addr_rd_cdf_head + 1'b1;
			end
			else begin
				addr_rd_cdf_head <= addr_rd_cdf_head;
			end
		end
		else begin
			addr_rd_cdf_head <= 'd0;
		end
	end
	
// =============================================================================
// 									dirtribute wire
// =============================================================================
	assign en_rd_pdf			= PROB_PDF ? en_rd_pdf_head: en_rd_pdf_init;
	assign addr_rd_pdf			= PROB_PDF ? addr_rd_pdf_head: addr_rd_pdf_init;
	assign data_rd_pdf_init 	= data_rd_pdf;
	assign data_rd_pdf_head		= data_rd_pdf;
	assign rd_valid_pdf_init 	= (state_c==SYMINIT) ? rd_valid_pdf: 1'b0;
	assign rd_valid_pdf_head 	= PROB_PDF ? rd_valid_pdf : 1'b0;
	
	assign en_rd_cdf			= PROB_CDF ? en_rd_cdf_head: en_rd_cdf_init;
	assign addr_rd_cdf			= PROB_CDF ? addr_rd_cdf_head: addr_rd_cdf_init;
	assign data_rd_cdf_init 	= data_rd_cdf;
	assign data_rd_cdf_head 	= data_rd_cdf;
	assign rd_valid_cdf_init 	= (state_c==SYMINIT) ? rd_valid_cdf: 1'b0;
	assign rd_valid_cdf_head 	= PROB_CDF ? rd_valid_cdf : 1'b0;
	
	 
// =============================================================================
// 									Module instance
// =============================================================================

	buildtable#(
		.DATA_WIDTH(DATA_WIDTH),
		.DATA_WIDTH_PDF(DATAWIDTH_PDF),
		.DATA_WIDTH_CDF(DATAWIDTH_CDF)
	)buildtable_inst(
		.clk(clk),
		.rst(rst_d1[1]),
		.start(start),
		.finish(finish_blttab),
		
		.tvalid_in(tvalid_in),
		.tdata_in(tdata_in),
		.tlast_in(tlast_in),
		
		.en_rd_pdf(en_rd_pdf),
		.addr_rd_pdf(addr_rd_pdf),
		.rd_valid_pdf(rd_valid_pdf),
		.data_rd_pdf(data_rd_pdf),
		
		.en_rd_cdf(en_rd_cdf),
		.addr_rd_cdf(addr_rd_cdf),
		.rd_valid_cdf(rd_valid_cdf),
		.data_rd_cdf(data_rd_cdf)
	);
	
	RansEncSymbolInit#(
		.DATAWIDTH_PDF(DATAWIDTH_PDF),
		.DATAWIDTH_CDF(DATAWIDTH_CDF),
		.DATAWIDTH_FREQ(DATAWIDTH_FREQ),
		.DATAWIDTH_START(DATAWIDTH_START),
		.DATAWIDTH_XMAX(DATAWIDTH_XMAX),
		.DATAWIDTH_RCPFREQ(DATAWIDTH_RCPFREQ),		
		.DATAWIDTH_BIAS(DATAWIDTH_BIAS),	
		.DATAWIDTH_CMPLFREQ(DATAWIDTH_CMPLFREQ),	
		.DATAWIDTH_RCPSHIFT(DATAWIDTH_RCPSHIFT),	
		.SCALE_BITS(SCALE_BITS),	
		.RANS_BYTE_L_SHIFT(RANS_BYTE_L_SHIFT)
	)RansEncSymbolInit_inst(
		.clk(clk),
		.rst(rst_d1[2]),
		.start(finish_blttab),
		.finish(finish_init),
		
		.en_rd_pdf(en_rd_pdf_init),
		.addr_rd_pdf(addr_rd_pdf_init),
		.data_rd_pdf(data_rd_pdf_init),
		.rd_valid_pdf(rd_valid_pdf_init),
			
		.en_rd_cdf(en_rd_cdf_init),
		.addr_rd_cdf(addr_rd_cdf_init),
		.data_rd_cdf(data_rd_cdf_init),
		.rd_valid_cdf(rd_valid_cdf_init),
		
		// output
		.x_max(x_max),
		.x_max_valid(x_max_valid),
		
		.rcp_freq(rcp_freq),
		.rcp_freq_valid(rcp_freq_valid),
		
		.bias(bias),
		.bias_valid(bias_valid),
		
		.cmpl_freq(cmpl_freq),
		.cmpl_freq_valid(cmpl_freq_valid),
		
		.rcp_shift(rcp_shift),
		.rcp_shift_valid(rcp_shift_valid)
	);
	
	assign enc_last = empty_fifo_in&&dma_rd_end_flag;
	// encode
	genvar i;
	generate
		for(i=0; i<8; i=i+1)begin
			encode#(
				.DATAWIDTH_XMAX(DATAWIDTH_XMAX),
				.DATAWIDTH_RCPFREQ(DATAWIDTH_RCPFREQ),		
				.DATAWIDTH_BIAS(DATAWIDTH_BIAS),	
				.DATAWIDTH_CMPLFREQ(DATAWIDTH_CMPLFREQ),	
				.DATAWIDTH_RCPSHIFT(DATAWIDTH_RCPSHIFT),	
				.RANS_BYTE_L_SHIFT(RANS_BYTE_L_SHIFT),
				.DATANUM(130560)
			)encode_inst(
				.clk(clk),
				.rst(rst_d1[5+i]),
				.start(start_enc),
				.onebyte_end(onebyte_end[i]),
				.finish(finish_enc[i]),
				
				// symbol init
				.x_max(x_max),
				.x_max_valid(x_max_valid),
				.rcp_freq(rcp_freq),
				.rcp_freq_valid(rcp_freq_valid),				
				.bias(bias),
				.bias_valid(bias_valid),				
				.cmpl_freq(cmpl_freq),
				.cmpl_freq_valid(cmpl_freq_valid),				
				.rcp_shift(rcp_shift),
				.rcp_shift_valid(rcp_shift_valid),
				
				.tvalid(en_rd_fifo_in_d1),
				.tdata(data_rd_fifo_in[8*(i+1)-1:8*i]),
				.tlast(enc_last),
				
				.byte_enc(enc_dout[8*(i+1)-1:8*i]),
				.out_valid(enc_out_valid[i])
			);
		end
	endgenerate

	
	fifo_64x128#(
		.DATA_WIDTH(DATA_WIDTH),
		.ADDR_WIDTH(7),
		.ALMOST_FULL_THRESHOLD(64),
		.ALMOST_EMPTY_THRESHOLD(8)
	)fifo_in_inst(
		.clk(clk),
		.rst(rst_d1[3]),
		
		.en_wr(en_wr_fifo_in),
		.din(data_wr_fifo_in),
		
		.en_rd(en_rd_fifo_in),
		.dout(data_rd_fifo_in),

		.almost_full(almost_full_fifo_in),
		.almost_empty(almost_empty_fifo_in),
		.empty(empty_fifo_in)
	);
		
	
	queue_fifo#(
		.DATANUM(8),
		.BYTES_NUM_WIDTH(BYTES_NUM_WIDTH)
	)queue_fifo_inst(
		.clk(clk),
		.rst(rst_d1[4]),
		.clear(finish),
		
		.din(enc_dout),
		.in_valid(enc_out_valid),
		
		.bytes_num(bytes_num),
		
		.en_rd(en_rd_fifo_out),
		.dout(data_rd_fifo_out),
		
		.full(full_fifo_out),
		.empty(empty_fifo_out),
		.almost_empty(almost_empty_fifo_out),
		.almost_full(almost_full_fifo_out)
	);

endmodule