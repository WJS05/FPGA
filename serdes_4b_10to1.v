module serdes_4b_10to1(		//四通道并行10bit->1bit串行输出
	input clkx5,
	input [9:0]datain_0,
	input [9:0]datain_1,
	input [9:0]datain_2,
	input [9:0]datain_3,
	output dataout_0_p, // out DDR data
	output dataout_0_n, // out DDR data
	output dataout_1_p, // out DDR data
	output dataout_1_n, // out DDR data
	output dataout_2_p, // out DDR data
	output dataout_2_n, // out DDR data
	output dataout_3_p, // out DDR data
	output dataout_3_n  // out DDR data
);
	reg [2:0] TMDS_mod5 = 0; // 模 5 计数器
	reg [4:0] TMDS_shift_0h = 0, TMDS_shift_0l = 0;
	reg [4:0] TMDS_shift_1h = 0, TMDS_shift_1l = 0;
	reg [4:0] TMDS_shift_2h = 0, TMDS_shift_2l = 0;
	reg [4:0] TMDS_shift_3h = 0, TMDS_shift_3l = 0;
	//1.首先将进来的3路10bit数据拆分到TMDS_x_l 和 TMDS_x_h 中
	//1
	wire [4:0]TMDS_0_l={datain_0[9],datain_0[7],datain_0[5],datain_0[3],datain_0[1]};
	wire [4:0]TMDS_0_h={datain_0[8],datain_0[6],datain_0[4],datain_0[2],datain_0[0]};
	//2
	wire [4:0]TMDS_1_l={datain_1[9],datain_1[7],datain_1[5],datain_1[3],datain_1[1]};
	wire [4:0]TMDS_1_h={datain_1[8],datain_1[6],datain_1[4],datain_1[2],datain_1[0]};
	//3
	wire [4:0]TMDS_2_l={datain_2[9],datain_2[7],datain_2[5],datain_2[3],datain_2[1]};
	wire [4:0]TMDS_2_l={datain_2[8],datain_2[6],datain_2[4],datain_2[2],datain_2[0]};
	//4
	wire [4:0] TMDS_3_l ={datain_3[9],datain_3[7],datain_3[5],datain_3[3],datain_3[1]};
	wire [4:0] TMDS_3_h ={datain_3[8],datain_3[6],datain_3[4],datain_3[2],datain_3[0]};
	
	/*// 模 5 计数器+更新数据
	always @(posedge clkx5)
	begin
	if(TMDS_mod5 >= 3'd4)
		TMDS_mod5 <= 3'd0;
	else
		TMDS_mod5 <= TMDS_mod5 + 3'd1;
	end
	// 5 倍速度移位发送数据
	always @(posedge clkx5)
	begin
	if(TMDS_mod5 == 3'd4)begin
		TMDS_shift_0h <= TMDS_0_h;
		TMDS_shift_0l <= TMDS_0_l;
		TMDS_shift_1h <= TMDS_1_h;
		TMDS_shift_1l <= TMDS_1_l;
		TMDS_shift_2h <= TMDS_2_h;
		TMDS_shift_2l <= TMDS_2_l;
		TMDS_shift_3h <= TMDS_3_h;
		TMDS_shift_3l <= TMDS_3_l;
	end
	else begin
		TMDS_shift_0h <= TMDS_shift_0h[4:1];
		TMDS_shift_0l <= TMDS_shift_0l[4:1];
		TMDS_shift_1h <= TMDS_shift_1h[4:1];
		TMDS_shift_1l <= TMDS_shift_1l[4:1];
		TMDS_shift_2h <= TMDS_shift_2h[4:1];
		TMDS_shift_2l <= TMDS_shift_2l[4:1];
		TMDS_shift_3h <= TMDS_shift_3h[4:1];
		TMDS_shift_3l <= TMDS_shift_3l[4:1];
	end
	end
	*/
	always @(posedge clkx5)
	begin
	TMDS_mod5 <= (TMDS_mod5[2]) ? 3'd0 : TMDS_mod5 + 3'd1;
	TMDS_shift_0h <= TMDS_mod5[2] ? TMDS_0_h : TMDS_shift_0h[4:1];
	TMDS_shift_0l <= TMDS_mod5[2] ? TMDS_0_l : TMDS_shift_0l[4:1];
	TMDS_shift_1h <= TMDS_mod5[2] ? TMDS_1_h : TMDS_shift_1h[4:1];
	TMDS_shift_1l <= TMDS_mod5[2] ? TMDS_1_l : TMDS_shift_1l[4:1];
	TMDS_shift_2h <= TMDS_mod5[2] ? TMDS_2_h : TMDS_shift_2h[4:1];
	TMDS_shift_2l <= TMDS_mod5[2] ? TMDS_2_l : TMDS_shift_2l[4:1];
	TMDS_shift_3h <= TMDS_mod5[2] ? TMDS_3_h : TMDS_shift_3h[4:1];
	TMDS_shift_3l <= TMDS_mod5[2] ? TMDS_3_l : TMDS_shift_3l[4:1];
	end
	
	wire dataout_0;
	wire dataout_1;
	wire dataout_2;
	wire dataout_3;
	
	ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_0 (
      .Q(dataout_0),   // 1-bit DDR output
      .C(clkx5),   // 时钟信号
      .CE(1'b1), // 使能
      .D1(TMDS_shift_0l[0]), // 输入数据高段输出端口
      .D2(TMDS_shift_0h[0]), // 输入数据低段输出端口
      .R(1'b0),   // 置位输入
      .S(1'b0)    // 复位   高电平复位
   );
	OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_0 (
      .O(dataout_0_p ),     // Diff_p output (connect directly to top-level port)
      .OB(dataout_0_n),   // Diff_n output (connect directly to top-level port)
      .I(dataout_0 )      // Buffer input
   );

	ODDR #(
	.DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
	.INIT(1'b0), // Initial value of Q: 1'b0 or 1'b1
	.SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_1 (
	.Q (dataout_1 ),// 1-bit DDR output
	.C (clkx5 ),// 1-bit clock input
	.CE(1'b1 ),// 1-bit clock enable input
	.D1(TMDS_shift_1l[0] ),// 1-bit data input (positive edge)
	.D2(TMDS_shift_1h[0] ),// 1-bit data input (negative edge)
	.R (1'b0 ),// 1-bit reset
	.S (1'b0 ) // 1-bit set
   );
	OBUFDS #(
	.IOSTANDARD("DEFAULT"), // Specify the output I/O standard
	.SLEW("SLOW") // Specify the output slew rate
   ) OBUFDS_1 (
	.O (dataout_1_p ),// Diff_p output (connect directly to top-level port)
	.OB (dataout_1_n ),// Diff_n output (connect directly to top-level port)
	.I (dataout_1 ) // Buffer input
   );   
   
	ODDR #(
	.DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
	.INIT(1'b0), // Initial value of Q: 1'b0 or 1'b1
	.SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_2 (
	.Q (dataout_2 ),// 1-bit DDR output
	.C (clkx5 ),// 1-bit clock input
	.CE(1'b1 ),// 1-bit clock enable input
	.D1(TMDS_shift_2l[0] ),// 1-bit data input (positive edge)
	.D2(TMDS_shift_2h[0] ),// 1-bit data input (negative edge)
	.R (1'b0 ),// 1-bit reset
	.S (1'b0 ) // 1-bit set
   );
	OBUFDS #(
	.IOSTANDARD("DEFAULT"), // Specify the output I/O standard
	.SLEW("SLOW") // Specify the output slew rate
   ) OBUFDS_2 (
	.O (dataout_2_p ),// Diff_p output (connect directly to top-level port)
	.OB (dataout_2_n ),// Diff_n output (connect directly to top-level port)
	.I (dataout_2 ) // Buffer input
   );

	ODDR #(
	.DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
	.INIT(1'b0), // Initial value of Q: 1'b0 or 1'b1
	.SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_3 (
	.Q (dataout_3 ),// 1-bit DDR output
	.C (clkx5 ),// 1-bit clock input
	.CE(1'b1 ),// 1-bit clock enable input
	.D1(TMDS_shift_3l[0] ),// 1-bit data input (positive edge)
	.D2(TMDS_shift_3h[0] ),// 1-bit data input (negative edge)
	.R (1'b0 ),// 1-bit reset
	.S (1'b0 ) // 1-bit set
   );
	OBUFDS #(
	.IOSTANDARD("DEFAULT"), // Specify the output I/O standard
	.SLEW("SLOW") // Specify the output slew rate
   ) OBUFDS_3 (
	.O (dataout_3_p ),// Diff_p output (connect directly to top-level port)
	.OB (dataout_3_n ),// Diff_n output (connect directly to top-level port)
	.I (dataout_3 ) // Buffer input
   );
endmodule