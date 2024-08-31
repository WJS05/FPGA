module dvi_encoder(
	input pixelclk,
	input pixelclk5x,
	input rst,
	input hsync,
	input vsync,
	input de,
	input [7:0]bule_din,
	input [7:0]green_din,
	input [7:0]red_din,
	output [2:0]tmds_data_p,
	output [2:0]tmds_data_n,
	output tmds_clk_p,
	output tmds_clk_n
);

	wire [9:0] red;
	wire [9:0] green;
	wire [9:0] blue;

	encode en_BLUE(	//最小化传输编码
		.clk	(pixelclk)		,//input clk
		.rst	(rst)			,//input rst
		.din	(bule_din)		,//input [7:0]din
		.c0		(hsync)			,//input c0输入
		.c1		(vsync)			,//input c1输入
		.de		(de)			,//input 数据使能
		.dout	(blue)			//数据输出output [9:0]dout 
	);
	
	encode en_GREEN(	//最小化传输编码
		.clk	(pixelclk)		,//input clk
		.rst	(rst)			,//input rst
		.din	(green_din)		,//input [7:0]din
		.c0		(1'b0)			,//input c0输入
		.c1		(1'b0)			,//input c1输入
		.de		(de)			,//input 数据使能
		.dout	(green)			//数据输出output [9:0]dout 
	);
	
	encode en_REG(	//最小化传输编码
		.clk	(pixelclk)		,//input clk
		.rst	(rst)			,//input rst
		.din	(reg_din)		,//input [7:0]din
		.c0		(1'b0)			,//input c0输入
		.c1		(1'b0)			,//input c1输入
		.de		(de)			,//input 数据使能
		.dout	(red)			//数据输出output [9:0]dout 
	);
	
	serdes_4b_10to1(		//四通道并行10bit->1bit串行输出
	.clkx5		(pixelclk5x),        //	input clkx5,
	.datain_0	(blue),//	input [9:0]datain_0
	.datain_1	(green),//	input [9:0]datain_1
	.datain_2	(red),//	input [9:0]datain_2
	.datain_3	(10'b1111100000),//	input [9:0]datain_3
	.dataout_0_p(tmds_data_p[0]), //	output dataout_0_p,
	.dataout_0_n(tmds_data_n[0]), //	output dataout_0_n,
	.dataout_1_p(tmds_data_p[1]), //	output dataout_1_p,
	.dataout_1_n(tmds_data_n[1]), //	output dataout_1_n,
	.dataout_2_p(tmds_data_p[2]), //	output dataout_2_p,
	.dataout_2_n(tmds_data_n[2]), //	output dataout_2_n,
	.dataout_3_p(tmds_data_p[3]), //	output dataout_3_p,
	.dataout_3_n(tmds_data_n[3])  //	output dataout_3_n 
);
endmodule