module normalization(
	input isInf,
	input clk,
	input[2:0] blk,
	input[127:0] frac_in,
	input sign,
	input finish_in,
	input rst,
	
	output[31:0] unum,
	output isInf_out,
	output overflow,
	output finish_out
);

reg[127:0] frac_1;
reg rst_flag;
reg sign_1;
reg isInf_1;
reg[7:6] expo_value_1;
reg finish_1;
wire[2:0] expo_wire;
assign expo_wire=blk-3'b10;
always@(posedge clk)begin
	frac_1<=sign?{~frac_in[127:64]+{63'b0,frac_in[63:0]==64'b0}, ~frac_in[63:0]+64'b1}:frac_in[127:0];
	
	expo_value_1[7:6]<=expo_wire[1:0];
	
	sign_1<=sign;
	
	isInf_1<=isInf;
	
	finish_1<=finish_in;

end

reg[7:0] expo_value_2;
reg[31:0] fraction_2;
reg sign_2;
reg isInf_2;
reg overflow_2;
reg finish_2;
wire isZero1,isZero2;
wire[5:0] shift;
wire[127:0] shift_result=frac_1<<shift;
wire[7:0] expo_value_unsign={expo_value_1[7:6],~shift};
always@(posedge clk)begin
	fraction_2<=shift_result[127:96];
	sign_2<=sign_1;
	expo_value_2[7]<=expo_value_unsign[7];
	expo_value_2[6:0]=expo_value_unsign[7]?expo_value_unsign[6:0]:(~expo_value_unsign[6:0]+7'b1);
	isInf_2<=isInf_1;
	finish_2<=finish_1;
end
NLC64 lza64(.x(frac_1[127:64]),.a(),.z(shift));

reg round;
reg[31:0] unumo_3;
reg isInf_3;
reg overflow_3;
reg finish_3;
wire signed [31:0] shift_num;
assign shift_num={expo_value_2[7],~expo_value_2[7],expo_value_2[1:0],fraction_2[30:3]};
always@(posedge clk)begin
	{unumo_3[30:0],round}<=shift_num>>>expo_value_2[6:2];
	unumo_3[31]<=sign_2;
	overflow_3<=expo_value_2[7]&expo_value_2[6];
	isInf_3<=isInf_2;
	finish_3<=finish_2;
end

reg[31:0] unumo_4;
reg isInf_4;
reg overflow_4;
reg finish_4;
wire[31:0] unumo_2s=unumo_3[31]?{unumo_3[31], ~unumo_3[30:0]+31'b1}:unumo_3;
always@(posedge clk)begin
	if(isInf_3)begin unumo_4<=32'h8000_0000; end
	else begin unumo_4<=unumo_2s+{31'b0,round}; end
	isInf_4<=isInf_3;
	overflow_4<=overflow_3;
	finish_4<=finish_3;
end

assign unum=unumo_4;
assign isInf_out=isInf_3;
assign overflow=overflow_4;
assign finish_out=finish_4;

endmodule


module NLC64(
			input[63:0] x,
			output a,
			output[5:0] z
			);
wire[3:0] a1;
wire[15:0] z1;
reg[3:0] z_out;
assign z[3:0]=z_out;
always@(*)begin
	case(z[5:4])
	2'b11:begin z_out<=z1[15:12]; end
	2'b10:begin z_out<=z1[11:8]; end
	2'b01:begin z_out<=z1[7:4]; end
	2'b00:begin z_out<=z1[3:0]; end
	endcase
end

PENC nlc(.x(a1),.a(a),.z(z[5:4]));

PENC16 PENC16_3(.x(x[15:0]), .a(a1[0]),.z(z1[15:12]) );
PENC16 PENC16_2(.x(x[31:16]), .a(a1[1]),.z(z1[11:8]) );
PENC16 PENC16_1(.x(x[47:32]), .a(a1[2]),.z(z1[7:4]) );
PENC16 PENC16_0(.x(x[63:48]), .a(a1[3]),.z(z1[3:0]) );
			
endmodule

module PENC16(
			input[15:0] x,
			output a,
			output[3:0] z
			);
wire[3:0] a1;
wire[7:0] z1;
reg[1:0] z_out;
assign z[1:0]=z_out;
always@(*)begin
	case(z[3:2])
		2'b11: begin z_out<=z1[7:6]; end
		2'b10: begin z_out<=z1[5:4]; end
		2'b01: begin z_out<=z1[3:2]; end
		2'b00: begin z_out<=z1[1:0]; end
	endcase
end
PENC PENC4(.x(a1[3:0]),.a(a),.z(z[3:2]));		
PENC PENC3(.x(x[3:0]),.a(a1[0]),.z(z1[7:6]));
PENC PENC2(.x(x[7:4]),.a(a1[1]),.z(z1[5:4]));
PENC PENC1(.x(x[11:8]),.a(a1[2]),.z(z1[3:2]));
PENC PENC0(.x(x[15:12]),.a(a1[3]),.z(z1[1:0]));
				
endmodule

module PENC(
			input[3:0] x,
			output a,
			output[1:0] z
			);

assign z[1]=~(x[3]|x[2]);
assign z[0]=~(((~x[2])&x[1])|x[3]);
assign a=(x[0]|x[1]|x[2]|x[3]);
endmodule 