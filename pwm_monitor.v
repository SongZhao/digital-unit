module pwm_monitor(clk,rst_n,CH_A,CH_B,duty,duty_valid);

//////////////////////////////////////////////////////////////
// Monitors PWM channels A & B and determines their        //
// duty cycle.  The duty cycle is given on the output     //
// duty[13:0] and is valid upon assertion of duty_valid. //
// It is a good idea to check in your testbench using   //
// @(posedge duty_valid) if duty[13:0] equal expected. //
////////////////////////////////////////////////////////

input clk,rst_n;	// hook clock to same source as DUT gets
input CH_A, CH_B;	// PWM inputs this unit monitors

output [13:0] duty;	// resulting 14-bit signed value of PWM duty cycle
output reg duty_valid;	// indicates when duty cycle is valid

reg CH_A_ff, CH_B_ff;
reg sign,strobed;
reg [12:0] mag_cntr;
reg [12:0] mag_capture;
reg [13:0] duty,duty_prev;
reg [13:0] timer;

wire [13:0] duty_val;
wire [12:0] mag_2scomp;
wire timeout, CH_A_neg,CH_A_pos,CH_B_neg,CH_B_pos;

//////////////////////////////////////////////
// Flop CH_A & CH_B to make edge detectors //
////////////////////////////////////////////
always @(posedge clk, negedge rst_n)
    if (!rst_n) begin
      CH_A_ff <= 0;
      CH_B_ff <= 0;
    end
    else begin
      CH_A_ff <= CH_A;
      CH_B_ff <= CH_B;
    end

//////////////////////////////////////////////////////
// Implement pos/neg edge detectors on CH_A & CH_B //
////////////////////////////////////////////////////
assign CH_A_pos = CH_A & ~CH_A_ff;
assign CH_B_pos = CH_B & ~CH_B_ff;
assign CH_A_neg = ~CH_A && CH_A_ff;
assign CH_B_neg = ~CH_B && CH_B_ff;

//////////////////////////////////////////////////
// Need a timer to see if CH_A & CH_B are both //
// always zero.  This is the duty==0000 case. //
///////////////////////////////////////////////
always @(posedge clk, negedge rst_n)
    if (!rst_n)
      timer <= 14'h0000;
    else if (CH_A_neg | CH_B_neg | timeout)
      timer <= 14'h0000;
    else
      timer <= timer + 1;

assign timeout = (timer==14'h2001) ? 1'b1 : 1'b0;

///////////////////////////////////////////////////
// Implement a counter to count the time either //
// CH_A or CH_B is high.  This form magnitude  //
// of PWM duty.  Also need to determine sign. //
///////////////////////////////////////////////
always @(posedge clk, negedge rst_n)
    if (!rst_n) begin
      mag_cntr <= 13'b0000;
      sign <= 1'b0;
    end else if (CH_A_neg | CH_B_neg | timeout) begin
      mag_cntr <= 13'b0000;
      sign <= (timeout) ? 1'b0 : sign;
    end else if (CH_A | CH_B) begin
      mag_cntr = mag_cntr + 1;
      sign <= CH_B;
    end

////////////////////////////////////////////
// Capture magnitude when either CH_A or //
// CH_B fall, or when timeout.          //
/////////////////////////////////////////
always @(posedge clk, negedge rst_n)
    if (!rst_n) 
      mag_capture <= 13'h0000;
    else if (CH_A_neg | CH_B_neg | timeout)
      mag_capture <= mag_cntr;

//////////////////////////////////////////////
// Form a delayed version of when captured //
// called strobed.                        //
///////////////////////////////////////////
always @(posedge clk, negedge rst_n)
    if (!rst_n)
      strobed <= 1'b0;
    else 
      strobed <= (CH_A_neg | CH_B_neg | timeout);

///////////////////////////////////////////////
// Using sign & magnitude form a duty value //
/////////////////////////////////////////////
assign mag_2scomp = ~mag_capture + 1;
assign duty_val = (sign) ? {1'b1,mag_2scomp} : {1'b0,mag_capture};

/////////////////////////////////////////
// Capture duty value based on strobe //
///////////////////////////////////////
always @(posedge clk, negedge rst_n)
    if (!rst_n)
      duty <= 14'h0000;
    else if (strobed)
      duty <= duty_val;

////////////////////////////////////////////////
// duty_valid is only asserted if we have    //
// seen the same duty cycle for 2 cycles in //
// a row.  Need to capture the previous    //
// duty cycle to implement this.          //
///////////////////////////////////////////
always @(posedge clk, negedge rst_n)
    if (!rst_n) begin
      duty_prev <= 14'h0000;
      duty_valid <= 0;
    end else if (strobed) begin
      duty_prev <= duty; 
      duty_valid = (duty_val==duty_prev) ? 1'b1 : 1'b0; 
    end

endmodule




