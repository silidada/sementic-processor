//////////////////////////////////////////////////////////////////////////////////
// Company: GDUT
// Engineer: JF Lee
// 
// Create Date:  
// Design Name:
// Module Name: 
// Project Name: 
// Taget Devices: ZCU104
// Tool Versions: 2018.3
// Description: 
// Dependencies: 
// Revision: 
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////

module dma_config#(
	//parameters value---the master will start generating data from the C_M_START_DATA_VALUE value
	parameter integer M_AXI_ADDR_WIDTH = 32,	// Width of M_AXI address bus
	parameter integer M_AXI_DATA_WIDTH = 32  	// Width of M_AXI data bus
)(
	//----------------------------------clock-------------------------------------
	// AXI clock signal 总线时钟信号：
	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 M_AXI_ACLK CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M_AXI, ASSOCIATED_RESET M_AXI_ARESET" *)
	input  wire   							M_AXI_ACLK,
	(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 M_AXI_ARESET RST" *)
	(* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
	input  wire   							M_AXI_ARESET,
	
    // start signal
    input  wire   							START,
    output reg   							FINISH,
	
	input  wire  [M_AXI_ADDR_WIDTH-1:0] 	DMA_REG_BASE,
	input  wire  [M_AXI_ADDR_WIDTH-1:0] 	DMA_BUFFER_BASE,
	input  wire  [1:0] 						DIRECTION,		//S2MM OR MM2S
    input  wire  [M_AXI_DATA_WIDTH-1:0] 	TRANSFER_LEN,
	// write data address channel
	output wire  [M_AXI_ADDR_WIDTH-1:0] 	M_AXI_AWADDR,
	output wire  [2:0] 						M_AXI_AWPROT,
	output wire  							M_AXI_AWVALID,
	input  wire  							M_AXI_AWREADY,
	// write data channel
	output wire  [M_AXI_DATA_WIDTH-1:0]   	M_AXI_WDATA,
	output wire  [M_AXI_DATA_WIDTH/8-1:0] 	M_AXI_WSTRB,//8位数据选通信号
	output wire  							M_AXI_WVALID,
	input  wire  							M_AXI_WREADY,
	// write data response channel 
	input  wire  [1:0] 						M_AXI_BRESP, 
	input  wire  							M_AXI_BVALID,
	output wire  							M_AXI_BREADY,
	// read address channel 
	output wire  [M_AXI_ADDR_WIDTH-1:0] 	M_AXI_ARADDR,
	output wire  [2:0] 						M_AXI_ARPROT,
	output wire  							M_AXI_ARVALID,
	input  wire  							M_AXI_ARREADY,
	// read data channel 
	input  wire  [M_AXI_DATA_WIDTH-1:0] 	M_AXI_RDATA,
	input  wire  [1:0] 						M_AXI_RRESP,
	input  wire  							M_AXI_RVALID,
	output wire  							M_AXI_RREADY
);
	//PARAMETER DEFINE
	//DMA BASIC DEF               
	localparam MM2S_DMACR_OFFSET  = 32'h00;          //MM2S DMA Control register
	localparam S2MM_DMACR_OFFSET  = 32'h30;          //S2MM DMA Control register
	localparam MM2S_SA_OFFSET     = 32'h18;          //MM2S Source Address. Lower 32 bits of address.
	localparam S2MM_DA_OFFSET     = 32'h48;          //S2MM Destination Address. Lower 32 bit address.
	localparam MM2S_LENGTH_OFFSET = 32'h28;          //MM2S Transfer Length (Bytes)
	localparam S2MM_LENGTH_OFFSET = 32'h58;          //S2MM Buffer Length (Bytes)
	localparam MM2S_DMASR_OFFSET  = 32'h04;          //MM2S DMA Status register
	localparam S2MM_DMASR_OFFSET  = 32'h34;          //S2MM DMA Status register
								
	localparam DMA_START_SET      = 32'h0000_0001;   // START DMA
	localparam DMA_INTR_SET       = 32'h0000_1001;   // START DMA AND INTERRUPT   
	localparam DMA_INTR_CLR       = 32'h0000_1000;   // CLEAR INTERRUPT   
	//ADDRESS: 
	//DMA_CONTROL_REG_BASE
	//DMA_BUFFER	
	localparam IDLE 	= 5'b0_0001,
			   INIT 	= 5'b0_0010,
			   CONFIG 	= 5'b0_0100,
		       TRANSMIT = 5'b0_1000,
			   RESPONSE = 5'b1_0000;
	reg [4:0] state_c, state_n;
	wire trans2resp,resp2idle,resp2config;

	// AXI4-LITE 信号：
	//------------------------------valid----------------------------------------
	reg  						axi_awvalid;                   // write address valid
	reg  						axi_wvalid;  	               // write data valid
	//----------------------------acceptance-------------------------------------	
	reg  						axi_bready;					   // write response acceptance
	//-----------------------------address---------------------------------------
	reg [M_AXI_ADDR_WIDTH-1:0] 	axi_awaddr;	// write address
	reg [M_AXI_DATA_WIDTH-1:0] 	axi_wdata;	// write data

	reg [M_AXI_ADDR_WIDTH-1:0] 	DMA_REG_BASE_REG;
	reg [M_AXI_DATA_WIDTH-1:0] 	TRANSFER_LEN_REG;
	reg [M_AXI_ADDR_WIDTH-1:0] 	DMA_BUFFER_BASE_REG;
	reg [1:0] 					DIRECTION_REG;
	
	reg [1:0]					cnt_stage;	// 3 stage: write address -> write data -> get response
	reg [1:0] 					wr_trans_done;
	
	// IO_pins connection
	assign M_AXI_AWADDR	 = axi_awaddr;
	assign M_AXI_WDATA	 = axi_wdata;
	assign M_AXI_AWPROT	 = 3'b000;
	assign M_AXI_AWVALID = axi_awvalid;
	//Write Data(W)
	assign M_AXI_WVALID	 = axi_wvalid;
	assign M_AXI_WSTRB	 = 4'b1111;		//32 bit data均选通
	//Write Response (B)
	assign M_AXI_BREADY	 = axi_bready;
	//Read Address (AR)
	assign M_AXI_ARADDR  = 'd0; 
    assign M_AXI_ARVALID = 'd0;
	assign M_AXI_ARPROT	 = 3'b001;
	//Read and Read Response (R)
	assign M_AXI_RREADY  = 'd0;
	
	
	(* keep = "true" *)
	reg    rst_d1;
	always@(posedge M_AXI_ACLK)begin
		if(M_AXI_ARESET)begin
			rst_d1 <= 1'b1;
		end
		else begin
			rst_d1 <= 1'b0;
		end
	end
	
	// FSM
	always@(posedge M_AXI_ACLK)begin
		if(M_AXI_ARESET)begin
			state_c <= IDLE;
		end
		else begin
			state_c <= state_n; 
		end
	end
	always@(*)begin
		case(state_c)
			IDLE: begin
				if(START)begin
					state_n = INIT;
				end
				else begin
					state_n = IDLE;
				end
			end
			INIT: begin
				state_n = CONFIG;
			end
			CONFIG: begin
				state_n = TRANSMIT;
			end
			TRANSMIT: begin
				if(trans2resp)begin
					state_n = RESPONSE;
				end
				else begin
					state_n = TRANSMIT;
				end
			end
			RESPONSE: begin
				if(resp2idle)begin
					state_n = IDLE;
				end
				else if(resp2config)begin
					state_n = CONFIG;
				end
				else begin
					state_n = RESPONSE;	
				end
			end
			default: state_n = IDLE;
		endcase
	end
	assign trans2resp	= wr_trans_done[0]&&wr_trans_done[1];
	assign resp2idle    = (axi_bready&&M_AXI_BVALID)&&(cnt_stage==2'b10);
	assign resp2config  = axi_bready&&M_AXI_BVALID;
	
	// FINISH
	always@(posedge M_AXI_ACLK)begin
		if(M_AXI_ARESET)begin
			FINISH <= 1'b0;
		end
		else if(resp2idle)begin
			FINISH <= 1'b1;
		end
		else begin
			FINISH <= 1'b0;
		end
	end
	
	// DIRECTION_REG
	always@(posedge M_AXI_ACLK)begin
		if(M_AXI_ARESET)begin
			DIRECTION_REG <= 'd0;
		end
		else if(state_c == INIT)begin
			DIRECTION_REG <= DIRECTION;
		end
	end
	// DMA_REG_BASE_REG
	always@(posedge M_AXI_ACLK)begin
		if(M_AXI_ARESET)begin
			DMA_REG_BASE_REG <= 'd0;
		end
		else if(state_c == INIT)begin
			DMA_REG_BASE_REG <= DMA_REG_BASE;
		end
	end
	// DMA_BUFFER_BASE_REG
	always@(posedge M_AXI_ACLK)begin
		if(M_AXI_ARESET)begin
			DMA_BUFFER_BASE_REG <= 'd0;
		end
		else if(state_c == INIT)begin
			DMA_BUFFER_BASE_REG <= DMA_BUFFER_BASE;
		end
	end
	// TRANSFER_LEN_REG
	always@(posedge M_AXI_ACLK)begin
		if(M_AXI_ARESET)begin
			TRANSFER_LEN_REG <= 'd0;
		end
		else if(state_c == INIT)begin
			TRANSFER_LEN_REG <= TRANSFER_LEN;
		end
	end

	// cnt_stage
	always@(posedge M_AXI_ACLK)begin
		if(M_AXI_ARESET)begin
			cnt_stage <= 'd0;
		end
		else if(axi_bready&&M_AXI_BVALID)begin
			if(cnt_stage==2'd2)begin
				cnt_stage <= 'd0;
			end
			else begin
			    cnt_stage <= cnt_stage + 1'b1;
			end
		end
	end
	
	// axi_awaddr
    always@(posedge M_AXI_ACLK)begin
		if(M_AXI_ARESET)begin
			axi_awaddr <= 'd0;
		end
		else if(state_c==CONFIG)begin
			case(cnt_stage)
				2'd0: begin
					if(DIRECTION_REG==2'b01)begin
						axi_awaddr <= DMA_REG_BASE_REG + S2MM_DMACR_OFFSET;
					end
					else begin
						axi_awaddr <= DMA_REG_BASE_REG + MM2S_DMACR_OFFSET;
					end
				end
				2'd1: begin
					if(DIRECTION_REG==2'b01)begin
						axi_awaddr <= DMA_REG_BASE_REG + S2MM_DA_OFFSET;
					end
					else begin
						axi_awaddr <= DMA_REG_BASE_REG + MM2S_SA_OFFSET;
					end
				end
				2'd2: begin
					if(DIRECTION_REG==2'b01)begin
						axi_awaddr <= DMA_REG_BASE_REG + S2MM_LENGTH_OFFSET;
					end
					else begin
						axi_awaddr <= DMA_REG_BASE_REG + MM2S_LENGTH_OFFSET;
					end
				end
				default: axi_awaddr <= 'd0;
			endcase
		end
	end
	// axi_wdata
	always@(posedge M_AXI_ACLK)begin
		if(M_AXI_ARESET)begin
			axi_wdata <= 'd0;
		end
		else if(state_c==CONFIG)begin
			case(cnt_stage)
				2'd0: begin
					axi_wdata <= DMA_START_SET;
				end
				2'd1:begin
					axi_wdata <= DMA_BUFFER_BASE_REG;
				end
				2'd2:begin
					axi_wdata <= TRANSFER_LEN_REG;
				end
				default: axi_wdata <= 'd0;
			endcase
		end
	end
	
	// wr_trans_done
	always@(posedge M_AXI_ACLK)begin   // write address done
		if(M_AXI_ARESET)begin
			wr_trans_done[0] <= 1'b0;
		end
		else if(wr_trans_done==2'b11)begin
			wr_trans_done[0] <= 1'b0;
		end
		else if(axi_awvalid&&M_AXI_AWREADY)begin
			wr_trans_done[0] <= 1'b1;
		end
	end
	always@(posedge M_AXI_ACLK)begin   // write data done
		if(M_AXI_ARESET)begin
			wr_trans_done[1] <= 1'b0;
		end
		else if(wr_trans_done==2'b11)begin
			wr_trans_done[1] <= 1'b0;
		end
		else if(axi_wvalid&&M_AXI_WREADY)begin
			wr_trans_done[1] <= 1'b1;
		end
	end
	
	// axi_awvalid
	always@(posedge M_AXI_ACLK)begin
		if(M_AXI_ARESET)begin
			axi_awvalid <= 1'b0;
		end
		else if((state_c==TRANSMIT)&&(~wr_trans_done[0]))begin
			if(axi_awvalid&&M_AXI_AWREADY)begin
				axi_awvalid <= 1'b0;
			end
			else begin
				axi_awvalid <= 1'b1;
			end
		end
	end
	// axi_wvalid
	always@(posedge M_AXI_ACLK)begin
		if(M_AXI_ARESET)begin
			axi_wvalid <= 1'b0;
		end
		else if((state_c==TRANSMIT)&&(~wr_trans_done[1]))begin
			if(axi_wvalid&&M_AXI_WREADY)begin
				axi_wvalid <= 1'b0;
			end
			else begin
				axi_wvalid <= 1'b1;
			end
		end
	end
	// axi_bready
	always@(posedge M_AXI_ACLK)begin
		if(M_AXI_ARESET)begin
			axi_bready <= 1'b0;
		end
		else if(state_c==RESPONSE)begin
			if(axi_bready&&M_AXI_BVALID)begin
				axi_bready <= 1'b0;
			end
			else begin
				axi_bready <= 1'b1;
			end
		end
	end

endmodule