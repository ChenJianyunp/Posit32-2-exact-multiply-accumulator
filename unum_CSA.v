module unum_CSA(
	input clk,
	input[31:0] unum1,
	input[31:0] unum2,
	input finish_in,
	input rst,
	input valid,
	
	output[63:0] frac_even,
	output[63:0] frac_odd,
	output[1:0] adr_even,
	output[1:0] adr_odd,
	output finish_adr,
	output finish_o,
	output isInf, 
	output sign_even,
	output sign_odd,
	output rst_out,
	output valid_out
					);

reg[31:0] unum1_0,unum2_0;
reg finish_0,rst_0,valid_0;
//0st in order to reduce the delay, first buffer all the input 
always@(posedge clk)begin
	unum1_0<=unum1;
	unum2_0<=unum2;
	finish_0<=finish_in;
	rst_0<=rst;
	valid_0<=valid;
end

					
//1st: check whether the input number is special situations: zero and Inf
//If the number is nagative, change it from 2's complement to original  
reg[1:0] isZero_1;   //isZero[1]: unum1   [0]: unum2    =0 if value is zero
reg[1:0] isInf_1;	 //isInf[1]: unum1    [0]: unum2    =1 if value is Inf
reg[31:0] temp1,temp2;  //store changed or unchange input numbers
//reg[4:0] unum1_shift,unum2_shift; //result of zero/one counting
reg finish_1;
reg rst_1;
reg valid_1;
wire[4:0] n1,n2;//result of leading zero count
wire[30:0] unum1_2s,unum2_2s;
assign unum1_2s=unum1_0[31]?(~unum1_0[30:0]+31'b1):unum1_0[30:0];
assign unum2_2s=unum2_0[31]?(~unum2_0[30:0]+31'b1):unum2_0[30:0];					
always@(posedge clk)begin
	if(unum1_0[30:0]==31'b0)begin isZero_1[1]<=unum1_0[31]; isInf_1[1]<=unum1_0[31]; end
	else begin isZero_1[1]<=1'b1; isInf_1[1]<=1'b0;end 
	
	if(unum2_0[30:0]==31'b0)begin isZero_1[0]<=unum2_0[31]; isInf_1[0]<=unum2_0[31]; end
	else begin isZero_1[0]<=1'b1; isInf_1[0]<=1'b0; end
	
	temp1<=unum1_2s;  /// change unum from 2nd complement to original
	
	temp2<=unum2_2s;
	
	finish_1<=finish_0;
	valid_1<=valid_0;
	
	temp1[31]<=unum1_0[31];
	temp2[31]<=unum2_0[31];
	
	rst_1<=rst_0;
end


//2nd: Left shift the temp so that the exponent bits, sign bit and fraction bits will in the certain positions.
//change regime bits and exponent bits into exponent value in 2's complement format
reg isInf_2;  //if one of the input numbers is Inf, this bit will be 1
reg[31:0] temp1_2,temp2_2;  //[31]:sign bit   [30]: ==1 if component value is negative, ==0 if zero or positive. [29]: ~[30]      [28:26]:exponent bits [25:0]:fraction bit 
reg[7:2] expo_num1, expo_num2; //store exponent values
reg NaN_2;
reg rst_2;
reg isZero_2;
reg finish_2;
reg valid_2;
always@(posedge clk)begin        ///2nd
	temp1_2[30:0]<=temp1[30:0]<<n1;
	temp2_2[30:0]<=temp2[30:0]<<n2;
	temp1_2[31]<=temp1[31];
	temp2_2[31]<=temp2[31];	
	
	if(temp1[30]) begin expo_num1[6:2]<=n1; end
	else begin expo_num1[6:2]<=~n1; end
	expo_num1[7]<=temp1[30];
	
	
	if(temp2[30]) begin expo_num2[6:2]<=n2; end
	else begin expo_num2[6:2]<=~n2; end
	expo_num2[7]<=temp2[30];
	
	isInf_2<=isInf_1[1]|isInf_1[0];
	NaN_2<=(isInf_1[1]&~isZero_1[0])|(~isZero_1[1]&isInf_1[0]);
	
	isZero_2<=isZero_1[1]&isZero_1[0];
	
	finish_2<=finish_1;
	valid_2<=valid_1;
	rst_2<=rst_1;

end
LZC lzc1(.x1(temp1[30:0]),.n(n1));
LZC lzc2(.x1(temp2[30:0]),.n(n2));

reg isInf_3;  //if one of the input numbers is Inf, this bit will be 1
reg[8:0] expo_numo;
reg sign_3;
reg rst_3;
//wire[55:0] frac_numo;
reg finish_3;
reg valid_3;
reg[1:0] adress_odd_3,adress_even_3;
wire[8:0] expo_numow;
wire[27:0] frac_num1_3,frac_num2_3;
assign expo_numow={expo_num1[7:2],temp1_2[28:27]}+{expo_num2[7:2],temp2_2[28:27]};
assign frac_num1_3={isZero_2,temp1_2[26:0]};
assign frac_num2_3={isZero_2,temp2_2[26:0]};
reg[41:0] product_l,product_h;
always@(posedge clk)begin
	expo_numo<=expo_numow;
	product_l<=frac_num1_3*frac_num2_3[14:0];
	product_h<=frac_num1_3*frac_num2_3[27:15];
	adress_even_3<=expo_numow[8:7];
	adress_odd_3<=expo_numow[8:7]-{1'b0,~expo_numow[6]};
	sign_3<=temp1_2[31]^temp2_2[31];
	isInf_3<=isInf_2;
	finish_3<=finish_2;
	rst_3<=rst_2;
	valid_3<=valid_2;
end

reg isInf_4;
reg sign_even_4,sign_odd_4;
reg finish_4;
reg rst_4;
reg valid_4;
reg[1:0] adress_odd_4,adress_even_4;
reg[127:0] shift_result;
reg sign_w;
reg sign_4;
reg choose_evenodd;
wire[55:0] product;
assign product[13:0]=product_l[13:0];
assign product[55:14]=product_h+{14'b0,product_l[41:14]};
always@(posedge clk)begin
	isInf_4<=isInf_3;
	adress_even_4<=adress_even_3;
	adress_odd_4<=adress_odd_3;
	shift_result<={62'b0,product,10'b0}<<expo_numo[5:0];
	sign_w<=sign_3&(shift_result[63:0]!=64'b0);
	sign_4<=sign_3;
	choose_evenodd<=expo_numo[6];
	
	valid_4<=valid_3;
	finish_4<=finish_3;
	rst_4<=rst_3;
end

reg valid_5,finish_5,rst_5,isInf_5;
reg[1:0] adress_odd_5,adress_even_5;
reg sign_even_5,sign_odd_5;
reg[63:0] odd, even;
wire[127:0] shift_2s;
assign shift_2s=sign_4?{~shift_result[127:64]+64'b1,~shift_result[63:0]+64'b1}:shift_result;
always@(posedge clk)begin
	if(choose_evenodd)begin
		{odd,even}<=shift_2s;
		{sign_odd_5,sign_even_5}<={sign_4,sign_w};
	end 
	else begin
		{even,odd}<=shift_2s;
		{sign_even_5,sign_odd_5}<={sign_4,sign_w};	
	end
	
	
	adress_even_5<=adress_even_4;
	adress_odd_5<=adress_odd_4;
	isInf_5<=isInf_4;
	valid_5<=valid_4;
	finish_5<=finish_4;
	rst_5<=rst_4;
end

//reg isInf_4;
//reg sign_even_4,sign_odd_4;
//reg[63:0] odd, even;
//reg finish_4;
//reg rst_4;
//reg valid_4;
//reg[1:0] adress_odd_4,adress_even_4;
//wire[127:0] shift_result,shift_2s;
//wire sign_w;
//assign shift_result={62'b0,frac_numo,10'b0}<<expo_numo[5:0];
//assign shift_2s=sign_3?{~shift_result[127:64]+64'b1,~shift_result[63:0]+64'b1}:shift_result;
//assign sign_w=sign_3&(shift_result[63:0]!=64'b0);
//always@(posedge clk)begin
//	isInf_4<=isInf_3;
//	adress_even_4<=adress_even_3;
//	adress_odd_4<=adress_odd_3;
//	if(expo_numo[6])begin
//		{odd,even}<=shift_2s;
//		{sign_odd_4,sign_even_4}<={sign_3,sign_w};
//	end 
//	else begin
//		{even,odd}<=shift_2s;
//		{sign_even_4,sign_odd_4}<={sign_3,sign_w};	
//	end
	
//	valid_4<=valid_3;
//	finish_4<=finish_3;
//	rst_4<=rst_3;
//end



assign frac_even=even;
assign frac_odd=odd;
assign adr_even=adress_even_5;
assign adr_odd=adress_odd_5;
assign finish_adr=finish_5;
assign finish_o=finish_5;
assign isInf=isInf_5;
assign sign_even=sign_even_5;
assign sign_odd=sign_odd_5;
assign rst_out=rst_4;
assign valid_out=valid_5;



endmodule 


//LZC(leading zero counter) module is designed based on MODULAR DESIGN OF FAST LEADING ZEROS COUNTING CIRCUIT (http://iris.elf.stuba.sk/JEEEC/data/pdf/6_115-05.pdf)
module LZC(
			input[30:0] x1,
			output[4:0] n
			);
wire[7:0] a;
wire[15:0] z;
reg[31:0] x;
reg [1:0] n1;
wire[2:0] y;
assign n[1:0]=n1[1:0];
assign n[4:2]=y;

always@(*)begin

	if(x1[30]) begin x[31:2]=~x1[29:0]; end			//if the number starts with 1, inverse it
	else begin x[31:2]=x1[29:0]; end
	x[1:0]=2'b10;
	case(y)
	3'b000: n1[1:0]=z[1:0];
	3'b001: n1[1:0]=z[3:2];
	3'b010: n1[1:0]=z[5:4];
	3'b011: n1[1:0]=z[7:6];
	3'b100: n1[1:0]=z[9:8];
	3'b101: n1[1:0]=z[11:10];
	3'b110: n1[1:0]=z[13:12];
	3'b111: n1[1:0]=z[15:14];
	endcase
end
BNE BNE1(.a(a), .y(y));			
NLC NLC7(.x(x[3:0]),		.a(a[7]), 	.z(z[15:14]) );
NLC NLC6(.x(x[7:4]),		.a(a[6]), 	.z(z[13:12]) );
NLC NLC5(.x(x[11:8]),	.a(a[5]),	.z(z[11:10]) );
NLC NLC4(.x(x[15:12]),	.a(a[4]), 	.z(z[9:8])  );
NLC NLC3(.x(x[19:16]),	.a(a[3]), 	.z(z[7:6])  );
NLC NLC2(.x(x[23:20]),	.a(a[2]), 	.z(z[5:4])  );
NLC NLC1(.x(x[27:24]),	.a(a[1]), 	.z(z[3:2])  );
NLC NLC0(.x(x[31:28]),	.a(a[0]), 	.z(z[1:0])  );
endmodule


module BNE(
			input[7:0] a,
			output[2:0] y 
			);
assign y[2]=a[0]&a[1]&a[2]&a[3];
assign y[1]=a[0]&a[1]&(~a[2]|~a[3]|(a[4]&a[5]));
assign y[0]=a[0]&(~a[1]|(a[2]&~a[3]))|(a[0]&a[2]&a[4]&(~a[5]|a[6]));
endmodule



module NLC(
			input[3:0] x,
			output a,
			output[1:0] z
			);

assign z[1]=~(x[3]|x[2]);
assign z[0]=~(((~x[2])&x[1])|x[3]);
assign a=~(x[0]|x[1]|x[2]|x[3]);
endmodule 