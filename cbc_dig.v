module cbc_dig(clk,rst_n,RX_A,RX_C,TX_C,CH_A,CH_B,dst,eep_rd_data,eep_addr,eep_cs_n,eep_r_w_n,chrg_pmp_en);

input clk,rst_n;		// clock is 800MHz, reset is active low
input RX_A;			// 921,600 baud, 2-byte packets of acceleration from accelerometer
input RX_C;			// 921,600 baud, 3-byte command data packets from controller
output TX_C;			// 921,600 baud, 2-byte response packets to controller
output CH_A;			// PWM output A to DC motor control H-bridge
output CH_B;			// PWM output B to DC motor control H-bridge

output [13:0] dst;		// main ALU result bus ==> forms EEPROM write data
input [13:0] eep_rd_data;	// EEPROM read data
output [1:0] eep_addr;
output eep_cs_n;		// active low chip select used for all EEP operationS
output eep_r_w_n;		// read/write_n control to EEPROM
output chrg_pmp_en;		// enable charge pump for programming, hold for 3ms

//////////////////////////////////////////
// Internal net needed for connections //
////////////////////////////////////////
wire [23:0] cfg_data;
wire [13:0] Xmeas;
wire [13:0] dst;
wire accel_vld;
wire frm_rdy,clr_rdy;

///////////////////////////////
// Instantiate digital core //
/////////////////////////////
dig_cor iDIG(.clk(clk), .rst_n(rst_n), .Xmeas(Xmeas), .accel_vld(accel_vld),
	.cfg_data(cfg_data), .frm_rdy(frm_rdy), .clr_rdy(clr_rdy),
	.eep_rd_data(eep_rd_data), .eep_cs_n(eep_cs_n), .eep_r_w_n(eep_r_w_n),
	.eep_addr(eep_addr), .chrg_pmp_en(chrg_pmp_en), .dst(dst),
	.wrt_duty(wrt_duty), .snd_rsp(snd_rsp));

///////////////////////////
// Instantiate cfg_UART //
/////////////////////////
cfg_UART iCFG(.clk(clk), .rst_n(rst_n), .RX_C(RX_C), .TX_C(TX_C),
	.frm_rdy(frm_rdy), .clr_frm_rdy(clr_rdy), .cfg_data(cfg_data),
	.rsp_data({2'b00,dst}), .snd_rsp(snd_rsp));

/////////////////////////////
// Instantiate accel_UART //
///////////////////////////
accel_UART iACCEL(.clk(clk), .rst_n(rst_n), .RX_A(RX_A), .Xmeas(Xmeas),
	          .accel_vld(accel_vld));

//////////////////////////
// Instatiate PWM Unit //
////////////////////////
pwm iPWM(.clk(clk), .rst_n(rst_n), .duty(dst), .wrt_duty(wrt_duty), .CH_A(CH_A),
	.CH_B(CH_B));

endmodule
