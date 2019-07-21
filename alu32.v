module alu32(sum,a,b,sham,zout,nout,gin);//ALU operation according to the ALU control line values
output [31:0] sum;
input [31:0] a,b; 
input [2:0] gin;//ALU control line
input [4:0] sham;
reg [31:0] sum;
reg [31:0] sub;
reg [31:0] less;
wire [4:0]  sham;
output zout,nout;
reg zout,nout;
always @(a or b or sham or gin)
begin
	case(gin)
	3'b010: sum=a+b; 		//ALU control line=010, ADD
	3'b110: begin sub=a+1+(~b);	//ALU control line=110, SUB
                if (sub[31]) sum=0;     //activate negativity bit where result is negative
                else sum=1;
                end
        3'b011: sum=((a&(~b)) | ((~a)&b));   //ALU control line=011, XOR
	3'b111: begin less=a+1+(~b);	//ALU control line=111, set on less than
			if (less[31]) sum=1;	
			else sum=0;
		  end
	3'b000: sum=a & b;	//ALU control line=000, AND
	3'b001: sum=a|b;		//ALU control line=001, OR
        3'b100: sum=b>>sham;        //ALU control line=100 ,SHR
	default: sum=31'bx;	
	endcase
zout=~(|sum);
nout=~(|sum);
end
endmodule
