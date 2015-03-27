module cfg_mstr(TX_C, resp, cmd_data, snd_frm, RX_C, clk, rst_n, rsp_rdy);
output  TX_C;
output [15:0] resp;
output rsp_rdy;
input [23:0] cmd_data;
input snd_frm, clk, rst_n, RX_C;
reg [7:0] tx_data;
wire [7:0] rx_data;
wire rdy, tx_done;
reg trmt, clr_rdy, rsp_rdy;
reg [2:0] state, nxt_state;
reg ENH, ENL, S, R;
reg [1:0] sel;


// define states
  localparam IDLE = 3'b000;
  localparam SENDH = 3'b001;
  localparam SENDM = 3'b010;
  localparam RSPH = 3'b011;
  localparam RSPL = 3'b100;
  localparam DONE = 3'b101;


UART URT(
         .clk(clk), 
         .rst_n(rst_n), 
         .trmt(trmt),
         .clr_rdy(clr_rdy),
         .tx_done(tx_done), 
         .rdy(rdy), 
         .tx_data(tx_data), 
         .rx_data(rx_data), 
         .TX_C(TX_C), 
         .RX_C(RX_C)
        ); // instantiate UART

always @(posedge clk or negedge rst_n)    // state machine
 if(!rst_n)
  state <= IDLE;
 else
  state <= nxt_state;

 always @(*)
     begin nxt_state = IDLE;
       ENH = 0;                                 //ENH is choose the high byte of resp
       ENL = 0;                                 //ENL is choose the low byte of resp
       sel = 2'b00;                                 //sel is the select of cmd_data
       trmt = 0;                                //trmt signal for UART.tx
       clr_rdy = 0;
       R =0;                                    //R is the reset signal for rsp_rdy
       S = 0;                                   //S is the set signal for rsp_rdy
       
       
       
   case(state)
    IDLE:begin                         
		if(snd_frm)
			begin    
			trmt = 1; // update 
      			sel = 2'b00; // select msb 8 bits of cmd_data
			end
		if(tx_done)
			begin
			sel = 2'b01; // select middle 8bit of cdmd_data
			trmt= 1; // update
			nxt_state = SENDH; 
			end
		else
			nxt_state = IDLE; 
      end  
    
    SENDH:begin 
      trmt =0;                                
      if(tx_done) // if tx_done
		begin
		sel= 2'b10; // select the lowest 8 bit data
		trmt = 1;
	       	nxt_state =SENDM; 
		end
     else begin
        nxt_state = SENDH;  
	sel = 2'b01;
     end
   end
      
     SENDM:begin
	trmt = 0;                                  
        if(tx_done) begin // if all cdm_data are sent
		nxt_state = RSPH; // go to response high
	end
    	else begin
        nxt_state = SENDM ;  
	sel = 2'b10;
	end
       
      end
      
      RSPH:begin
	R = 1;     // set R tgat rsp_rdy is not on                               
      if(rdy) begin        // if ready, first 8 bit is ready                     
        ENH = 1;  // set they are the high byte
        nxt_state = RSPL;
				end
      else
        nxt_state = RSPH;
      end
     RSPL:begin                                
      clr_rdy = 1;     // clear the ready first                      
      if(rdy) begin                             
        ENL = 1;
	S = 1;	// set S for rsp_ready
        nxt_state = DONE;
        end
      else
        nxt_state = RSPL;
     end

     default:
	begin 
	if (snd_frm) begin
        	nxt_state = IDLE;
		trmt = 1'b1;
		sel = 2'b00;
		R = 1;
	end
	else
		nxt_state = DONE;
		S = 1;
	end
        
      endcase
    end

reg [7:0] tx_high, tx_low; //tx_high is the high byte of resp, tx_low is low byte of resp
always @(posedge clk or negedge rst_n)   
 if(!rst_n)
   tx_high <= 8'b0;
 else
  if(ENH == 1) // enable
   tx_high <= rx_data[7:0];
  else //disable
   tx_high <= tx_high;

always @(posedge clk or negedge rst_n)    
 if(!rst_n)
 tx_low <= 8'b0;
 else
  if(ENL == 1) // enable
   tx_low <= rx_data[7:0];
  else // disable
   tx_low <= tx_low;
   

always @(posedge clk or negedge rst_n) //SR latch for resp_rdy, S has priority
 if(!rst_n) // reset frm_rdy
  rsp_rdy <= 0;
 else if(S) // set frm_rdy
  rsp_rdy <= 1;
 else if(R) // clear frm_rdy 
  rsp_rdy <= 0;

always @(*)
 begin
 if(sel == 00) // mux selects high byte of cmd_data
  tx_data = cmd_data[23:16];
 else if(sel == 01) 
  tx_data = cmd_data[15:8];
 else
  tx_data = cmd_data[7:0];
 end
  
  assign resp = {tx_high, tx_low}; // 
endmodule

