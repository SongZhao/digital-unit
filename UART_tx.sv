module UART_tx(clk,rst_n,TX,tx_data,trmt,tx_done);

///////////////////////////////////////////////////////
// UART transmitter.  Transmits 8-bit data tx_data  //
// upon a trmt asserted.  Transmits at 921,600 baud //
// using a 800MHz clock                           //
///////////////////////////////////////////////////

input [7:0] tx_data;

input clk,rst_n,trmt;
output TX,tx_done;

//////////////////////////
// Typedefs for states //
////////////////////////
typedef enum reg { IDLE, TXS } state_t;
state_t state, nxt_state;

logic tx_done;
logic [3:0] bit_cntr;			// need to count to 10 to include start/stop
logic [8:0] shft_reg;
logic [9:0] baud_cntr;			// need 10-bits to get 921,600 from 800MHz

/////////////////////////////////
// outputs from state machine //
///////////////////////////////
logic shft, set_tx_done, rst_bit_cntr, transmitting;

wire baud_full;

////////////////////////////
// Implement state flops //
//////////////////////////
always_ff @(posedge clk,negedge rst_n)
    if (!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;

/////////////////////////////
// Implement tx_done flop //
///////////////////////////
always_ff @(posedge clk,negedge rst_n)
    if (!rst_n)
      tx_done <= 1'b0;
    else if (set_tx_done)
      tx_done <= 1'b1;
    else if (trmt)
      tx_done <= 1'b0;

/////////////////////////////
// Implement Baud Counter //
///////////////////////////
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      baud_cntr <= 10'h000;
    else if (baud_full)
      baud_cntr <= 10'h000;
    else if (transmitting)
      baud_cntr <= baud_cntr + 1;

always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      bit_cntr <= 4'b0;
    else if (rst_bit_cntr)
      bit_cntr <= 4'b0;
    else if (shft)
      bit_cntr <= bit_cntr + 1;

////////////////////////////////////////
// 0x363 derives 921,600 from 800MHz //
//////////////////////////////////////
assign baud_full = (baud_cntr==10'h363) ? 1'b1 : 1'b0;

///////////////////////////////
// Implement shift register //
/////////////////////////////
always_ff @(posedge clk,negedge rst_n)
    if (!rst_n)
      shft_reg <= 9'h1FF;
    else if (trmt)
      shft_reg <= {tx_data,1'b0};
    else if (shft)
      shft_reg <= {1'b1,shft_reg[8:1]};		// shift in idle condition (1'b1)

assign TX = shft_reg[0];

always_comb
  begin
    //////////////////////
    // Default outputs //
    ////////////////////
    shft = 0;
    set_tx_done = 0;
    rst_bit_cntr = 0;
    nxt_state = IDLE;
    transmitting = 0;
    case (state)
      IDLE : begin
        rst_bit_cntr = 1;
        if (trmt) 
	  nxt_state = TXS;
      end
      TXS : begin
        shft = baud_full;
	transmitting = 1;
	if (bit_cntr==4'hA)
          begin
            nxt_state = IDLE;
	    set_tx_done = 1;
	  end
	else
	  nxt_state = TXS;
      end
    endcase
  end

endmodule
