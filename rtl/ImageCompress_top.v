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

`include "hyperparam.vh"

module ImageCompress_top#(
	//parameters value---the master will start generating data from the C_M_START_DATA_VALUE value
	parameter integer DATA_WIDTH	   = 64,
	parameter integer M_AXI_ADDR_WIDTH = 32,	// Width of M_AXI address bus
	parameter integer M_AXI_DATA_WIDTH = 32  	// Width of M_AXI data bus
)(
	input  wire 							clk,
	input  wire 							rst,
	input  wire 							start,
	output reg 								finish,
//>>>>> DMA configuration <<<<<
// ==================== input feature map ====================  
//>>>>> C0 <<<<<:
	// write data address channel
	output wire  [M_AXI_ADDR_WIDTH-1:0]   	M_AXI_AWADDR_C0,
	output wire  [2:0] 					  	M_AXI_AWPROT_C0,
	output wire  						  	M_AXI_AWVALID_C0,
	input  wire  						  	M_AXI_AWREADY_C0,
	// write data channel
	output wire  [M_AXI_DATA_WIDTH-1:0]   	M_AXI_WDATA_C0,
	output wire  [M_AXI_DATA_WIDTH/8-1:0] 	M_AXI_WSTRB_C0,
	output wire  							M_AXI_WVALID_C0,
	input  wire  							M_AXI_WREADY_C0,
	// write data response channel
	input  wire  [1:0] 						M_AXI_BRESP_C0, 
	input  wire  							M_AXI_BVALID_C0,
	output wire  							M_AXI_BREADY_C0,
	// read address channel
	output wire  [M_AXI_ADDR_WIDTH-1:0] 	M_AXI_ARADDR_C0,
	output wire  [2:0] 						M_AXI_ARPROT_C0,
	output wire  							M_AXI_ARVALID_C0,
	input  wire  							M_AXI_ARREADY_C0,
	// read data channel
	input  wire  [M_AXI_DATA_WIDTH-1:0] 	M_AXI_RDATA_C0,
	input  wire  [1:0] 						M_AXI_RRESP_C0,
	input  wire  							M_AXI_RVALID_C0,
	output wire  							M_AXI_RREADY_C0,

//>>>>> C1 <<<<<:
	// write data address channel
	output wire  [M_AXI_ADDR_WIDTH-1:0]   	M_AXI_AWADDR_C1,
	output wire  [2:0] 					  	M_AXI_AWPROT_C1,
	output wire  						  	M_AXI_AWVALID_C1,
	input  wire  						  	M_AXI_AWREADY_C1,
	// write data channel
	output wire  [M_AXI_DATA_WIDTH-1:0]   	M_AXI_WDATA_C1,
	output wire  [M_AXI_DATA_WIDTH/8-1:0] 	M_AXI_WSTRB_C1,
	output wire  							M_AXI_WVALID_C1,
	input  wire  							M_AXI_WREADY_C1,
	// write data response channel
	input  wire  [1:0] 						M_AXI_BRESP_C1, 
	input  wire  							M_AXI_BVALID_C1,
	output wire  							M_AXI_BREADY_C1,
	// read address channel
	output wire  [M_AXI_ADDR_WIDTH-1:0] 	M_AXI_ARADDR_C1,
	output wire  [2:0] 						M_AXI_ARPROT_C1,
	output wire  							M_AXI_ARVALID_C1,
	input  wire  							M_AXI_ARREADY_C1,
	// read data channel
	input  wire  [M_AXI_DATA_WIDTH-1:0] 	M_AXI_RDATA_C1,
	input  wire  [1:0] 						M_AXI_RRESP_C1,
	input  wire  							M_AXI_RVALID_C1,
	output wire  							M_AXI_RREADY_C1,
	
//>>>>> C2 <<<<<:
	// write data address channel
	output wire  [M_AXI_ADDR_WIDTH-1:0]   	M_AXI_AWADDR_C2,
	output wire  [2:0] 					  	M_AXI_AWPROT_C2,
	output wire  						  	M_AXI_AWVALID_C2,
	input  wire  						  	M_AXI_AWREADY_C2,
	// write data channel
	output wire  [M_AXI_DATA_WIDTH-1:0]   	M_AXI_WDATA_C2,
	output wire  [M_AXI_DATA_WIDTH/8-1:0] 	M_AXI_WSTRB_C2,
	output wire  							M_AXI_WVALID_C2,
	input  wire  							M_AXI_WREADY_C2,
	// write data response channel
	input  wire  [1:0] 						M_AXI_BRESP_C2, 
	input  wire  							M_AXI_BVALID_C2,
	output wire  							M_AXI_BREADY_C2,
	// read address channel
	output wire  [M_AXI_ADDR_WIDTH-1:0] 	M_AXI_ARADDR_C2,
	output wire  [2:0] 						M_AXI_ARPROT_C2,
	output wire  							M_AXI_ARVALID_C2,
	input  wire  							M_AXI_ARREADY_C2,
	// read data channel
	input  wire  [M_AXI_DATA_WIDTH-1:0] 	M_AXI_RDATA_C2,
	input  wire  [1:0] 						M_AXI_RRESP_C2,
	input  wire  							M_AXI_RVALID_C2,
	output wire  							M_AXI_RREADY_C2,

//>>>>> C3 <<<<<:
	// write data address channel
	output wire  [M_AXI_ADDR_WIDTH-1:0]   	M_AXI_AWADDR_C3,
	output wire  [2:0] 					  	M_AXI_AWPROT_C3,
	output wire  						  	M_AXI_AWVALID_C3,
	input  wire  						  	M_AXI_AWREADY_C3,
	// write data channel
	output wire  [M_AXI_DATA_WIDTH-1:0]   	M_AXI_WDATA_C3,
	output wire  [M_AXI_DATA_WIDTH/8-1:0] 	M_AXI_WSTRB_C3,
	output wire  							M_AXI_WVALID_C3,
	input  wire  							M_AXI_WREADY_C3,
	// write data response channel
	input  wire  [1:0] 						M_AXI_BRESP_C3, 
	input  wire  							M_AXI_BVALID_C3,
	output wire  							M_AXI_BREADY_C3,
	// read address channel
	output wire  [M_AXI_ADDR_WIDTH-1:0] 	M_AXI_ARADDR_C3,
	output wire  [2:0] 						M_AXI_ARPROT_C3,
	output wire  							M_AXI_ARVALID_C3,
	input  wire  							M_AXI_ARREADY_C3,
	// read data channel
	input  wire  [M_AXI_DATA_WIDTH-1:0] 	M_AXI_RDATA_C3,
	input  wire  [1:0] 						M_AXI_RRESP_C3,
	input  wire  							M_AXI_RVALID_C3,
	output wire  							M_AXI_RREADY_C3,

// ==================== weight ====================  
	// write data address channel
	output wire  [M_AXI_ADDR_WIDTH-1:0]   	M_AXI_AWADDR_W,
	output wire  [2:0] 					  	M_AXI_AWPROT_W,
	output wire  						  	M_AXI_AWVALID_W,
	input  wire  						  	M_AXI_AWREADY_W,
	// write data channel
	output wire  [M_AXI_DATA_WIDTH-1:0]   	M_AXI_WDATA_W,
	output wire  [M_AXI_DATA_WIDTH/8-1:0] 	M_AXI_WSTRB_W,
	output wire  							M_AXI_WVALID_W,
	input  wire  							M_AXI_WREADY_W,
	// write data response channel
	input  wire  [1:0] 						M_AXI_BRESP_W, 
	input  wire  							M_AXI_BVALID_W,
	output wire  							M_AXI_BREADY_W,
	// read address channel
	output wire  [M_AXI_ADDR_WIDTH-1:0] 	M_AXI_ARADDR_W,
	output wire  [2:0] 						M_AXI_ARPROT_W,
	output wire  							M_AXI_ARVALID_W,
	input  wire  							M_AXI_ARREADY_W,
	// read data channel
	input  wire  [M_AXI_DATA_WIDTH-1:0] 	M_AXI_RDATA_W,
	input  wire  [1:0] 						M_AXI_RRESP_W,
	input  wire  							M_AXI_RVALID_W,
	output wire  							M_AXI_RREADY_W,

// ==================== output feature map ===================
	// write data address channel
	output wire  [M_AXI_ADDR_WIDTH-1:0]   	M_AXI_AWADDR_O_0,
	output wire  [2:0] 					  	M_AXI_AWPROT_O_0,
	output wire  						  	M_AXI_AWVALID_O_0,
	input  wire  						  	M_AXI_AWREADY_O_0,
	// write data channel
	output wire  [M_AXI_DATA_WIDTH-1:0]   	M_AXI_WDATA_O_0,
	output wire  [M_AXI_DATA_WIDTH/8-1:0] 	M_AXI_WSTRB_O_0,
	output wire  							M_AXI_WVALID_O_0,
	input  wire  							M_AXI_WREADY_O_0,
	// write data response channel
	input  wire  [1:0] 						M_AXI_BRESP_O_0, 
	input  wire  							M_AXI_BVALID_O_0,
	output wire  							M_AXI_BREADY_O_0,
	// read address channel
	output wire  [M_AXI_ADDR_WIDTH-1:0] 	M_AXI_ARADDR_O_0,
	output wire  [2:0] 						M_AXI_ARPROT_O_0,
	output wire  							M_AXI_ARVALID_O_0,
	input  wire  							M_AXI_ARREADY_O_0,
	// read data channel
	input  wire  [M_AXI_DATA_WIDTH-1:0] 	M_AXI_RDATA_O_0,
	input  wire  [1:0] 						M_AXI_RRESP_O_0,
	input  wire  							M_AXI_RVALID_O_0,
	output wire  							M_AXI_RREADY_O_0,
	
	// write data address channel
	output wire  [M_AXI_ADDR_WIDTH-1:0]   	M_AXI_AWADDR_O_1,
	output wire  [2:0] 					  	M_AXI_AWPROT_O_1,
	output wire  						  	M_AXI_AWVALID_O_1,
	input  wire  						  	M_AXI_AWREADY_O_1,
	// write data channel
	output wire  [M_AXI_DATA_WIDTH-1:0]   	M_AXI_WDATA_O_1,
	output wire  [M_AXI_DATA_WIDTH/8-1:0] 	M_AXI_WSTRB_O_1,
	output wire  							M_AXI_WVALID_O_1,
	input  wire  							M_AXI_WREADY_O_1,
	// write data response channel
	input  wire  [1:0] 						M_AXI_BRESP_O_1, 
	input  wire  							M_AXI_BVALID_O_1,
	output wire  							M_AXI_BREADY_O_1,
	// read address channel
	output wire  [M_AXI_ADDR_WIDTH-1:0] 	M_AXI_ARADDR_O_1,
	output wire  [2:0] 						M_AXI_ARPROT_O_1,
	output wire  							M_AXI_ARVALID_O_1,
	input  wire  							M_AXI_ARREADY_O_1,
	// read data channel
	input  wire  [M_AXI_DATA_WIDTH-1:0] 	M_AXI_RDATA_O_1,
	input  wire  [1:0] 						M_AXI_RRESP_O_1,
	input  wire  							M_AXI_RVALID_O_1,
	output wire  							M_AXI_RREADY_O_1,

// >>>>> DMA transfer <<<<<
// ==================== input feature map ====================  
	//CH0:
    input  wire       						s_axis_tvalid_c0,
	output wire       						s_axis_tready_c0,
	input  wire	 [DATA_WIDTH-1:0] 			s_axis_tdata_c0,
    input  wire	       						s_axis_tlast_c0,
	//CH1:
    input  wire       						s_axis_tvalid_c1,
	output wire       						s_axis_tready_c1,
	input  wire  [DATA_WIDTH-1:0] 			s_axis_tdata_c1,
    input  wire       						s_axis_tlast_c1,
	//CH2:
    input  wire       						s_axis_tvalid_c2,
	output wire       						s_axis_tready_c2,
	input  wire  [DATA_WIDTH-1:0] 			s_axis_tdata_c2,
    input  wire       						s_axis_tlast_c2,
	//CH3:
    input  wire       						s_axis_tvalid_c3,
	output wire       						s_axis_tready_c3,
	input  wire  [DATA_WIDTH-1:0]			s_axis_tdata_c3,
    input  wire       						s_axis_tlast_c3,
	
// ==================== weight ====================  
    input  wire       						s_axis_tvalid_w,
	output wire       						s_axis_tready_w,
	input  wire  [DATA_WIDTH-1:0] 			s_axis_tdata_w,
    input  wire       						s_axis_tlast_w,

// ==================== output feature map ===================
	input  wire  							m_axis_tready_out_0,
	output wire  [DATA_WIDTH-1:0] 			m_axis_tdata_out_0,
	output wire  							m_axis_tvalid_out_0,
	output wire  							m_axis_tlast_out_0,

	input  wire  							m_axis_tready_out_1,
	output wire  [DATA_WIDTH-1:0] 			m_axis_tdata_out_1,
	output wire  							m_axis_tvalid_out_1,
	output wire  							m_axis_tlast_out_1
);
	parameter IDLE 		= 7'b000_0001,
	          CONFIG_LY = 7'b000_0010,
			  LOAD_W	= 7'b000_0100,
			  LOAD_IN	= 7'b000_1000,
			  WORK		= 7'b001_0000,
			  ENCODE	= 7'b010_0000,
			  WAIT		= 7'b100_0000;
			  
	reg [6:0] state_c, state_n;
	wire config_ly2load_w, load_w2load_in, work2wait, wait2work, wait2config_ly;
	reg load_in2work;
	reg config_ly_d1;
	reg	wait2encode;
	
	reg [2:0] 					layer;

	//
	reg [7:0]					TILE_DEEP_IN;
	reg [4:0]					BLOCK_DEEP_IN;
	reg [4:0]					LOOP_DEEP_IN;
	reg [7:0]					LOOP_DEEP_OUT;
	
// ======= dma config ======= 
	reg  [3:0]					dma_in_cfg_start;
	wire [3:0]					dma_in_cfg_finish;
	reg  [3:0]					dma_in_cfg_finish_flag;
	
	reg  						dma_w_cfg_start;
	wire						dma_w_cfg_finish;
	reg 						dma_w_cfg_finish_flag;
	
	reg  						dma_o_cfg_start;
	wire 						dma_o_cfg_start_0, dma_o_cfg_start_1;					
	wire [1:0]					dma_o_cfg_finish;
	reg 						dma_o_cfg_finish_flag;
	
	// write/read DDR base address
	reg [31:0]					DMA_C0_RD_BASE_ADDR;
	reg [31:0]					DMA_C1_RD_BASE_ADDR;
	reg [31:0]					DMA_C2_RD_BASE_ADDR;
	reg [31:0]					DMA_C3_RD_BASE_ADDR;
	reg [31:0]					DMA_W_RD_BASE_ADDR;
	reg [31:0]					DMA_O_WR_BASE_ADDR;
	
	// write/read length(Byte)
	reg [31:0]					DMA_IN_TRANS_LEN;
	reg [31:0]					DMA_W_TRANS_LEN;
	reg [31:0]					DMA_O_TRANS_LEN;
	
	// input dma
	reg [7:0]					cnt_tile_deep_in;
	reg [4:0]					cnt_block_deep_in;
	reg [4:0]					cnt_loop_deep_in;
	reg [1:0]					cnt_trans_times_in;
	wire						add_cnt_tile_deep_in,end_cnt_tile_deep_in;
	wire						add_cnt_block_deep_in,end_cnt_block_deep_in;
	wire						add_cnt_loop_deep_in,end_cnt_loop_deep_in;
	wire 						add_cnt_trans_times_in,end_cnt_trans_times_in;
	reg							end_cnt_trans_times_in_reg;
	// output dma
	reg [4:0]					cnt_dma_out_times;   // 32 times = 1 dma_trans_32batch
	reg	[7:0]					cnt_dma_out_32batch; // max is LOOP_DEEP_OUT, maybe no use
	reg [7:0]					cnt_loop_deep_out;
	wire						add_cnt_dma_out_times,end_cnt_dma_out_times;
	wire						add_cnt_dma_out_32batch,end_cnt_dma_out_32batch;
	wire						add_cnt_loop_deep_out,end_cnt_loop_deep_out;
	
	// dma in/out address template
	reg  [11:0]					template_addr_in;
	wire [127:0]				template_dout_in;   	// {dma_c3,dma_c2,dma_c1,dma_c0}
	reg  [13:0]					template_addr_out;
	wire [31:0]					template_dout_out;
	
	reg							start_acc_post_obuf;
	
// >>>>> input buffer <<<<<
	reg 						start_inbuf;
	reg 						start_inbuf_reg;
	reg 						start_read_inbuf;
	wire						oneslice_wr_done;
	wire						is_dma_write;
	wire [3:0]					read_continue;
	wire [3:0]					read_pause;
	
	wire [3:0]					en_out;
	wire [199:0]				dout_c0,dout_c1,dout_c2,dout_c3;


// >>>>> weight <<<<<
	wire						s_axis_tready_w_;

	reg 						start_write_w;
	reg [8:0] 					start_read_w;
	wire 						read_done_w;
	reg							trans_w_done;
	reg [2:0]					cnt_trans_times_w;
	wire						add_cnt_trans_times_w, end_cnt_trans_times_w;
	reg							end_cnt_trans_times_w_reg;
	
	// output
	wire [7:0] 					en_out_w;
	wire [199:0]				dout_b0_w,dout_b1_w,dout_b2_w,dout_b3_w;
	wire [199:0]				dout_b4_w,dout_b5_w,dout_b6_w,dout_b7_w;
	
	
// >>>>> systolic_acc <<<<<
	wire [15:0]				  	en_out_acc;
	wire [DATA_WIDTH_O_PE-1:0]  dout0_pe00,dout0_pe01,dout0_pe02,dout0_pe03;
	wire [DATA_WIDTH_O_PE-1:0]  dout0_pe10,dout0_pe11,dout0_pe12,dout0_pe13;
	wire [DATA_WIDTH_O_PE-1:0]  dout0_pe20,dout0_pe21,dout0_pe22,dout0_pe23;
	wire [DATA_WIDTH_O_PE-1:0]  dout0_pe30,dout0_pe31,dout0_pe32,dout0_pe33;

	wire [DATA_WIDTH_O_PE-1:0]  dout1_pe00,dout1_pe01,dout1_pe02,dout1_pe03;
	wire [DATA_WIDTH_O_PE-1:0]  dout1_pe10,dout1_pe11,dout1_pe12,dout1_pe13;
	wire [DATA_WIDTH_O_PE-1:0]  dout1_pe20,dout1_pe21,dout1_pe22,dout1_pe23;
	wire [DATA_WIDTH_O_PE-1:0]  dout1_pe30,dout1_pe31,dout1_pe32,dout1_pe33;

// >>>>> post_process <<<<<
	wire [3:0]				  	en_out_bn;
	wire [8-1:0]				dout_bn0_b01, dout_bn1_b01;
	wire [8-1:0]				dout_bn0_b23, dout_bn1_b23; 
	wire [8-1:0]				dout_bn0_b45, dout_bn1_b45; 
	wire [8-1:0]				dout_bn0_b67, dout_bn1_b67;


// >>>>> output_buffer <<<<<
	wire					  	is_dma_send;
	reg					  		is_dma_send_reg;
	reg					  		is_dma_send_valid;
	wire						onebatch_done;
	wire						onetranstime_done;
	wire						obuf_read_done;
	reg 						next_batch;
	reg							next_batch_resume;
	reg							is_WrFastRd;     // write ram faster than read data from ram
	reg 					  	trans_out_done;  // transfer 1 block done(32 batch = 4reuse * 8batch)
	
	reg							dma_out_ppong; // switch dma_0/1 to transfer data current batch
	wire						m_axis_tready_obuf;
	wire						m_axis_tvalid_obuf;
	wire [DATA_WIDTH-1:0]		m_axis_tdata_obuf;
	wire						m_axis_tlast_obuf;

// >>>>> rANS encode <<<<<
	reg							start_rans;
	wire						init_done_rans;
	reg	 [3:0]					init_done_rans_dly;
	wire						onetrans_rd_done_rans;	// data in a single trans has read done
	wire						all_rd_done_rans;		// all data being encoded has read done
	wire						next_trans_wr_rans;
	reg							next_trans_wr_rans_d1; // delay 1 clk to ensure DMA_O_WR_BASE_ADDR has been updated
	reg							start_next_trans_wr_rans;
	wire						enc_done_rans;
	wire						finish_rans;
	
	reg							tvalid_rans;
	reg   [DATA_WIDTH-1:0] 		tdata_rans;
	reg							tlast_rans;
	
	wire       					s_axis_tvalid_rans;
	wire       					s_axis_tready_rans;
	wire  [DATA_WIDTH-1:0] 		s_axis_tdata_rans;
    wire       					s_axis_tlast_rans;
	
	wire						m_axis_tready_rans;
	wire						m_axis_tvalid_rans;
	wire [DATA_WIDTH-1:0]		m_axis_tdata_rans;
	wire						m_axis_tlast_rans;	
	
	// =============================================================================
	// 								distribute wire
	// =============================================================================

	assign s_axis_tready_w 		= (state_c==ENCODE) ? s_axis_tready_rans : s_axis_tready_w_;
	
	assign m_axis_tready_obuf	= dma_out_ppong	?	m_axis_tready_out_1	:	m_axis_tready_out_0;
	assign m_axis_tready_rans	= (state_c==ENCODE) ? (dma_out_ppong ?	m_axis_tready_out_1	:	m_axis_tready_out_0): (1'b0);
	// dma out 0
	assign m_axis_tvalid_out_0	= dma_out_ppong	?	(1'b0)	:	((state_c==ENCODE) ? m_axis_tvalid_rans : m_axis_tvalid_obuf);
	assign m_axis_tdata_out_0	= (state_c==ENCODE) ? m_axis_tdata_rans : m_axis_tdata_obuf;
	assign m_axis_tlast_out_0	= dma_out_ppong	?	(1'b0)	:	((state_c==ENCODE) ? m_axis_tlast_rans  : m_axis_tlast_obuf);
	// dma out 1
	assign m_axis_tvalid_out_1	= dma_out_ppong	?	((state_c==ENCODE) ? m_axis_tvalid_rans : m_axis_tvalid_obuf)	:	(1'b0);
	assign m_axis_tdata_out_1	= (state_c==ENCODE) ? m_axis_tdata_rans : m_axis_tdata_obuf;
	assign m_axis_tlast_out_1	= dma_out_ppong	?	((state_c==ENCODE) ? m_axis_tlast_rans  : m_axis_tlast_obuf )	:	(1'b0);
	
	/////////////////////////////////////////////////////////
	//                         FSM                       
	/////////////////////////////////////////////////////////
	always@(posedge clk)begin
		if(rst)begin
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
					state_n = CONFIG_LY;
				end
				else begin
					state_n = IDLE;
				end
			end
			CONFIG_LY: begin
				if(config_ly2load_w)begin
					state_n = LOAD_W;
				end
				else begin
					state_n = CONFIG_LY;
				end
			end
			LOAD_W: begin
				if(load_w2load_in)begin
					state_n = LOAD_IN;
				end
				else begin
					state_n = LOAD_W;
				end
			end
			LOAD_IN: begin
				if(load_in2work)begin
					state_n = WORK;
				end
				else begin
					state_n = LOAD_IN;
				end	
			end
			WORK: begin
				if(work2wait)begin
					state_n = WAIT;
				end
				else begin
					state_n = WORK;
				end
			end
			ENCODE: begin
				if(finish_rans)begin
					state_n = IDLE;
				end
				else begin
					state_n = ENCODE;
				end
			end
			WAIT: begin
				if(wait2config_ly)begin
					state_n = CONFIG_LY;
				end	
				else if(wait2work)begin
					state_n = WORK;
				end
				else if(wait2encode)begin
					state_n = ENCODE;
				end
				else begin
					state_n = WAIT;
				end
			end
			default: state_n = IDLE;
		endcase
	end
	// config_ly_d1
	always@(posedge clk)begin
		if(state_c==CONFIG_LY)begin
			config_ly_d1 <= 1'b1;
		end
		else begin
			config_ly_d1 <= 1'b0;
		end
	end
	// load_in2work
	always@(posedge clk)begin
		if(rst)begin
			load_in2work <= 1'b0;
		end
		else if(state_c==LOAD_IN)begin
			if((layer==3'b1)&&(cnt_tile_deep_in==1)&&add_cnt_tile_deep_in)begin
				load_in2work <= 1'b1;
			end
			else if((layer!=3'b1)&&(cnt_tile_deep_in==0)&&add_cnt_tile_deep_in)begin
				load_in2work <= 1'b1;
			end
			else begin
				load_in2work <= 1'b0;
			end
		end
		else begin
			load_in2work <= 1'b0;
		end
	end
	assign config_ly2load_w	= (state_c==CONFIG_LY)&&config_ly_d1;
	assign load_w2load_in 	= (state_c==LOAD_W)&&trans_w_done;
	assign work2wait		= (state_c==WORK)&&add_cnt_trans_times_in;
	assign wait2work		= (state_c==WAIT)&&(~end_cnt_trans_times_in_reg)&&onetranstime_done;
	assign wait2config_ly   = (state_c==WAIT)&&obuf_read_done&&(layer!=4);
	// wait2encode
	always@(posedge clk)begin
		if((state_c==WAIT)&&init_done_rans_dly[0])begin
			wait2encode <= 1'b1;
		end
		else begin
			wait2encode <= 1'b0;
		end
	end
	
	// layer
	always@(posedge clk)begin
		if(rst)begin
			layer <= 'd0;
		end
		else if(state_c==IDLE)begin
			layer <= 3'd1;					  
		end
		else if(wait2config_ly)begin
			layer <= layer + 1'b1;
		end
		else begin
			layer <= layer;
		end
	end
	
	// finish
	always@(posedge clk)begin
		if(rst)begin
			finish <= 1'b0;
		end
		else if(enc_done_rans)begin
			finish <= 1'b1;
		end
		else begin
			finish <= 1'b0;
		end
	end
	
	// start_write_w
	always@(posedge clk)begin
		if(rst)begin
			start_write_w <= 1'b0;
		end
		else if(config_ly2load_w)begin
			start_write_w <= 1'b1;
		end
		else begin
			start_write_w <= 1'b0;
		end
	end
	// start_read_w
	always@(posedge clk)begin
		if(rst)begin
			start_read_w[0] <= 1'b0;
		end
		else if(start_read_inbuf)begin
			start_read_w[0] <= 1'b1;
		end
		else begin
			start_read_w[0] <= 1'b0;
		end
	end
	genvar gv_j;
	generate
		for(gv_j=1; gv_j<9; gv_j=gv_j+1)begin:start_read_w_delay
			always@(posedge clk)begin
				start_read_w[gv_j] <= start_read_w[gv_j-1];
			end
		end
	endgenerate

	// start_inbuf
	always@(posedge clk)begin
		if(rst)begin
			start_inbuf <= 1'b0;
		end
		else if(load_w2load_in||wait2work)begin
			start_inbuf <= 1'b1;
		end
		else begin
			start_inbuf <= 1'b0;
		end
	end
	// start_inbuf_reg
	always@(posedge clk)begin
		if(rst)begin
		start_inbuf_reg <= 1'b0;
		end
		else if(start_read_inbuf)begin
			start_inbuf_reg <= 1'b0;
		end
		else if(start_inbuf)begin
			start_inbuf_reg <= 1'b1;
		end
	end
	// start_read_inbuf
	always@(posedge clk)begin
		if(rst)begin
			start_read_inbuf <= 1'b0;
		end
		else if((layer==3'b1)&&(cnt_tile_deep_in==1)&&add_cnt_tile_deep_in&&start_inbuf_reg)begin
			start_read_inbuf <= 1'b1;
		end
		else if((layer!=3'b1)&&(cnt_tile_deep_in==0)&&add_cnt_tile_deep_in&&start_inbuf_reg)begin
			start_read_inbuf <= 1'b1;
		end
		else begin
			start_read_inbuf <= 1'b0;
		end
	end
	
	// start_acc_post_obuf
	always@(posedge clk)begin
		if(rst)begin
			start_acc_post_obuf <= 1'b0;
		end
		else if(start_inbuf&&(cnt_trans_times_in==0))begin
			start_acc_post_obuf <= 1'b1;
		end
		else begin
			start_acc_post_obuf <= 1'b0;
		end
	end
	

	/////////////////////////////////////////////////////////
	//               configurate hyper parameter                         
	/////////////////////////////////////////////////////////
	// TILE_DEEP_IN
	always@(posedge clk)begin
		if(rst)begin
			TILE_DEEP_IN <= 8'd0;
		end
		else if(state_c==CONFIG_LY)begin
				TILE_DEEP_IN <= 3 - 1;
			endcase
		end
	end
	// BLOCK_DEEP_IN
	always@(posedge clk)begin
		if(rst)begin
			BLOCK_DEEP_IN <= 'd0;
		end
		else if(state_c==CONFIG_LY)begin
			case(layer)
				3'd1: BLOCK_DEEP_IN <= 0;
				3'd2, 3'd3,
				3'd4: BLOCK_DEEP_IN <= 31;
				default: BLOCK_DEEP_IN <= 'd0;
			endcase
		end
	end
	// LOOP_DEEP_IN
	always@(posedge clk)begin
		if(rst)begin
			LOOP_DEEP_IN <= 5'd0;
		end
		else if(state_c==CONFIG_LY)begin
			case(layer)
				3'd1, 3'd4: LOOP_DEEP_IN <= 0;
				3'd2: LOOP_DEEP_IN <= 17;
				3'd3: LOOP_DEEP_IN <= 3;
				default: LOOP_DEEP_IN <= 'd0;
			endcase
		end
	end
	// LOOP_DEEP_OUT
	always@(posedge clk)begin
		if(rst)begin
			LOOP_DEEP_OUT <= 'd0;
		end
		else if(state_c==CONFIG_LY)begin
			case(layer)
				3'd1: LOOP_DEEP_OUT <= 89;
				3'd2: LOOP_DEEP_OUT <= 17;
				3'd3: LOOP_DEEP_OUT <= 3;
				3'd4: LOOP_DEEP_OUT <= 0;
				default: LOOP_DEEP_OUT <= 'd0;
			endcase
		end
	end
	
	
// write/read length(Byte)
	// DMA_IN_TRANS_LEN
	always@(posedge clk)begin
		if(rst)begin
			DMA_IN_TRANS_LEN <= 'd0;
		end
		else begin
			if((cnt_loop_deep_in==0)&&(cnt_tile_deep_in==0))begin
				DMA_IN_TRANS_LEN <= 10560;
			end
			else if(cnt_tile_deep_in==TILE_DEEP_IN)begin
				if(cnt_loop_deep_in==LOOP_DEEP_IN)begin
					DMA_IN_TRANS_LEN <= 9600;
				end
				else begin
					DMA_IN_TRANS_LEN <= 11040;
				end
			end
			else begin
				DMA_IN_TRANS_LEN <= 11520;
			end
		end
	end
	// DMA_W_TRANS_LEN
	always@(posedge clk)begin
		if(rst)begin
			DMA_W_TRANS_LEN <= 'd0;
		end
		else if(config_ly2load_w)begin
			case(layer)
				3'd1: DMA_W_TRANS_LEN <= 4096;
				3'd2,3'd3,
				3'd4: DMA_W_TRANS_LEN <= 131072; 
				default: DMA_W_TRANS_LEN <= 'd0;
			endcase
		end
		else if(init_done_rans_dly[1])begin
			DMA_W_TRANS_LEN <= rANS_DMA_RD_LENGTH_ONETRANS;
		end
		else begin
			DMA_W_TRANS_LEN <= DMA_W_TRANS_LEN;
		end
	end
	// DMA_O_TRANS_LEN
	always@(posedge clk)begin
		if(rst)begin
			DMA_O_TRANS_LEN <= 'd0;
		end
		else if(state_c==ENCODE)begin
			DMA_O_TRANS_LEN <= rANS_DMA_WR_LENGTH_ONETRANS;
		end
		else begin
			DMA_O_TRANS_LEN <= 8160;
		end
	end
	
// write/read DDR base address
	// DMA_C0_RD_BASE_ADDR
	always@(posedge clk)begin
		if(rst)begin
			DMA_C0_RD_BASE_ADDR <= 'd0;
		end
		else begin
			DMA_C0_RD_BASE_ADDR <= template_dout_in[31:0];
		end
	end
	// DMA_C1_RD_BASE_ADDR
	always@(posedge clk)begin
		if(rst)begin
			DMA_C1_RD_BASE_ADDR <= 'd0;
		end
		else begin
			DMA_C1_RD_BASE_ADDR <= template_dout_in[63:32];
		end
	end
	// DMA_C2_RD_BASE_ADDR
	always@(posedge clk)begin
		if(rst)begin
			DMA_C2_RD_BASE_ADDR <= 'd0;
		end
		else begin
			DMA_C2_RD_BASE_ADDR <= template_dout_in[95:64];
		end
	end
	// DMA_C3_RD_BASE_ADDR
	always@(posedge clk)begin
		if(rst)begin
			DMA_C3_RD_BASE_ADDR <= 'd0;
		end
		else begin
			DMA_C3_RD_BASE_ADDR <= template_dout_in[127:96];
		end
	end
	// DMA_W_RD_BASE_ADDR
	always@(posedge clk)begin
		if(rst)begin
			DMA_W_RD_BASE_ADDR <= 'd0;
		end
		else if(state_c==CONFIG_LY)begin
			case(layer)
				3'd1: DMA_W_RD_BASE_ADDR <= W_BASE_ADDR_LY1;
				3'd2: DMA_W_RD_BASE_ADDR <= W_BASE_ADDR_LY2;
				3'd3: DMA_W_RD_BASE_ADDR <= W_BASE_ADDR_LY3;
				3'd4: DMA_W_RD_BASE_ADDR <= W_BASE_ADDR_LY4;
				default: DMA_W_RD_BASE_ADDR <= 'd0;
			endcase
		end
		else if(init_done_rans_dly[1])begin
			DMA_W_RD_BASE_ADDR <= OUT_BASE_ADDR_LY4;
		end
		else if(dma_w_cfg_finish_flag)begin
			if(state_c==ENCODE)begin
				DMA_W_RD_BASE_ADDR <= DMA_W_RD_BASE_ADDR + W_ADDR_OFFSET_rANS;
			end
			else if(layer==3'd1)begin
				DMA_W_RD_BASE_ADDR <= DMA_W_RD_BASE_ADDR + W_ADDR_OFFSET_LY1;
			end
			else begin
				DMA_W_RD_BASE_ADDR <= DMA_W_RD_BASE_ADDR + W_ADDR_OFFSET_LY234;
			end
		end
	end
	// DMA_O_WR_BASE_ADDR
	always@(posedge clk)begin
		if(rst)begin
			DMA_O_WR_BASE_ADDR <= 'd0;
		end
		else if(init_done_rans_dly[1])begin
			DMA_O_WR_BASE_ADDR <= rANS_OUT_BYTE_BASE_ADDR;
		end
		else if(enc_done_rans)begin
			DMA_O_WR_BASE_ADDR <= rANS_OUT_HEADER_BASE_ADDR;
		end
		else if(state_c==ENCODE)begin
			if(dma_o_cfg_finish_flag)begin
				DMA_O_WR_BASE_ADDR <= DMA_O_WR_BASE_ADDR + rANS_DMA_WR_LENGTH_ONETRANS;
			end	
			else begin
				DMA_O_WR_BASE_ADDR <= DMA_O_WR_BASE_ADDR;
			end
		end
		else begin
			DMA_O_WR_BASE_ADDR <= template_dout_out;
		end
	end


// template rd address	
	// template_addr_in
	always@(posedge clk)begin
		if(rst)begin
			template_addr_in <= 'd0;
		end
		else if((state_c==CONFIG_LY)||(state_c==WAIT))begin
			case(layer)
				3'd1: template_addr_in <= TEMPLATE_BASE_IN_LY1;
				3'd2: template_addr_in <= TEMPLATE_BASE_IN_LY2;
				3'd3: template_addr_in <= TEMPLATE_BASE_IN_LY3;
				3'd4: template_addr_in <= TEMPLATE_BASE_IN_LY4;
				default: template_addr_in <= 'd0;
			endcase
		end
		else if(dma_in_cfg_finish_flag==4'b1111)begin
			template_addr_in <= template_addr_in + 1'b1;
		end
	end
	// template_addr_out
	always@(posedge clk)begin
		if(rst)begin
			template_addr_out <= 'd0;
		end
		else if(state_c==CONFIG_LY)begin
			case(layer)
				3'd1: template_addr_out <= TEMPLATE_BASE_OUT_LY1;
				3'd2: template_addr_out <= TEMPLATE_BASE_OUT_LY2;
				3'd3: template_addr_out <= TEMPLATE_BASE_OUT_LY3;
				3'd4: template_addr_out <= TEMPLATE_BASE_OUT_LY4;
				default: template_addr_out <= 'd0;
			endcase
		end
		else if(dma_o_cfg_finish_flag)begin
			template_addr_out <= template_addr_out + 1'b1;
		end
	end


// dma config flag
	// dma_in_cfg_start
	always@(posedge clk)begin
		if(rst)begin
			dma_in_cfg_start <= 'd0;
		end
		else if(start_inbuf||(is_dma_write&&(state_c==WORK))||
			   ((layer==3'b1)&&(cnt_tile_deep_in==0)&&add_cnt_tile_deep_in))begin
			if(layer==3'd1)begin 
				dma_in_cfg_start <= 4'b0111;
			end
			else begin
				dma_in_cfg_start <= 4'b1111;
			end
		end
		else begin
			dma_in_cfg_start <= 'd0;
		end
	end
	// dma_w_cfg_start
	always@(posedge clk)begin
		if(rst)begin
			dma_w_cfg_start <= 1'b0;
		end
		else if(start_write_w||									
			   (trans_w_done&&(cnt_trans_times_w==0))||			
			   (wait2work&&(~end_cnt_trans_times_w_reg))||	
			   init_done_rans_dly[3]||(onetrans_rd_done_rans&&(~all_rd_done_rans)))begin 
			dma_w_cfg_start <= 1'b1;
		end
		else begin
			dma_w_cfg_start <= 1'b0;
		end
	end
	// dma_o_cfg_start
	always@(posedge clk)begin
		if(rst)begin
			dma_o_cfg_start <= 1'b0;
		end
		else if(next_trans_wr_rans_d1)begin
			dma_o_cfg_start <= 1'b1;
		end
		else if(is_dma_send_valid||add_cnt_dma_out_times||next_batch_resume)begin
			if(cnt_dma_out_times==31)begin
				dma_o_cfg_start <= 1'b0;
			end
			else begin
				dma_o_cfg_start <= 1'b1;
			end
		end
		else begin
			dma_o_cfg_start <= 1'b0;
		end
	end
	assign dma_o_cfg_start_0 = dma_out_ppong ?	(1'b0)			:	dma_o_cfg_start;
	assign dma_o_cfg_start_1 = dma_out_ppong ?	dma_o_cfg_start	:	(1'b0);
	
	// dma_in_cfg_finish_flag
	always@(posedge clk)begin
		if(rst)begin
			dma_in_cfg_finish_flag[0] <= 1'b0; 
		end
		else if(dma_in_cfg_finish_flag==4'b1111)begin
			dma_in_cfg_finish_flag[0] <= 1'b0;
		end
		else begin
			dma_in_cfg_finish_flag[0] <= dma_in_cfg_finish[0];
		end
	end
	always@(posedge clk)begin
		if(rst)begin
			dma_in_cfg_finish_flag[1] <= 1'b0; 
		end
		else if(dma_in_cfg_finish_flag==4'b1111)begin
			dma_in_cfg_finish_flag[1] <= 1'b0;
		end
		else begin
			dma_in_cfg_finish_flag[1] <= dma_in_cfg_finish[1];
		end
	end
	always@(posedge clk)begin
		if(rst)begin
			dma_in_cfg_finish_flag[2] <= 1'b0; 
		end
		else if(dma_in_cfg_finish_flag==4'b1111)begin
			dma_in_cfg_finish_flag[2] <= 1'b0;
		end
		else begin
			dma_in_cfg_finish_flag[2] <= dma_in_cfg_finish[2];
		end
	end
	always@(posedge clk)begin
		if(rst)begin
			dma_in_cfg_finish_flag[3] <= 1'b0; 
		end
		else if(dma_in_cfg_finish_flag==4'b1111)begin
			dma_in_cfg_finish_flag[3] <= 1'b0;
		end
		else if(layer==3'd1)begin
			dma_in_cfg_finish_flag[3] <= 1'b1;
		end
		else begin
			dma_in_cfg_finish_flag[3] <= dma_in_cfg_finish[3];
		end
	end
	// dma_w_cfg_finish_flag
	always@(posedge clk)begin
		if(rst)begin
			dma_w_cfg_finish_flag <= 1'b0;
		end
		else begin
			dma_w_cfg_finish_flag <= dma_w_cfg_finish;
		end
	end
	// dma_o_cfg_finish_flag
	always@(posedge clk)begin
		if(rst)begin
			dma_o_cfg_finish_flag <= 1'b0;
		end
		else if(dma_o_cfg_finish[0]||dma_o_cfg_finish[1])begin
			dma_o_cfg_finish_flag <= 1'b1;
		end
		else begin
			dma_o_cfg_finish_flag <= 1'b0;
		end
	end	
	
	
	// trans_w_done
	always@(posedge clk)begin
		if(rst)begin
			trans_w_done <= 1'b0;
		end
		else if(s_axis_tlast_w&&s_axis_tvalid_w&&s_axis_tready_w)begin
			trans_w_done <= 1'b1;
		end
		else begin
			trans_w_done <= 1'b0;
		end
	end
	// trans_out_done
	always@(posedge clk)begin
		if(rst)begin
			trans_out_done <= 1'b0;
		end
		else if(is_dma_send||dma_o_cfg_finish_flag||next_batch_resume)begin
			trans_out_done <= 1'b0;
		end
		else if(end_cnt_dma_out_times)begin
			trans_out_done <= 1'b1;
		end
	end
	
	// is_dma_send_reg
	always@(posedge clk)begin
		if(rst)begin
			is_dma_send_reg <= 1'b0;
		end
		else if(is_dma_send_valid)begin
			is_dma_send_reg <= 1'b0;
		end
		else if(is_dma_send)begin
			is_dma_send_reg <= 1'b1;
		end
	end
	// is_dma_send_valid
	always@(posedge clk)begin
		if(rst)begin
			is_dma_send_valid <= 1'b0;
		end
		else if(is_dma_send_reg&&((cnt_dma_out_times==0)||trans_out_done))begin // the first time and the other times
			is_dma_send_valid <= 1'b1;
		end
		else begin
			is_dma_send_valid <= 1'b0;
		end
	end
	

	// is_WrFastRd
	always@(posedge clk)begin
		if(rst)begin
			is_WrFastRd <= 1'b0;
		end
		else if(trans_out_done)begin   // transfer 1 block done
			is_WrFastRd <= 1'b0;
		end
		else if(is_dma_send&&(~trans_out_done)&&(cnt_dma_out_times > 0))begin // during the transmission period of 1 block
			is_WrFastRd <= 1'b1;
		end
	end
	// next_batch
	always@(posedge clk)begin
		if(rst)begin
			next_batch <= 1'b0;
		end
		else begin
			next_batch <= (state_c != ENCODE)&&dma_o_cfg_finish_flag;
		end
	end
	// next_batch_resume
	always@(posedge clk)begin
		if(rst)begin
			next_batch_resume <= 1'b0;
		end
		else if(is_WrFastRd&&trans_out_done)begin
			next_batch_resume <= 1'b1;
		end
		else begin
			next_batch_resume <= 1'b0;
		end
	end
	
	// dma_out_ppong
	always@(posedge clk)begin
		if(state_c==CONFIG_LY)begin
			dma_out_ppong <= 1'b0;
		end
		else if(onebatch_done||next_trans_wr_rans)begin
			dma_out_ppong <= ~dma_out_ppong;
		end
		else begin
			dma_out_ppong <= dma_out_ppong;
		end
	end
	
	/////////////////////////////////////////////////////////
	//               		 rANS                       
	/////////////////////////////////////////////////////////
	// start_rans
	always@(posedge clk)begin
		if(rst)begin
			start_rans <= 1'b0;
		end
		else if((state_c==CONFIG_LY)&&(layer==4))begin
			start_rans <= 1'b1;
		end
		else begin
			start_rans <= 1'b0;
		end
	end
	// init_done_rans_dly
	always@(posedge clk)begin
		if(rst)begin
			init_done_rans_dly <= 'd0;
		end
		else begin
			init_done_rans_dly <= {init_done_rans_dly[2:0], init_done_rans};
		end
	end
	// next_trans_wr_rans_d1
	always@(posedge clk)begin
		next_trans_wr_rans_d1 <= next_trans_wr_rans;
	end
	
	// tvalid_rans
	always@(posedge clk)begin
		if(m_axis_tvalid_obuf&&m_axis_tready_obuf)begin
			tvalid_rans <= 1'b1;
		end
		else begin
			tvalid_rans <= 1'b0;
		end
	end
	// tdata_rans
	always@(posedge clk)begin
		tdata_rans <= m_axis_tdata_obuf;
	end	
	// tlast_rans
	always@(posedge clk)begin
		if((layer==4)&&(state_c==WAIT)&&obuf_read_done)begin
			tlast_rans <= 1'b1;
		end
		else begin
			tlast_rans <= 1'b0;
		end
	end
	// start_next_trans_wr_rans
	always@(posedge clk)begin
		if(rst)begin
			start_next_trans_wr_rans <= 1'b0;
		end
		else begin
			start_next_trans_wr_rans <= (state_c == ENCODE)&&dma_o_cfg_finish_flag;
		end
	end
	
	/////////////////////////////////////////////////////////
	//               		 counter                         
	/////////////////////////////////////////////////////////
// dma input
	// cnt_tile_deep_in
	always@(posedge clk)begin
		if(rst)begin
			cnt_tile_deep_in <= 'd0;
		end
		else begin
			if(end_cnt_tile_deep_in)begin
				cnt_tile_deep_in <= 'd0;
			end
			else if(add_cnt_tile_deep_in)begin
				cnt_tile_deep_in <= cnt_tile_deep_in + 1'b1;
			end
		end
	end
	assign add_cnt_tile_deep_in = oneslice_wr_done;
	assign end_cnt_tile_deep_in = (cnt_tile_deep_in==TILE_DEEP_IN)&&add_cnt_tile_deep_in;
	// cnt_block_deep_in
	always@(posedge clk)begin
		if(rst)begin
			cnt_block_deep_in <= 'd0;
		end
		else begin
			if(end_cnt_block_deep_in)begin
				cnt_block_deep_in <= 'd0;
			end
			else if(add_cnt_block_deep_in)begin
				cnt_block_deep_in <= cnt_block_deep_in + 1'b1;
			end
		end
	end
	assign add_cnt_block_deep_in = end_cnt_tile_deep_in;
	assign end_cnt_block_deep_in = (cnt_block_deep_in==BLOCK_DEEP_IN)&&add_cnt_block_deep_in;	
	// cnt_loop_deep_in
	always@(posedge clk)begin
		if(rst)begin
			cnt_loop_deep_in <= 'd0;
		end
		else begin
			if(end_cnt_loop_deep_in)begin
				cnt_loop_deep_in <= 'd0;
			end
			else if(add_cnt_loop_deep_in)begin
				cnt_loop_deep_in <= cnt_loop_deep_in + 1'b1;
			end
		end
	end
	assign add_cnt_loop_deep_in = end_cnt_block_deep_in;
	assign end_cnt_loop_deep_in = (cnt_loop_deep_in==LOOP_DEEP_IN)&&add_cnt_loop_deep_in;
	// cnt_trans_times_in
	always@(posedge clk)begin
		if(rst)begin
			cnt_trans_times_in <= 'd0;
		end
		else begin
			if(end_cnt_trans_times_in)begin
				cnt_trans_times_in <= 'd0;
			end
			else if(add_cnt_trans_times_in)begin
				cnt_trans_times_in <= cnt_trans_times_in + 1'b1;
			end
		end
	end
	assign add_cnt_trans_times_in = end_cnt_loop_deep_in;
	assign end_cnt_trans_times_in = (cnt_trans_times_in==2'd3)&&add_cnt_trans_times_in;	
	// end_cnt_trans_times_in_reg
	always@(posedge clk)begin
		if(rst)begin
			end_cnt_trans_times_in_reg <= 1'b0;
		end
		else if(state_c==CONFIG_LY)begin
			end_cnt_trans_times_in_reg <= 1'b0;
		end
		else if(end_cnt_trans_times_in)begin
			end_cnt_trans_times_in_reg <= 1'b1;
		end
	end
	
	
// dma output
	// cnt_dma_out_times
	always@(posedge clk)begin
		if(rst)begin
			cnt_dma_out_times <= 'd0;
		end
		else begin
			if(end_cnt_dma_out_times)begin
				cnt_dma_out_times <= 'd0;
			end
			else if(add_cnt_dma_out_times)begin
				cnt_dma_out_times <= cnt_dma_out_times + 1'b1;
			end
		end
	end
	assign add_cnt_dma_out_times = onebatch_done; // 1 bram 1 reuse 
	assign end_cnt_dma_out_times = (cnt_dma_out_times==31)&&add_cnt_dma_out_times;         // 8 bram 4 reuse = 1 loop
	// cnt_dma_out_32batch
	always@(posedge clk)begin
		if(rst)begin
			cnt_dma_out_32batch <= 'd0;
		end
		else begin
			if(end_cnt_dma_out_32batch)begin
				cnt_dma_out_32batch <= 'd0;
			end
			else if(add_cnt_dma_out_32batch)begin
				cnt_dma_out_32batch <= cnt_dma_out_32batch + 1'b1;
			end
		end
	end
	assign add_cnt_dma_out_32batch = end_cnt_dma_out_times;
	assign end_cnt_dma_out_32batch = (cnt_dma_out_32batch==LOOP_DEEP_OUT)&&end_cnt_dma_out_times;
	// cnt_loop_deep_out
	always@(posedge clk)begin
		if(rst)begin
			cnt_loop_deep_out <= 'd0;
		end
		else begin
			if(end_cnt_loop_deep_out)begin
				cnt_loop_deep_out <= 'd0;
			end
			else if(add_cnt_loop_deep_out)begin
				cnt_loop_deep_out <= cnt_loop_deep_out + 1'b1;
			end
		end
	end
	assign add_cnt_loop_deep_out = end_cnt_dma_out_times;
	assign end_cnt_loop_deep_out = (cnt_loop_deep_out==LOOP_DEEP_OUT)&&add_cnt_loop_deep_out;
	
	
// dma weight
	// cnt_trans_times_w
	always@(posedge clk)begin
		if(rst)begin
			cnt_trans_times_w <= 'd0;
		end
		else begin
			if(end_cnt_trans_times_w)begin
				cnt_trans_times_w <= 'd0;
			end
			else if(add_cnt_trans_times_w)begin
				cnt_trans_times_w <= cnt_trans_times_w + 1'b1;
			end
		end
	end
	assign add_cnt_trans_times_w = trans_w_done;
	assign end_cnt_trans_times_w = (cnt_trans_times_w==(TransferTimes-1))&&add_cnt_trans_times_w;
	// end_cnt_trans_times_w_reg
	always@(posedge clk)begin
		if(rst)begin
			end_cnt_trans_times_w_reg <= 1'b0;
		end
		else if(state_c==CONFIG_LY)begin
			end_cnt_trans_times_w_reg <= 1'b0;
		end
		else if(end_cnt_trans_times_w)begin
			end_cnt_trans_times_w_reg <= 1'b1;
		end
		else begin
			end_cnt_trans_times_w_reg <= end_cnt_trans_times_w_reg;
		end
	end
	

/////////////////////////////////////////////////////////
//                     IP instance                        
/////////////////////////////////////////////////////////
// >>>>> DMA_C0 <<<<<
dma_config#(
	.M_AXI_ADDR_WIDTH(M_AXI_ADDR_WIDTH),	// Width of M_AXI address bus
	.M_AXI_DATA_WIDTH(M_AXI_DATA_WIDTH)  	// Width of M_AXI data bus
)DMA_C0_INST(
	//----------------------------------clock-------------------------------------
	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 M_AXI_ACLK CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M_AXI, ASSOCIATED_RESET M_AXI_ARESET" *)
	.M_AXI_ACLK(clk),
	(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 M_AXI_ARESET RST" *)
	(* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
	.M_AXI_ARESET(rst),
    //start signal
    .START          (dma_in_cfg_start[0]),
    .FINISH         (dma_in_cfg_finish[0]),
	
	.DMA_REG_BASE   (DMA_REG_BASE_C0),
	.DMA_BUFFER_BASE(DMA_C0_RD_BASE_ADDR),
	.DIRECTION      (MM2S),//S2MM OR MM2S
    .TRANSFER_LEN   (DMA_IN_TRANS_LEN),
	// write data address channel 
	.M_AXI_AWADDR (M_AXI_AWADDR_C0),
	.M_AXI_AWPROT (M_AXI_AWPROT_C0),
	.M_AXI_AWVALID(M_AXI_AWVALID_C0),
	.M_AXI_AWREADY(M_AXI_AWREADY_C0),
	// write data channel 
	.M_AXI_WDATA (M_AXI_WDATA_C0),
	.M_AXI_WSTRB (M_AXI_WSTRB_C0),
	.M_AXI_WVALID(M_AXI_WVALID_C0),
	.M_AXI_WREADY(M_AXI_WREADY_C0),
	// write data response channel 
	.M_AXI_BRESP (M_AXI_BRESP_C0), 
	.M_AXI_BVALID(M_AXI_BVALID_C0),
	.M_AXI_BREADY(M_AXI_BREADY_C0),
	// read address channel
	.M_AXI_ARADDR (M_AXI_ARADDR_C0),
	.M_AXI_ARPROT (M_AXI_ARPROT_C0),
	.M_AXI_ARVALID(M_AXI_ARVALID_C0),
	.M_AXI_ARREADY(M_AXI_ARREADY_C0),
	// read data channel
	.M_AXI_RDATA (M_AXI_RDATA_C0),
	.M_AXI_RRESP (M_AXI_RRESP_C0),
	.M_AXI_RVALID(M_AXI_RVALID_C0),
	.M_AXI_RREADY(M_AXI_RREADY_C0)
);
// >>>>> DMA_C1 <<<<<
dma_config#(
	.M_AXI_ADDR_WIDTH(M_AXI_ADDR_WIDTH),	// Width of M_AXI address bus
	.M_AXI_DATA_WIDTH(M_AXI_DATA_WIDTH)  	// Width of M_AXI data bus
)DMA_C1_INST(
	//----------------------------------clock-------------------------------------
	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 M_AXI_ACLK CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M_AXI, ASSOCIATED_RESET M_AXI_ARESET" *)
	.M_AXI_ACLK(clk),
	(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 M_AXI_ARESET RST" *)
	(* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
	.M_AXI_ARESET(rst),
    //start signal
    .START          (dma_in_cfg_start[1]),
    .FINISH         (dma_in_cfg_finish[1]),
	
	.DMA_REG_BASE   (DMA_REG_BASE_C1),
	.DMA_BUFFER_BASE(DMA_C1_RD_BASE_ADDR),
	.DIRECTION      (MM2S),//S2MM OR MM2S
    .TRANSFER_LEN   (DMA_IN_TRANS_LEN),
	// write data address channel 
	.M_AXI_AWADDR (M_AXI_AWADDR_C1),
	.M_AXI_AWPROT (M_AXI_AWPROT_C1),
	.M_AXI_AWVALID(M_AXI_AWVALID_C1),
	.M_AXI_AWREADY(M_AXI_AWREADY_C1),
	// write data channel 
	.M_AXI_WDATA (M_AXI_WDATA_C1),
	.M_AXI_WSTRB (M_AXI_WSTRB_C1),
	.M_AXI_WVALID(M_AXI_WVALID_C1),
	.M_AXI_WREADY(M_AXI_WREADY_C1),
	// write data response channel 
	.M_AXI_BRESP (M_AXI_BRESP_C1), 
	.M_AXI_BVALID(M_AXI_BVALID_C1),
	.M_AXI_BREADY(M_AXI_BREADY_C1),
	// read address channel
	.M_AXI_ARADDR (M_AXI_ARADDR_C1),
	.M_AXI_ARPROT (M_AXI_ARPROT_C1),
	.M_AXI_ARVALID(M_AXI_ARVALID_C1),
	.M_AXI_ARREADY(M_AXI_ARREADY_C1),
	// read data channel
	.M_AXI_RDATA (M_AXI_RDATA_C1),
	.M_AXI_RRESP (M_AXI_RRESP_C1),
	.M_AXI_RVALID(M_AXI_RVALID_C1),
	.M_AXI_RREADY(M_AXI_RREADY_C1)
);
// >>>>> DMA_C2 <<<<<
dma_config#(
	.M_AXI_ADDR_WIDTH(M_AXI_ADDR_WIDTH),	// Width of M_AXI address bus
	.M_AXI_DATA_WIDTH(M_AXI_DATA_WIDTH)  	// Width of M_AXI data bus
)DMA_C2_INST(
	//----------------------------------clock-------------------------------------
	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 M_AXI_ACLK CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M_AXI, ASSOCIATED_RESET M_AXI_ARESET" *)
	.M_AXI_ACLK(clk),
	(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 M_AXI_ARESET RST" *)
	(* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
	.M_AXI_ARESET(rst),
    //start signal
    .START          (dma_in_cfg_start[2]),
    .FINISH         (dma_in_cfg_finish[2]),
	
	.DMA_REG_BASE   (DMA_REG_BASE_C2),
	.DMA_BUFFER_BASE(DMA_C2_RD_BASE_ADDR),
	.DIRECTION      (MM2S),//S2MM OR MM2S
    .TRANSFER_LEN   (DMA_IN_TRANS_LEN),
	// write data address channel 
	.M_AXI_AWADDR (M_AXI_AWADDR_C2),
	.M_AXI_AWPROT (M_AXI_AWPROT_C2),
	.M_AXI_AWVALID(M_AXI_AWVALID_C2),
	.M_AXI_AWREADY(M_AXI_AWREADY_C2),
	// write data channel 
	.M_AXI_WDATA (M_AXI_WDATA_C2),
	.M_AXI_WSTRB (M_AXI_WSTRB_C2),
	.M_AXI_WVALID(M_AXI_WVALID_C2),
	.M_AXI_WREADY(M_AXI_WREADY_C2),
	// write data response channel 
	.M_AXI_BRESP (M_AXI_BRESP_C2), 
	.M_AXI_BVALID(M_AXI_BVALID_C2),
	.M_AXI_BREADY(M_AXI_BREADY_C2),
	// read address channel
	.M_AXI_ARADDR (M_AXI_ARADDR_C2),
	.M_AXI_ARPROT (M_AXI_ARPROT_C2),
	.M_AXI_ARVALID(M_AXI_ARVALID_C2),
	.M_AXI_ARREADY(M_AXI_ARREADY_C2),
	// read data channel
	.M_AXI_RDATA (M_AXI_RDATA_C2),
	.M_AXI_RRESP (M_AXI_RRESP_C2),
	.M_AXI_RVALID(M_AXI_RVALID_C2),
	.M_AXI_RREADY(M_AXI_RREADY_C2)
);
// >>>>> DMA_C3 <<<<<
dma_config#(
	.M_AXI_ADDR_WIDTH(M_AXI_ADDR_WIDTH),	// Width of M_AXI address bus
	.M_AXI_DATA_WIDTH(M_AXI_DATA_WIDTH)  	// Width of M_AXI data bus
)DMA_C3_INST(
	//----------------------------------clock-------------------------------------
	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 M_AXI_ACLK CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M_AXI, ASSOCIATED_RESET M_AXI_ARESET" *)
	.M_AXI_ACLK(clk),
	(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 M_AXI_ARESET RST" *)
	(* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
	.M_AXI_ARESET(rst),
    //start signal
    .START          (dma_in_cfg_start[3]),
    .FINISH         (dma_in_cfg_finish[3]),
	
	.DMA_REG_BASE   (DMA_REG_BASE_C3),
	.DMA_BUFFER_BASE(DMA_C3_RD_BASE_ADDR),
	.DIRECTION      (MM2S),//S2MM OR MM2S
    .TRANSFER_LEN   (DMA_IN_TRANS_LEN),
	// write data address channel 
	.M_AXI_AWADDR (M_AXI_AWADDR_C3),
	.M_AXI_AWPROT (M_AXI_AWPROT_C3),
	.M_AXI_AWVALID(M_AXI_AWVALID_C3),
	.M_AXI_AWREADY(M_AXI_AWREADY_C3),
	// write data channel 
	.M_AXI_WDATA (M_AXI_WDATA_C3),
	.M_AXI_WSTRB (M_AXI_WSTRB_C3),
	.M_AXI_WVALID(M_AXI_WVALID_C3),
	.M_AXI_WREADY(M_AXI_WREADY_C3),
	// write data response channel 
	.M_AXI_BRESP (M_AXI_BRESP_C3), 
	.M_AXI_BVALID(M_AXI_BVALID_C3),
	.M_AXI_BREADY(M_AXI_BREADY_C3),
	// read address channel
	.M_AXI_ARADDR (M_AXI_ARADDR_C3),
	.M_AXI_ARPROT (M_AXI_ARPROT_C3),
	.M_AXI_ARVALID(M_AXI_ARVALID_C3),
	.M_AXI_ARREADY(M_AXI_ARREADY_C3),
	// read data channel
	.M_AXI_RDATA (M_AXI_RDATA_C3),
	.M_AXI_RRESP (M_AXI_RRESP_C3),
	.M_AXI_RVALID(M_AXI_RVALID_C3),
	.M_AXI_RREADY(M_AXI_RREADY_C3)
);
// >>>>> DMA_W <<<<<
dma_config#(
	.M_AXI_ADDR_WIDTH(M_AXI_ADDR_WIDTH),	// Width of M_AXI address bus
	.M_AXI_DATA_WIDTH(M_AXI_DATA_WIDTH)  	// Width of M_AXI data bus
)DMA_W_INST(
	//----------------------------------clock-------------------------------------
	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 M_AXI_ACLK CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M_AXI, ASSOCIATED_RESET M_AXI_ARESET" *)
	.M_AXI_ACLK(clk),
	(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 M_AXI_ARESET RST" *)
	(* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
	.M_AXI_ARESET(rst),
    //start signal
    .START          (dma_w_cfg_start),
    .FINISH         (dma_w_cfg_finish),
	
	.DMA_REG_BASE   (DMA_REG_BASE_W),
	.DMA_BUFFER_BASE(DMA_W_RD_BASE_ADDR),
	.DIRECTION      (MM2S),//S2MM OR MM2S
    .TRANSFER_LEN   (DMA_W_TRANS_LEN),
	// write data address channel 
	.M_AXI_AWADDR (M_AXI_AWADDR_W),
	.M_AXI_AWPROT (M_AXI_AWPROT_W),
	.M_AXI_AWVALID(M_AXI_AWVALID_W),
	.M_AXI_AWREADY(M_AXI_AWREADY_W),
	// write data channel 
	.M_AXI_WDATA (M_AXI_WDATA_W),
	.M_AXI_WSTRB (M_AXI_WSTRB_W),
	.M_AXI_WVALID(M_AXI_WVALID_W),
	.M_AXI_WREADY(M_AXI_WREADY_W),
	// write data response channel 
	.M_AXI_BRESP (M_AXI_BRESP_W), 
	.M_AXI_BVALID(M_AXI_BVALID_W),
	.M_AXI_BREADY(M_AXI_BREADY_W),
	// read address channel
	.M_AXI_ARADDR (M_AXI_ARADDR_W),
	.M_AXI_ARPROT (M_AXI_ARPROT_W),
	.M_AXI_ARVALID(M_AXI_ARVALID_W),
	.M_AXI_ARREADY(M_AXI_ARREADY_W),
	// read data channel
	.M_AXI_RDATA (M_AXI_RDATA_W),
	.M_AXI_RRESP (M_AXI_RRESP_W),
	.M_AXI_RVALID(M_AXI_RVALID_W),
	.M_AXI_RREADY(M_AXI_RREADY_W)
);
// >>>>> DMA_O_0 <<<<<
dma_config#(
	.M_AXI_ADDR_WIDTH(M_AXI_ADDR_WIDTH),	// Width of M_AXI address bus
	.M_AXI_DATA_WIDTH(M_AXI_DATA_WIDTH)  	// Width of M_AXI data bus
)DMA_O_0_INST(
	//----------------------------------clock-------------------------------------
	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 M_AXI_ACLK CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M_AXI, ASSOCIATED_RESET M_AXI_ARESET" *)
	.M_AXI_ACLK(clk),
	(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 M_AXI_ARESET RST" *)
	(* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
	.M_AXI_ARESET(rst),
    //start signal
    .START          (dma_o_cfg_start_0),
    .FINISH         (dma_o_cfg_finish[0]),
	
	.DMA_REG_BASE   (DMA_REG_BASE_O_0),
	.DMA_BUFFER_BASE(DMA_O_WR_BASE_ADDR),
	.DIRECTION      (S2MM),//S2MM OR MM2S
    .TRANSFER_LEN   (DMA_O_TRANS_LEN),
	// write data address channel 
	.M_AXI_AWADDR (M_AXI_AWADDR_O_0),
	.M_AXI_AWPROT (M_AXI_AWPROT_O_0),
	.M_AXI_AWVALID(M_AXI_AWVALID_O_0),
	.M_AXI_AWREADY(M_AXI_AWREADY_O_0),
	// write data channel 
	.M_AXI_WDATA (M_AXI_WDATA_O_0),
	.M_AXI_WSTRB (M_AXI_WSTRB_O_0),
	.M_AXI_WVALID(M_AXI_WVALID_O_0),
	.M_AXI_WREADY(M_AXI_WREADY_O_0),
	// write data response channel 
	.M_AXI_BRESP (M_AXI_BRESP_O_0), 
	.M_AXI_BVALID(M_AXI_BVALID_O_0),
	.M_AXI_BREADY(M_AXI_BREADY_O_0),
	// read address channel
	.M_AXI_ARADDR (M_AXI_ARADDR_O_0),
	.M_AXI_ARPROT (M_AXI_ARPROT_O_0),
	.M_AXI_ARVALID(M_AXI_ARVALID_O_0),
	.M_AXI_ARREADY(M_AXI_ARREADY_O_0),
	// read data channel
	.M_AXI_RDATA (M_AXI_RDATA_O_0),
	.M_AXI_RRESP (M_AXI_RRESP_O_0),
	.M_AXI_RVALID(M_AXI_RVALID_O_0),
	.M_AXI_RREADY(M_AXI_RREADY_O_0)
);
// >>>>> DMA_O_1 <<<<<
dma_config#(
	.M_AXI_ADDR_WIDTH(M_AXI_ADDR_WIDTH),	// Width of M_AXI address bus
	.M_AXI_DATA_WIDTH(M_AXI_DATA_WIDTH)  	// Width of M_AXI data bus
)DMA_O_1_INST(
	//----------------------------------clock-------------------------------------
	// AXI clock signal 总线时钟信号：
	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 M_AXI_ACLK CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M_AXI, ASSOCIATED_RESET M_AXI_ARESET" *)
	.M_AXI_ACLK(clk),
	(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 M_AXI_ARESET RST" *)
	(* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
	.M_AXI_ARESET(rst),
    //start signal
    .START          (dma_o_cfg_start_1),
    .FINISH         (dma_o_cfg_finish[1]),
	
	.DMA_REG_BASE   (DMA_REG_BASE_O_1),
	.DMA_BUFFER_BASE(DMA_O_WR_BASE_ADDR),
	.DIRECTION      (S2MM),//S2MM OR MM2S
    .TRANSFER_LEN   (DMA_O_TRANS_LEN),
	// write data address channel 
	.M_AXI_AWADDR (M_AXI_AWADDR_O_1),
	.M_AXI_AWPROT (M_AXI_AWPROT_O_1),
	.M_AXI_AWVALID(M_AXI_AWVALID_O_1),
	.M_AXI_AWREADY(M_AXI_AWREADY_O_1),
	// write data channel 
	.M_AXI_WDATA (M_AXI_WDATA_O_1),
	.M_AXI_WSTRB (M_AXI_WSTRB_O_1),//8位数据选通信号
	.M_AXI_WVALID(M_AXI_WVALID_O_1),
	.M_AXI_WREADY(M_AXI_WREADY_O_1),
	// write data response channel 
	.M_AXI_BRESP (M_AXI_BRESP_O_1), 
	.M_AXI_BVALID(M_AXI_BVALID_O_1),
	.M_AXI_BREADY(M_AXI_BREADY_O_1),
	// read address channel
	.M_AXI_ARADDR (M_AXI_ARADDR_O_1),
	.M_AXI_ARPROT (M_AXI_ARPROT_O_1),
	.M_AXI_ARVALID(M_AXI_ARVALID_O_1),
	.M_AXI_ARREADY(M_AXI_ARREADY_O_1),
	// read data channel
	.M_AXI_RDATA (M_AXI_RDATA_O_1),
	.M_AXI_RRESP (M_AXI_RRESP_O_1),
	.M_AXI_RVALID(M_AXI_RVALID_O_1),
	.M_AXI_RREADY(M_AXI_RREADY_O_1)
);
// >>>>> dma_input_addr_template <<<<<
dma_input_addr_template_lut dma_input_addr_template_inst(
	.clk(clk),
	.addr(template_addr_in),
	.dout(template_dout_in)
);
// >>>>> dma_output_addr_template <<<<<
dma_output_addr_template_lut dma_output_addr_template_inst(
	.clk(clk),
	.addr(template_addr_out),
	.dout(template_dout_out)
);


// >>>>> input_buffer <<<<<
input_buffer#(
	.DATA_WIDTH(DATA_WIDTH),
	.DATA_WIDTH_O(200)
)input_buffer_inst(
	.clk(clk),
	.rst(rst),
	.layer(layer),
	.start(start_inbuf),
	.start_read(start_read_inbuf),
	.oneslice_wr_done(oneslice_wr_done),
	.is_dma_write(is_dma_write),
	.read_continue(read_continue),
	.read_pause(read_pause),
	.is_WrFastRd_obuf(is_WrFastRd),

	//CH0:
	//(S_AXIS) INPUT  CHANNEL
    .S_AXIS_TVALID_C0(s_axis_tvalid_c0),
	.S_AXIS_TREADY_C0(s_axis_tready_c0),
	.S_AXIS_TDATA_C0(s_axis_tdata_c0),
    .S_AXIS_TLAST_C0(s_axis_tlast_c0),
	//CH1:
	//(S_AXIS) INPUT  CHANNEL
    .S_AXIS_TVALID_C1(s_axis_tvalid_c1),
	.S_AXIS_TREADY_C1(s_axis_tready_c1),
	.S_AXIS_TDATA_C1(s_axis_tdata_c1),
    .S_AXIS_TLAST_C1(s_axis_tlast_c1),
	//CH2:
	//(S_AXIS) INPUT  CHANNEL
    .S_AXIS_TVALID_C2(s_axis_tvalid_c2),
	.S_AXIS_TREADY_C2(s_axis_tready_c2),
	.S_AXIS_TDATA_C2(s_axis_tdata_c2),
    .S_AXIS_TLAST_C2(s_axis_tlast_c2),
	//CH3:
	//(S_AXIS) INPUT  CHANNEL
    .S_AXIS_TVALID_C3(s_axis_tvalid_c3),
	.S_AXIS_TREADY_C3(s_axis_tready_c3),
	.S_AXIS_TDATA_C3(s_axis_tdata_c3),
    .S_AXIS_TLAST_C3(s_axis_tlast_c3),
	
	// Output
	.en_out(en_out),
	.dout_c0(dout_c0),
	.dout_c1(dout_c1),
	.dout_c2(dout_c2),
	.dout_c3(dout_c3)
);
// >>>>> weight <<<<<
weight#(
	.DATA_WIDTH_I(DATA_WIDTH),
	.DATA_WIDTH_O(200)
)weight_inst(
	.clk(clk),
	.rst(rst),
	.layer(layer),
	.start_write(start_write_w),
	.start_read(start_read_w[8]),
	.read_done(read_done_w),
	.read_continue(read_continue),
	.read_pause(read_pause),
	
	//(S_AXIS) INPUT  CHANNEL
    .S_AXIS_TVALID(s_axis_tvalid_w),
	.S_AXIS_TREADY(s_axis_tready_w_),
	.S_AXIS_TDATA(s_axis_tdata_w),
	.S_AXIS_TLAST(s_axis_tlast_w),
	
	//OUTPUT
	.en_out(en_out_w),
	.dout_b0(dout_b0_w),
	.dout_b1(dout_b1_w),
	.dout_b2(dout_b2_w),
	.dout_b3(dout_b3_w),
	.dout_b4(dout_b4_w),
	.dout_b5(dout_b5_w),
	.dout_b6(dout_b6_w),
	.dout_b7(dout_b7_w)
);
// >>>>> systolic_acc <<<<<
systolic_acc#(
	.DATA_WIDTH_I(8),
	.DATA_WIDTH_P(DATA_WIDTH_P), // psum
	.DATA_WIDTH_O(DATA_WIDTH_O_PE)  // output
)systolic_acc_inst(
	.clk(clk),
	.rst(rst),
	.start(start_acc_post_obuf),
	.layer(layer),
	
	// input feature map 4 channel
	.en_fm(en_out),      // fm: feature map
	.din_fm_c0(dout_c0),
	.din_fm_c1(dout_c1),
	.din_fm_c2(dout_c2),
	.din_fm_c3(dout_c3),
	// input weight 8 batches
	.en_w(en_out_w),
	.din_w_b0(dout_b0_w),
	.din_w_b1(dout_b1_w),
	.din_w_b2(dout_b2_w),
	.din_w_b3(dout_b3_w),
	.din_w_b4(dout_b4_w),
	.din_w_b5(dout_b5_w),
	.din_w_b6(dout_b6_w),
	.din_w_b7(dout_b7_w),
	
	// accmulation output
	.en_out(en_out_acc),
	.dout0_pe00(dout0_pe00),.dout0_pe01(dout0_pe01),.dout0_pe02(dout0_pe02),.dout0_pe03(dout0_pe03),
	.dout0_pe10(dout0_pe10),.dout0_pe11(dout0_pe11),.dout0_pe12(dout0_pe12),.dout0_pe13(dout0_pe13),
	.dout0_pe20(dout0_pe20),.dout0_pe21(dout0_pe21),.dout0_pe22(dout0_pe22),.dout0_pe23(dout0_pe23),
	.dout0_pe30(dout0_pe30),.dout0_pe31(dout0_pe31),.dout0_pe32(dout0_pe32),.dout0_pe33(dout0_pe33),

	.dout1_pe00(dout1_pe00),.dout1_pe01(dout1_pe01),.dout1_pe02(dout1_pe02),.dout1_pe03(dout1_pe03),
	.dout1_pe10(dout1_pe10),.dout1_pe11(dout1_pe11),.dout1_pe12(dout1_pe12),.dout1_pe13(dout1_pe13),
	.dout1_pe20(dout1_pe20),.dout1_pe21(dout1_pe21),.dout1_pe22(dout1_pe22),.dout1_pe23(dout1_pe23),
	.dout1_pe30(dout1_pe30),.dout1_pe31(dout1_pe31),.dout1_pe32(dout1_pe32),.dout1_pe33(dout1_pe33)
);
// >>>>> post_process <<<<<
post_process#(
	.DATA_WIDTH_I(DATA_WIDTH_O_PE),
	.DATA_WIDTH_O(8)
)post_process_inst(
	.clk(clk),
	.rst(rst),
	.start(start_acc_post_obuf),
	.layer(layer),
	
	.en_in(en_out_acc),
	.din0_pe00(dout0_pe00),.din0_pe01(dout0_pe01),.din0_pe02(dout0_pe02),.din0_pe03(dout0_pe03),
	.din0_pe10(dout0_pe10),.din0_pe11(dout0_pe11),.din0_pe12(dout0_pe12),.din0_pe13(dout0_pe13),
	.din0_pe20(dout0_pe20),.din0_pe21(dout0_pe21),.din0_pe22(dout0_pe22),.din0_pe23(dout0_pe23),
	.din0_pe30(dout0_pe30),.din0_pe31(dout0_pe31),.din0_pe32(dout0_pe32),.din0_pe33(dout0_pe33),
	
	.din1_pe00(dout1_pe00),.din1_pe01(dout1_pe01),.din1_pe02(dout1_pe02),.din1_pe03(dout1_pe03),
	.din1_pe10(dout1_pe10),.din1_pe11(dout1_pe11),.din1_pe12(dout1_pe12),.din1_pe13(dout1_pe13),
	.din1_pe20(dout1_pe20),.din1_pe21(dout1_pe21),.din1_pe22(dout1_pe22),.din1_pe23(dout1_pe23),
	.din1_pe30(dout1_pe30),.din1_pe31(dout1_pe31),.din1_pe32(dout1_pe32),.din1_pe33(dout1_pe33),
	
	.en_out(en_out_bn),
	.dout_bn0_b01(dout_bn0_b01),.dout_bn1_b01(dout_bn1_b01), 
	.dout_bn0_b23(dout_bn0_b23),.dout_bn1_b23(dout_bn1_b23), 
	.dout_bn0_b45(dout_bn0_b45),.dout_bn1_b45(dout_bn1_b45), 
	.dout_bn0_b67(dout_bn0_b67),.dout_bn1_b67(dout_bn1_b67)
);
// >>>>> output_buffer <<<<<
output_buffer#(
	.DATA_WIDTH_I(8),
	.DATA_WIDTH_U(72),  // uram
	.DATA_WIDTH_O(DATA_WIDTH)
)output_buffer_inst(
	.clk(clk),
	.rst(rst),
	.start(start_acc_post_obuf),
	.layer(layer),
	.is_dma_send(is_dma_send),
	.next_batch(next_batch),
	.onebatch_done(onebatch_done),
	.onetranstime_done(onetranstime_done),
	.read_done(obuf_read_done),
	
	.en_in(en_out_bn),
	.din_b0(dout_bn0_b01), .din_b1(dout_bn1_b01), 
	.din_b2(dout_bn0_b23), .din_b3(dout_bn1_b23), 
	.din_b4(dout_bn0_b45), .din_b5(dout_bn1_b45), 
	.din_b6(dout_bn0_b67), .din_b7(dout_bn1_b67), 
	
	.M_AXIS_TREADY(m_axis_tready_obuf),
	.M_AXIS_TVALID(m_axis_tvalid_obuf),
	.M_AXIS_TDATA(m_axis_tdata_obuf),
	.M_AXIS_TLAST(m_axis_tlast_obuf)
);

// >>>>> rANS encode <<<<<
rANS#(
	.DATA_WIDTH(64),
	.PROBSCALE(256)
)rANS_inst(
	.clk(clk),
	.rst(rst),
	.start(start_rans),
	.init_done(init_done_rans),
	
	.onetrans_rd_done(onetrans_rd_done_rans),
	.all_rd_done(all_rd_done_rans),	
	
	.next_trans_wr(next_trans_wr_rans),
	.start_next_trans_wr(start_next_trans_wr_rans),
	
	.enc_done(enc_done_rans),
	.finish(finish_rans),
	
	.trans_times(rANS_DMA_RD_TRANSTIMES),
	.dma_wr_num(rANS_DMA_WR_DATANUM_ONETRANS),
	
	.tvalid_in(tvalid_rans),
	.tdata_in(tdata_rans),
	.tlast_in(tlast_rans),
	
	.s_axis_tvalid(s_axis_tvalid_w),
	.s_axis_tready(s_axis_tready_rans),
	.s_axis_tdata(s_axis_tdata_w),
	.s_axis_tlast(s_axis_tlast_w),	
	
	.m_axis_tvalid(m_axis_tvalid_rans),
	.m_axis_tready(m_axis_tready_rans),
	.m_axis_tdata(m_axis_tdata_rans),
	.m_axis_tlast(m_axis_tlast_rans)	
);

endmodule