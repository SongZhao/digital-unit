module accel_UART (RX_A, clk, rst_n, accel_vld, Xmeas);
	input RX_A, clk, rst_n;
	output accel_vld;
	output [13:0] Xmeas;
	wire		rdy;			// From receiver of UART_rx.v
	wire [7:0]	rx_data;		// From receiver of UART_rx.v
	reg		clr_rdy;		// To receiver of UART_rx.v

	reg [5:0] high_byte;
	wire [5:0] high_byte_slct_in;
	reg [7:0] low_byte;
	wire [7:0] low_byte_slct_in;
	reg accel_vld, setA, clrA, rd_high, rd_low;

	reg [1:0] currState, nextState;

	UART_rx receiver (/*AUTOINST*/
			  // Outputs
			  .rdy			(rdy),
			  .rx_data		(rx_data[7:0]),
			  // Inputs
			  .RX			(RX_A),
			  .clr_rdy		(clr_rdy),
			  .clk			(clk),
			  .rst_n		(rst_n));

	localparam IDLE = 2'b00;
	localparam TLOW = 2'b01;
	localparam ACCL = 2'b10;

	// Input select for high byte
	assign high_byte_slct_in = rd_high ? rx_data[5:0] : high_byte;

	// Input select for low byte
	assign low_byte_slct_in = rd_low ? rx_data : low_byte;

	// Assign output
	assign Xmeas = {high_byte, low_byte};

	// High byte DFF
always @(posedge clk, negedge rst_n)
	if (!rst_n)
		high_byte <= 6'h0;
	else
		high_byte <= high_byte_slct_in;
	// Low byte DFF
always @(posedge clk, negedge rst_n)
	if (!rst_n)
		low_byte <= 8'h0;
	else
		low_byte <= low_byte_slct_in;

	// SR ff for accel_vld
always @(posedge clk, negedge rst_n)
	if (!rst_n)
		accel_vld <= 1'b0;
	else if (setA)
		accel_vld <= 1'b1;
	else if (clrA & ~setA)
		accel_vld <= 1'b0;
	else
		accel_vld <= accel_vld;

	// FSM FF
always @(posedge clk, negedge rst_n)
	if (!rst_n)
		currState = IDLE;
	else
		currState = nextState;

	// Next state & output logic
always @(*)
begin
	setA = 1'b0;
	clrA = 1'b0;
	rd_high = 1'b0;
	rd_low = 1'b0;
	clr_rdy = 1'b0;
	nextState = IDLE;
	case (currState)
		IDLE :
		// If the first data ready
		// It's the high ready
		// So read in high and wait for low
		if (rdy)
		begin
			nextState = TLOW;
			rd_high = 1'b1;
			clr_rdy = 1'b1;
		end

		TLOW :
		// If the second data ready
		// Low byte ready and Xmeas is ready
		if (rdy)
		begin
			nextState = ACCL;
			rd_low = 1'b1;
			clr_rdy = 1'b1;
			clrA = 1'b1;
		end
		// Loop if not rdy
		else
			nextState = TLOW;
			
		ACCL :
		// If another data is ready in this state
		// The new set of high byte is ready
		// So go back to wait for low byte
		if (rdy)
		begin
			nextState = TLOW;
			rd_high = 1'b1;
			clr_rdy = 1'b1;
			clrA = 1'b1;
		end
		else
		// Else hold the accel_vld high
		begin
			nextState = ACCL;
			setA = 1'b1;
		end
		
		default :
			nextState = 2'bxx;
	endcase
end // end always
endmodule
