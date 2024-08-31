module VGA_CTRL(
    input clk,
    input rst,
    input [23:0]Data,
    output VGA_BLK,
    output VGA_HS,
    output VGA_VS,
    output [23:0]VGA_RGB,
    output [9:0]hcount,
    output [9:0]vcount
    );
	
    localparam HS_End=96;
    localparam VS_End=2;
    localparam Hdata_Begin=144;
    localparam Vdata_Begin=35;
    localparam Hdata_End=784;
    localparam Vdata_End=515;
    localparam Hsync_End=800;
    localparam Vsync_End=525;
    
    wire data_act;//有效显示区标定
    reg [9:0]hcnt;
    always@(posedge clk or negedge rst)
        if(!rst)
            hcnt<=0;
        else if(hcnt>=Hsync_End-1)
            hcnt<=0;
        else 
            hcnt<=hcnt+1;
    //行同步信号        
    assign VGA_HS=(hcnt<HS_End-1)?0:1;
    
    reg [9:0]vcnt;
    always@(posedge clk or negedge rst)
        if(!rst)
            vcnt<=0;
        else if(hcnt>=Hsync_End-1)begin
            if(vcnt==Vsync_End-1)
                vcnt<=0;
            else
                vcnt<=vcnt+1;
        end
        else
            vcnt<=vcnt;
     //场同步信号     
     assign VGA_VS=(vcnt<=VS_End-1)?0:1;
     //数据有效信号
     assign data_act=((hcnt>=Hdata_Begin-1)&&(hcnt<Hdata_End-1)&&(vcnt>=Vdata_Begin-1)&&(vcnt<Vdata_End-1))?1:0;
     assign VGA_BLK=data_act;
     assign VGA_RGB=data_act?Data:0;
     
     //为了使其他模块能够根据当前扫描位置正确的输出图像数据，因此需要将 VGA 控制器的实时扫描位置输出，以供其他模块使用。
     assign hcount=data_act?(hcnt-(Hdata_Begin-1)):10'd0;
     assign vcount=data_act?(vcnt-(Vdata_Begin-1)):10'd0;               
endmodule