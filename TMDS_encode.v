module encode(	//最小化传输编码
	input clk,
	input rst,
	input [7:0]din,//数据输入，需要寄存
	input c0,		//c0输入
	input c1,		//c1输入
	input de,		//数据使能
	output [9:0]dout	//数据输出
);
	//四种状态
	parameter CTL0 = 10'b1101010100;
	parameter CTL1 = 10'b0010101011;
	parameter CTL2 = 10'b0101010100;
	parameter CTL3 = 10'b1010101011;
	
	reg [3:0]n1d;	//统计输入8bit数据中1的个数
	reg [7:0]din_q;	//同步寄存输入的8bit数据（统计需要一拍时间）
	
	//统计输入8bit数据中1的个数。流水线输出。同步寄存输入的数据。
	always@(posedge clk)begin
	din_q<=din;
	n1d<=din[0]+din[1]+din[2]+din[3]+din[4]+din[5]+din[6]+din[7];
	end
	
	//第一步:8bit->9bit
	wire decision1;//0
	assign decision1=(n1d>4'h4)|((n1d==4'h4)&(din_q[0]==1;b0));
	
	// 最低位不变，剩下的等于前一位跟对应的 din_q 相异或运算，或者是同或运算
	// q_m[0] = din_q[0];
	// q_m[i+1] = q_m[i] ^ din_q[i+1]; q_m[8] = 1;
	// q_m[i+1] = q_m[i] ^~ din_q[i+1]; q_m[8] = 0;
	//使用下面的语句进行替换两个for
	
	wire [8:0]q_m;
	assign q_m[0]=din_q[0];
	assign q_m[1]=(decision1)?~(q_m[0] ^din_q[1]):(q_m[0] ^ din_q[1]);
	assign q_m[2]=(decision1)?~(q_m[1] ^din_q[2]):(q_m[1] ^ din_q[2]);
	assign q_m[3]=(decision1)?~(q_m[2] ^din_q[3]):(q_m[2] ^ din_q[3]);
	assign q_m[4]=(decision1)?~(q_m[3] ^din_q[4]):(q_m[3] ^ din_q[4]);
	assign q_m[5]=(decision1)?~(q_m[4] ^din_q[5]):(q_m[4] ^ din_q[5]);
	assign q_m[6]=(decision1)?~(q_m[5] ^din_q[6]):(q_m[5] ^ din_q[6]);
	assign q_m[7]=(decision1)?~(q_m[6] ^din_q[7]):(q_m[6] ^ din_q[7]);
	assign q_m[8]=(decision1)?1'b0:1'b1;
	
	//第二步：9bit->10bit
	reg [3:0]n1q_m,n0q_m;//统计q_m中1和0的个数
	always @ (posedge clk) begin
	n1q_m <= q_m[0]+ q_m[1]+ q_m[2]+ q_m[3]+ q_m[4]+ q_m[5]+q_m[6]+ q_m[7];
	n0q_m <= 4'h8-(q_m[0]+q_m[1]+q_m[2]+q_m[3]+ q_m[4]+ q_m[5]+q_m[6]+ q_m[7]);
	end
	
	reg[4:0]cnt;//计数器差距统计：统计1和0是否过量发送，最高位cnt[4]是符号位
	wire decision2,decision3;
	assign decision2=(cnt==5'h0)|(n1q_m==n0q_m);
	
	// [(cnt > 0) and (N1q_m > N0q_m)] or [(cnt < 0) and (N0q_m > N1q_m)]
	//第三个判断条件,因为cnt[4]是符号位，所以可以根据是否为1来判断大于0或者小于0
	assign decision3 = (~cnt[4] & (n1q_m > n0q_m)) | (cnt[4] &(n0q_m > n1q_m));


	// 流水线对齐(同步寄存器 2 拍)
	reg [1:0] de_reg;
	reg [1:0] c0_reg;
	reg [1:0] c1_reg;
	reg [8:0] q_m_reg;
	//使用这个方法可以存储两拍数据，来解决一些告诉转化的问题
	/*在高速接口中有多个时钟域，对此可以使信号进入不同的时钟域
	正确的对齐与同步*/
	always @ (posedge clk) begin
	de_reg <= {de_reg[0], de};
	c0_reg <= {c0_reg[0], c0};
	c1_reg <= {c1_reg[0], c1};
	q_m_reg <= q_m;
	end
	
	//10bit 数据输出
	always@(posedge clk or negedge rst)begin
		if(!rst)begin
			dout<=0;
			cnt<=0;
		end
		else begin
			if(de_reg[1])begin//这个是使能信号    数据周期：发送对应的编码数据
				if(decision2)begin
					dout[9]<=~q_m_reg[8];
					dout[8]<=q_m_reg[8];
					dout[7:0]<=(q_m_reg[8])?q_m_reg[7:0]:~q_m_reg[7:0];
					cnt<=(~q_m_reg[8])?(cnt+n0q_m-n1q_m):(cnt+n1q_m-n0q_m);
				end
				else begin
					if(decision3)begin
						dout[9]<=1'b1;
						dout[8]<=q_m_reg[8];
						dout[7:0]<=~q_m_reg[7:0];
						cnt<=cnt+{q_m_reg,1'b0}+(n0q_m-n1q_m);
					end
					else begin
						dout[9] <= 1'b0;
						dout[8] <= q_m_reg[8];
						dout[7:0] <= q_m_reg[7:0];
						cnt <= cnt - {~q_m_reg[8], 1'b0} + (n1q_m -n0q_m);	
					end
				end
			end
			else begin
				cnt<=5'd0;
				case({c1_reg[1], c0_reg[1]})
				2'b00:	dout<=CTL0;
				2'b01:	dout<=CTL1;
				2'b10:	dout<=CTL2;
				default:dout<=CTL3;
				endcase
			end
		end
	end
endmodule
