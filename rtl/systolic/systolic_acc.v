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

module systolic_acc#(
	parameter DATA_WIDTH_I = 8,
	parameter DATA_WIDTH_P = 18,
	parameter DATA_WIDTH_O = 22
)(
	input wire 					     clk,
	input wire 					     rst,
	input wire 					     start,
	input wire [2:0]			     layer,
		
	// input feature map 4 channel
	input wire [3:0]					en_fm,      // fm: feature map
	input wire [DATA_WIDTH_I*25-1:0]	din_fm_c0,
	input wire [DATA_WIDTH_I*25-1:0]	din_fm_c1,
	input wire [DATA_WIDTH_I*25-1:0]	din_fm_c2,
	input wire [DATA_WIDTH_I*25-1:0]	din_fm_c3,
	// input weight 8 batches
	input wire [7:0]					en_w,
	input wire [DATA_WIDTH_I*25-1:0]	din_w_b0,
	input wire [DATA_WIDTH_I*25-1:0]  	din_w_b1,
	input wire [DATA_WIDTH_I*25-1:0]  	din_w_b2,
	input wire [DATA_WIDTH_I*25-1:0]  	din_w_b3,
	input wire [DATA_WIDTH_I*25-1:0]  	din_w_b4,
	input wire [DATA_WIDTH_I*25-1:0]  	din_w_b5,
	input wire [DATA_WIDTH_I*25-1:0]  	din_w_b6,
	input wire [DATA_WIDTH_I*25-1:0]  	din_w_b7,
	
	output wire [15:0]				  	en_out,
	output wire [DATA_WIDTH_O-1:0]   	dout0_pe00,dout0_pe01,dout0_pe02,dout0_pe03,
	output wire [DATA_WIDTH_O-1:0]		dout0_pe10,dout0_pe11,dout0_pe12,dout0_pe13,
	output wire [DATA_WIDTH_O-1:0]   	dout0_pe20,dout0_pe21,dout0_pe22,dout0_pe23,
	output wire [DATA_WIDTH_O-1:0]   	dout0_pe30,dout0_pe31,dout0_pe32,dout0_pe33,
	
	output wire [DATA_WIDTH_O-1:0]   	dout1_pe00,dout1_pe01,dout1_pe02,dout1_pe03,
	output wire [DATA_WIDTH_O-1:0]   	dout1_pe10,dout1_pe11,dout1_pe12,dout1_pe13,
	output wire [DATA_WIDTH_O-1:0]   	dout1_pe20,dout1_pe21,dout1_pe22,dout1_pe23,
	output wire [DATA_WIDTH_O-1:0]   	dout1_pe30,dout1_pe31,dout1_pe32,dout1_pe33
);
	wire [15:0]					en_psum0;
	wire [DATA_WIDTH_P*25-1:0]  psum0_pe00,psum0_pe01,psum0_pe02,psum0_pe03;
	wire [DATA_WIDTH_P*25-1:0]  psum0_pe10,psum0_pe11,psum0_pe12,psum0_pe13;
	wire [DATA_WIDTH_P*25-1:0]  psum0_pe20,psum0_pe21,psum0_pe22,psum0_pe23;
	wire [DATA_WIDTH_P*25-1:0]  psum0_pe30,psum0_pe31,psum0_pe32,psum0_pe33;

	wire [15:0]					en_psum1;
	wire [DATA_WIDTH_P*25-1:0]  psum1_pe00,psum1_pe01,psum1_pe02,psum1_pe03;
	wire [DATA_WIDTH_P*25-1:0]  psum1_pe10,psum1_pe11,psum1_pe12,psum1_pe13;
	wire [DATA_WIDTH_P*25-1:0]  psum1_pe20,psum1_pe21,psum1_pe22,psum1_pe23;
	wire [DATA_WIDTH_P*25-1:0]  psum1_pe30,psum1_pe31,psum1_pe32,psum1_pe33;

PE_array#(
	.DATA_WIDTH_I(DATA_WIDTH_I),
	.DATA_WIDTH_O(DATA_WIDTH_P)
)PE_array_inst(
	.clk(clk),
	.rst(rst),
	
	// input feature map 4 channel
	.en_fm(en_fm),      // fm: feature map
	.din_fm_c0(din_fm_c0),
	.din_fm_c1(din_fm_c1),
	.din_fm_c2(din_fm_c2),
	.din_fm_c3(din_fm_c3),
	// input weight 8 batches
	.en_w(en_w),
	.din_w_b0(din_w_b0),
	.din_w_b1(din_w_b1),
	.din_w_b2(din_w_b2),
	.din_w_b3(din_w_b3),
	.din_w_b4(din_w_b4),
	.din_w_b5(din_w_b5),
	.din_w_b6(din_w_b6),
	.din_w_b7(din_w_b7),
	// output partial sum 0
	.en_psum0(en_psum0),
	.psum0_pe00(psum0_pe00),.psum0_pe01(psum0_pe01),.psum0_pe02(psum0_pe02),.psum0_pe03(psum0_pe03),
	.psum0_pe10(psum0_pe10),.psum0_pe11(psum0_pe11),.psum0_pe12(psum0_pe12),.psum0_pe13(psum0_pe13),
	.psum0_pe20(psum0_pe20),.psum0_pe21(psum0_pe21),.psum0_pe22(psum0_pe22),.psum0_pe23(psum0_pe23),
	.psum0_pe30(psum0_pe30),.psum0_pe31(psum0_pe31),.psum0_pe32(psum0_pe32),.psum0_pe33(psum0_pe33),
	// output partial sum 1
	.en_psum1(en_psum1),
	.psum1_pe00(psum1_pe00),.psum1_pe01(psum1_pe01),.psum1_pe02(psum1_pe02),.psum1_pe03(psum1_pe03),
	.psum1_pe10(psum1_pe10),.psum1_pe11(psum1_pe11),.psum1_pe12(psum1_pe12),.psum1_pe13(psum1_pe13),
	.psum1_pe20(psum1_pe20),.psum1_pe21(psum1_pe21),.psum1_pe22(psum1_pe22),.psum1_pe23(psum1_pe23),
	.psum1_pe30(psum1_pe30),.psum1_pe31(psum1_pe31),.psum1_pe32(psum1_pe32),.psum1_pe33(psum1_pe33)
);
	
accmulation#(
	.DATA_WIDTH_I(DATA_WIDTH_P),
	.DATA_WIDTH_O(DATA_WIDTH_O)
)accmulation_inst(
	.clk(clk),
	.rst(rst),
	.start(start),
	.layer(layer),
	
	.en_psum0(en_psum0),
	.psum0_pe00(psum0_pe00),.psum0_pe01(psum0_pe01),.psum0_pe02(psum0_pe02),.psum0_pe03(psum0_pe03),
	.psum0_pe10(psum0_pe10),.psum0_pe11(psum0_pe11),.psum0_pe12(psum0_pe12),.psum0_pe13(psum0_pe13),
	.psum0_pe20(psum0_pe20),.psum0_pe21(psum0_pe21),.psum0_pe22(psum0_pe22),.psum0_pe23(psum0_pe23),
	.psum0_pe30(psum0_pe30),.psum0_pe31(psum0_pe31),.psum0_pe32(psum0_pe32),.psum0_pe33(psum0_pe33),
	.en_psum1(en_psum1),
	.psum1_pe00(psum1_pe00),.psum1_pe01(psum1_pe01),.psum1_pe02(psum1_pe02),.psum1_pe03(psum1_pe03),
	.psum1_pe10(psum1_pe10),.psum1_pe11(psum1_pe11),.psum1_pe12(psum1_pe12),.psum1_pe13(psum1_pe13),
	.psum1_pe20(psum1_pe20),.psum1_pe21(psum1_pe21),.psum1_pe22(psum1_pe22),.psum1_pe23(psum1_pe23),
	.psum1_pe30(psum1_pe30),.psum1_pe31(psum1_pe31),.psum1_pe32(psum1_pe32),.psum1_pe33(psum1_pe33),
	
	.en_out(en_out),
	.dout0_pe00(dout0_pe00),.dout0_pe01(dout0_pe01),.dout0_pe02(dout0_pe02),.dout0_pe03(dout0_pe03),
	.dout0_pe10(dout0_pe10),.dout0_pe11(dout0_pe11),.dout0_pe12(dout0_pe12),.dout0_pe13(dout0_pe13),
	.dout0_pe20(dout0_pe20),.dout0_pe21(dout0_pe21),.dout0_pe22(dout0_pe22),.dout0_pe23(dout0_pe23),
	.dout0_pe30(dout0_pe30),.dout0_pe31(dout0_pe31),.dout0_pe32(dout0_pe32),.dout0_pe33(dout0_pe33),

	.dout1_pe00(dout1_pe00),.dout1_pe01(dout1_pe01),.dout1_pe02(dout1_pe02),.dout1_pe03(dout1_pe03),
	.dout1_pe10(dout1_pe10),.dout1_pe11(dout1_pe11),.dout1_pe12(dout1_pe12),.dout1_pe13(dout1_pe13),
	.dout1_pe20(dout1_pe20),.dout1_pe21(dout1_pe21),.dout1_pe22(dout1_pe22),.dout1_pe23(dout1_pe23),
	.dout1_pe30(dout1_pe30),.dout1_pe31(dout1_pe31),.dout1_pe32(dout1_pe32),.dout1_pe33(dout1_pe33)
);



endmodule