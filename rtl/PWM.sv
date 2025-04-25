`default_nettype none
// this module implements PWM using a counter
module PWM(clk, rst_n, duty, PWM_sig, PWM_synch);
	// declare input and output signals
	input logic clk;
	input logic rst_n;
	input logic [10:0]duty;
	output logic PWM_sig;
	output logic PWM_synch;
	// declare intermediate signals
	logic [10:0]cnt;
	// flip flop for PWM signal, compare cnt to duty
	always @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			PWM_sig <= 0;
		else if (cnt <= duty)
			PWM_sig <= 1'b1;
		else
			PWM_sig <= 1'b0;
	end
	// flip flop for cnt, increment until overflow
	always @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			cnt <= 0;
		else
			cnt <= cnt + 1'b1;
	end
	// assign synch based on if cnt is 1
	assign PWM_synch = (cnt == 11'h001);
endmodule
