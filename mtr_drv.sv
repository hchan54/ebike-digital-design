`default_nettype none;
// this module implements the motor drive block
module mtr_drv(clk, rst_n, duty, PWM_synch, selGrn, selYlw, selBlu, highGrn, lowGrn, highYlw, lowYlw, highBlu, lowBlu);
	// declare input and output signals
	input logic clk, rst_n;
	input logic [1:0] selGrn, selYlw, selBlu;
	input logic [10:0] duty;
	output logic PWM_synch, highGrn, lowGrn, highYlw, lowYlw, highBlu, lowBlu;
	// declare intermediate signals
	logic PWM_sig;
	logic highGrnIn, lowGrnIn, highYlwIn, lowYlwIn, highBluIn, lowBluIn;
	
	// declare an instance of PWM
	PWM pwm0(.clk(clk), .rst_n(rst_n), .duty(duty), .PWM_sig(PWM_sig), .PWM_synch(PWM_synch));

	// declare 3 instances of nonoverlap, 1 for each color
	nonoverlap nonoverlap_grn(.clk(clk), .rst_n(rst_n), .highIn(highGrnIn), .lowIn(lowGrnIn), .highOut(highGrn), .lowOut(lowGrn));
	nonoverlap nonoverlap_ylw(.clk(clk), .rst_n(rst_n), .highIn(highYlwIn), .lowIn(lowYlwIn), .highOut(highYlw), .lowOut(lowYlw));
	nonoverlap nonoverlap_blu(.clk(clk), .rst_n(rst_n), .highIn(highBluIn), .lowIn(lowBluIn), .highOut(highBlu), .lowOut(lowBlu));

	// hierarchical ternary statements for mux logic for inputs to nonoverlap blocks
	// check MSB first then LSB
	assign highGrnIn = (selGrn[1]) ? (selGrn[0] ? 1'b0 : PWM_sig) : (selGrn[0] ? ~PWM_sig : 1'b0);
	assign lowGrnIn = (selGrn[1]) ? (selGrn[0] ? PWM_sig : ~PWM_sig) : (selGrn[0] ? PWM_sig : 1'b0);
	
	// repeat logic for yellow inputs
	assign highYlwIn = (selYlw[1]) ? (selYlw[0] ? 1'b0 : PWM_sig) : (selYlw[0] ? ~PWM_sig : 1'b0);
	assign lowYlwIn = (selYlw[1]) ? (selYlw[0] ? PWM_sig : ~PWM_sig) : (selYlw[0] ? PWM_sig : 1'b0);
	
	// repeat logic for blue inputs
	assign highBluIn = (selBlu[1]) ? (selBlu[0] ? 1'b0 : PWM_sig) : (selBlu[0] ? ~PWM_sig : 1'b0);
	assign lowBluIn = (selBlu[1]) ? (selBlu[0] ? PWM_sig : ~PWM_sig) : (selBlu[0] ? PWM_sig : 1'b0);
endmodule