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

// stabalize the signals
task stablize_dut();
  BATT       = 12'hFFF;
  BRAKE      = 12'h800;
endtask

// Set the cadence‑toggle period (in clock cycles)
task drive_cadence(input int cycles);
  num_cycles = FAST_SIM ? (cycles/10) : cycles;
endtask

// Drive a specific torque value into TORQUE
task drive_torque(input logic [11:0] torque_val);
  TORQUE = torque_val;
endtask

// Apply the brake
task press_brake(input logic [11:0] brake_val);
  BRAKE = brake_val;
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

// testing the cadence increasing, we expect curr to be greater than the starting curr. Starting curr is curr before we wait and set the cadence
task automatic test_cadence_increasing(input int cycles);
  automatic logic [11:0] start_curr = curr;
  drive_cadence(cycles);
  repeat (2_500_000) @(posedge clk);
  assert (curr > start_curr + 500)
    else $fatal("cadence up failed: curr %0d <= start %0d", curr, start_curr);
  $display("time %0t  curr %0d <= start %0d", $realtime, curr, start_curr);
  $display("Test cadence increase: Passed");
endtask

// testing the cadence decreasing, which when cadence is low enough not pedaling will assert causing error to be 0 so we test error
task automatic test_not_pedaling();
  force iDUT.u_sensorCondition.not_pedaling = 1'b1;
  repeat (2_500_000) @(posedge clk);

  assert (iDUT.u_sensorCondition.error === 0)
    else $fatal("cadence low failed: error is not 0");
  
  release iDUT.u_sensorCondition.not_pedaling;
  $display("Test cadence decrease: Passed");
endtask

// tests torque when it increases we expect the current curr to be way larger than the starting curr
task automatic test_torque_increasing(input logic [11:0] torque_val);
  automatic logic [11:0] start_curr = curr;
  drive_torque(torque_val);
  repeat (2_500_000) @(posedge clk);
  assert (curr > start_curr + 2000) else begin
    $fatal("torque increase failed: curr %0d <= start %0d", curr, start_curr);
  end
  
  $display("time %0t  curr %0d <= start %0d", $realtime, curr, start_curr);
  $display("Test torque increase: Passed");
endtask

// tests torque when it decreases we expect the current curr to be way less than the starting curr
task automatic test_torque_decreasing(input logic [11:0] torque_val);
  automatic logic [11:0] start_curr = curr;
  repeat(2_500_000) @(posedge clk); 
  drive_torque(torque_val);
  repeat (2_500_000) @(posedge clk);
  assert (curr < start_curr - 2500) else begin
    $fatal("torque down failed: curr %0d >= start %0d", curr, start_curr);
  end

  $display("time %0t  curr %0d <= start %0d", $realtime, curr, start_curr);
  $display("Test torque decrease: Passed");
endtask

// testing the brake when we test brake, the expected behavior is that the current curr is going to be less then the starting one
task automatic test_brake();
  automatic logic [11:0] start_curr = curr;
  press_brake(12'h000);
  repeat (2_500_000) @(posedge clk);
  assert (curr < start_curr - 150) else begin
    $fatal("brake failed: curr stuck at %0d", curr);
  end
  
  $display("time %0t  curr %0d <= start %0d", $realtime, curr, start_curr);
  $display("Test brake: Passed");
endtask

// testing when yaw is high or uphill, we expect the current curr to be larger than the starting curr
task automatic test_yaw_uphill(input signed [15:0] yaw_val);
  automatic logic [11:0] start_curr = curr;
  set_yaw(yaw_val);
  repeat (2_500_000) @(posedge clk);
  assert (curr > start_curr)
    else $fatal("yaw up failed: curr %0d <= start %0d", curr, start_curr);
  
  $display("time %0t  curr %0d <= start %0d", $realtime, curr, start_curr);
  $display("Test yaw uphill: Passed");
endtask

// testing when yaw is low or downhill, we expect the current curr to be less than the starting curr
task automatic test_yaw_downhill(input signed [15:0] yaw_val);
  automatic logic [11:0] start_curr = curr;
  set_yaw(yaw_val);
  repeat (2_500_000) @(posedge clk);
  assert (curr < start_curr)
    else $fatal("yaw down failed: curr %0d >= start %0d", curr, start_curr);
  
  $display("time %0t  curr %0d <= start %0d", $realtime, curr, start_curr);
  $display("Test yaw downhill: Passed");
endtask

// testing when the battery is below threshold, we expect error to be zero
task test_battery_below_thres(input logic [11:0] battery);
  BATT = battery;
  repeat (2_500_000) @(posedge clk);
  assert(iDUT.u_sensorCondition.error === 0) else begin
    $fatal("Test BATT Low: Failed");
  end

  $display("Test BATT Low: Passed");
endtask
