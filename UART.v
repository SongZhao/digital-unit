module UART(clk, rst_n, trmt, clr_rdy, tx_done, rdy, tx_data, rx_data, TX_C, RX_C);
input clk, rst_n, trmt, clr_rdy;
output tx_done, rdy;
input [7:0] tx_data;
output [7:0] rx_data;
output TX_C;
input RX_C;

UART_tx transmitter(
          .clk(clk),
          .rst_n(rst_n),
          .TX(TX_C),
          .tx_data(tx_data),
          .trmt(trmt),
          .tx_done(tx_done)
                    );

UART_rx receiver(
          .RX(RX_C),
          .clk(clk),
          .rst_n(rst_n),
          .clr_rdy(clr_rdy),
          .rdy(rdy),
          .rx_data(rx_data)
                );

endmodule
