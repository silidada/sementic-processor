//////////////////////////////////////////////////////////////////////////////////
// Company: GDUT
// Engineer: JF_Lee
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

	parameter DATA_WIDTH_P = 18;
	parameter DATA_WIDTH_O_PE = 18;
	parameter TransferTimes = 4;
	parameter S2MM = 2'b01, MM2S = 2'b10;
	// dma reg base address
	parameter DMA_REG_BASE_C0 	= 32'h4044_0000,
			  DMA_REG_BASE_C1 	= 32'h4045_0000,
			  DMA_REG_BASE_C2 	= 32'h4046_0000,
			  DMA_REG_BASE_C3 	= 32'h4047_0000,
			  DMA_REG_BASE_W  	= 32'h4048_0000,
			  DMA_REG_BASE_O_0	= 32'h4049_0000,
			  DMA_REG_BASE_O_1	= 32'h404a_0000;
	// input base address
	parameter IN_BASE_ADDR_LY1 = 32'h0100_0000,
		      IN_BASE_ADDR_LY2 = 32'h0160_0000,
			  IN_BASE_ADDR_LY3 = 32'h0560_0000,
			  IN_BASE_ADDR_LY4 = 32'h0660_0000;
	// weight base address
	parameter W_BASE_ADDR_LY1 = 32'h0800_0000,
		      W_BASE_ADDR_LY2 = 32'h0800_4000,
			  W_BASE_ADDR_LY3 = 32'h0808_4000,
			  W_BASE_ADDR_LY4 = 32'h0810_4000;
	// output base address
	parameter OUT_BASE_ADDR_LY1 = 32'h0160_0000,
		      OUT_BASE_ADDR_LY2 = 32'h0560_0000,
			  OUT_BASE_ADDR_LY3 = 32'h0660_0000,
			  OUT_BASE_ADDR_LY4 = 32'h0700_0000;
			  
	// weight address offset(32 batch)
	parameter W_ADDR_OFFSET_LY1   = 4096,
			  W_ADDR_OFFSET_LY234 = 131072,
			  W_ADDR_OFFSET_rANS  = 8160;
	// input template base address 
	parameter TEMPLATE_BASE_IN_LY1 = 0,
		      TEMPLATE_BASE_IN_LY2 = 181,
			  TEMPLATE_BASE_IN_LY3 = 1909,
			  TEMPLATE_BASE_IN_LY4 = 2293;
	// output template base address
	parameter TEMPLATE_BASE_OUT_LY1 = 0,
		      TEMPLATE_BASE_OUT_LY2 = 11520,
			  TEMPLATE_BASE_OUT_LY3 = 13824,
			  TEMPLATE_BASE_OUT_LY4 = 14336;
	// rANS DMA hyperparam
	parameter rANS_DMA_RD_TRANSTIMES 	   = 128;
	parameter rANS_DMA_RD_LENGTH_ONETRANS  = 8160;	//	120*68
	parameter rANS_DMA_WR_LENGTH_ONETRANS  = 8160;
	parameter rANS_DMA_WR_DATANUM_ONETRANS = 1020;
		
	parameter rANS_OUT_HEADER_BASE_ADDR	= 32'h0710_0000;	// base address of header information
	parameter rANS_OUT_BYTE_BASE_ADDR	= 32'h0710_0600;	// base address of byte encoded
	
	parameter 
	
	
	
			  
	
	