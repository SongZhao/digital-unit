`timescale 1 ns / 100 ps;
module cbc_dig_tb();

////////////////////////////////////////////////
// Define any interconnects wider than 1-bit //
//////////////////////////////////////////////
wire [1:0] eep_addr;
wire [13:0] eep_rd_data;
wire [13:0] dst;
wire [15:0] rsp;
wire [13:0] duty;
wire        duty_valid;
reg signed [13:0]     err;
integer     file;
integer	    tstnum;
integer     i;

/////////////////////////////////////////////
// Define any registers used in testbench //
///////////////////////////////////////////
reg [23:0] cmd_data;		// used to provide commands/data to cfg_UART of DUT
reg [9:0] temp_cmd_data;
reg [13:0] rand_cmd_data;
reg initiate;			// kicks off command/data transmission to DUT 
reg clk,rst_n;
reg clk_ref, rst_n_ref;
reg [63:0] expected [0:255];     // Array of expected output
reg [13:0] multiplicant, multiplier, product;
reg start;


demo reff(.EEP_rd_data(multiplier), .preDst(multiplicant), .posDst(product), .clk(clk_ref), .rst_n(rst_n_ref), .start(start));

//////////////////////
// Instantiate DUT //
////////////////////
cbc_dig DUT(.clk(clk), .rst_n(rst_n), .RX_A(RX_A), .RX_C(RX_C), .TX_C(TX_C),
	.CH_A(CH_A), .CH_B(CH_B), .dst(dst), .eep_rd_data(eep_rd_data),
	.eep_addr(eep_addr), .eep_cs_n(eep_cs_n), .eep_r_w_n(eep_r_w_n),
	.chrg_pmp_en(chrg_pmp_en));
        
///////////////////////////////
// Instantiate EEPROM Model //
/////////////////////////////
eep iEEP(.clk(clk), .por_n(rst_n), .eep_addr(eep_addr), .wrt_data(dst),  .rd_data(eep_rd_data), .eep_cs_n(eep_cs_n),
         .eep_r_w_n(eep_r_w_n), .chrg_pmp_en(chrg_pmp_en));

////////////////////////////////
// Instantiate Config Master //
//////////////////////////////
cfg_mstr iCFG(.clk(clk), .rst_n(rst_n), .cmd_data(cmd_data), .snd_frm(initiate),
	      .RX_C(TX_C), .TX_C(RX_C), .resp(rsp), .rsp_rdy(rsp_rdy));

///////////////////////////////
// Instantiate Accel Master //
/////////////////////////////
accel_mstr iACCEL(.clk(clk), .rst_n(rst_n), .TX_A(RX_A));

//////////////////////////////
// Instantiate PWM monitor //
////////////////////////////
pwm_monitor iMON(.clk(clk), .rst_n(rst_n), .CH_A(CH_A), .CH_B(CH_B),
	.duty(duty), .duty_valid(duty_valid));


always
  ///////////////////
  // 500MHz clock // 
  /////////////////
  #1 clk = ~clk;

always
  #0.1 clk_ref = ~clk_ref;

/////////////////////////////////////////////////////////////////
// The following section actually implements the real testing //
///////////////////////////////////////////////////////////////
initial
  begin
    initialize();
    tstnum = 3; // Specify which test to run
    case (tstnum)
	0 : smp_5edge();
	1 : smp_newXset();
	2 : smp_cmdmode();
	3 : edge_PID();
    endcase

    // All tests should terminate within the task
    $display ("Error Finish");
    $finish;
  end
/*
initial begin
	repeat (2000000) @(posedge clk);
	$finish;
end
*/
`include "./tb_tasks.sv"

endmodule
