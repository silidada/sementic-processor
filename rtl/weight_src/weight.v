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

module weight#(
	parameter DATA_WIDTH_I 	= 64,
	parameter DATA_WIDTH_O 	= 200
)(
	input wire 						clk,
	input wire 						rst,
	input wire [2:0]				layer,
	input wire 						start_write,
	input wire 						start_read,
	output wire						read_done,
	input wire [3:0]				read_continue,
	input wire [3:0]				read_pause,
	
	//(S_AXIS) INPUT  CHANNEL
    input  wire         			S_AXIS_TVALID,
	output wire          			S_AXIS_TREADY,
	input  wire [DATA_WIDTH_I-1:0]	S_AXIS_TDATA,
	input  wire						S_AXIS_TLAST,
	
	output wire	[7:0]				en_out,
	
	output wire	[DATA_WIDTH_O-1:0]  dout_b0,
	output wire	[DATA_WIDTH_O-1:0]  dout_b1,
	output wire	[DATA_WIDTH_O-1:0]  dout_b2,
	output wire	[DATA_WIDTH_O-1:0]  dout_b3,
	output wire	[DATA_WIDTH_O-1:0]  dout_b4,
	output wire	[DATA_WIDTH_O-1:0]  dout_b5,
	output wire	[DATA_WIDTH_O-1:0]  dout_b6,
	output wire	[DATA_WIDTH_O-1:0]  dout_b7
	
);
	// weight write
	wire [7:0]					en_wr;
	wire [11:0]					addr_wr;
	wire [DATA_WIDTH_I-1: 0]	dout_wr;
	// weight read
	wire [7:0]					en_rd;
	wire [11:0]					addr_rd;
	wire [255:0]				din_rd_b0,din_rd_b2,din_rd_b4,din_rd_b6;
	wire [255:0]				din_rd_b1,din_rd_b3,din_rd_b5,din_rd_b7;				

weight_write#(
	.DATA_WIDTH(DATA_WIDTH_I)
)weight_write_inst(
	.clk(clk),
	.rst(rst),
	.start(start_write),
	.layer(layer),
	
	//(S_AXIS) INPUT  CHANNEL
    .S_AXIS_TVALID(S_AXIS_TVALID),
	.S_AXIS_TREADY(S_AXIS_TREADY),
	.S_AXIS_TDATA(S_AXIS_TDATA),
	.S_AXIS_TLAST(S_AXIS_TLAST),
	
	.en_out(en_wr),
	.addr_out(addr_wr),
	.dout(dout_wr)
);

weight_read weight_read_inst(
	.clk(clk),
	.rst(rst),
	.start(start_read),
	.layer(layer),
	.read_done(read_done),
	.read_continue(read_continue),
	.read_pause(read_pause),
	
	.en_rd(en_rd),
	.addr_rd(addr_rd),
	.din_b0(din_rd_b0),
	.din_b1(din_rd_b1),
	.din_b2(din_rd_b2),
	.din_b3(din_rd_b3),
	.din_b4(din_rd_b4),
	.din_b5(din_rd_b5),
	.din_b6(din_rd_b6),
	.din_b7(din_rd_b7),
	
	.en_out(en_out),
	.dout_b0(dout_b0),
	.dout_b1(dout_b1),
	.dout_b2(dout_b2),
	.dout_b3(dout_b3),
	.dout_b4(dout_b4),
	.dout_b5(dout_b5),
	.dout_b6(dout_b6),
	.dout_b7(dout_b7)
);

//WEIGHT BRAM
// batch_0
RAM_W RAM_W_inst_b0(
	// WRITE
	.clka(clk),
	.ena(en_wr[0]),
	.wea(1'b1), // just write
	.addra(addr_wr),
	.dina(dout_wr),
	.douta(),
	// READ
	.clkb(clk),
	.enb(en_rd[0]),
	.web(1'b0), // just read
	.addrb(addr_rd),	
	.dinb(),
	.doutb(din_rd_b0)
);
// batch_1
RAM_W RAM_W_inst_b1(
	// WRITE
	.clka(clk),
	.ena(en_wr[1]),
	.wea(1'b1), // just write
	.addra(addr_wr),
	.dina(dout_wr),
	.douta(),
	// READ
	.clkb(clk),
	.enb(en_rd[1]),
	.web(1'b0), // just read
	.addrb(addr_rd),	
	.dinb(),
	.doutb(din_rd_b1)
);
// batch_2
RAM_W RAM_W_inst_b2(
	// WRITE
	.clka(clk),
	.ena(en_wr[2]),
	.wea(1'b1), // just write
	.addra(addr_wr),
	.dina(dout_wr),
	.douta(),
	// READ
	.clkb(clk),
	.enb(en_rd[2]),
	.web(1'b0), // just read
	.addrb(addr_rd),	
	.dinb(),
	.doutb(din_rd_b2)
);
// batch_3
RAM_W RAM_W_inst_b3(
	// WRITE
	.clka(clk),
	.ena(en_wr[3]),
	.wea(1'b1), // just write
	.addra(addr_wr),
	.dina(dout_wr),
	.douta(),
	// READ
	.clkb(clk),
	.enb(en_rd[3]),
	.web(1'b0), // just read
	.addrb(addr_rd),	
	.dinb(),
	.doutb(din_rd_b3)
);
// batch_4
RAM_W RAM_W_inst_b4(
	// WRITE
	.clka(clk),
	.ena(en_wr[4]),
	.wea(1'b1), // just write
	.addra(addr_wr),
	.dina(dout_wr),
	.douta(),
	// READ
	.clkb(clk),
	.enb(en_rd[4]),
	.web(1'b0), // just read
	.addrb(addr_rd),	
	.dinb(),
	.doutb(din_rd_b4)
);
// batch_5
RAM_W RAM_W_inst_b5(
	// WRITE
	.clka(clk),
	.ena(en_wr[5]),
	.wea(1'b1), // just write
	.addra(addr_wr),
	.dina(dout_wr),
	.douta(),
	// READ
	.clkb(clk),
	.enb(en_rd[5]),
	.web(1'b0), // just read
	.addrb(addr_rd),	
	.dinb(),
	.doutb(din_rd_b5)
);
// batch_6
RAM_W RAM_W_inst_b6(
	// WRITE
	.clka(clk),
	.ena(en_wr[6]),
	.wea(1'b1), // just write
	.addra(addr_wr),
	.dina(dout_wr),
	.douta(),
	// READ
	.clkb(clk),
	.enb(en_rd[6]),
	.web(1'b0), // just read
	.addrb(addr_rd),	
	.dinb(),
	.doutb(din_rd_b6)
);
// batch_7
RAM_W RAM_W_inst_b7(
	// WRITE
	.clka(clk),
	.ena(en_wr[7]),
	.wea(1'b1), // just write
	.addra(addr_wr),
	.dina(dout_wr),
	.douta(),
	// READ
	.clkb(clk),
	.enb(en_rd[7]),
	.web(1'b0), // just read
	.addrb(addr_rd),	
	.dinb(),
	.doutb(din_rd_b7)
);


endmodule