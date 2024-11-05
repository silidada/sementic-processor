`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: GDUT
// Engineer: JF Lee
// Create Date:
// Design Name: 
// Module Name:
// Project Name: 
// Target Devices: 
// Tool Versions: vivado 2018.3
// Description: Okay
// Dependencies: 
// Revision:
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////

module mac#(
	parameter DATA_WIDTH_I = 8,
	parameter DATA_WIDTH_O = 18
)(
	input wire 	       					 clk,
	input wire 	       					 rst,
	input wire 							 en_in, 
	input wire signed [DATA_WIDTH_I-1:0] W1_IN,
	input wire signed [DATA_WIDTH_I-1:0] W2_IN,		// sign weights
	input wire signed [DATA_WIDTH_I-1:0] B_IN, 		// unsign input feature map because of relu B>=0;
	
	output reg							 en_out,
	output wire signed[DATA_WIDTH_O-1:0] PSUM_0,
	output wire signed[DATA_WIDTH_O-1:0] PSUM_1
);
	localparam AccTimes = 3; // 4-1
	reg	 [24:0] 		A;
	reg  [8:0]  		B;
	reg  [8:0]  		D;
	reg  [18:0] 		C;  // 19-bit
	wire [34:0] 		P;
	
	reg signed [15:0] 	P_OUT_0;
	reg signed [15:0] 	P_OUT_1;
	
	reg [5:0]			en_reg;
	reg					en_reg_d1;
	reg [1:0]			cnt_stage;
	reg					pingpong;
	wire 				pingpong_flip;
	
	reg signed [17:0]	psum0_0, psum0_1;
	reg signed [17:0]	psum1_0, psum1_1;
	
	assign PSUM_0 = pingpong?psum0_0:psum0_1;
	assign PSUM_1 = pingpong?psum1_0:psum1_1;
	
	// A
	always@(posedge clk)begin
		if(rst)begin
			A <= 25'b0;
		end
		else if(en_in)begin
			A <= {W2_IN, {9{1'b0}}, W1_IN};
		end
	end
	// B
	always@(posedge clk)begin
		if(rst)begin
			B <= 8'b0;
		end
		else if(en_in)begin
			B <= {B_IN[7], B_IN};
		end
	end
	// C
	always@(posedge clk)begin
		if(rst)begin
			C <= 19'd0;
		end
		else if(en_in)begin
			if(W1_IN[7]==1'b0)begin // W1_IN >= 0
				case(B_IN[7])
					1'b0: C <= 19'd0;
					1'b1: C <= {1'b0, 1'b1, {17{1'b0}}}; // 2^17
					default: C <= 19'd0;
				endcase
			end
			else if(B_IN == 8'b0000_0000)begin // note here!!! B_IN=0
				C <= 19'd0;
			end
			else begin   // W1_IN < 0
				case(B_IN[7])
					1'b0: C <= {1'b0, 1'b1, {17{1'b0}}}; // 2^17
					1'b1: C <= 19'd0;
					default: C <= 19'd0;
				endcase
			end
		end
		else begin
			C <= 19'd0;
		end
	end
	// D
	always@(posedge clk)begin
		if(rst)begin
			D <= 9'd0;
		end
		else if(en_in)begin
			if(W1_IN[7]==1'b0)begin 
				case(B_IN[7])
					1'b0: D <= 9'd0;   					// W1_IN >= 0, B>=0
					1'b1: D <= {W1_IN[7], {8{1'b0}}};   // W1_IN >= 0, B<0
					default: D <= 9'd0;  
				endcase
			end
			else begin   // W1_IN<0, B>=0; W1_IN<0, B<0
				D <= {W1_IN[7], {8{1'b0}}}; 
			end
		end
		else begin
			D <= 9'd0; 
		end
	end	
	
	// pingpong
	always@(posedge clk)begin
		if(rst)begin
			pingpong <= 1'b0;
		end
		else if(pingpong_flip)begin
			pingpong <= ~pingpong;
		end
	end
	assign pingpong_flip = (cnt_stage==AccTimes)&&en_reg[5];
	
	// en_reg
	always@(posedge clk)begin
		if(rst)begin
			en_reg <= 'd0;
		end
		else begin
			en_reg <= {en_reg[4:0], en_in};
		end
	end
	// en_reg_d1
	always@(posedge clk)begin
		if(rst)begin
			en_reg_d1 <= 1'b0;
		end
		else begin
			en_reg_d1 <= en_reg[5];
		end
	end
	
	// cnt_stage
	always@(posedge clk)begin
		if(rst)begin
			cnt_stage <= 2'b0;
		end
		else if(en_reg[5])begin
			cnt_stage <= cnt_stage + 1'b1;
		end
	end
	
	// P_OUT_0/1
	always@(posedge clk)begin
		if(rst)begin
			P_OUT_0 <= 'd0;
		end
		else begin
			P_OUT_0 <= P[15:0];
		end
	end
	always@(posedge clk)begin
		if(rst)begin
			P_OUT_1 <= 'd0;
		end
		else begin
			P_OUT_1 <= P[32:17];
		end
	end
	
	// psum0_0/1
	always@(posedge clk)begin
		if(rst)begin
			psum0_0 <= 'd0;
		end
		else if(pingpong==1'b0)begin
			if(en_reg[5])
				psum0_0 <= psum0_0 + P_OUT_0;
			else begin
				psum0_0 <= psum0_0;
			end
		end
		else if(pingpong_flip)begin
			psum0_0 <= 'd0;
		end
	end
	always@(posedge clk)begin
		if(rst)begin
			psum0_1 <= 'd0;
		end
		else if(pingpong==1'b1)begin
			if(en_reg[5])
				psum0_1 <= psum0_1 + P_OUT_0;
			else begin
				psum0_1 <= psum0_1;
			end
		end
		else if(pingpong_flip)begin
			psum0_1 <= 'd0;
		end
	end
	
	// psum1_0/1
	always@(posedge clk)begin
		if(rst)begin
			psum1_0 <= 'd0;
		end
		else if(pingpong==1'b0)begin
			if(en_reg[5])
				psum1_0 <= psum1_0 + P_OUT_1;
			else begin
				psum1_0 <= psum1_0;
			end
		end
		else if(pingpong_flip)begin
			psum1_0 <= 'd0;
		end
	end
	always@(posedge clk)begin
		if(rst)begin
			psum1_1 <= 'd0;
		end
		else if(pingpong==1'b1)begin
			if(en_reg[5])
				psum1_1 <= psum1_1 + P_OUT_1;
			else begin
				psum1_1 <= psum1_1;
			end
		end
		else if(pingpong_flip)begin
			psum1_1 <= 'd0;
		end
	end
	
	// en_out
	always@(posedge clk)begin
		if(rst)begin
			en_out <= 1'b0;
		end
		else if(en_reg_d1&&(cnt_stage==2'd3))begin
			en_out <= 1'b1;
		end
		else begin
			en_out <= 1'b0;
		end
	end
	
	DSP48_E2 DSP_inst(
		.CLK(clk), 
		.A(A),	 
		.B(B),
		.D(D),
		.C(C),
		.P(P)
	);
	

endmodule