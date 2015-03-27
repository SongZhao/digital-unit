module pwm(clk,rst_n,duty,wrt_duty,CH_A,CH_B);

//////////////////////////////////////////////////////////////
// This PWM module is used for DC motor control.  It will  //
// output two PWM signals with 13-bit resolution.  The    //
// duty cycle specified is 14-bits and a signed number.  //
// When it is positive then CH_B is always low and CH_A //
// pulse width assumes the magnitude specified.        //
// When duty is negative then CH_A is ground and CH_B //
// pulse width assumes the magnitude specified.      //
//////////////////////////////////////////////////////
input clk,rst_n;	// global clock and reset, reset is active low
input [13:0] duty;	// 14-bit duty cycle as signed number
input wrt_duty;		// write signal used to update duty

output reg CH_A, CH_B;	// output PWM signals

reg [12:0] magnitude,cntr;
reg sign;

wire [12:0] mag;	// used to form magnitude of duty as combinational logic
wire set_pwm,clr_pwm;

////////////////////////////////////////////////
// mag[12:0] gets the absolute value of duty //
//////////////////////////////////////////////
assign mag = (duty[13]) ? ((duty[12:0]^13'h1FFFF)+1) : duty[12:0];

/////////////////////////////////////
// Implement flops to hold sign & //
// magnitude of incoming duty.   //
//////////////////////////////////
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) 
      begin
        magnitude <= 13'h0000;
	sign <= 1'b0;
      end
    else if (wrt_duty)
      begin
        magnitude <= mag;
	sign <= duty[13];
      end

//////////////////////////////////////////
// PWM outputs done as set/reset flops //
////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      begin
        CH_A <= 1'b0;
	CH_B <= 1'b0;
      end
    else if (clr_pwm || wrt_duty)
      begin
        CH_A <= 1'b0;
	CH_B <= 1'b0;
      end
    else if (set_pwm)
      if (sign)
        begin
	  CH_B <= 1'b1;
	  CH_A <= 1'b0;
	end
      else
        begin
	  CH_A <= 1'b1;
	  CH_B <= 1'b0;
	end

//////////////////////////////////////////////
// Implement main counter used as timebase //
////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      cntr <= 13'h00000;
    else if (wrt_duty)
      cntr <= 13'h00000;
    else
      cntr <= cntr + 1;

assign clr_pwm = (magnitude==cntr) ? 1'b1 : 1'b0;
assign set_pwm = ((!(|cntr)) && (|magnitude)) ? 1'b1 : 1'b0;

endmodule
