module cfg_UART(clk, rst_n, RX_C, TX_C, clr_frm_rdy, snd_rsp, frm_rdy, cfg_data, rsp_data);

// define ports
input clk, rst_n, RX_C, clr_frm_rdy, snd_rsp;
output TX_C, frm_rdy;
output reg [23:0] cfg_data;
input [15:0] rsp_data;
reg [7:0] tx_data;
wire [7:0] rx_data;
wire rdy, tx_done;
reg trmt, clr_rdy, frm_rdy;
reg [2:0] state, nxt_state;
reg ENH, ENM, S, R, sel;
reg [7:0] rsp_data_low;

// define states
  localparam IDLE = 3'b000;
  localparam SENDH = 3'b001;
  localparam SENDM = 3'b010;
  localparam RSPH = 3'b011;
  localparam RSPL = 3'b100;
  localparam DONE = 3'b101;


UART UT(
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
        ); // call UART module

always @(posedge clk or negedge rst_n)    // state machine
 if(!rst_n)
  state <= IDLE;
 else
  state <= nxt_state;

 always @(*)
     begin nxt_state = IDLE;
       ENH = 0;                                 //ENH is the enable for the dff of clg_data[23:16]
       ENM = 0;                                 //ENM is the enable for the dff of clg_data[15:8]
       sel = 0;                                 //sel is the select signal for rsp_data
       trmt = 0;                                //trmt signal for UART.tx
       clr_rdy = 0;
       R =0;                                    //R is the reset signal for frm_rdy
       S = 0;                                   //S is the set signal for frm_rdy
       
       
       
   case(state)
    IDLE:begin                                  //state IDLE
      R = 1;                                    //reset frm_rdy
      if(rdy) begin                             //if a rdy signal be asserted from UART then ENH = 1. 
        ENH = 1;
        nxt_state = SENDH;end
      else
        nxt_state = IDLE;
      end  
    
    SENDH:begin                                 
      clr_rdy = 1;                              //assert clr_rdy
      if(rdy) begin                             //if a rdy signal be asserted from UART then ENH = 1. 
        ENM = 1;
        nxt_state = SENDM;end
      else
        nxt_state = SENDH;
      end
      
     SENDM:begin                                  
        clr_rdy = 1;              //assert clr_rdy
        if(rdy)                   //if the third rdy be asserted, set S = 1. 
          S = 1;
	if (clr_frm_rdy & ~rdy)
		R = 1'b1;
        if(snd_rsp)                   //if frm_rdy & snd_rsp set trmt = 1 and 
				      //jump to nxt state which start send 
				      //rsp_data[15:8] to UART.tx
          begin
          sel = 0; 
          nxt_state = RSPH;
          trmt = 1;
          end
        else
        nxt_state = SENDM;
      end
      
      RSPH:begin
	if (clr_frm_rdy)
		R = 1;
        if(tx_done)begin                        //if tx_done we can jump to next state and set trmt = 1  
          sel = 1;                               //set sel = 1 to select rsp_data[7:0]
          nxt_state = RSPL;
          trmt = 1;end
        else
          nxt_state = RSPH;
     end
     
     RSPL:begin                                 //if tx_done, jump to done
     if(tx_done)
       nxt_state = DONE;
     else
        nxt_state = RSPL;  
       end
       
       default:begin                               //in DONE state, it waits for signal clr_frm_rdy to jump to the state IDLE
            nxt_state = IDLE;
        end
        
      endcase
    end

always @(posedge clk or negedge rst_n)    // dff to store high byte of cfg_data
 if(!rst_n)
  cfg_data[23:16] <= 8'b0;
 else
  if(ENH == 1) // enable
   cfg_data[23:16] <= rx_data[7:0];
  else //disable
   cfg_data[23:16] <= cfg_data[23:16];

always @(posedge clk or negedge rst_n)    // dff to store mid byte of cfg_data
 if(!rst_n)
  cfg_data[15:8] <= 8'b0;
 else
  if(ENM == 1) // enable
   cfg_data[15:8] <= rx_data[7:0];
  else // disable
   cfg_data[15:8] <= cfg_data[15:8];

always @(posedge clk or negedge rst_n)    // dff to store low byte of rsp_data
 if(!rst_n)
  rsp_data_low <= 8'b0;
 else
  if(snd_rsp == 1)  // enable
   rsp_data_low <= rsp_data[7:0];
  else // disable
   rsp_data_low <= rsp_data_low;

always @(posedge clk or negedge rst_n)
 if(!rst_n) // reset frm_rdy
  frm_rdy <= 0;
 else if(S) // set frm_rdy
  frm_rdy <= 1;
 else if(R) // clear frm_rdy 
  frm_rdy <= 0;

always @(*)
 begin
 cfg_data[7:0] = rx_data[7:0];
 if(sel == 0) // mux selects high byte of rsp_data
  tx_data = rsp_data[15:8];
 else // mux selects low byte of rsp_data
  tx_data = rsp_data_low;
 end
endmodule

