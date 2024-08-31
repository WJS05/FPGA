/*采用的是RGB565的16位色*/
module image_extract(
	clk_ctrl		,//模块工作时钟
	rst				,//复位
	img_disp_hbegin	,//图片起始位置的行位置设置
	img_disp_vbegin	,//图片起始位置的列位置设置
	disp_back_color	,//屏幕背景显示颜色
	disp_data_req	,//屏幕可见区标示信号
	visible_hcount	,//图像行扫描地址
	visible_vcount	,//图像列扫描地址
	frame_begin		,//场信号开始标志
	rom_data		,//从ROM读取的数据
	disp_data		,//TFT显示的数据
	rom_addra		 //从ROM读取的数据的地址
);
	
	/*
	img_disp_hbegin=	parameter DISP_HBEGIN = (TFT_WIDTH  - DISP_IMAGE_W)/2;
	img_disp_vbegin=	parameter DISP_VBEGIN = (TFT_HEIGHT - DISP_IMAGE_H)/2;
	设计顶层文件的时候将后面两句话复制过去分别设置长度
	*/
	
	parameter H_Visible_area = 800, //整个屏幕显示区域宽度
	parameter V_Visible_area = 480, //整个屏幕显示区域高度
	parameter IMG_WIDTH = 200, //图片宽度
	parameter IMG_HEIGHT = 200, //图片高度
	parameter IMG_DATA_WIDTH = 16, //图片像素点位宽
	parameter ROM_ADDR_WIDTH = 16 //存储图片 ROM 的地址位宽
	
	input clk_ctrl ; //时钟输入，与 TFT 屏时钟保持一致
	input rst ; //复位信号，低电平有效
	input [15:0] img_disp_hbegin; //待显示图片左上角第一个像素点在 TFT 屏的行向坐标
	input [15:0] img_disp_vbegin; //待显示图片左上角第一个像素点在 TFT 屏的场向坐标
	input [IMG_DATA_WIDTH-1:0] disp_back_color; //显示的背景颜色
	output [ROM_ADDR_WIDTH-1:0] rom_addra; //读图片数据 ROM 地址
	input [IMG_DATA_WIDTH-1:0] rom_data; //读图片数据 ROM 数据
	input frame_begin; //一帧图像起始标识信号，clk_ctrl 时钟域
	input disp_data_req; //
	input [11:0] visible_hcount; //TFT 可见区域行扫描计数器
	input [11:0] visible_vcount; //TFT 可见区域场扫描计数器
	output [IMG_DATA_WIDTH-1:0] disp_data; //待显示图片数据
	
	reg [ROM_ADDR_WIDTH-1:0] rom_addra; //读图片数据 rom 地址
	
	
	//上述定义完各个端口后下面进入具体的显示环节
	
	
	//*************	首先判断图片是否能完全显示在TFT屏/显示屏的上面 *************
	wire h_exceed;
	wire v_exceed;
	assign h_exceed = (img_disp_hbegin + IMG_WIDTH) > (H_Visible_area -1'b1);
	assign v_exceed = (img_disp_vbegin + IMG_HEIGHT) > (V_Visible_area-1'b1);
	//低电平 是能完整显示在屏幕中心上
	
	wire img_h_disp;
	wire img_v_disp;
	assign img_h_disp=h_exceed?(visible_hcount>=img_disp_hbegin&&visible_hcount<H_Visible_area):(visible_hcount>=img_disp_hbegin&&visible_hcount<img_disp_hbegin+IMG_WIDTH);
	assign img_v_disp=V_exceed?(visible_vcount>=img_disp_vbegin&&visible_vcount<V_Visible_area):(visible_vcount>=img_disp_hbegin&&visible_vcount<img_disp_vbegin+IMG_HEIGHT);
	
	wire img_disp;
	assign img_disp = disp_data_req && img_h_disp && img_v_disp;
	
	//计算hcount_max的最大值，用来去区分两个情况，防止图片过大，显示在屏幕的部分
	//不处理会乱码
	assign hcount_max = h_exceed ? (H_Visible_area -1'b1):(img_disp_hbegin + IMG_WIDTH - 1'b1);
	
	always@(posedge clk_ctrl or negedge reset_n)begin
		if(!reset_n)
			rom_addra <= 15'd0;
		else if(frame_begin)
			rom_addra <= 15'd0; 
		else if(img_disp)begin
			if(visible_hcount == hcount_max)
				rom_addra <= rom_addra + (img_disp_hbegin + IMG_WIDTH -hcount_max);
			else
				rom_addra <= rom_addra + 1'b1;
		end
		else
			rom_addra <= rom_addra;
	end
	/*将 ROM 读出数据送到显示区域，其他显示区域给设置的
	背景颜色，通过二选一的方式*/
	assign disp_data = img_disp ? rom_data : disp_back_color;
	
endmodule