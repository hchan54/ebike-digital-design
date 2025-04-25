`default_nettype none;
// this module implements the wrapper for the UART_tx
module telemetry(batt_v, avg_curr, avg_torque, clk, rst_n, TX);
	// declare input and output signals
	input logic clk, rst_n;
	input logic [11:0] batt_v, avg_curr, avg_torque;
	output logic TX;

	// declare intermediate signals
	logic [7:0] tx_data;
	logic trmt;
	logic tx_done;
	logic [19:0] counter;
	logic snd; // counter reached max, start sending

	// declare local parameters
	localparam delim1 = 8'hAA;
	localparam delim2 = 8'h55;
	localparam max = 1048575; // 2^20, approx 50M/47.68

	// flip flop so the state machine executes 47.68 times per second
	always_ff @(posedge clk or negedge rst_n) begin
        	if (!rst_n)
            		counter <= 0;   // Reset counter
        	else if (counter == max) // When counter reaches max (1,048,576 - 1)
            		counter <= 0;
        	else
            		counter <= counter + 1;
    	end
	
	// start the sending when the counter reaches the max
	assign snd = (counter == max);

	// define an enum for states
	typedef enum reg [3:0] {IDLE, DLM1, DLM2, PYD1, PYD2, PYD3, PYD4, PYD5, PYD6} state_t;
	state_t state, nxt_state;

	// state machine reset is IDLE state
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) state <= IDLE;
		else state <= nxt_state;
	end

	// state transition logic
	always_comb begin
		// set default outputs
		trmt = 0;
		nxt_state = state;
		tx_data = 0;
		
		case(state)
			// format for each data sending state
			DLM1: if (tx_done) begin // check if the previous data has been sent
				tx_data = delim2; // prepare next data to be sent
				trmt = 1; // raise to send
				nxt_state = DLM2; // next state corresponds to data that has been sent
			end
			// repeat for each delim and payload state
			// delim2 state
			DLM2: if (tx_done) begin
				tx_data = {4'h0,batt_v[11:8]};
				trmt = 1;
				nxt_state = PYD1;
			end
			// payload 1 state
			PYD1: if (tx_done) begin
				tx_data = batt_v[7:0];
				trmt = 1;
				nxt_state = PYD2;
			end
			// payload 2 state
			PYD2: if (tx_done) begin
				tx_data = {4'h0,avg_curr[11:8]};
				trmt = 1;
				nxt_state = PYD3;
			end
			// payload 3 state
			PYD3: if (tx_done) begin
				tx_data = avg_curr[7:0];
				trmt = 1;
				nxt_state = PYD4;
			end
			// payload 4 state
			PYD4: if (tx_done) begin
				tx_data = {4'h0,avg_torque[11:8]};
				trmt = 1;
				nxt_state = PYD5;
			end
			// payload 5 state
			PYD5: if (tx_done) begin
				tx_data = avg_torque[7:0];
				trmt = 1;
				nxt_state = PYD6;
			end
			// payload 6 state
			PYD6: if (tx_done) begin 
				nxt_state = IDLE;
			end

			// default is IDLE state, prepare tx_data and send
			default: if (snd) begin
				tx_data = delim1;
				trmt = 1;
				nxt_state = DLM1;
			end
		endcase
	end

	// instantiate UART transmitter
	UART_tx transmitter(.clk(clk), .rst_n(rst_n), .trmt(trmt), .TX(TX), .tx_done(tx_done), .tx_data(tx_data));

endmodule

	
