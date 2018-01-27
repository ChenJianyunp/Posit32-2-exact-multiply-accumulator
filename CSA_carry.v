module CSA_carry(
	input enable,
	input clk,
	input[79:0] frac_even,
	input[79:0] frac_odd,

	
	output[1:0] adr_even,
	output[1:0] adr_odd,
	output[2:0] blk,
	output[127:0] frac_out,
	output clr_odd,
	output sign,
	output finish
					);

reg[15:0] carry;
reg sign_1;
reg[63:0] fraction;
reg[2:0] block,block_delay1;
reg stop_flag,stop_flag_delay1;
reg enable_delay1;

wire[79:0] frac;
wire[79:0] add_result;
assign frac=block[0]?frac_odd:frac_even;
assign add_result=frac+{{64{carry[15]}},carry};
always@(posedge clk)begin
	if(enable)begin
		block<=3'b000;
		carry<=16'b0;
		fraction<=64'b0;
		stop_flag<=1'b0;
	end
	else begin
		if(block==3'b111)begin
			stop_flag<=1'b1;
		end else begin
			block<=block+3'b1;
		end
		carry<=add_result[79:64];
		fraction<=add_result[63:0];
	end
	
	if(block==3'b111)begin
		sign_1<=carry[15];
	end
	
	block_delay1<=block;
	stop_flag_delay1<=stop_flag;
	enable_delay1<=enable;
	
end

reg[127:0] fraction_pos_2,fraction_neg_2;
reg[2:0] block_pos_2,block_neg_2;
reg sign_2;
reg finish_2,finish_2_delay,finish_2_delay2;
always@(posedge clk)begin
	if(enable_delay1)begin
		fraction_pos_2<=128'b0;
		fraction_neg_2<=128'b0;
		block_neg_2<=3'b0;
		block_pos_2<=3'b0;
	end else begin
		if(~stop_flag_delay1) begin
			if(fraction!=64'b0)begin
				fraction_pos_2[127:64]<=fraction;
				fraction_pos_2[63:0]<=(block_delay1==(block_pos_2+3'b1))?fraction_pos_2[127:64]:64'b0;
				block_pos_2<=block_delay1;
			end
		
			if(fraction!=64'hffff_ffff_ffff_ffff)begin
				fraction_neg_2[127:64]<=fraction;
				fraction_neg_2[63:0]<=(block_delay1==(block_neg_2+3'b1))?fraction_neg_2[127:64]:64'b0;
				block_neg_2<=block_delay1;
			end
		end
	end

	if(block_delay1==3'b110)begin
		finish_2<=1'b1;
	end
	else begin
		finish_2<=1'b0;
	end
	sign_2<=sign_1;
	finish_2_delay<=finish_2;
	finish_2_delay2<=finish_2_delay;
end

assign adr_even=block[2:1];
assign adr_odd=block[2:1];
assign frac_out=sign_2?fraction_neg_2:fraction_pos_2;
assign blk=sign_2?block_neg_2:block_pos_2;
assign clr_odd=block[0];
assign sign=sign_2;
assign finish=finish_2_delay2;//&~finish_2_delay2;

endmodule 