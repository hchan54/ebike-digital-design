//------------------------------------------------------------------------------
// File: tb_tasks.sv
// Assumes the including module has these signals in scope:
//   clk, RST_n, tgglMd, BATT, BRAKE, TORQUE, YAW_RT, num_cycles, FAST_SIM, curr
//------------------------------------------------------------------------------

// Reset DUT to a known state
task reset_dut();
  BATT       = 12'hFFF;
  BRAKE      = 12'h800;
  TORQUE     = '0;
  YAW_RT     = '0;
  tgglMd     = 1'b0;
  num_cycles = FAST_SIM ? 50000 : 50000;

  RST_n = 0;
  repeat (10) @(posedge clk);
  @(negedge clk) RST_n = 1;
  repeat (10) @(posedge clk);
  $display("Reset complete");
endtask

// Set the cadence‐toggle period (in clock cycles)
task drive_cadence(input int cycles);
  num_cycles = FAST_SIM ? (cycles/10) : cycles;
endtask

// Drive a specific torque value into TORQUE
task drive_torque(input logic [11:0] torque_val);
  TORQUE = torque_val;
endtask

// Apply the brake
task press_brake(input logic [11:0] brake_val);
  BRAKE <= brake_val;
endtask

// Set the yaw/incline rate
task set_yaw(input signed [15:0] yaw_val);
  YAW_RT = yaw_val;
  $display("[%0t] YAW_RT = %0d", $time, yaw_val);
endtask

//------------------------------------------------------------------------------
// The following test_… tasks only examine the single signal `curr`.
// Each is declared AUTOMATIC to get fresh locals per call.
//------------------------------------------------------------------------------

task automatic test_cadence_increasing(input int cycles);
  automatic logic [11:0] start_curr = curr;
  drive_cadence(cycles);
  repeat (2_500_000) @(posedge clk);
  assert (curr > start_curr)
    else $fatal("cadence↑ failed: curr %0d <= start %0d", curr, start_curr);
  
  $display("Test cadence increase: Passed");
endtask

task automatic test_cadence_decreasing( input int cycles);
  automatic logic [11:0] start_curr = curr;
  force iDUT.not_pedaling = 1'b1;
  drive_cadence(cycles);
  repeat (2_500_000) @(posedge clk);
  assert (curr < start_curr)
    else $fatal("cadence↓ failed: curr %0d >= start %0d", curr, start_curr);
  
  release iDUT.not_pedaling;
  $display("Test cadence decrease: Passed");
endtask

task automatic test_torque_increasing(input logic [11:0] torque_val);
  automatic logic [11:0] start_curr = curr;
  drive_torque(torque_val);
  repeat (2_500_000) @(posedge clk);
  assert (curr > start_curr)
    else $fatal("torque↑ failed: curr %0d <= start %0d", curr, start_curr);

  $display("Test torque increase: Passed");
endtask

task automatic test_torque_decreasing(input logic [11:0] torque_val);
  automatic logic [11:0] start_curr = curr;
  repeat(2_500_000) @(posedge clk); 
  drive_torque(torque_val);
  repeat (2_500_000) @(posedge clk);
  $display("curr %0d , start %0d , time %t", curr, start_curr, $realtime);
  assert (curr < start_curr + 70)
    else $fatal("torque↓ failed: curr %0d >= start %0d", curr, start_curr);
  $display("Test torque decrease: Passed");
endtask

task automatic test_brake();
  automatic logic [11:0] start_curr = curr;
  press_brake(12'h800);
  repeat (2_500_000) @(posedge clk);
  assert (curr != start_curr)
    else $fatal("brake failed: curr stuck at %0d", curr);
  
  $display("Test brake: Passed");
endtask

task automatic test_yaw_uphill(input signed [15:0] yaw_val);
  automatic logic [11:0] start_curr = curr;
  set_yaw(yaw_val);
  repeat (2_500_000) @(posedge clk);
  assert (curr > start_curr)
    else $fatal("yaw↑ failed: curr %0d <= start %0d", curr, start_curr);
  $display("Test yaw uphill: Passed");
endtask

task automatic test_yaw_downhill(input signed [15:0] yaw_val);
  automatic logic [11:0] start_curr = curr;
  set_yaw(yaw_val);
  repeat (2_500_000) @(posedge clk);
  assert (curr > start_curr)
    else $fatal("yaw decrease failed");
  
  $display("Test yaw downhill: Passed");
endtask
