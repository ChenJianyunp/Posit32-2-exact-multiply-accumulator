module RAM_control(
		input clk,
		input[79:0] data,
		input[1:0] wraddress,
		input[1:0] rdaddress,
		input wren,
		
		output[79:0] q
		);

	
reg[79:0] dram[3:0];
initial
begin
	dram[0]<=80'h0;
	dram[1]<=80'h0;
	dram[2]<=80'h0;
	dram[3]<=80'h0;
end
	
always@(posedge clk)begin
	if(wren)begin
		dram[wraddress]<=data;
	end
end
assign q=dram[rdaddress];
			
endmodule 