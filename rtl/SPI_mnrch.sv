`default_nettype none;
// this module iomplements a SPI tranceiver
module SPI_mnrch(clk, rst_n, SS_n, SCLK, MOSI, MISO, snd, cmd, done, resp);
	// declare input and output signals
	input logic clk, rst_n, MISO, snd;
	input logic [15:0]cmd;
	output logic done, SS_n, SCLK, MOSI;
	output logic [15:0]resp;

	// declare internal signals
	logic [4:0] SCLK_div, bit_cntr;
	logic done16, shft, full, ld_SCLK, init, set_done;
	logic [15:0]shft_reg;

	// define an enum for states
	typedef enum reg [1:0] {IDLE, SHIFT, DONE} state_t;
	state_t state, nxt_state;

	// state machine reset is IDLE state
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) state <= IDLE;
		else state <= nxt_state;
	end

	// state transition logic
	always_comb begin
		// set default outputs
		ld_SCLK = 0;
		init = 0;
		set_done = 0;
		nxt_state = state;
		
		case(state)
			// shift state, transition if 16 bits have been shifted
			SHIFT: if (done16)
				nxt_state = DONE;
			
			// done state, transition when shift reg is full
			DONE: if (full) begin
				set_done = 1;
				nxt_state = IDLE;
			end

			// default is IDLE state, wait for snd
			default: if (snd) begin
				init = 1;
				nxt_state = SHIFT;
			end
			else
				ld_SCLK = 1;
		endcase
	end

	// shift register
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) shft_reg <= 16'b0;
		else if (init) shft_reg <= cmd;
		else if (shft) shft_reg <= {shft_reg[14:0], MISO};
	end

	// shift bit counter
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) bit_cntr <= 5'b0;
		else if (init) bit_cntr <= 5'b0;
		else if (shft) bit_cntr <= bit_cntr + 1;
	end

	// SCLK is raised when counter reaches 32, so SCLK is 1/32 of clk
	assign SCLK = SCLK_div[4];
	// shift signal to the MOSI-MISO shift register
	assign shft = (SCLK_div == 5'b10001);
	// SCLK counter has all bits full
	assign full = (&SCLK_div);
	// all bits shifted in
	assign done16 = bit_cntr[4];
	// MOSI is MSB of shift_reg
	assign MOSI = shft_reg[15];
	// resp is the result of the shift reg
	assign resp = shft_reg;
	
	// SCLK counter
	always @(posedge clk, negedge rst_n) begin
		if (!rst_n) SCLK_div <= 5'b0;
		else if (ld_SCLK) SCLK_div <= 5'b10111;
		else SCLK_div <= SCLK_div + 1;
	end

	// SS_n FF, preset
	always @(posedge clk, negedge rst_n) begin
		if (!rst_n) SS_n <= 1'b1;
		else if (init) SS_n <= 1'b0;
		else if (set_done) SS_n <= 1'b1;
	end

	// done FF, reset
	always @(posedge clk, negedge rst_n) begin
		if (!rst_n) done <= 1'b0;
		else if (init) done <= 1'b0;
		else if (set_done) done <= 1'b1;
	end


endmodule
