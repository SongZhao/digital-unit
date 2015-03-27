module demo(EEP_rd_data, posDst, preDst, start, clk, rst_n);
wire src0_sel, cmplmnt;
reg src1_sel;
input clk, rst_n;
output [13:0] posDst;
reg [13:0] dst;
input [13:0] EEP_rd_data; // Eset P I D
reg [28:0] Preg;
reg [1:0] state, nxt_state;
wire finish;//if finish is asserted means 14 shifts have made.
reg init;
reg [3:0] counter;
reg Zero; // if Zero is high, src0 is always 0
input start; // if start is asserted, booth start
input [13:0] preDst;
reg counter_rst;

wire [28:0] preShift;
wire [13:0] src1, src0, presrc0, preSat; // preSat is the value before satuation
localparam IDLE = 2'b00;
localparam Mult = 2'b01;
localparam Done = 2'b10;


assign preShift = {dst, Preg[14:0]};
always@(posedge clk, negedge rst_n)
 if(!rst_n)
 Preg <= 0;
 else 
 begin
 if(init == 1)
 Preg <={14'h000, preDst, 1'b0}; // initial value
 else 
 Preg <= {preShift[28], preShift[28:1]};// shift right one list
 end

assign src1 = (src1_sel)? Preg[28:15] :Preg[25:12];

assign presrc0 = (src0_sel)? EEP_rd_data : 14'h0;
assign src0 = (cmplmnt)? ~presrc0 : presrc0; //if cmplmnt is on, not presrc0
assign{co ,preSat} = src1+src0 +cmplmnt; //co is carrry out


assign sat_pos = (src1_sel == 1'b0)?((Preg[28]==0 && Preg[27:25]!= 3'b000)? 1:0):
				((!src1[13] && !src0[13] && preSat[13])? 1:0); //saturation positive
assign sat_neg = (src1_sel == 1'b0)?((Preg[28]==1 && Preg[27:25]!= 3'b111)? 1:0):
				((src1[13] && src0[13] && !preSat[13])? 1:0);  //saturation negative



//assign sat_pos = ((Preg[28]==0 && Preg[27:25]!= 3'b000)? 1:0)|((!src1[13] && !src0[13] && preSat[13])? 1:0); //saturation positive
//assign sat_neg = ((Preg[28]==1 && Preg[27:25]!= 3'b111)? 1:0)|((src1[13] && src0[13] && !preSat[13])? 1:0);  //saturation negative

always @(*)
case({sat_pos, sat_neg})      
2'b00: dst = preSat;
2'b10: dst = 14'h1FFF;
2'b01: dst = 14'h2000;
default : dst = 14'hx;
endcase
assign cmplmnt = (Preg[1:0] == 2'b10)? 1:0;  
assign src0_sel = (Preg[1:0] == 2'b11 || Preg[1:0]== 2'b00 || Zero == 1)? 0:1;// zero is in case of not mutiplying.. 
//assign src0 = src0_sel? EEP_rd_data : 14'h0;

always@(posedge clk, negedge rst_n) //detect the negedge of init to start increment
 if(!rst_n)
 counter <= 0;
 else if(counter_rst)
 counter <= 0;
 else
 counter <= counter + 1; // counter increases
 

assign finish = (counter == 13)? 1 : 0;
assign posDst = dst;

always @(posedge clk, negedge rst_n)
 if(!rst_n)
 state <= IDLE;
 else 
 state <= nxt_state;

always@(*)
begin
src1_sel = 1;
init =1;
Zero = 1;
counter_rst = 1;
case(state)
 IDLE: begin
 if(start) begin
 nxt_state = Mult;
 Zero = 0; // the cmplmnt does not determined by the sel [1:0]
 end
 else 
 nxt_state = IDLE;
 end

 Mult:
 begin
 counter_rst = 0;
 init= 0;
 Zero = 0;
 if(finish)
 begin
 nxt_state = Done;
 end
 else
 begin
 Zero = 0;
 nxt_state = Mult;
 end
 end
 Done:
 begin
 init = 0;
 counter_rst = 1;
 src1_sel = 0;
 nxt_state = IDLE;
 end
 default: nxt_state = IDLE;
endcase
 end
endmodule
