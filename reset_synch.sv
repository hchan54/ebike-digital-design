`default_nettype none
module reset_synch(RST_n, clk,rst_n);
	input logic RST_n;
	input logic clk;
	output logic rst_n;

	logic rst_ff;

	always_ff @(negedge clk, negedge RST_n) begin
		if (!RST_n) begin
			rst_ff <= 1'b0;
			rst_n <= 1'b0;
		end else begin
			rst_ff <= 1'b1;
			rst_n <= rst_ff;
		end
	end
endmodule
	
		
