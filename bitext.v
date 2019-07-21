module bitext(in1,in2,out1);
input [3:0] in1;
input [27:0] in2;
output [31:0] out1;
assign 	 out1 = {in1,in2};
endmodule
