// `default_nettype none

// package tb_tasks;

// typedef struct packed {
//     logic highGrn;
//     logic lowGrn;
//     logic highYlw;
//     logic lowYlw;
//     logic highBlu;
//     logic lowBlu;
// } mtr_state_t;

// localparam PWM_cycle = 2048;

// 	// LED mode string mapping
// 	function string LED_mode(input [1:0] LED);
// 		case (LED)
// 			2'b00: LED_mode = "OFF";
// 			2'b01: LED_mode = "LOW";
// 			2'b10: LED_mode = "MED";
// 			2'b11: LED_mode = "HIGH";
// 			default: LED_mode = "UNKNOWN";
// 		endcase
// 	endfunction

// 	// Check PWM duty over a cycle
// 	task automatic PWM_duty(ref clk, ref PWM_sig, output int duty);
// 		duty = 1;
// 		for (int i = 0; i < PWM_cycle; i++) begin
// 			@(posedge clk);
// 			if (PWM_sig === 'Z || PWM_sig === 'X) begin
// 				$display("PWM_sig is %b, aborting measurement", PWM_sig);
// 				duty = -1;
// 				return;
// 			end
// 			else if (PWM_sig)
// 				duty++;
// 		end
// 	endtask

// 	// FET string conversion
// 	function string FET_str(input int idx);
// 		case (idx)
// 			0:       FET_str = "highGrn";
// 			1:       FET_str = "lowGrn";
// 			2:       FET_str = "highYlw";
// 			3:       FET_str = "lowYlw";
// 			4:       FET_str = "highBlu";
// 			5:       FET_str = "lowBlu";
// 			default: FET_str.itoa(idx);
// 		endcase
// 	endfunction

// 	// Initialize DUT
// 	task automatic init(ref logic clk, ref logic RST_n, ref logic tgglMd);
// 		RST_n = 0;
// 		tgglMd = 0;
// 		@(posedge clk);
// 		@(negedge clk);
// 		RST_n = 1;
// 		$display("Init DUT");
// 	endtask

// 	// Battery low/high test
// 	task automatic test_battery(ref logic clk, ref [11:0] BATT, ref logic signed [12:0] error);
// 		$display("Begin Battery Test");
// 		BATT = 12'h000;
// 		repeat (1000000) @(posedge clk);
// 		assert(error == 0) else $display("Battery low but signal not zeroed");

// 		BATT = 12'hFFF;
// 		repeat (1000000) @(posedge clk);
// 		assert(error != 0) else $display("Battery high but signal zeroed");
// 		$display("End Battery Test");
// 	endtask

// 	// Toggle assist mode
// 	task automatic toggle(ref logic clk, ref logic tgglMd);
// 		tgglMd = 1;
// 		@(posedge clk);
// 		tgglMd = 0;
// 		@(posedge clk);
// 	endtask

// 	// Brake test
// 	task automatic test_brakes(ref logic clk, ref [11:0] BRAKE, ref [11:0] avg_curr, ref [19:0] omega);
// 		$display("Begin Brake Test");
// 		repeat (1000000) @(posedge clk);
// 		BRAKE = 12'h000;
// 		repeat (3000000) @(posedge clk);
// 		assert(avg_curr <= 10) else $display("Brake applied but current not zeroed");
// 		assert(omega <= 100) else $display("Brake applied but omega not zeroed");
// 		BRAKE = 12'h800;
// 		repeat (3000000) @(posedge clk);
// 		$display("End Brake Test");
// 	endtask

// 	// Assist toggle mode test
// 	task automatic test_toggle_mode(ref logic clk, ref logic tgglMd, ref [1:0] LED, ref [19:0] omega);
// 		logic [19:0] omega_prev;
// 		logic [1:0] mode_prev;
		
// 		mode_prev = LED;
// 		omega_prev = omega;

// 		toggle(clk, tgglMd);
// 		repeat (3000000) @(posedge clk);

// 		$display("Assist toggled from %s to %s at time %0t", LED_mode(mode_prev), LED_mode(LED), $time());

// 		case (mode_prev)
// 			2'b10: assert(omega >= omega_prev) else $display("Expected omega to increase: MEDIUM to HIGH");
// 			2'b11: assert(omega <= omega_prev) else $display("Expected omega to decrease: HIGH to OFF");
// 			2'b00: assert(omega >= omega_prev) else $display("Expected omega to increase: OFF to LOW");
// 			2'b01: assert(omega >= omega_prev) else $display("Expected omega to increase: LOW to MEDIUM");
// 			default: $display("Unexpected LED mode: %b", mode_prev);
// 		endcase
// 	endtask

// 	// Uphill (yaw increasing)
// 	task automatic test_uphill(ref logic clk, ref int cadence_period, ref [11:0] TORQUE, ref [15:0] YAW_RT, ref [11:0] avg_curr, ref [19:0] omega);
// 		logic [11:0] curr_prev;
// 		logic [19:0] omega_prev;

// 		$display("Begin uphill at constant cadence and torque test");
// 		cadence_period = 32'h1000;
// 		TORQUE = 12'h500;
		
// 		for (YAW_RT = '0; YAW_RT <= 16'h1800; YAW_RT += 16'h100) begin
// 			curr_prev = avg_curr;
// 			omega_prev = omega;

// 			$display("YAW_RT=%x at time=%t", YAW_RT, $time());
// 			repeat (5000000) @(posedge clk);

// 			assert(avg_curr >= curr_prev) else $display("Uphill but avg curr did not increase. Prev=%h Curr=%h", curr_prev, avg_curr);
// 			assert(omega >= omega_prev) else $display("Uphill but omega did not increase. Prev=%h Curr=%h", omega_prev, omega);
// 		end

// 		$display("Uphill test complete");
// 	endtask

// 	// Downhill (yaw decreasing)
// 	task automatic test_downhill(ref logic clk, ref int cadence_period, ref [11:0] TORQUE, ref [15:0] YAW_RT, ref [11:0] avg_curr, ref [19:0] omega);
// 		logic [11:0] curr_prev;
// 		logic [19:0] omega_prev;

// 		$display("Begin downhill at constant cadence and torque test");
// 		cadence_period = 32'h1000;
// 		TORQUE = 12'h500;
		
// 		for (YAW_RT = '0; $signed(YAW_RT) >= -16'sh1800; YAW_RT -= 16'h100) begin
// 			curr_prev = avg_curr;
// 			omega_prev = omega;

// 			$display("YAW_RT=%x at time=%t", YAW_RT, $time());
// 			repeat (5000000) @(posedge clk);

// 			assert(avg_curr <= curr_prev) else $display("Downhill but avg curr did not decrease. Prev=%h Curr=%h", curr_prev, avg_curr);
// 			assert(omega <= omega_prev) else $display("Downhill but omega did not decrease. Prev=%h Curr=%h", omega_prev, omega);
// 		end

// 		$display("Downhill test complete");
// 	endtask

// 	// Cadence increase
// 	task automatic test_cadence_increase(ref logic clk, ref int cadence_period, ref [11:0] avg_curr, ref [19:0] omega);
// 		logic [11:0] curr_prev;
// 		logic [19:0] omega_prev;

// 		$display("Cadence increase test start");

// 		for (cadence_period = 32'h10000; cadence_period >= 32'h0000; cadence_period -= 32'h0800) begin
// 			curr_prev = avg_curr;
// 			omega_prev = omega;

// 			$display("Cadence period=%h at time=%t", cadence_period, $time());
// 			repeat (5000000) @(posedge clk);

// 			assert(avg_curr >= curr_prev) else $display("Cadence increase but avg curr did not increase. Prev=%h Curr=%h", curr_prev, avg_curr);
// 			assert(omega >= omega_prev) else $display("Cadence increase but omega did not increase. Prev=%h Curr=%h", omega_prev, omega);
// 		end

// 		$display("Cadence increase test complete");
// 	endtask

// 	// Cadence decrease
// 	task automatic test_cadence_decrease(ref logic clk, ref int cadence_period, ref [11:0] avg_curr, ref [19:0] omega);
// 		logic [11:0] curr_prev;
// 		logic [19:0] omega_prev;

// 		$display("Cadence decrease test start");

// 		for (cadence_period = 32'h8000; cadence_period <= 32'h10000; cadence_period += 32'h0800) begin
// 			curr_prev = avg_curr;
// 			omega_prev = omega;

// 			$display("Cadence period=%h at time=%t", cadence_period, $time());
// 			repeat (1000000) @(posedge clk);

// 			assert(avg_curr <= curr_prev) else $display("Cadence decrease but avg curr did not decrease. Prev=%h Curr=%h", curr_prev, avg_curr);
// 			assert(omega <= omega_prev) else $display("Cadence decrease but omega did not decrease. Prev=%h Curr=%h", omega_prev, omega);
// 		end

// 		$display("Cadence decrease test complete");
// 	endtask

// 	task automatic test_torque_increase(
// 	  ref logic          clk,
// 	  ref logic [11:0]   TORQUE,
// 	  ref logic [11:0]   avg_curr,
// 	  ref logic [19:0]   omega
// 	);
// 	  // Parameters / constants
// 	  localparam logic [11:0] TORQUE_MIN   = 12'h380;
// 	  localparam integer      WAIT_CYCLES  = 5_000_000;
// 	  localparam integer      MAX_DELTA    = 100;

// 	  logic [11:0] curr_prev;
// 	  logic [19:0] omega_prev;
// 	  logic [11:0] delta_curr;
// 	  logic [19:0] delta_omega;

// 	  $display("Torque increase test start");
// 	  TORQUE = 12'h000;
// 	  repeat (WAIT_CYCLES) @(posedge clk);

// 	  for (TORQUE = 12'h100; TORQUE <= 12'h800; TORQUE += 12'h100) begin
// 		curr_prev  = avg_curr;
// 		omega_prev = omega;
// 		$display("  Setting TORQUE = %0h at time = %0t", TORQUE, $time);
// 		repeat (WAIT_CYCLES) @(posedge clk);

// 		// compute absolute changes
// 		delta_curr  = (avg_curr  >= curr_prev)  ? (avg_curr  - curr_prev)
// 												: (curr_prev - avg_curr);
// 		delta_omega = (omega      >= omega_prev) ? (omega      - omega_prev)
// 												 : (omega_prev - omega);

// 		if (TORQUE <= TORQUE_MIN) begin
// 		  assert (delta_curr  < MAX_DELTA)
// 			else $error("Torque ≤ MIN but avg_curr changed by %0d", delta_curr);
// 		  assert (delta_omega < MAX_DELTA)
// 			else $error("Torque ≤ MIN but omega changed by %0d", delta_omega);
// 		end
// 		else begin
// 		  assert (avg_curr  >= curr_prev)
// 			else $error("Expected avg_curr ≥ prev: prev=%0h curr=%0h", curr_prev, avg_curr);
// 		  assert (omega     >= omega_prev)
// 			else $error("Expected omega ≥ prev: prev=%0h curr=%0h", omega_prev, omega);
// 		end
// 	  end

// 	  $display("Torque increase test complete");
// 	endtask


// 	task automatic test_torque_decrease(
// 	  ref logic          clk,
// 	  ref logic [11:0]   TORQUE,
// 	  ref logic [11:0]   avg_curr,
// 	  ref logic [19:0]   omega
// 	);
// 	  // tweak these as needed
// 	  localparam logic [11:0] TORQUE_MIN   = 12'h380;
// 	  localparam integer      WAIT_CYCLES  = 5_000_000;
// 	  localparam integer      MAX_DELTA    = 100;

// 	  logic [11:0] curr_prev;
// 	  logic [19:0] omega_prev;
// 	  logic [11:0] delta_curr;
// 	  logic [19:0] delta_omega;

// 	  $display("Torque decrease test start");
// 	  // start above max
// 	  TORQUE = 12'h900;
// 	  repeat (WAIT_CYCLES) @(posedge clk);

// 	  // step down from 0x800 to 0x100
// 	  for (TORQUE = 12'h800; TORQUE >= 12'h100; TORQUE -= 12'h100) begin
// 		curr_prev  = avg_curr;
// 		omega_prev = omega;
// 		$display("  Setting TORQUE = %0h at time = %0t", TORQUE, $time);
// 		repeat (WAIT_CYCLES) @(posedge clk);

// 		// absolute change
// 		delta_curr  = (avg_curr >= curr_prev)  ? (avg_curr  - curr_prev)
// 											   : (curr_prev - avg_curr);
// 		delta_omega = (omega     >= omega_prev) ? (omega     - omega_prev)
// 											   : (omega_prev - omega);

// 		if (TORQUE <= (TORQUE_MIN - 12'h100)) begin
// 		  // below threshold, expect only small drift
// 		  assert (delta_curr  < MAX_DELTA)
// 			else $error("Torque ≤ MIN but avg_curr changed by %0d", delta_curr);
// 		  assert (delta_omega < MAX_DELTA)
// 			else $error("Torque ≤ MIN but omega changed by %0d", delta_omega);
// 		end
// 		else begin
// 		  // above threshold, must strictly decrease or stay equal
// 		  assert (avg_curr  <= curr_prev)
// 			else $error("Expected avg_curr ≤ prev: prev=%0h curr=%0h", curr_prev, avg_curr);
// 		  assert (omega     <= omega_prev)
// 			else $error("Expected omega ≤ prev: prev=%0h curr=%0h", omega_prev, omega);
// 		end
// 	  end

// 	  $display("Torque decrease test complete");
// 	endtask


// endpackage





















//  System?level reset
task automatic reset_dut (input int cycles = 10);
  RST_n <= 0;
  repeat (cycles) @(posedge clk);
  RST_n <= 1;
  $display("[%0t] **Reset released**", $time);
endtask

//  Toggle assist? mode push? button for one clock
task automatic press_toggle_mode;
  tgglMd <= 1;
  @(posedge clk);
  tgglMd <= 0;
  $display("[%0t] Assist?mode toggled", $time);
endtask

task automatic apply_torque
(
    ref  logic [11:0] TORQUE,   // <-- add the full type and width
    input logic [11:0] val
);
    TORQUE = val;
endtask



// //  Apply a fixed pedal?torque value for N clock cycles
// task automatic apply_torque (ref TORQUE, input [11:0] val);
//   TORQUE = val;
//   // repeat (cycles) @(posedge clk);
//   // TORQUE <= '0;
//   // $display("[%0t] TORQUE = 0x%0h for %0d cycles", $time, val, cycles);
// endtask

//  Change simulated road grade (yaw?rate)
task automatic set_yaw (input signed [15:0] val);
  YAW_RT <= val;
  $display("[%0t] YAW_RT set to %0d (0x%0h)", $time, val, val);
endtask

// task automatic drive_cadence
// (
//     input  logic          clk,
//     input  logic          RST_n,
//     output logic          cadence_driver,
//     input  logic [15:0]   period,      // full PWM period   (≥1)
//     input  logic [15:0]   high_cnt     // width of HIGH time (0-period)
// );
//     logic [15:0] counter;

//     // forever PWM generator
//     forever begin
//         @(posedge clk or negedge RST_n);
//         if (!RST_n) begin
//             counter         = 16'd0;
//             cadence_driver  = 1'b0;
//         end
//         else begin
//             // free-running counter
//             counter = (counter == period-1) ? 16'd0
//                                              : counter + 16'd1;

//             cadence_driver = (counter < high_cnt); // duty-cycle compare
//         end
//     end
// endtask
    

//  Generate one cadence pulse 
//  (Directly drives the cadence logic line; avoids force/release.)
localparam int HI_CYCLES  = FAST_SIM ? 5_000 : 50_000; // 0.1 ms vs 1 ms
localparam int LO_CYCLES  = HI_CYCLES;                 // symmetric

task automatic cadence_pulse;
  forever begin
    cadence = 1;
    repeat (HI_CYCLES) @(posedge clk);
    cadence = 0;
    repeat (LO_CYCLES) @(posedge clk);
  end
endtask

//  Wait for a UART byte, log it, and clear the ready flag
task automatic uart_get_byte;
  @(posedge rdy);
  $display("[%0t] UART byte 0x%02h (%c)",
           $time, rx_data, (^rx_data) ? rx_data : " ");
  clr_rdy <= 1;
  @(posedge clk);
  clr_rdy <= 0;
endtask