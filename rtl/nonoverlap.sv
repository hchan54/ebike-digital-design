`default_nettype none

// this module implements the nonoverlap design preventing a 
module nonoverlap(clk, rst_n, highIn, lowIn, highOut, lowOut);
	
	// declare input and output signals
	input logic clk;
	input logic rst_n;
	input logic highIn;
	input logic lowIn;
	output logic highOut;
	output logic lowOut;
	// declare intermediate signals
	logic [4:0] dead_time;
	logic ff_high_1, ff_high_2, ff_low_1, ff_low_2;
	logic change_detected;

    // change detected goes high when it sees a difference between FF 1 and 2
    assign change_detected = ((ff_high_1 != ff_high_2) || (ff_low_1 != ff_low_2));
	
	// flip flops to avoid metastability
	always @(posedge clk, negedge rst_n) begin
		// asynchronous reset
		if (!rst_n) begin
			ff_high_1 <= 1'b0;
			ff_high_2 <= 1'b0;
			ff_low_1 <= 1'b0;
			ff_low_2 <= 1'b0;
		end
		else begin
			// propagate values
			ff_high_1 <= highIn;
			ff_high_2 <= ff_high_1;
			ff_low_1 <= lowIn;
			ff_low_2 <= ff_low_1;
		end
	end
	// FF for output values
    always @(posedge clk, negedge rst_n) begin
       		// asynchronous reset
		if (!rst_n) begin
            lowOut <= 1'b0;
			highOut <= 1'b0;
        	end
		// hold outputs low when change is detected
        else if (change_detected) begin
            lowOut <= 1'b0;
			highOut <= 1'b0;
        end
		// otherwise propagate values
        else begin
            lowOut <= ff_low_2 & (&dead_time);
            highOut <= ff_high_2 & (&dead_time);
        end
    end

	// FF for dead time counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            dead_time <= '1;
	// set to 1 for first count when change is detected
        else if (change_detected) 
            dead_time <= 0; 
	// increment when max has not been reached yet
        else if (dead_time != 5'd31) 
            dead_time <= dead_time + 1; 
    end


endmodule
