

module one_channel_bram#(
	parameter   DATA_WIDTH = 64
)(
	input wire						clk,
	
	input wire [5:0]				en_wr, 
	input wire [8:0]				addr_wr,
	input wire [DATA_WIDTH-1:0]   	data_wr,
	
	input wire [2:0]    			order,
	//input wire [5:0]				en_rd,
	input wire 						en_rd,
	input wire [8:0]				addr_rd_0,
	input wire [8:0]				addr_rd_1,
	input wire [8:0]				addr_rd_2,
	input wire [8:0]				addr_rd_3,
	input wire [8:0]				addr_rd_4,
	input wire [8:0]				addr_rd_5,
	output reg [DATA_WIDTH*5-1:0]  	data_rd
);
	wire [63:0] douta_0, douta_1, douta_2, douta_3, douta_4, douta_5; // not use
	wire [63:0] dinb_0, dinb_1, dinb_2, dinb_3, dinb_4, dinb_5; // not use

	wire [63:0] data_out_0, data_out_1, data_out_2,
				data_out_3, data_out_4, data_out_5;
				
	reg [2:0]	order_reg;
	
	// order_reg
	always@(posedge clk)begin
		if(en_rd)begin
			order_reg <= order;
		end
		else begin
			//order_reg <= order_reg;
			order_reg <= 3'd0;
		end
	end
	
	always@(posedge clk)begin
		case(order_reg)
			3'b001: data_rd <= {data_out_4,data_out_3,data_out_2,data_out_1,data_out_0};
			3'b010: data_rd <= {data_out_0,data_out_5,data_out_4,data_out_3,data_out_2};
			3'b100: data_rd <= {data_out_2,data_out_1,data_out_0,data_out_5,data_out_4};
			default: data_rd <= 320'd0;
		endcase
	end
	
	// bram 0  64-bit 512deep
	input_line_buffer_TPR input_line_buffer_TPR_inst_0(  // without reg output
		// input write
		.clka(clk),
		.ena(en_wr[0]),
		.wea(1),  // just write
		.addra(addr_wr),
		.dina(data_wr),
		.douta(douta_0), // not use
		// output read
		.clkb(clk),
		.enb(en_rd),
		.web(0),  // just read
		.addrb(addr_rd_0), 
		.dinb(dinb_0), // not use
		.doutb(data_out_0)
	);
	// bram 1
	input_line_buffer_TPR input_line_buffer_TPR_inst_1(
		// input write
		.clka(clk),
		.ena(en_wr[1]),
		.wea(1),  // just write
		.addra(addr_wr),
		.dina(data_wr),
		.douta(douta_1),
		// output read
		.clkb(clk),
		.enb(en_rd),
		.web(0),  // just read
		.addrb(addr_rd_1), 
		.dinb(dinb_1),
		.doutb(data_out_1)
	);
	// bram 2
	input_line_buffer_TPR input_line_buffer_TPR_inst_2(
		// input write
		.clka(clk),
		.ena(en_wr[2]),
		.wea(1),  // just write
		.addra(addr_wr),
		.dina(data_wr),
		.douta(douta_2),
		// output read
		.clkb(clk),
		.enb(en_rd),
		.web(0),  // just read
		.addrb(addr_rd_2), 
		.dinb(dinb_2),
		.doutb(data_out_2)
	);
	// bram 3
	input_line_buffer_TPR input_line_buffer_TPR_inst_3(
		// input write
		.clka(clk),
		.ena(en_wr[3]),
		.wea(1),  // just write
		.addra(addr_wr),
		.dina(data_wr),
		.douta(douta_3),
		// output read
		.clkb(clk),
		.enb(en_rd),
		.web(0),  // just read
		.addrb(addr_rd_3), 
		.dinb(dinb_3),
		.doutb(data_out_3)
	);
	// bram 4
	input_line_buffer_TPR input_line_buffer_TPR_inst_4(
		// input write
		.clka(clk),
		.ena(en_wr[4]),
		.wea(1),  // just write
		.addra(addr_wr),
		.dina(data_wr),
		.douta(douta_4),
		// output read
		.clkb(clk),
		.enb(en_rd),
		.web(0),  // just read
		.addrb(addr_rd_4), 
		.dinb(dinb_4),
		.doutb(data_out_4)
	);
	// bram 5
	input_line_buffer_TPR input_line_buffer_TPR_inst_5(
		// input write
		.clka(clk),
		.ena(en_wr[5]),
		.wea(1),  // just write
		.addra(addr_wr),
		.dina(data_wr),
		.douta(douta_5),
		// output read
		.clkb(clk),
		.enb(en_rd),
		.web(0),  // just read
		.addrb(addr_rd_5), 
		.dinb(dinb_5),
		.doutb(data_out_5)
	);
endmodule