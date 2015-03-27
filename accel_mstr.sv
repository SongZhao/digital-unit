module accel_mstr(clk,rst_n,TX_A);
////////////////////////////////////////////////////////////
// This module is used to generate acceleration stimulus //
// It reads value from a file (accel_vals.txt) and      //
// applies a new one every time hit_me is asserted     //
////////////////////////////////////////////////////////
input clk,rst_n;
output TX_A;			// serial output representing two 8-bit accel bytes

wire [7:0] tx_data;
///////////////////////////////////////////////////////////////////////
// Memory that holds value of acceleration read from accel_vals.txt //
/////////////////////////////////////////////////////////////////////
reg [15:0] accel_vals[0:255];
reg [13:0] pause_cnt;		// 16384 clocks between accel packets

reg [7:0] accel_ptr;	// points to next value of acceleration to send

////////// typedef for state enumeration ////////
typedef enum reg [1:0] {IDLE, WAIT_HIGH, WAIT_LOW} state_t;
state_t state,nxt_state;

////////////////////////////
// State Machine Outputs //
//////////////////////////
logic trmt,sel_high,advance_ptr,clr_pause_cnt;

////////////////////////////////////////////////////////////
// Instantiate a UART transmitter for providing stimulus //
//////////////////////////////////////////////////////////
UART_tx iSTIM(.clk(clk), .rst_n(rst_n), .TX(TX_A), .tx_data(tx_data),
	      .trmt(trmt), .tx_done(tx_done));

///////////////////////////////
// Implement state register //
/////////////////////////////
always @(posedge clk, negedge rst_n)
    if (!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;

//////////////////////////////////////////////
// Implement pointer to next entry to send //
////////////////////////////////////////////
always @(posedge clk, negedge rst_n)
    if (!rst_n)
      accel_ptr <= 8'h00;
    else if (advance_ptr)
      accel_ptr <= accel_ptr+1;

/////////////////////////////////////////////////////////
// Counter used to pause between Acceleration packets //
///////////////////////////////////////////////////////
always @(posedge clk, negedge rst_n)
    if (!rst_n)
      pause_cnt <= 14'h0000;
    else if (clr_pause_cnt)
      pause_cnt <= 14'h0000;
    else
      pause_cnt <= pause_cnt + 1;

assign pause_over = &pause_cnt;

always_comb begin
  //////////////////////
  // Default outputs //
  ////////////////////
  nxt_state = IDLE;
  sel_high = 1;
  advance_ptr = 0;
  trmt = 0;
  clr_pause_cnt = 0;
  
  case (state)
    IDLE : begin
      if (pause_over) begin
        trmt = 1;
        nxt_state = WAIT_HIGH;
      end
    end
    WAIT_HIGH : begin
      sel_high = 0;
      if (tx_done) begin
        trmt = 1;
        nxt_state = WAIT_LOW;
      end
      else nxt_state = WAIT_HIGH;
    end
    default : begin 		// this is WAIT_LOW state 
      if (tx_done) begin
        advance_ptr = 1;
	clr_pause_cnt = 1;
	nxt_state = IDLE;
      end
      else nxt_state = WAIT_LOW;
    end
  endcase
end

///////////////////////////////////////////////////////////////////////////
// Select data to drive to UART based on sel_high from SM and accel_ptr //
/////////////////////////////////////////////////////////////////////////
assign tx_data = (sel_high) ? accel_vals[accel_ptr][15:8] : accel_vals[accel_ptr][7:0];

initial
  $readmemh("./accel_vals.txt",accel_vals);

endmodule
