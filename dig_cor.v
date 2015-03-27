module dig_cor(clk, rst_n, Xmeas, accel_vld, cfg_data, frm_rdy, clr_rdy,
               eep_rd_data, eep_cs_n, eep_r_w_n, eep_addr, chrg_pmp_en, dst,
               wrt_duty, snd_rsp);
	/*AUTOWIRE*/
	// Beginning of automatic wires (for undeclared instantiated-module outputs)
	wire		Duty_en;		// From DUT0 of mathSM.v
	wire		mans_en;			// From DUT0 of mathSM.v
	wire		Err_en;			// From DUT0 of mathSM.v
//	wire		PWM_rst;		// From DUT0 of mathSM.v
	wire		PreErr_en;		// From DUT0 of mathSM.v
	wire		PreErr_rst;		// From DUT0 of mathSM.v
        wire		XsetEEPrd;
	wire		SumErr_en;		// From DUT0 of mathSM.v
	wire		SumErr_rst;		// From DUT0 of mathSM.v
	wire		Xset_en;		// From DUT0 of mathSM.v
	output		chrg_pmp_en;		// From DUT0 of mathSM.v
	output		clr_rdy;		// From DUT0 of mathSM.v
        output		wrt_duty;
	wire		cmplmnt;		// From DUT0 of mathSM.v
	wire		counter_rst;		// From DUT0 of mathSM.v
	output [13:0]	dst;			// From DUT1 of datapath.v
	output [1:0]	eep_addr;		// From DUT0 of mathSM.v
	output		eep_cs_n;		// From DUT0 of mathSM.v
	output		eep_r_w_n;		// From DUT0 of mathSM.v
	wire		finish;			// From DUT1 of datapath.v
	wire		init;			// From DUT0 of mathSM.v
	wire [1:0]	sel;			// From DUT1 of datapath.v
	output		snd_rsp;		// From DUT0 of mathSM.v
	wire [2:0]	src0_sel;		// From DUT0 of mathSM.v
	wire [2:0]	src1_sel;		// From DUT0 of mathSM.v
	// End of automatics
	/*AUTOREGINPUT*/
	// Beginning of automatic reg inputs (for undeclared instantiated-module inputs)
	input [13:0]	eep_rd_data;		// To DUT1 of datapath.v
	input	[13:0]	Xmeas;			// To DUT1 of datapath.v
	input		accel_vld;		// To DUT0 of mathSM.v
	input [23:0]	cfg_data;		// To DUT0 of mathSM.v, ...
	input		clk;			// To DUT0 of mathSM.v, ...
	input		frm_rdy;		// To DUT0 of mathSM.v
	input		rst_n;			// To DUT0 of mathSM.v, ...
	// End of automatics

	mathSM DUT0(/*AUTOINST*/
		    // Outputs
		    .Duty_en		(Duty_en),
		    .Err_en		(Err_en),
		    .PreErr_en		(PreErr_en),
		    .Xset_en		(Xset_en),
		    .SumErr_en		(SumErr_en),
		    .mans_en		(mans_en),
		    .counter_rst	(counter_rst),
		    .cmplmnt		(cmplmnt),
		    .init		(init),
		    .snd_rsp		(snd_rsp),
		    .clr_rdy		(clr_rdy),
	//	    .PWM_rst		(PWM_rst),
		    .src1_sel		(src1_sel[2:0]),
		    .src0_sel		(src0_sel[2:0]),
		    .eep_cs_n		(eep_cs_n),
		    .eep_r_w_n		(eep_r_w_n),
		    .XsetEEPrd		(XsetEEPrd),
		    .chrg_pmp_en	(chrg_pmp_en),
		    .eep_addr		(eep_addr[1:0]),
		    .wrt_duty		(wrt_duty),
		    .SumErr_rst		(SumErr_rst),
		    .PreErr_rst		(PreErr_rst),
		    // Inputs
		    .accel_vld		(accel_vld),
		    .clk		(clk),
		    .rst_n		(rst_n),
		    .finish		(finish),
		    .frm_rdy		(frm_rdy),
		    .sel		(sel[1:0]),
		    .cfg_data		(cfg_data[23:0]));
	datapath DUT1(/*AUTOINST*/
		      // Outputs
		      .finish		(finish),
		      .dst		(dst[13:0]),
		      .sel		(sel[1:0]),
		      // Inputs
		      .src0_sel		(src0_sel),
		      .cmplmnt		(cmplmnt),
		      .src1_sel		(src1_sel),
		      .counter_rst	(counter_rst),
		      .Duty_en		(Duty_en),
		      .Err_en		(Err_en),
		      .PreErr_en	(PreErr_en),
		      .Xset_en		(Xset_en),
		      .SumErr_en	(SumErr_en),
		      .mans_en		(mans_en),
		      .XsetEEPrd	(XsetEEPrd),
		      .SumErr_rst	(SumErr_rst),
		      .PreErr_rst	(PreErr_rst),
		      .Xmeas		(Xmeas),
		      .cfg_data		(cfg_data[13:0]),
		      .clk		(clk),
		      .rst_n		(rst_n),
		      .EEP_rd_data	(eep_rd_data[13:0]),
		      .init		(init));
endmodule
