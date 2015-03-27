module mathSM(accel_vld, clk, rst_n, Duty_en, Err_en, frm_rdy, PreErr_en, Xset_en, SumErr_en, mans_en, counter_rst, sel, cmplmnt, src1_sel, src0_sel, finish, eep_addr, eep_cs_n, eep_r_w_n, init, SumErr_rst, PreErr_rst, chrg_pmp_en,cfg_data,snd_rsp,clr_rdy, wrt_duty, XsetEEPrd);
//finish is asserted when counter is 13
input accel_vld, clk, rst_n, finish, frm_rdy;
//least significant bits of Preg
input [1:0] sel;
//enables for registers, init is asserted choose dst value, else shift right
output reg Duty_en, Err_en, PreErr_en, Xset_en, SumErr_en, mans_en, counter_rst, cmplmnt, init,snd_rsp,clr_rdy;
//select signal for ALU's muxes
output reg [2:0] src1_sel, src0_sel;
reg check_accel;
//if accel_became_vld is one, accel_vld is rised
wire accel_became_vld;
reg [3:0] state, nxt_state;
//eeprom chip_select, eeprom read write enable
output reg eep_cs_n, eep_r_w_n,chrg_pmp_en; 
//eeprom address
output reg [1:0] eep_addr;
//SumErr and PreErr register rst
output reg SumErr_rst, PreErr_rst;
output reg wrt_duty;
output reg XsetEEPrd;
input [23:0] cfg_data;
reg [9:0] WRT_EEP = 6'b000010xx00;
reg [9:0] READ_EEP = 6'b000001xx00;
reg [9:0] START_CM = 6'b0000001100;
reg [9:0] NEW_XSET = 6'b0000110000;
wire counte3ms;
reg[20:0] cntr;
reg in_CM;
reg in_CMS;
reg toCount;
localparam LD_Xset = 4'b0000;
localparam Wait_accel_vld = 4'b0001;
localparam Calc_err = 4'b0010;
localparam Pmult = 4'b0011;
localparam SumErr = 4'b0100;
localparam Imult = 4'b0101;
localparam DmultPrep = 4'b0110;
localparam Dmult = 4'b0111;
localparam PrevErr = 4'b1000;
localparam XSET = 4'b1001;
localparam Clear_PWM = 4'b1010;
localparam CMDINTR = 4'b1011;
localparam Write_EEPROM = 4'b1100;
localparam CMDloop = 4'b1101;
localparam Iadd = 4'b1110;
localparam Dadd = 4'b1111;
//////////////////////////////////////
// check if the accel_valid rises////
/////////////////////////////////////
assign accel_became_vld = (~check_accel) & accel_vld;

always@(posedge clk, negedge rst_n)
	if(!rst_n)
		check_accel <= 0;
 	else 
  	check_accel <= accel_vld;

always@(posedge clk, negedge rst_n)
	if(!rst_n)
	 	state <= LD_Xset;
	else 
  	state <= nxt_state;

always@(*)
	begin
		//All the register are diabled as default
		Duty_en = 1'b0; 
		Err_en = 1'b0;
		PreErr_en = 1'b0;
		Xset_en = 1'b0;
		snd_rsp = 1'b0;
		src0_sel = 3'b101;
		src1_sel = 3'b110;
		SumErr_en = 1'b0;
	//	EEP_en = 1'b0;
		wrt_duty = 1'b0;
		//cmplmnt is 0 as default
		cmplmnt = 1'b0;
		clr_rdy = 1'b0;
		// Preg choose dst as default
		init = 1'b1;
		// counter_rst is one that counter is alway 0 as default
		counter_rst = 1'b1;
		//SumErr_rst and PreErr_rst are 0 that not reset
		SumErr_rst = 1'b0;
		XsetEEPrd = 1'b0; // If directly read from EEP to Xset
		PreErr_rst = 1'b0;
		eep_cs_n = 1'b1; // chip is disabled as default
		in_CM = 1'b0;
		eep_r_w_n = 1'b0; //chip is read as default
		eep_addr = 2'b00; // address is Xset as default
		nxt_state = LD_Xset;
		chrg_pmp_en = 1'b0;
		mans_en = 1'b0;
		toCount = 1'b0;

case(state)
	LD_Xset:
  		begin
		src1_sel = 3'b110; //choose 0x000
		SumErr_rst = 1'b1; //SumErr is 0
		PreErr_rst = 1'b1; //PreErr is 0-
//		EEP_en = 1'b1;
		src0_sel = 3'b011; // choose eeprom
		eep_cs_n = 1'b0;
        eep_r_w_n = 1'b1;
		cmplmnt = 0;    
		Xset_en = 1; //enable Xset register
		XsetEEPrd = 1'b1; // Read EEP rd data to Xset
		nxt_state = Wait_accel_vld; //jump to Wait state
  		end

	Wait_accel_vld:
		begin
		Xset_en = 0;//diable Xset
		if(accel_became_vld)
			//accel_became_vld is asserted, jump to Calc_err  
			nxt_state = Calc_err;
		else
			nxt_state = Wait_accel_vld;
 		 end
 
	Calc_err:
		begin
		nxt_state = Pmult; 
		src1_sel = 3'b001;// choose Xmeas
		src0_sel = 3'b001;// choose Xset
		cmplmnt = 1'b1; //Xmeas - Xset
	//	eep_cs_n = 0; //chip select is on
	//	eep_r_w_n = 1;  //read from EEprom
	//	eep_addr = 2'b01;// 01 is for P
		Err_en = 1'b1; //enable the Err register
		end
 
	Pmult:
	begin
		//Preg is dst value that is Err from last step
        eep_cs_n = 0; //chip select is on
		eep_r_w_n = 1;  //read from EEprom
		eep_addr = 2'b01;// 01 is for P

		init = 1'b0;// Preg is shifted value now
		counter_rst = 1'b0; //counter could increments now
		if(!finish) //counter != 13
		begin
			src1_sel = 3'b010;// choose Preg[28:15]
			if(sel == 2'b00 || sel == 2'b11) // if the last two bits of 
      		//Preg is 00 and 11, choose 0x000
				src0_sel = 3'b101;
				else if(sel == 2'b10) 
				begin
					cmplmnt = 1'b1; //minus 
					src0_sel = 3'b011; //choose P
				end
				else
					src0_sel = 3'b011; //choose P
					nxt_state = Pmult; // jump back to the state
		end
		else
   		begin
			src1_sel = 3'b011; //choose Preg[25;12]
			src0_sel = 3'b101; //choose 0x00
			nxt_state = SumErr; // jump to next state
			Duty_en = 1'b1; // enable Duty register
		end
	end
 
	SumErr:
	begin
		nxt_state = Imult; // jump to next state
		SumErr_en = 1'b1; // enable SumErr register
		src1_sel = 3'b101; // choose value in Reg Err
		src0_sel = 3'b010; // choose value in Reg SumErr
	//	eep_cs_n = 0;//chip select is on
	//	eep_r_w_n = 1; //read from EEprom
	//	eep_addr = 2'b10; // 10 is for I
	//	EEP_en = 1;
	end
 
	Imult:
	begin
		//Preg is dst value that is SumErr from last step
		eep_cs_n = 0;//chip select is on
		eep_r_w_n = 1; //read from EEprom
		eep_addr = 2'b10; // 10 is for I

		init = 1'b0;// Preg is shifted value now
		counter_rst = 1'b0;//counter could increments now
		if(!finish)
			begin
			src1_sel = 3'b010;// choose Preg[28:15]
			/*eep_cs_n = 0;//chip select is on
			eep_r_w_n = 1; //read from EEprom
			eep_addr = 2'b10; // 10 is for I */
			if(sel == 2'b00 || sel == 2'b11) // if the last two bits of 
				//Preg is 00 and 11, choose 0x000
				src0_sel = 3'b101;
			else if(sel == 2'b10)
				begin
				cmplmnt = 1'b1;//minus 
				src0_sel = 3'b011;//choose I
				end
			else
			src0_sel = 3'b011;//choose I
			nxt_state = Imult;// jump back to the state
			end
		else
			begin
			src1_sel = 3'b011;//choose Preg[25;12]
		//	src0_sel = 3'b110;//choose value in Reg Duty
			nxt_state = Iadd;// jump to next state
		//	Duty_en = 1'b1;// enable Duty register
            mans_en = 1'b1;
			end
	end

    Iadd: 

			begin
			src1_sel = 3'b100;//choose Preg[25;12]
			src0_sel = 3'b111;//choose value in Reg Duty
			nxt_state = DmultPrep;// jump to next state
			Duty_en = 1'b1;// enable Duty register
			end
 
	DmultPrep:
		begin
		nxt_state = Dmult; // jump to next state
		src1_sel = 3'b101; // choose value in Reg Err
		src0_sel = 3'b000;// choose value in Reg PrevErr
		cmplmnt = 1'b1; // minus
	//	eep_cs_n = 0;//chip select is on
	//	eep_r_w_n = 1;//read from EEprom
	//	eep_addr = 2'b11;// 11 is for D
	//	EEP_en = 1;
		end
 
	Dmult: 
		begin
		eep_cs_n = 0;//chip select is on
		eep_r_w_n = 1;//read from EEprom
		eep_addr = 2'b11;// 11 is for D

		//Preg is dst value that is Derr from last step
		init = 1'b0;// Preg is shifted value now
		counter_rst = 1'b0;//counter could increments now
		if(!finish)
			begin
			src1_sel = 3'b010;// choose Preg[28:15]
			if(sel == 2'b00 || sel == 2'b11)
 				src0_sel = 3'b101;
			else if(sel == 2'b10)// if the last two bits of 
			//Preg is 00 and 11, choose 0x000
				begin
				cmplmnt = 1'b1; //minus 
				src0_sel = 3'b011; // choose D
				end
			else
     			src0_sel = 3'b011; // choose D
			
			nxt_state = Dmult; // jump back to the state
			end
		else
			begin
			src1_sel = 3'b011; //choose Preg[25;12]
			//src0_sel = 3'b110; //choose value in Reg Duty
			nxt_state = Dadd; // jump to the next state
			//Duty_en = 1'b1; // enable Duty Reg
			mans_en = 1'b1;
              //          wrt_duty = 1'b1;
			end   
		end

    Dadd: 

			begin
			src1_sel = 3'b100;//choose Preg[25;12]
			src0_sel = 3'b111;//choose value in Reg Duty
			nxt_state = PrevErr;// jump to next state
			Duty_en = 1'b1;// enable Duty register
            wrt_duty = 1'b1;
			end


	PrevErr:
		begin
		src1_sel = 3'b101; // choose value in Reg Err
		src0_sel = 3'b101; // choose 0x000
		PreErr_en = 1'b1; // enable the PrevErr Reg
		//wrt_duty = 1'b1;
		if(frm_rdy)
			if(cfg_data[23:14] == NEW_XSET) 
				nxt_state = XSET;
			else 
				nxt_state = Clear_PWM;
		else
			nxt_state = Wait_accel_vld; // jump back to the state
		end 
  
	XSET:
		begin
		src1_sel = 3'b000;
		Xset_en = 1;
		snd_rsp = 1;	
		clr_rdy = 1;
		nxt_state = Wait_accel_vld;
  		end
  
 	Clear_PWM:
		begin
		src1_sel = 3'b110;
		src0_sel = 3'b101;
		wrt_duty = 1'b1;
		nxt_state = CMDINTR;
		end
    
	CMDINTR:
		begin 
		clr_rdy = 1;      //clear frm_rdy
		src1_sel = 3'b110;
		if (cfg_data[23:14] == START_CM) begin
					in_CM = 1;
					src1_sel = 3'b110;
					src0_sel = 3'b100;
					snd_rsp = 1;
					nxt_state = CMDloop;
		end

		else if (in_CMS)
			casex(cfg_data[23:14])
				WRT_EEP :
					begin
					eep_r_w_n = 0;
					eep_cs_n = 0;
					eep_addr = cfg_data[17:16];
				 	src1_sel = 3'b000;
					nxt_state = Write_EEPROM;
					end	
				READ_EEP :
					begin
					eep_addr = cfg_data[17:16];
					src1_sel = 3'b110;
					src0_sel = 3'b011;
					eep_r_w_n = 1;
					eep_cs_n = 0;
					chrg_pmp_en = 1;
					snd_rsp = 1;	
					nxt_state = CMDloop;
					end	
			default:
				begin
					src1_sel = 3'b110;
					src0_sel = 3'b100;
					snd_rsp = 1;
					cmplmnt = 1;
					nxt_state = CMDloop;
				end
  			endcase
		else // If not in command mode
			begin
			src1_sel = 3'b110;
			src0_sel = 3'b100;
			snd_rsp = 1;
			cmplmnt = 1;
			nxt_state = CMDloop;
		end
  	end // end state

	Write_EEPROM:
		begin
		chrg_pmp_en = 1;
		toCount = 1;
		if(counte3ms) 
			begin
			src1_sel = 3'b110;
			src0_sel = 3'b100;
			snd_rsp = 1;
			nxt_state = CMDloop;
			end
		else
			nxt_state = Write_EEPROM;
		end

	CMDloop:
		if(frm_rdy)
			nxt_state = CMDINTR;
		else
			nxt_state = CMDloop;


		//default: nxt_state = 4'bx; // default state
 
	endcase
	end

always@(posedge clk, negedge rst_n)
	if(!rst_n)
		cntr <= 0;
	else if(counte3ms)
		cntr <= 0;
	else if(toCount)
		cntr <= cntr + 1;
	

assign counte3ms = (cntr == 21'h155cc0)? 1:0;

always@(posedge clk, negedge rst_n)
	if(!rst_n)
		in_CMS <= 0;	
	else if(in_CM)
		in_CMS <= 1;
	else
		in_CMS <= in_CMS;
	

endmodule

