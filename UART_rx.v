module UART_rx(clk,rst_n,RX, rx_data,rdy,clr_rdy);
  
  output [7:0] rx_data;
  input clk, rst_n, RX, clr_rdy;
  output rdy;

  reg A,data,B,transmitting,rst_bit_cntr,state,nxt_state;
  reg [7:0] rx_data;
  reg rdy;
  
  reg [3:0] bit_cntr;
  reg [9:0] baud_cntr;
  wire shift, RX_active;
  reg rx_done;
  
  localparam IDLE = 2'b00;
  localparam RXS = 2'b01;
  localparam DONE = 2'b10;
  
  always @(posedge clk or negedge rst_n)begin // a triple flip-flop, the first two are for 
    if(!rst_n)begin                           // preventing possible glitch.
      A <= 0;                                 // the third one is used to generate the active signal 
      data <= 0;
      B <= 0;end
    else begin
      A<= RX;
      data <= A ;
      B<= data;end
    end
  assign RX_active = (!data) & B;             //acitve signal becomes 1 when it detects a 0 in tx_data
  
        
      
  always @(posedge clk, negedge rst_n)        //baud counter 
    if (!rst_n)
      baud_cntr <= 10'h000;
    else if (shift)
      baud_cntr <= 10'h000;
    else if (transmitting)
      baud_cntr <= baud_cntr + 1;
      
  assign shift = (baud_cntr== 868) ? 1'b1 : 1'b0;  //generate a shift signal when baud counter counts to 868

  always @(posedge clk, negedge rst_n)begin        //bit counter to count how many bit has been transfered 
    if (!rst_n)
      bit_cntr <= 4'b0;
    else if (rst_bit_cntr)
      bit_cntr <= 4'b0;
    else if (shift)
      bit_cntr <= bit_cntr + 1; end
          


  always @(posedge clk,negedge rst_n)              //shift the input into the rx_data when the shift signal is high 
    if (!rst_n)
      rx_data <= 8'h00;
    else if (shift)
      rx_data <= {data,rx_data[7:1]};
    else
      rx_data<=rx_data;   
 
  
  always @(posedge clk,negedge rst_n)                 
    if (!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;  
  
  always @(*)                                 //state machine
    begin
      nxt_state = IDLE;                       //set default value
      rst_bit_cntr = 0;
      transmitting = 0;
      rdy = 0;
      case (state)
        IDLE : begin                          //when in IDLE it waits for the active signal to  
        rdy = 0;                               //kick it into next state
        rst_bit_cntr = 1;                     //rdy will be cleared when clr_rdy asserted
        transmitting = 0;
        if(RX_active)
          nxt_state = RXS;
        else
          nxt_state = IDLE;
        end
           
        RXS : begin                           //when in this state the transfer started, set transmitting = 1
                                             //so the baud counter can start counting
        transmitting = 1;
        if(bit_cntr == 4'b1000) begin         //when 8 bits has been recieved, next state will be DONE and set rdy = 1         
           rdy = 1;
          nxt_state = DONE;
         end
        else
        nxt_state = RXS;
      end
      
      DONE : begin                            //at DONE state the rdy will be one and remain in DONE state
        rdy = 1;                              //until a clr_rdy asserted
        if(clr_rdy)
          nxt_state = IDLE;
        end
        
     default : begin
          nxt_state = IDLE;                       //set default value
      rst_bit_cntr = 0;
      transmitting = 0;
      rdy = 0;
    end
          
    endcase
  end

                
endmodule    
        
          
              