module datapath(EEP_rd_data, dst, clk, rst_n, Xmeas, cfg_data, src0_sel, src1_sel, cmplmnt, counter_rst, finish, Duty_en, Err_en, PreErr_en, Xset_en, SumErr_en, mans_en, sel, init, SumErr_rst, PreErr_rst, XsetEEPrd);
input [2:0] src0_sel;
input cmplmnt; 
input XsetEEPrd;
input [2:0] src1_sel;
input counter_rst;
input Duty_en, Err_en, PreErr_en, Xset_en, SumErr_en, mans_en;
input SumErr_rst, PreErr_rst;
output finish;
input [13:0] Xmeas, cfg_data;
input clk, rst_n;
output reg [13:0] dst;
input [13:0] EEP_rd_data; // Xset P I D
reg [28:0] Preg;
input init; // sm output to choose init mux
reg [3:0] counter;
reg [13:0] Duty, Err, PreErr, Xset, SumErr, mans;
wire [28:0] preShift;
reg [13:0] src1, presrc0;
wire [13:0] src0, preSat; // preSat is the value before satuation
output [1:0] sel;

always@(posedge clk, negedge rst_n) // Duty Reg with enable and asyn reset
  if(!rst_n)
      Duty <= 0;
  else
      if(Duty_en) 
          Duty <= dst;
      else
          Duty <= Duty;

always@(posedge clk, negedge rst_n) // Err Reg with enable and asyn reset
  if(!rst_n)
      Err <= 0;
  else
      if(Err_en) 
          Err <= dst;
      else
          Err <= Err;

always@(posedge clk, negedge rst_n) // PreErr Reg with enable and asyn reset and syn reset
  if(!rst_n)
      PreErr <= 0;
  else if(PreErr_rst)
      PreErr <= 0;
  else
      if(PreErr_en) 
          PreErr <= dst;
      else
          PreErr <= PreErr;

always@(posedge clk, negedge rst_n) // Xset Reg with enable and asyn reset
  if(!rst_n)
      Xset <= 0;
  else
      if (XsetEEPrd)
	 Xset <= EEP_rd_data;
      else if (Xset_en) 
         Xset <= dst;
      else
         Xset <= Xset;

always@(posedge clk, negedge rst_n) // SumErr Reg with enable and asyn reset and syn reset
  if(!rst_n)
      SumErr <= 0;
  else if(SumErr_rst)
      SumErr <= 0;
  else 
      if(SumErr_en)
         SumErr <= dst;
      else
         SumErr <= SumErr;

//always@(posedge clk, negedge rst_n) // EEP Reg (PID) with enable and asyn reset
 // if(!rst_n)
   //   EEP_Reg <= 0;
 // else
   //   if(EEP_en) 
     //    EEP_Reg <= EEP_rd_data;
     // else
       //  EEP_Reg <= EEP_Reg;

always@(posedge clk, negedge rst_n) // store multiple answer
  if(!rst_n)
      mans <= 0;
  else
      if(mans_en) 
         mans <= dst;
      else
         mans <= mans;



always@(posedge clk, negedge rst_n) // Preg
  if(!rst_n)
      Preg <= 0;
  else 
  begin
      if(init == 1)
         Preg <={14'h000, dst, 1'b0}; // initial value
      else 
         Preg <= {preShift[28], preShift[28:1]};// shift right one list
  end

always@(*) // 2 big muxes
begin
  case(src1_sel) // left mux
    3'b000: src1 = cfg_data[13:0]; // for Xset reg  
    3'b001: src1 = Xmeas; // for Xmeas - Xset
    3'b010: src1 = Preg[28:15]; // for booth
    3'b011: src1 = Preg[25:12]; // for /0x800
    3'b100: src1 = Duty; 
    3'b101: src1 = Err;
    3'b110: src1 = 14'h0;
    default: src1 = 14'bx;
  endcase
 
  case(src0_sel) // right mux
    3'b000: presrc0 = PreErr;
    3'b001: presrc0 = Xset;
    3'b010: presrc0 = SumErr;
  //  3'b011: presrc0 = EEP_Reg; // for PID and Xset
    3'b011: presrc0 = EEP_rd_data; // for PID and Xset
    3'b100: presrc0 = 14'hA5A; // command signal
    3'b101: presrc0 = 14'h0;
    3'b110: presrc0 = Duty; // Duty should be in both sides
    3'b111: presrc0 = mans;
  endcase
end

assign sel[1:0] = Preg[1:0]; // output sel for statemachine(last 2 bits)
assign src0 = (cmplmnt)? ~presrc0 : presrc0; //if cmplmnt is on, not presrc0
assign preShift = {dst, Preg[14:0]}; // for mux(init) choose
assign{co ,preSat} = src1+src0 +cmplmnt; //co is carrry out (Adder)
assign sat_pos = (src1_sel == 3'b011)?((Preg[28]==0 && Preg[27:25]!= 3'b000)? 1:0):
				((!src1[13] && !src0[13] && preSat[13])? 1:0); //saturation positive
assign sat_neg = (src1_sel == 3'b011)?((Preg[28]==1 && Preg[27:25]!= 3'b111)? 1:0):
				((src1[13] && src0[13] && !preSat[13])? 1:0);  //saturation negative
/*
assign sat_pos = (src1_sel == 3'b011)? 
				((src0_sel == 3'b110)? 
				((Preg[28]==0 && Preg[27:25]!= 3'b000)||(!src1[13] && !src0[13] && preSat[13]))? 1:0) :
				(Preg[28]==0 && Preg[27:25]!= 3'b000)? 1:0 )):
				((!src1[13] && !src0[13] && preSat[13])? 1:0);

assign sat_neg = (src1_sel == 3'b011)? 
				((src0_sel == 3'b110)? 
				((Preg[28]==0 && Preg[27:25]!= 3'b111)||(src1[13] && src0[13] && !preSat[13]))? 1:0) :
				(Preg[28]==0 && Preg[27:25]!= 3'b111)? 1:0 )):
				((src1[13] && src0[13] && !preSat[13])? 1:0);*/

assign finish = (counter == 14)? 1 : 0; // output signal for statemachine (finish 14 cycles to mul)

always @(*) // saturation logic
 case({sat_pos, sat_neg})      
   2'b00: dst = preSat;
   2'b10: dst = 14'h1FFF;
   2'b01: dst = 14'h2000;
   default : dst = 14'hx;
 endcase

// counter is for MULT state 
always@(posedge clk, negedge rst_n) //detect the negedge of init to start increment
  if(!rst_n)
      counter <= 0;
  else if(counter_rst) // controled by statemachine
      counter <= 0;
  else
      counter <= counter + 1; // counter increases

endmodule
