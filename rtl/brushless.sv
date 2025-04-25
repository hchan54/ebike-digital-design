`default_nettype none;
// this module implements the drive and inspection for each coil in brushless motor
module brushless(clk, rst_n, drv_mag, hallGrn, hallYlw, hallBlu, brake_n, PWM_synch, duty, selGrn, selYlw, selBlu);
	// declare input and output signals
	input logic clk, rst_n, hallGrn, hallYlw, hallBlu, brake_n, PWM_synch;
	input logic [11:0] drv_mag;
	output logic [1:0] selGrn, selYlw, selBlu;
	output logic [10:0] duty;
	// declare intermediate signals
	logic green1, green2, yellow1, yellow2, blue1, blue2;
	logic synchGrn, synchYlw, synchBlu;
	logic [2:0] rotation_state;

	// create enum for drive states
	typedef enum reg [1:0] {HIGH_Z, rev_curr, for_curr, regen_braking} drive_t;

	// FF to synchronize signals, double flopping
	always_ff @(posedge clk) begin
		green1 <= hallGrn;
		green2 <= green1;
		yellow1 <= hallYlw;
		yellow2 <= yellow1;
		blue1 <= hallBlu;
		blue2 <= blue1;
	end

	// FF with active low reset and PWM_synch ternary
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			synchGrn <= 1'b0;
			synchYlw <= 1'b0;
			synchBlu <= 1'b0;
		end
		else if (PWM_synch) begin
			synchGrn <= green2;
			synchYlw <= yellow2;
			synchBlu <= blue2;
		end
		// implicitly recycles value if PWM_synch is low
	end
	
	// concatenate the bits for rotation state
	assign rotation_state = {synchGrn,synchYlw,synchBlu};

	// logic for assigning the coil drive
	always_comb begin
		// check brake, has highest priority
		if (!brake_n) begin
			selGrn = regen_braking;
			selYlw = regen_braking;
			selBlu = regen_braking;
		end
		// otherwise, assign the coil drives accordingly
		// assigned values use the enum type
		else case(rotation_state)
			3'b101: begin
				selGrn = for_curr;
				selYlw = rev_curr;
				selBlu = HIGH_Z;
			end
			3'b100: begin
				selGrn = for_curr;
				selYlw = HIGH_Z;
				selBlu = rev_curr;
			end
			3'b110: begin
				selGrn = HIGH_Z;
				selYlw = for_curr;
				selBlu = rev_curr;
			end
			3'b010: begin
				selGrn = rev_curr;
				selYlw = for_curr;
				selBlu = HIGH_Z;
			end
			3'b011: begin
				selGrn = rev_curr;
				selYlw = HIGH_Z;
				selBlu = for_curr;
			end
			3'b001: begin
				selGrn = HIGH_Z;
				selYlw = rev_curr;
				selBlu = for_curr;
			end
			// default case: something went wrong, all high impedance
			default: begin
				selGrn = HIGH_Z;
				selYlw = HIGH_Z;
				selBlu = HIGH_Z;
			end
		endcase
	end

	// set the duty value, the 11'h400 represents the voltage "equalization" for the coils
	assign duty = (brake_n) ? (drv_mag[11:2] + 11'h400) : 11'h600;

endmodule
		


