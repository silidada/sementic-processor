

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


module output_buffer#(
	parameter DATA_WIDTH_I = 8,
	parameter DATA_WIDTH_U = 72,
	parameter DATA_WIDTH_O = 64,
	parameter DATA_DEPTH   = 8192
)(
	input wire 					    clk,
	input wire 					    rst,
	input wire 					    start,
	input wire [2:0]			    layer,
	output reg 						is_dma_send, // indicate the first time to start dma
	input wire						next_batch,
	output wire						onebatch_done,
	output wire						onetranstime_done,
	output wire						read_done,
	
	input wire [3:0]				en_in,
	input wire [DATA_WIDTH_I-1:0]	din_b0, din_b1, 
	input wire [DATA_WIDTH_I-1:0]	din_b2, din_b3, 
	input wire [DATA_WIDTH_I-1:0]	din_b4, din_b5, 
	input wire [DATA_WIDTH_I-1:0]	din_b6, din_b7,
	
	input wire						M_AXIS_TREADY,
	output wire						M_AXIS_TVALID,
	output wire	[DATA_WIDTH_O-1:0]	M_AXIS_TDATA,
	output wire						M_AXIS_TLAST
);
	parameter ADDR_WIDTH  = $clog2(DATA_DEPTH);
	parameter MEMORY_SIZE = 64*DATA_DEPTH;
	
	reg 							start_d1;
	wire [3:0]						write_done;
	reg  [3:0]						write_done_flag;
	
	// write
	wire [3:0]						en_wr;
	wire [ADDR_WIDTH-1:0]			addr_wr[0:3];
	wire [DATA_WIDTH_U-1:0]			dout_b0_wr,dout_b1_wr;
	wire [DATA_WIDTH_U-1:0]			dout_b2_wr,dout_b3_wr;
	wire [DATA_WIDTH_U-1:0]			dout_b4_wr,dout_b5_wr;
	wire [DATA_WIDTH_U-1:0]			dout_b6_wr,dout_b7_wr;
	
	// read
	wire 							en_rd;
	wire [ADDR_WIDTH-1:0]			addr_rd;
	wire [DATA_WIDTH_U-1:0]			dout_b0_rd,dout_b1_rd;
	wire [DATA_WIDTH_U-1:0]			dout_b2_rd,dout_b3_rd;
	wire [DATA_WIDTH_U-1:0]			dout_b4_rd,dout_b5_rd;
	wire [DATA_WIDTH_U-1:0]			dout_b6_rd,dout_b7_rd;	
	
	
	(* keep = "true" *)
	reg [5:0] rst_d1;
	always@(posedge clk)begin
		if(rst)begin
			rst_d1 <= 6'b11_1111;
		end
		else begin
			rst_d1 <= 6'b00_0000;
		end
	end
	
	// start_d1
	always@(posedge clk)begin
		if(rst_d1[0])begin
			start_d1 <= 1'b0;
		end
		else begin
			start_d1 <= start;
		end
	end
	
	// write_done_flag
	always@(posedge clk)begin
		if(rst_d1)begin
			write_done_flag[0] <= 1'b0;
		end
		else if(write_done_flag == 4'b1111)begin
			write_done_flag[0] <= 1'b0;
		end
		else if(write_done[0])begin
			write_done_flag[0] <= 1'b1;
		end
	end
	always@(posedge clk)begin
		if(rst_d1)begin
			write_done_flag[1] <= 1'b0;
		end
		else if(write_done_flag == 4'b1111)begin
			write_done_flag[1] <= 1'b0;
		end
		else if(write_done[1])begin
			write_done_flag[1] <= 1'b1;
		end
	end
	always@(posedge clk)begin
		if(rst_d1)begin
			write_done_flag[2] <= 1'b0;
		end
		else if(write_done_flag == 4'b1111)begin
			write_done_flag[2] <= 1'b0;
		end
		else if(write_done[2])begin
			write_done_flag[2] <= 1'b1;
		end
	end
	always@(posedge clk)begin
		if(rst_d1)begin
			write_done_flag[3] <= 1'b0;
		end
		else if(write_done_flag == 4'b1111)begin
			write_done_flag[3] <= 1'b0;
		end
		else if(write_done[3])begin
			write_done_flag[3] <= 1'b1;
		end
	end
	
	// is_dma_send
	always@(posedge clk)begin
		if(rst_d1[0])begin
			is_dma_send <= 1'b0;
		end
		else if(write_done_flag == 4'b1111)begin
			is_dma_send <= 1'b1;
		end
		else begin
			is_dma_send <= 1'b0;
		end
	end
	
	// output_write_batch01
	output_write#(
		.DATA_WIDTH_I(DATA_WIDTH_I),
		.DATA_WIDTH_O(DATA_WIDTH_U),
		.ADDR_WIDTH(ADDR_WIDTH)
	)output_write_inst_b01(
		.clk(clk),
		.rst(rst_d1[1]),
		.start(start_d1),
		.layer(layer),
		.write_done(write_done[0]),
	
		.en_in(en_in[0]),
		.din_b0(din_b0), .din_b1(din_b1), 
	
		.en_wr(en_wr[0]),
		.addr_wr(addr_wr[0]),
		.dout_b0(dout_b0_wr), .dout_b1(dout_b1_wr)
	);
	// output_write_batch23
	output_write#(
		.DATA_WIDTH_I(DATA_WIDTH_I),
		.DATA_WIDTH_O(DATA_WIDTH_U),
		.ADDR_WIDTH(ADDR_WIDTH)
	)output_write_inst_b23(
		.clk(clk),
		.rst(rst_d1[2]),
		.start(start_d1),
		.layer(layer),
		.write_done(write_done[1]),
	
		.en_in(en_in[1]),
		.din_b0(din_b2), .din_b1(din_b3), 
	
		.en_wr(en_wr[1]),
		.addr_wr(addr_wr[1]),
		.dout_b0(dout_b2_wr), .dout_b1(dout_b3_wr)
	);
	// output_write_batch45
	output_write#(
		.DATA_WIDTH_I(DATA_WIDTH_I),
		.DATA_WIDTH_O(DATA_WIDTH_U),
		.ADDR_WIDTH(ADDR_WIDTH)
	)output_write_inst_b45(
		.clk(clk),
		.rst(rst_d1[3]),
		.start(start_d1),
		.layer(layer),
		.write_done(write_done[2]),
	
		.en_in(en_in[2]),
		.din_b0(din_b4), .din_b1(din_b5), 
	
		.en_wr(en_wr[2]),
		.addr_wr(addr_wr[2]),
		.dout_b0(dout_b4_wr), .dout_b1(dout_b5_wr)
	);
	// output_write_batch67
	output_write#(
		.DATA_WIDTH_I(DATA_WIDTH_I),
		.DATA_WIDTH_O(DATA_WIDTH_U),
		.ADDR_WIDTH(ADDR_WIDTH)
	)output_write_inst_b67(
		.clk(clk),
		.rst(rst_d1[4]),
		.start(start_d1),
		.layer(layer),
		.write_done(write_done[3]),
	
		.en_in(en_in[3]),
		.din_b0(din_b6), .din_b1(din_b7), 
	
		.en_wr(en_wr[3]),
		.addr_wr(addr_wr[3]),
		.dout_b0(dout_b6_wr), .dout_b1(dout_b7_wr)
	);
	
	// output_read
	output_read#(
		.DATA_WIDTH_I(DATA_WIDTH_I),
		.DATA_WIDTH_U(DATA_WIDTH_U),
		.DATA_WIDTH_O(DATA_WIDTH_O),
		.ADDR_WIDTH(ADDR_WIDTH)
	)output_read_inst(
		.clk(clk),
		.rst(rst_d1[5]),
		.start(start_d1),
		.layer(layer),
		.next_batch(next_batch),
		.onebatch_done(onebatch_done),
		.onetranstime_done(onetranstime_done),
		.read_done(read_done),
	
		.en_rd(en_rd),
		.addr_rd(addr_rd),
		.din_b0(dout_b0_rd),.din_b1(dout_b1_rd),
		.din_b2(dout_b2_rd),.din_b3(dout_b3_rd),
		.din_b4(dout_b4_rd),.din_b5(dout_b5_rd),
		.din_b6(dout_b6_rd),.din_b7(dout_b7_rd),
		
		.m_axis_tready(M_AXIS_TREADY),
		.m_axis_tvalid(M_AXIS_TVALID),
		.m_axis_tdata(M_AXIS_TDATA),
		.m_axis_tlast(M_AXIS_TLAST)
	);
	
	
	ram_output #(
      .ADDR_WIDTH(ADDR_WIDTH)
	)ram_output_inst_b0(
		.clk(clk),
		.rst(rst_d1)
		
		.ena(en_wr[0]),   
		.addra(addr_wr[0]),
		.dina(dout_b0_wr),    
		
		.enb(en_rd),   
		.addrb(addr_rd),                
		.doutb(dout_b0_rd)             
   );
	
	ram_output #(
      .ADDR_WIDTH(ADDR_WIDTH)
	)ram_output_inst_b1(
		.clk(clk),
		.rst(rst_d1)
      
		.ena(en_wr[0]),   
		.addra(addr_wr[0]),
		.dina(dout_b1_wr),    
		
		.enb(en_rd),   
		.addrb(addr_rd),                
		.doutb(dout_b1_rd)      
   );

	ram_output #(
      .ADDR_WIDTH(ADDR_WIDTH)
	)ram_output_inst_b2(
		.clk(clk),
		.rst(rst_d1)
      
		.ena(en_wr[1]),   
		.addra(addr_wr[1]),
		.dina(dout_b2_wr),    
		
		.enb(en_rd),   
		.addrb(addr_rd),                
		.doutb(dout_b2_rd)      
   );

	ram_output #(
      .ADDR_WIDTH(ADDR_WIDTH)
	)ram_output_inst_b3(
		.clk(clk),
		.rst(rst_d1)
      
		.ena(en_wr[1]),   
		.addra(addr_wr[1]),
		.dina(dout_b3_wr),    
		
		.enb(en_rd),   
		.addrb(addr_rd),                
		.doutb(dout_b3_rd)      
   );

	ram_output #(
      .ADDR_WIDTH(ADDR_WIDTH)
	)ram_output_inst_b4(
		.clk(clk),
		.rst(rst_d1)
      
		.ena(en_wr[2]),   
		.addra(addr_wr[2]),
		.dina(dout_b4_wr),    
		
		.enb(en_rd),   
		.addrb(addr_rd),                
		.doutb(dout_b4_rd)      
   );
   
	ram_output #(
      .ADDR_WIDTH(ADDR_WIDTH)
	)ram_output_inst_b5(
		.clk(clk),
		.rst(rst_d1)
      
		.ena(en_wr[2]),   
		.addra(addr_wr[2]),
		.dina(dout_b5_wr),    
		
		.enb(en_rd),   
		.addrb(addr_rd),                
		.doutb(dout_b5_rd)      
   );

	ram_output #(
      .ADDR_WIDTH(ADDR_WIDTH)
	)ram_output_inst_b6(
		.clk(clk),
		.rst(rst_d1)
      
		.ena(en_wr[3]),   
		.addra(addr_wr[3]),
		.dina(dout_b6_wr),    
		
		.enb(en_rd),   
		.addrb(addr_rd),                
		.doutb(dout_b6_rd)      
   );

	ram_output #(
      .ADDR_WIDTH(ADDR_WIDTH)
	)ram_output_inst_b7(
		.clk(clk),
		.rst(rst_d1)
      
		.ena(en_wr[3]),   
		.addra(addr_wr[3]),
		.dina(dout_b7_wr),    
		
		.enb(en_rd),   
		.addrb(addr_rd),                
		.doutb(dout_b7_rd)      
   );

endmodule