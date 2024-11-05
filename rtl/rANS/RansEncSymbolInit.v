

module RansEncSymbolInit#(
	parameter DATAWIDTH_PDF   		= 20,
	parameter DATAWIDTH_CDF   		= 18,
	parameter DATAWIDTH_FREQ  		= 9,
	parameter DATAWIDTH_START 		= 8,
	parameter DATAWIDTH_XMAX		= 18,	// ok
	parameter DATAWIDTH_RCPFREQ		= 32,		
	parameter DATAWIDTH_BIAS		= 10,	// ok
	parameter DATAWIDTH_CMPLFREQ	= 9,	// ok
	parameter DATAWIDTH_RCPSHIFT	= 6,	// ok
	parameter SCALE_BITS	  		= 8,	
	parameter RANS_BYTE_L_SHIFT		= 8		// RANS_BYTE_L = 1 << RANS_BYTE_L_SHIFT
)(
	input wire								clk,
	input wire								rst,
	input wire								start,
	output reg								finish,
	
	output reg								en_rd_pdf,
	output reg	[				    7:0]	addr_rd_pdf,
	input wire	[	  DATAWIDTH_PDF-1:0]	data_rd_pdf,
	input wire								rd_valid_pdf,
		
	output reg								en_rd_cdf,
	output reg	[				    7:0]	addr_rd_cdf,
	input wire	[	  DATAWIDTH_CDF-1:0]	data_rd_cdf,
	input wire								rd_valid_cdf,
	
	// output
	output reg	[	 DATAWIDTH_XMAX-1:0]	x_max,
	output reg								x_max_valid,
	
	output reg	[ DATAWIDTH_RCPFREQ-1:0]	rcp_freq,
	output reg								rcp_freq_valid,
	
	output reg	[	 DATAWIDTH_BIAS-1:0]	bias,
	output reg								bias_valid,
	
	output reg	[DATAWIDTH_CMPLFREQ-1:0]	cmpl_freq,
	output reg								cmpl_freq_valid,
	
	output reg	[DATAWIDTH_RCPSHIFT-1:0]	rcp_shift,
	output reg								rcp_shift_valid
);
	localparam	SCALE	  	  = 1 << SCALE_BITS;
	localparam	BiasAddScale1 = (1 << SCALE_BITS) - 1;

	reg								en_work;
	reg		[				 7:0]	cnt_out;
	
	reg								cdf_valid;
	reg 	[DATAWIDTH_START-1:0]	cdf;
	reg								freq_valid;
	reg 	[ DATAWIDTH_FREQ-1:0]	freq;
	reg		[ DATAWIDTH_FREQ-1:0]	freq_d1;
	reg		[ DATAWIDTH_FREQ-1:0]	freq_d2;
	reg		[ DATAWIDTH_FREQ-1:0]	freq_1;	
	reg		[                5:0]	shift_lut[0:255];
	reg		[                5:0]	shift;	
	reg								shift_valid;
	reg		[				39:0]	shift_31;
	reg								shift_31_valid;
	
	wire							freq_lower_than_2;
	reg		[               10:0]	freq_low2_dly;
	
	reg		[				39:0]	dividend;
	reg		[ 				15:0]	divisor;
	reg								dividend_valid;
	reg								divisor_valid;
	wire	[				55:0]	div_out;
	wire							div_out_valid;
	
	// shift_lut
	initial begin: shift_lut_impl
		integer i, j;
		shift_lut[0] = 0;
		shift_lut[1] = 0;
		shift_lut[2] = 32;
		for(i=3; i<=4; i=i+1)begin
			shift_lut[i] = 33; 
		end
		for(i=5; i<=8; i=i+1)begin
			shift_lut[i] = 34; 
		end
		for(i=9; i<=16; i=i+1)begin
			shift_lut[i] = 35;
		end
		for(i=17; i<=32; i=i+1)begin
			shift_lut[i] = 36;
		end
		for(i=33; i<=64; i=i+1)begin
			shift_lut[i] = 37;
		end
		for(i=65; i<=128; i=i+1)begin
			shift_lut[i] = 38;
		end
		for(i=129; i<256; i=i+1)begin
			shift_lut[i] = 39;
		end
	end

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
		if((cnt_out==255)&&rcp_freq_valid)begin
			finish <= 1'b1;
		end
		else begin
			finish <= 1'b0;
		end
	end
	
	// en_work
	always@(posedge clk)begin
		if(rst_d1)begin
			en_work <= 1'b0;
		end
		else if((addr_rd_pdf==254)&&en_rd_pdf)begin
			en_work <= 1'b0;
		end
		else if(start)begin
			en_work <= 1'b1;
		end
		else begin
			en_work <= en_work;
		end
	end
	
	// cnt_out
	always@(posedge clk)begin
		if(rst_d1)begin
			cnt_out <= 'd0;
		end
		else if(rcp_freq_valid)begin
			cnt_out <= cnt_out + 1'b1;
		end
		else begin
			cnt_out <= cnt_out;
		end
	end
	
	
// ============== pdf ============== 
	// en_rd_pdf
	always@(posedge clk)begin
		if(en_work)begin
			en_rd_pdf <= 1'b1;
		end
		else begin
			en_rd_pdf <= 1'b0;
		end
	end
	// addr_rd_pdf
	always@(posedge clk)begin
		if(rst_d1)begin
			addr_rd_pdf <= 'd0;
		end
		else if(en_rd_pdf)begin
			addr_rd_pdf <= addr_rd_pdf + 1'b1;
		end
		else begin
			addr_rd_pdf <= addr_rd_pdf;
		end
	end
	// freq
	// freq_valid
	always@(posedge clk)begin
		freq 		<= data_rd_pdf[DATAWIDTH_FREQ-1:0];
		freq_valid 	<= rd_valid_pdf;
	end
	// freq_d1
	always@(posedge clk)begin
		freq_d1 		<= freq;
		freq_d2 		<= freq_d1;
	end
	
// ============== cdf ============== 	
	// en_rd_cdf
	always@(posedge clk)begin
		if(en_work)begin
			en_rd_cdf <= 1'b1;
		end
		else begin
			en_rd_cdf <= 1'b0;
		end
	end
	// addr_rd_cdf
	always@(posedge clk)begin
		if(rst_d1)begin
			addr_rd_cdf <= 'd255;
		end
		else if(en_rd_cdf)begin
			addr_rd_cdf <= addr_rd_cdf + 1'b1;
		end
		else begin
			addr_rd_cdf <= addr_rd_cdf;
		end
	end
	// cdf
	// cdf_valid
	always@(posedge clk)begin
		cdf 	  <= data_rd_cdf[DATAWIDTH_START-1:0];
		cdf_valid <= rd_valid_cdf;
	end	
	
	
	// freq_lower_than_2
	assign freq_lower_than_2 = freq_valid&&(freq < 2);
	// freq_low2_dly
	always@(posedge clk)begin
		if(rst_d1)begin
			freq_low2_dly <= 'd0;
		end
		else begin
			freq_low2_dly <= {freq_low2_dly[9:0], freq_lower_than_2};
		end
	end
	
	// shift
	always@(posedge clk)begin
		shift		<= shift_lut[freq];
		shift_valid <= freq_valid;	
	end
	
	// freq_1
	always@(posedge clk)begin
		freq_1 <= freq_d1 - 1'b1;
	end
	// shift_31_valid
	always@(posedge clk)begin
		case(shift)
			39: shift_31 <= 40'b1000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
			38: shift_31 <= 40'b0100_0000_0000_0000_0000_0000_0000_0000_0000_0000;
			37: shift_31 <= 40'b0010_0000_0000_0000_0000_0000_0000_0000_0000_0000;
			36: shift_31 <= 40'b0001_0000_0000_0000_0000_0000_0000_0000_0000_0000;
			35: shift_31 <= 40'b0000_1000_0000_0000_0000_0000_0000_0000_0000_0000;
			34: shift_31 <= 40'b0000_0100_0000_0000_0000_0000_0000_0000_0000_0000;
			33: shift_31 <= 40'b0000_0010_0000_0000_0000_0000_0000_0000_0000_0000;
			32: shift_31 <= 40'b0000_0001_0000_0000_0000_0000_0000_0000_0000_0000;
			default: shift_31 <= 'd0;				
		endcase
		shift_31_valid <= shift_valid&&(shift>0);		
	end
	// divisor
	// divisor_valid
	always@(posedge clk)begin
		divisor 	  <= freq_d2;
		divisor_valid <= shift_31_valid;		
	end
	// dividend
	// dividend_valid
	always@(posedge clk)begin
		dividend 	   <= shift_31 + freq_1;
		dividend_valid <= shift_31_valid;
	end
	
	// x_max
	// x_max_valid
	always@(posedge clk)begin
		if(freq_valid)begin
			x_max <= freq << RANS_BYTE_L_SHIFT;
			x_max_valid <= 1'b1;
		end
		else begin
			x_max <= 'd0;
			x_max_valid <= 1'b0;
		end
	end
	
	// rcp_freq
	// rcp_freq_valid
	always@(posedge clk)begin
		//if(freq_low2_dly[10])begin   // divider latency = 7
		if(freq_low2_dly[11])begin     // divider latency = 8	
			rcp_freq 		<= 32'hffff_ffff;
			rcp_freq_valid 	<= 1'b1;
		end
		else begin
			rcp_freq 		<= div_out[47:16];
			rcp_freq_valid 	<= div_out_valid;		
		end
	end
	
	// bias
	// bias_valid
	always@(posedge clk)begin
		case(freq_lower_than_2)
			1'b0: bias <= cdf;
			1'b1: bias <= cdf + BiasAddScale1;
			default: bias <= 'd0;
		endcase
		bias_valid <= cdf_valid;
	end
	
	// cmpl_freq
	// cmpl_freq_valid
	always@(posedge clk)begin
		if(freq_valid)begin
			cmpl_freq 		<= SCALE - freq;
			cmpl_freq_valid <= 1'b1;
		end
		else begin
			cmpl_freq 		<= 'd0;
			cmpl_freq_valid <= 1'b0;		
		end
	end
	
	// rcp_shift
	// rcp_shift_valid
	always@(posedge clk)begin
		if(freq_low2_dly[0])begin
			rcp_shift <= 32;
			rcp_shift_valid <= 1'b1;
		end
		else if(shift_valid)begin
			rcp_shift 		<= shift;
			rcp_shift_valid <= 1'b1;
		end
		else begin
			rcp_shift 		<= 'd0;
			rcp_shift_valid <= 1'b0;		
		end
	end
	
	
	// latency=2 unsigned
	div_40_16 divider_inst(
		.aclk(clk),
		.s_axis_divisor_tvalid(divisor_valid), 
		.s_axis_divisor_tdata(divisor), 
		.s_axis_dividend_tvalid(dividend_valid), 
		.s_axis_dividend_tdata(dividend), 
		
		.m_axis_dout_tvalid(div_out_valid), 
		.m_axis_dout_tdata(div_out)
	);
	
endmodule