module multiply_accumulator(
	input clk,
	input[31:0] unum1,
	input[31:0] unum2,
	input finish,
	input rst,
	input valid,
	
	output[31:0] sum,
	output isInf,
	output overflow,
	output finish_out
	);
	

///for csa1
wire[63:0] csa_frac_even;
wire[63:0] csa_frac_odd;
wire[1:0] csa_adr_even;
wire[1:0] csa_adr_odd;
wire csa_finish;
wire csa_finishadr;
wire csa_isInf; 
wire csa_sign_even,csa_sign_odd;
wire csa_rst_out;
wire csa_valid_out;
//for carry1
wire[79:0] carry1_frac_even;
wire[79:0] carry1_frac_odd;
wire[1:0] carry1_adr_even;
wire[1:0] carry1_adr_odd;
wire[2:0] carry1_block;
wire[127:0] carry1_frac_out;
wire carry1_clr_odd;
wire carry1_sign;
wire carry1_finish;
/////for ram
wire[79:0] even1_data,even1_q;
wire[1:0] even1_wradr,even1_rdadr;

wire[79:0] odd1_data,odd1_q;
wire[1:0] odd1_wradr,odd1_rdadr;
wire odd1_enable,even1_enable;

wire[79:0] even2_data,even2_q;
wire[1:0] even2_wradr,even2_rdadr;

wire[79:0] odd2_data,odd2_q;
wire[1:0] odd2_wradr,odd2_rdadr;
wire odd2_enable,even2_enable;
//////////
reg adr_select,carry_select;
reg isInf1,isInf2;
reg[9:0] isInf_delay;
wire carry1_enable;
wire ram_select;
initial
begin
	adr_select<=1'b0;
end
always@(posedge clk)begin
	if(csa_finishadr||csa_rst_out)begin 
		adr_select<=~adr_select; 
	end
end

//solve infinit case
always@(posedge clk)begin
	if(ram_select)begin
		isInf1<=1'b0;
		isInf2<=isInf2||csa_isInf;
	end else
	begin
		isInf1<=isInf1||csa_isInf;
		isInf2<=1'b0;
	end
	
	isInf_delay[9:1]<=isInf_delay[8:0];
	isInf_delay[0]<=ram_select?isInf1:isInf2;
end

assign carry1_frac_odd=ram_select?odd1_q:odd2_q;
assign carry1_frac_even=ram_select?even1_q:even2_q;


assign even1_data=ram_select?80'b0:({{16{csa_sign_even}},csa_frac_even}+even1_q);
assign odd1_data=ram_select?80'b0:({{16{csa_sign_odd}},csa_frac_odd}+odd1_q);
assign even2_data=ram_select?({{16{csa_sign_even}},csa_frac_even}+even2_q):80'b0;
assign odd2_data=ram_select?({{16{csa_sign_odd}},csa_frac_odd}+odd2_q):80'b0;

assign even1_wradr=ram_select?carry1_adr_even:csa_adr_even;
assign odd1_wradr=ram_select?carry1_adr_odd:csa_adr_odd;
assign even2_wradr=ram_select?csa_adr_even:carry1_adr_even;
assign odd2_wradr=ram_select?csa_adr_odd:carry1_adr_odd;

assign even1_rdadr=adr_select?carry1_adr_even:csa_adr_even;
assign odd1_rdadr=adr_select?carry1_adr_odd:csa_adr_odd;
assign even2_rdadr=adr_select?csa_adr_even:carry1_adr_even;
assign odd2_rdadr=adr_select?csa_adr_odd:carry1_adr_odd;

assign odd1_enable=ram_select?carry1_clr_odd:csa_valid_out;
assign odd2_enable=ram_select?csa_valid_out:carry1_clr_odd;
assign even1_enable=ram_select?1'b1:csa_valid_out;
assign even2_enable=ram_select?csa_valid_out:1'b1;


assign carry1_enable=csa_finishadr;
assign ram_select=adr_select;

RAM_control even1(
	.clk(clk),
	.data(even1_data),
	.wraddress(even1_wradr),
	.rdaddress(even1_rdadr),
	.wren(even1_enable),
	.q(even1_q)
		);

RAM_control odd1(
	.clk(clk),
	.data(odd1_data),
	.wraddress(odd1_wradr),
	.rdaddress(odd1_rdadr),
	.wren(odd1_enable),
	.q(odd1_q)
		);
RAM_control even2(
	.clk(clk),
	.data(even2_data),
	.wraddress(even2_wradr),
	.rdaddress(even2_rdadr),
	.wren(even2_enable),
	.q(even2_q)
		);
RAM_control odd2(
	.clk(clk),
	.data(odd2_data),
	.wraddress(odd2_wradr),
	.rdaddress(odd2_rdadr),
	.wren(odd2_enable),
	.q(odd2_q)
		);

CSA_carry carry1(
	.clk(clk),
	.enable(carry1_enable),
	.frac_even(carry1_frac_even),
	.frac_odd(carry1_frac_odd),
	
	.adr_even(carry1_adr_even),
	.adr_odd(carry1_adr_odd),
	.blk(carry1_block),
	.frac_out(carry1_frac_out),
	.clr_odd(carry1_clr_odd),
	.sign(carry1_sign),
	.finish(carry1_finish)
					);

					
unum_CSA unum_csa1(
	.clk(clk),
	.unum1(unum1),
	.unum2(unum2),
	.finish_in(finish),
	.rst(rst),
	.valid(valid),
	
	.frac_even(csa_frac_even),
	.frac_odd(csa_frac_odd),
	.adr_even(csa_adr_even),
	.adr_odd(csa_adr_odd),
	.finish_o(csa_finish),
	.finish_adr(csa_finishadr),
	.isInf(csa_isInf),
	.sign_even(csa_sign_even),
	.sign_odd(csa_sign_odd),
	.rst_out(csa_rst_out),
	.valid_out(csa_valid_out)
);


normalization normal1(
	.isInf(isInf_delay[9]),
	.clk(clk),
	.blk(carry1_block),
	.frac_in(carry1_frac_out),
	.sign(carry1_sign),
	.finish_in(carry1_finish),
	.rst(rst),
	
	.unum(sum),
	.isInf_out(isInf),
	.overflow(overflow),
	.finish_out(finish_out)
);


endmodule 