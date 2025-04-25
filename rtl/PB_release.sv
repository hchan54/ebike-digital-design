`default_nettype none

module PB_release(clk, rst_n, PB, released);
	input logic clk, rst_n, PB;
	output logic released;

	logic ff_1, ff_2, ff_3;

	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			ff_1 <= 1'b1;
			ff_2 <= 1'b1;
			ff_3 <= 1'b1;
		end
		else begin
			ff_1 <= PB;
			ff_2 <= ff_1;
			ff_3 <= ff_2;
		end
	end

	assign released = (~ff_3) & ff_2;
endmodule
			
