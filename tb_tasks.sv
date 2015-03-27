// 5 calculation test
task smp_5edge;
	begin
	integer expd;
	i = 0;
	file = $fopen("smp_5edge.log", "w");
	expd_calc(expd);
	repeat (20) @(posedge DUT.wrt_duty)
		begin
		@(negedge clk);
		writePWM(expd);
		i = i + 1;
		expd_calc(expd);
	end
	$finish;
	$fclose(file);
	end
endtask

// Set a new Xset value test
task smp_newXset;
	begin
	integer expd;
	i = 0;
	file = $fopen("smp_newXset.log", "w");
	expd_calc(expd);
	// First repeat some duty calculation with initial Xset val
	repeat (3) @(posedge DUT.wrt_duty)
		begin
		@(negedge clk);
		writePWM(expd);
		i = i + 1;
		expd_calc(expd);
	end
	// Send a command
	initiate = 1'b1;
	// A new set point command
	temp_cmd_data = 10'b0000_11_00_00;
	// Generate 14 bit random Xset value
	// rand_cmd_data = $random % 16384;
	rand_cmd_data = 14'h3aab;
	cmd_data = {temp_cmd_data[9:0], rand_cmd_data[13:0]};
	repeat (100) @(posedge clk);
	initiate = 1'b0;
	$display ("New Xset value entered: %h", rand_cmd_data);
	$fdisplay (file, "New Xset value entered: %h", rand_cmd_data);
	@(posedge DUT.wrt_duty);
	$display ("New write duty signal detected");
	expd_calc(expd);
	// Repeat another 3 calculation of PWM value 
	repeat (10) @(posedge DUT.wrt_duty) begin
		@(negedge clk);
		writePWM(expd);
		expd_calc(expd);
	end
	$finish;
	$fclose(file);
	end
endtask

// Set new PID values/read eeprom
// and start command mode
task smp_cmdmode;
	begin
	integer expd;
	expd = 0;
	i = 0;
	file = $fopen("smp_cmdmode.log", "w");
	expd_calc(expd);
	// First repeat some duty calculation with initial Xset val
	repeat (3) @(posedge DUT.wrt_duty)
		begin
		@(negedge clk);
		writePWM(expd);
		i = i + 1;
		if ( i > 2)
			i = i;
		else
			expd_calc(expd);
	end
	// Send a command
	initiate = 1'b1;
	// //////////////////
	// START COMMAND MODE
	// //////////////////
	temp_cmd_data = 10'b0000_00_11_00;
	rand_cmd_data = 14'hxxxx;
	cmd_data = {temp_cmd_data[9:0], rand_cmd_data[13:0]};
	repeat (100) @(posedge clk);
	$display ("Command mode initiated");
	$fdisplay (file, "Command mode initiated");
	initiate = 1'b0;
	
	@(posedge rsp_rdy);
	if (rsp == 16'h0a5a)begin
	  
		// ////////////////////////////
		// Choose which operation to do
		// or both
		// ////////////////////////////
		writeeeprom();
		readeeprom();
		
		
	end
	else begin
		$display ("Err: Did not receive positive acknowledge signal");
		$fdisplay (file, "Err: Did not receive positive acknowledge signal");
		$finish;
	end
	$finish;
	$fclose(file);

end
endtask

task readeeprom();
	begin
	reg [13:0] eep_data [3:0];
	i = 0;
	eep_data[0] = 14'h2aaa;
	eep_data[1] = 14'h0cbc;
	eep_data[2] = 14'h0123;
	eep_data[3] = 14'h0321;
	repeat (100)@(posedge clk);
	while(i < 4) begin
		initiate = 1'b1;
		// A read eeprom command
		// 0000_01_>>address bit<<_00;
		if (i == 0)
			temp_cmd_data = 10'b0000_01_00_00;
		else if (i == 1)
			temp_cmd_data = 10'b0000_01_01_00;
		else if (i == 2)
			temp_cmd_data = 10'b0000_01_10_00;
		else if (i == 3)
			temp_cmd_data = 10'b0000_01_11_00;
		// Data don't care
		rand_cmd_data = 14'hxxxx;
		cmd_data = {temp_cmd_data[9:0], rand_cmd_data[13:0]};
		repeat (100) @(posedge clk);
		initiate = 1'b0;
		$display ("Read command initiated");
		$fdisplay (file, "Read command initiated");
		// Repeat another 3 calculation of PWM value 
		@(posedge rsp_rdy) begin
			$display ("Read data at addr %h is %h, expected: %h", i, rsp, eep_data[i]);
			$fdisplay (file, "Read data at addr %h is %h, expected: %h", i, rsp, eep_data[i]);

		end
		i = i + 1;
	end
end
endtask

task writeeeprom();
	begin
	
	// Speicifies each cycle's command data
	reg [13:0] cmd_data_array [3:0];
	i = 0;
/*
	cmd_data_array[0] = $random % 16384;
	cmd_data_array[1] = $random % 16384;
	cmd_data_array[2] = $random % 16384;
	cmd_data_array[3] = $random % 16384;
*/
	cmd_data_array[0] = 14'h2aaa;
	cmd_data_array[1] = 14'h0cbc;
	cmd_data_array[2] = 14'h0123;
	cmd_data_array[3] = 14'h0321;

	repeat (100)@(posedge clk);
	while(i < 4) begin
		initiate = 1'b1;
		// A write eeprom command
		// 0000_10_>>address bit<<_00;
		if (i == 0)
			temp_cmd_data = 10'b0000100000;
		else if (i == 1)
			temp_cmd_data = 10'b0000100100;
		else if (i == 2)
			temp_cmd_data = 10'b0000101000;
		else if (i == 3)
			temp_cmd_data = 10'b0000101100;
		// Generate 14 bit random Write value
		// Or manually Specify
		// rand_cmd_data = 14'h3abc;
		cmd_data = {temp_cmd_data[9:0], cmd_data_array[i]};
		repeat (100) @(posedge clk);
		initiate = 1'b0;
		$display ("Time: %t, Write command initiated", $time);
		$fdisplay (file, "TIme: %t, Write command initiated", $time);
		// Repeat another 3 calculation of PWM value 
		@(posedge rsp_rdy) begin
			if (rsp == 16'h0A5A) begin
				$display ("Write command positive acknowledge signal received");
				$fdisplay (file, "Write command positive acknowledge signal received");
			end
			else begin
				$display ("Positive acknowledge did not received. Error");
				$fdisplay (file, "Positive acknowledge did not received. Error");
			end
		end
		i = i + 1;
	end
end
endtask

// Edge test for PID values
task edge_PID;
	begin
	integer expd;
	expd = 0;
	i = 0;
	file = $fopen("edge_PID.log", "w");
	// Send a command
	initiate = 1'b1;
	// //////////////////
	// Send a command but not entering command mode
	// //////////////////
	temp_cmd_data = 10'b0000_10_11_00;
	rand_cmd_data = 14'hxxxx;
	cmd_data = {temp_cmd_data[9:0], rand_cmd_data[13:0]};
	repeat (100) @(posedge clk);
	$display ("Invalid command initiated");
	$fdisplay (file, "Invalid command initiated");
	initiate = 1'b0;
	@(posedge rsp_rdy) begin
		if (rsp == 16'h35A6) begin
			$display ("Invalid command negative acknowledge signal received");
			$fdisplay (file, "Invalid command negative acknowledge signal received");
		end
	end
	// //////////////
	// Start a valid command (enter command mode)
	// //////////////
	initiate = 1'b1;
	// //////////////////
	// START COMMAND MODE
	// //////////////////
	temp_cmd_data = 10'b0000_00_11_00;
	rand_cmd_data = 14'hxxxx;
	cmd_data = {temp_cmd_data[9:0], rand_cmd_data[13:0]};
	repeat (100) @(posedge clk);
	$display ("Command mode initiated");
	$fdisplay (file, "Command mode initiated");
	initiate = 1'b0;
	@(posedge rsp_rdy);
	if (rsp == 16'h0a5a)begin
		// ////////////////////////////
		// Choose which operation to do
		// or both
		// ////////////////////////////
		writePID();
		readeeprom();
	end
	else begin
		$display ("Err: Did not receive positive acknowledge signal");
		$fdisplay (file, "Err: Did not receive positive acknowledge signal");
		$finish;
	end
	repeat (1000) @(negedge clk);
	// ///////////////////////
	// Reset the digitial core
	// to initiate calculations using new PID values
	// //////////////////////
	rst_n = 1'b0;
	repeat (10) @(negedge clk);
	rst_n = 1'b1;
	expd_calc(expd);
	repeat (5) @(posedge DUT.wrt_duty)
		begin
		@(negedge clk);
		writePWM(expd);
		i = i + 1;
		expd_calc(expd);
	end
	$finish;
	$fclose(file);
end
endtask

task writePID();
	begin
	// Speicifies each cycle's command data
	reg [13:0] cmd_data_array [3:0];
	i = 0;
/*
	cmd_data_array[0] = $random % 16384;
	cmd_data_array[1] = $random % 16384;
	cmd_data_array[2] = $random % 16384;
	cmd_data_array[3] = $random % 16384;
*/
	cmd_data_array[0] = 14'h1000;
	cmd_data_array[1] = 14'h1cbc;
	cmd_data_array[2] = 14'h1123;

	repeat (100)@(posedge clk);
	while(i < 3) begin
		initiate = 1'b1;
		// A write eeprom command
		// 0000_10_>>address bit<<_00;
		if (i == 0)
			temp_cmd_data = 10'b0000100100;
		else if (i == 1)
			temp_cmd_data = 10'b0000101000;
		else if (i == 2)
			temp_cmd_data = 10'b0000101100;
		// Generate 14 bit random Write value
		// Or manually Specify
		// rand_cmd_data = 14'h3abc;
		cmd_data = {temp_cmd_data[9:0], cmd_data_array[i]};
		repeat (100) @(posedge clk);
		initiate = 1'b0;
		$display ("Time: %t, Write command initiated", $time);
		$fdisplay (file, "TIme: %t, Write command initiated", $time);
		// Repeat another 3 calculation of PWM value 
		@(posedge rsp_rdy) begin
			if (rsp == 16'h0A5A) begin
				$display ("Write command positive acknowledge signal received");
				$fdisplay (file, "Write command positive acknowledge signal received");
			end
			else begin
				$display ("Positive acknowledge did not received. Error");
				$fdisplay (file, "Positive acknowledge did not received. Error");
			end
		end
		i = i + 1;
	end
end
endtask


// Helper functions
task writePWM (input integer exp);
	begin
	$display ("PWM: %h, expected: %h", DUT.iDIG.dst, exp);
	$fdisplay (file, "PWM: %h, expected: %h", DUT.dst, exp);
	end
endtask

task initialize;
	begin
	initiate = 1'b0;
	cmd_data = 24'b0;
	clk = 1'b0;
	clk_ref = 1'b0;
	rst_n = 1'b0;
	rst_n_ref = 1'b0;
	#5.5
	rst_n = 1'b1;
	rst_n_ref = 1'b1;
	end
endtask


task expd_calc(output [13:0] myOutput);
	begin
	reg signed [13:0]  Xmeas, Xset, Err, Duty, Derr;
	reg signed [13:0]  satVal, tempVal;
	reg signed [13:0] SumErr, prevErr;
	reg signed [13:0] P, I, D;
	integer garb;
	$display ("---------------------------------");
	$display ("Enters expected value calculation");
	Xset = DUT.iDIG.DUT1.Xset;
	@(posedge DUT.accel_vld);// begin
		Xset = DUT.iDIG.DUT1.Xset;
		SumErr = DUT.iDIG.DUT1.SumErr;
		prevErr = DUT.iDIG.DUT1.PreErr;
		P = iEEP.eep_mem[1];
		I = iEEP.eep_mem[2];
		D = iEEP.eep_mem[3];
		Xmeas = DUT.Xmeas;
		$display ("All values accepted are:");
		$display ("Xset: %h, P: %h, I: %h, D: %h, Xmeas: %h\nSumErr: %h, prevErr: %h", Xset, P, I, D, Xmeas, SumErr, prevErr);
		garb = Xmeas - Xset;
		saturate(garb, Err);
		demo_tb(Err, P, Duty);
		$display ("Result of Duty = (P * Err)/0x800 is %h", Duty);
		garb = SumErr + Err;
		saturate(garb, SumErr);
		$display ("Result of 3 is: %h", SumErr);
		demo_tb(SumErr, I, tempVal);
		$display ("Result of (I * SumErr)/0x800 is %h", tempVal);
		garb = Duty + tempVal;
		$display ("Result of 4 is: %h", garb);
		saturate(garb, Duty);
		garb = Err - prevErr;
		saturate(garb, Derr);
		$display ("Result of 5 is: %h", Derr);
		demo_tb(Derr, D, tempVal);
		garb = Duty + tempVal;
		saturate (garb, Duty);
		$display ("Result Duty written to PWM is %h", Duty);
		prevErr = Err;
		$display ("PrevErr = %h", prevErr);
	//end
	myOutput = Duty;
	$display ("Calculation Finished");
	$display ("-----------------------------------");
end
endtask

task saturate (input integer myVal, output signed [13:0] myValSat);
	begin
	if (myVal > 8191) begin
		$display ("Positive Saturation");
		myValSat = 14'h1fff;
	end
	else if (myVal < -8192) begin
		$display ("Negative Saturation");
		myValSat = 14'h2000;
	end
	else
		myValSat = myVal;
end
endtask

task demo_tb(input signed [13:0] preDst, input signed [13:0] EEP_rd_data, output signed [13:0] posDst);
	begin
	rst_n_ref = 1'b0;
	#0.2
	rst_n_ref = 1'b1;

	start = 1;
	multiplicant = preDst;
	multiplier = EEP_rd_data;
	@(posedge reff.finish);
	@(posedge clk_ref);
	@(negedge clk_ref);
	posDst = product;
	start = 0;

end
endtask
