module processor;
reg [31:0] pc; //32-bit prograom counter
reg clk; //clock
reg [7:0] datmem[0:31],mem[0:31]; //32-size data and instruction memory (8 bit(1 byte) for each location)
wire [31:0] 
dataa,	//Read data 1 output of Register File
datab,	//Read data 2 output of Register File
out2,		//Output of mux with ALUSrc control-mult2
out3,		//Output of mux with MemToReg control-mult3
out4,		//Output of mux with (Branch&ALUZero) control-mult4
out5,           //Output of mux with  signext or zeroext control-mult5
out6,           //Output of mux with  register adress or branch(offset) addresss control-mult6
out7,           //Output of mux with branch & jump control-mult7
out8,           //Output of mux with out1 and REg[31] -mult8
out9,           //Output of mux with ALU result and PC+4 - mult9
out10,          //Output of mux with PC+4 & jump32-mult10
out11,          //Output of mux with jump address or M[Reg[29]]-mult11
out12,          //Output of mux with datab & PC+4-mult12
sum,		//ALU result
jump32,         //32 bit jump address with PC+4 's 31-28 bits
reg31,          //rgister file that holds the reg31
extad,	        //Output of sign-extend unit
extzero,        //Output of Zero extend unit
adder1out,	//Output of adder which adds PC and 4-add1
adder2out,	//Output of adder which adds PC+4 and 2 shifted sign-extend result-add2
sextad;	//Output of shift left 2 unit
wire [27:0] jaddr;          //instr[25-0] shifted left 2 times 28 bits
wire [5:0] inst31_26;	//31-26 bits of instruction 
wire [3:0] pc4;   //PC+4 registers [31:28] bits
wire [4:0] sham, //shift amount for r types            
inst25_21,	//25-21 bits of instruction
inst20_16,	//20-16 bits of instruction
inst15_11,	//15-11 bits of instruction
out1;		//Write data input of Register File
wire [25:0] inst25_0;    //25-0 bits of instruction
wire [15:0] inst15_0;	//15-0 bits of instruction
wire [4:0]  regnumber;  //To identify register number
wire [31:0] instruc,	//current instruction
dpack;	//Read data output of memory (data read from memory)

wire [2:0] gout;	//Output of ALU control unit

wire zout,	//Zero output of ALU
nout,           //Negativity output of ALU
pcsrc,	//Output of AND gate with Branch and ZeroOut inputs
//Control signals
regdest,ext,jump,jspa,alusrc,memtoreg,regwrite,memread,memwrite,branch,aluop1,aluop0;

//32-size register file (32 bit(1 word) for each register)
reg [31:0] registerfile[0:31];

integer i;

// datamemory connections

always @(posedge clk)
//write data to memory
if (memwrite)
begin 
//sum stores address,datab stores the value to be written
datmem[sum[4:0]+3]=out12[7:0];
datmem[sum[4:0]+2]=out12[15:8];
datmem[sum[4:0]+1]=out12[23:16];
datmem[sum[4:0]]=out12[31:24];
end

//instruction memory
//4-byte instruction
 assign instruc={mem[pc[4:0]],mem[pc[4:0]+1],mem[pc[4:0]+2],mem[pc[4:0]+3]};
 assign inst31_26=instruc[31:26];
 assign inst25_21=instruc[25:21];
 assign inst25_0=instruc[25:0];
 assign inst20_16=instruc[20:16];
 assign inst15_11=instruc[15:11];
 assign inst15_0=instruc[15:0];
 assign sham=instruc[10:6];
 assign pc4=adder1out[31:28];
 assign regnumber=31;
// registers

assign dataa=registerfile[inst25_21];//Read register 1
assign datab=registerfile[inst20_16];//Read register 2
assign reg31=registerfile[5'b11111];//Read register 31
always @(posedge clk)
 registerfile[out8]= regwrite ? out3:registerfile[out8];//Write data to register

//read data from memory, sum stores address
assign dpack={datmem[sum[5:0]],datmem[sum[5:0]+1],datmem[sum[5:0]+2],datmem[sum[5:0]+3]};

//multiplexers
//mux with RegDst control
mult2_to_1_5  mult1(out1, instruc[20:16],instruc[15:11],regdest);

//mux with ALUSrc control
mult2_to_1_32 mult2(out2, datab,out5,alusrc);

//mux with MemToReg control
mult2_to_1_32 mult3(out3, out9,dpack,memtoreg);

//mux with (Branch&ALUZero) control
mult2_to_1_32 mult4(out4, adder1out,out6,pcsrc);

//mux with sign ext& zero ext control
mult2_to_1_32 mult5(out5, extad,extzero,ext);

//mux with register &offset address control
mult2_to_1_32 mult6(out6,adder2out,dataa,nout);

//mux with jump & branch control
mult2_to_1_32 mult7(out7,out4,out10,jump);

//mux with out1 & Reg[31] control
mult2_to_1_32 mult8(out8,registerfile[out1],reg31,jump);

//mux with ALU result & PC+4 control
mult2_to_1_32 mult9(out9,sum,adder1out,jump);

//mux with ALU jump32 & PC+4 control
mult2_to_1_32 mult10(out10,adder1out,out11,zout);

//mux with ALU M[Reg[29]] &  control
mult2_to_1_32 mult11(out11,jump32,dpack,jspa);

//mux with ALU jump32 & PC+4 control
mult2_to_1_32 mult12(out12,datab,adder1out,jspa);

// load pc
always @(negedge clk)
pc=out7;


//combine bits to make 32 bit jump address
bitext bitcombine(pc4,jaddr,jump32);

// alu, adder and control logic connections

//ALU unit
alu32 alu1(sum,dataa,out2,sham,zout,nout,gout);

//adder which adds PC and 4
adder add1(pc,32'h4,adder1out);

//adder which adds PC+4 and 2 shifted sign-extend result
adder add2(adder1out,sextad,adder2out);

//Control unit
control cont(instruc[31:26],regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,
ext,jump,jspa,aluop1,aluop0);

//Sign extend unit
signext sext(instruc[15:0],extad);

//Sign extend unit
zeroext zext(instruc[15:0],extzero);

//ALU control unit
alucont acont(aluop1,aluop0,instruc[3],instruc[2], instruc[1], instruc[0] ,gout);

//Shift-left 2 unit
shift shift2(sextad,extad);

//Shift-left 2 unit
shiftl shift1(jaddr,inst25_0);

//AND gate
assign pcsrc=branch && zout; 

//initialize datamemory,instruction memory and registers
//read initial data from files given in hex
initial
begin
$readmemh("C:\\Users\\Hale\\Desktop\\singlecycleMIPS-lite-commented\\initDM.dat",datmem); //read Data Memory
$readmemh("C:\\Users\\Hale\\Desktop\\singlecycleMIPS-lite-commented\\initIM.dat",mem);//read Instruction Memory
$readmemh("C:\\Users\\Hale\\Desktop\\singlecycleMIPS-lite-commented\\initReg.dat",registerfile);//read Register File

	for(i=0; i<31; i=i+1)
	$display("Instruction Memory[%0d]= %h  ",i,mem[i],"Data Memory[%0d]= %h   ",i,datmem[i],
	"Register[%0d]= %h",i,registerfile[i]);
end

initial
begin
pc=0;
#400 $finish;

end
initial
begin
clk=0;
//40 time unit for each cycle
forever #20  clk=~clk;
end
initial 
begin
  $monitor($time,"PC %h",pc,"  SUM %h",sum,"   INST %h",instruc[31:0],
"   REGISTER %h %h %h %h ",registerfile[4],registerfile[5], registerfile[6],registerfile[1] );
end
endmodule

