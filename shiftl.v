module shiftl(shout,shin);
output [27:0] shout;
input [25:0] shin;
wire [25:0] sh;
assign sh=shin<<2;
assign shout = {sh,{2'b00}};
endmodule
