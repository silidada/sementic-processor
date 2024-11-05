

module encode#(
	parameter DATAWIDTH_STATE		= 16,
	parameter DATAWIDTH_XMAX		= 18,
	parameter DATAWIDTH_RCPFREQ		= 32,		
	parameter DATAWIDTH_BIAS		= 10,
	parameter DATAWIDTH_CMPLFREQ	= 9,
	parameter DATAWIDTH_RCPSHIFT	= 6,
	parameter RANS_BYTE_L_SHIFT		= 8,
	parameter DATANUM				= 130560
)(
	input wire								clk,
	input wire								rst,
	input wire								start,
	output reg								onebyte_end,
	output reg								finish,
	
	input wire	[	 DATAWIDTH_XMAX-1:0]	x_max,
	input wire								x_max_valid,
	input wire	[ DATAWIDTH_RCPFREQ-1:0]	rcp_freq,
	input wire								rcp_freq_valid,
	input wire	[	 DATAWIDTH_BIAS-1:0]	bias,
	input wire								bias_valid,
	input wire	[DATAWIDTH_CMPLFREQ-1:0]	cmpl_freq,
	input wire								cmpl_freq_valid,
	input wire	[DATAWIDTH_RCPSHIFT-1:0]	rcp_shift,
	input wire								rcp_shift_valid,
	
	input wire								tvalid,
	input wire	[			   	    7:0]	tdata,
	input wire								tlast,
	
	output reg	[			   	    7:0]	byte_enc,
	output reg								out_valid
);
	localparam RANS_BYTE_L	= 1 << RANS_BYTE_L_SHIFT;
	
	(* ram_style="distributed" *)reg		[	 DATAWIDTH_XMAX-1:0]	x_max_array[0:255];
	reg		[				    7:0]	cnt_x_max;
	
	(* ram_style="distributed" *)reg		[ DATAWIDTH_RCPFREQ-1:0]	rcp_freq_array[0:255];
	reg		[				    7:0]	cnt_rcp_freq;
	
	(* ram_style="distributed" *)reg		[	 DATAWIDTH_BIAS-1:0]	bias_array[0:255];
	reg		[				    7:0]	cnt_bias;
	
	(* ram_style="distributed" *)reg		[DATAWIDTH_CMPLFREQ-1:0]	cmpl_freq_array[0:255];
	reg		[			        7:0]	cnt_cmpl_freq;
	
	(* ram_style="distributed" *)reg		[DATAWIDTH_RCPSHIFT-1:0]	rcp_shift_array[0:255];
	reg		[					7:0]	cnt_rcp_shift;
	
	
// ========================= RansEncode  ========================= 
	reg		[	DATAWIDTH_STATE-1:0]	ransState;
	reg		[	DATAWIDTH_STATE-1:0]	ransState_prev;
	reg		[	 DATAWIDTH_XMAX-1:0]	x_max_cur;
	wire								need_output;
	reg									need_output_d1;
	reg									need_output_reg;
	reg									last_flag;
	reg		[				   16:0]	cnt_enc_out;
	
	reg		[					7:0]	tdata_d1;

	reg		[				   15:0]	X;
	reg 	[				   15:0]	high16, low16;	
	wire	[				   31:0]	dsp_out1, dsp_out2;
	reg		[				   48:0]	out1;
	reg		[				   32:0]	out2;
	reg		[				   49:0]	x_mul_rcp_freq;
	reg		[DATAWIDTH_RCPSHIFT-1:0]	rcp_shift_cur;
	reg		[				   17:0]	q;
	reg		[DATAWIDTH_CMPLFREQ-1:0]	cmpl_freq_dsp;
	wire	[				   26:0]	q_x_cmpl_freq;
	reg		[	 DATAWIDTH_BIAS-1:0]	bias_cur;
	reg		[				   16:0]	x_bias;
	
	reg		[				    9:0]	pp_dly;	// 10 pipeline
	reg		[				    8:0]	finish_enc;			

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
	
	// finish
	always@(posedge clk)begin
		if(finish_enc[8])begin
			finish <= 1'b1;
		end
		else begin
			finish <= 1'b0;
		end
	end

	// x_max_array
	always@(posedge clk)begin
		if(x_max_valid)begin
			x_max_array[cnt_x_max] <= x_max;
		end
	end
	// cnt_x_max
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_x_max <= 'd0;
		end
		else if(x_max_valid)begin
			cnt_x_max <= cnt_x_max + 1'b1;
		end
		else begin
			cnt_x_max <= cnt_x_max;
		end
	end
	
	// rcp_freq_array
	always@(posedge clk)begin
		if(rcp_freq_valid)begin
			rcp_freq_array[cnt_rcp_freq] <= rcp_freq;
		end
	end
	// cnt_rcp_freq
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_rcp_freq <= 'd0;
		end
		else if(rcp_freq_valid)begin
			cnt_rcp_freq <= cnt_rcp_freq + 1'b1;
		end
		else begin
			cnt_rcp_freq <= cnt_rcp_freq;
		end
	end
	
	// bias_array
	always@(posedge clk)begin
		if(bias_valid)begin
			bias_array[cnt_bias] <= bias;
		end
	end
	// cnt_bias
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_bias <= 'd0;
		end
		else if(bias_valid)begin
			cnt_bias <= cnt_bias + 1'b1;
		end
		else begin
			cnt_bias <= cnt_bias;
		end
	end
	
	// cmpl_freq_array
	always@(posedge clk)begin
		if(cmpl_freq_valid)begin
			cmpl_freq_array[cnt_cmpl_freq] <= cmpl_freq;
		end
	end
	// cnt_cmpl_freq
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_cmpl_freq <= 'd0;
		end
		else if(cmpl_freq_valid)begin
			cnt_cmpl_freq <= cnt_cmpl_freq + 1'b1;
		end
		else begin
			cnt_cmpl_freq <= cnt_cmpl_freq;
		end
	end
	
	// rcp_shift_array
	always@(posedge clk)begin
		if(rcp_shift_valid)begin
			rcp_shift_array[cnt_rcp_shift] <= rcp_shift;
		end
	end
	// cnt_rcp_shift
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_rcp_shift <= 'd0;
		end
		else if(rcp_shift_valid)begin
			cnt_rcp_shift <= cnt_rcp_shift + 1'b1;
		end
		else begin
			cnt_rcp_shift <= cnt_rcp_shift;
		end
	end
	

// =============================================================================
// 									RansEncode
// =============================================================================
	// tdata_d1
	always@(posedge clk)begin
		if(tvalid)begin
			tdata_d1 <= tdata;
		end
		else begin
			tdata_d1 <= tdata_d1;
		end
	end
	
	// last_flag
	always@(posedge clk)begin
		if(rst_d1)begin
			last_flag <= 1'b0;
		end
		else if(finish_enc)begin	
			last_flag <= 1'b0;
		end	
		else if(tlast)begin
			last_flag <= 1'b1;
		end
		else begin
			last_flag <= last_flag;
		end
	end
	
	// onebyte_end
	always@(posedge clk)begin
		onebyte_end <= pp_dly[4];
	end
	
	// ransState
	always@(posedge clk)begin
		if(start)begin
			ransState <= RANS_BYTE_L;
		end
		else if(need_output_d1)begin
			ransState <= ransState >> 8;
		end
		else if(pp_dly[6])begin
			ransState <= x_bias + q_x_cmpl_freq;
		end
		else begin
			ransState <= ransState;
		end
	end
	// ransState_prev
	always@(posedge clk)begin
		if(start)begin
			ransState_prev <= RANS_BYTE_L;
		end
		else if(pp_dly[7])begin
			ransState_prev <= ransState;
		end
		else begin
			ransState_prev <= ransState_prev;
		end
	end
	// byte_enc
	// out_valid
	always@(posedge clk)begin
		if(pp_dly[5])begin
			byte_enc  <= ransState_prev[7:0];
			out_valid <= need_output_reg;
		end
		else if(finish_enc[0])begin
			byte_enc  <= ransState[ 7:0];
			out_valid <= 1'b1; 
		end
		else if(finish_enc[8])begin
			byte_enc  <= ransState[15:8];
			out_valid <= 1'b1; 		
		end
		else begin
			byte_enc  <= 'd0;
			out_valid <= 1'b0;
		end
	end
	// cnt_enc_out
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_enc_out <= 'd0;
		end
		else if(finish_enc)begin
			cnt_enc_out <= 'd0;
		end
		else if(out_valid)begin
			cnt_enc_out <= cnt_enc_out + 1'b1;
		end	
		else begin
			cnt_enc_out <= cnt_enc_out;
		end
	end
	// finish_enc
	always@(posedge clk)begin
		if(rst_d1)begin
			finish_enc <= 'd0;
		end
		else begin
			finish_enc <= {finish_enc[7:0], last_flag&&pp_dly[6]};
		end
	end
	
	// x_max_cur
	always@(posedge clk)begin
		if(tvalid)begin
			x_max_cur <= x_max_array[tdata];
		end
		else begin
			x_max_cur <= 'd0;
		end
	end
	// need_output
	assign need_output = pp_dly[0]&&(ransState >= x_max_cur);
	// need_output_d1
	always@(posedge clk)begin
		need_output_d1 <= need_output;
	end
	// need_output_reg
	always@(posedge clk)begin
		if(rst_d1)begin
			need_output_reg <= 1'b0;
		end
		else if(out_valid)begin
			need_output_reg <= 1'b0;
		end
		else if(need_output)begin
			need_output_reg <= 1'b1;
		end
		else begin
			need_output_reg <= need_output_reg;
		end
	end
	
	// pp_dly
	always@(posedge clk)begin
		if(rst_d1)begin
			pp_dly <= 'd0;
		end
		else begin
			pp_dly <= {pp_dly[8:0], tvalid};
		end
	end
	

	// high16 low16
	always@(posedge clk)begin
		if(pp_dly[0])begin
			high16[15:0] <= rcp_freq_array[tdata_d1][31:16];
			low16[15:0]	 <= rcp_freq_array[tdata_d1][15: 0];
		end
		else begin
			high16	<= 'd0;
			low16	<= 'd0;			
		end	
	end
	// X
	always@(posedge clk)begin
		if(pp_dly[0])begin
			if(need_output)begin
				X[15:0]  <= ransState >> 8;
			end
			else begin
				X[15:0]  <= ransState;
			end
		end
		else begin
			X <= 'd0;
		end
	end
	// out1 / 2
	always@(posedge clk)begin
		if(rst_d1)begin
			out1 <= 'd0;
			out2 <= 'd0;
		end
		else begin
			out1[47:16] <= dsp_out1[31:0];
			out2		<= dsp_out2[31:0];	
		end
	end
	// x_mul_rcp_freq
	always@(posedge clk)begin
		x_mul_rcp_freq <= out1 + out2;
	end
	// rcp_shift_cur
	always@(posedge clk)begin
		rcp_shift_cur <= rcp_shift_array[tdata_d1];
	end
	// q
	always@(posedge clk)begin
		if(rst_d1)begin
			q <= 'd0;
		end
		else begin
			q[17:0] <= x_mul_rcp_freq >> rcp_shift_cur;
		end
	end
	// cmpl_freq_dsp
	always@(posedge clk)begin
		if(rst_d1)begin
			cmpl_freq_dsp <= 'd0;
		end
		else begin
			cmpl_freq_dsp[8:0] <= cmpl_freq_array[tdata_d1];
		end
	end
	// bias_cur
	always@(posedge clk)begin
		bias_cur <= bias_array[tdata_d1];
	end
	// x_bias
	always@(posedge clk)begin
		x_bias <= ransState + bias_cur;
	end
		
	mul_16x16 mul_16x16_inst0(
		.CLK(clk),
		.A(X),
		.B(high16),
		.P(dsp_out1)
	);
	
	mul_16x16 mul_16x16_inst1(
		.CLK(clk),
		.A(X),
		.B(low16),
		.P(dsp_out2)
	);
	
	mul_18x9 mul_18x9_inst(
		.CLK(clk),
		.A(q),
		.B(cmpl_freq_dsp),
		.P(q_x_cmpl_freq)
	);



endmodule