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

//  Apply a fixed pedal?torque value for N clock cycles
task automatic apply_torque (input [11:0] val, input int cycles);
  TORQUE <= val;
  repeat (cycles) @(posedge clk);
  TORQUE <= '0;
  $display("[%0t] TORQUE = 0x%0h for %0d cycles", $time, val, cycles);
endtask

//  Change simulated road grade (yaw?rate)
task automatic set_yaw (input signed [15:0] val);
  YAW_RT <= val;
  $display("[%0t] YAW_RT set to %0d (0x%0h)", $time, val, val);
endtask

//  Generate one cadence pulse 
//  (Directly drives the cadence logic line; avoids force/release.)
localparam int HI_CYCLES  = FAST_SIM ? 5_000 : 50_000; // 0.1 ms vs 1 ms
localparam int LO_CYCLES  = HI_CYCLES;                 // symmetric

task automatic cadence_pulse;
  cadence = 1;
  repeat (HI_CYCLES) @(posedge clk);
  cadence = 0;
  repeat (LO_CYCLES) @(posedge clk);
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
