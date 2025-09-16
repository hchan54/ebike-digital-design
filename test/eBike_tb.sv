`timescale 1ns/1ps
`default_nettype none

module eBike_tb;
  localparam FAST_SIM = 1;

  //----------------------------------------------------------------------//
  // SIGNALS                                                               //
  //----------------------------------------------------------------------//
  reg            clk;
  reg            RST_n;
  reg  [11:0]    BATT, BRAKE, TORQUE;
  reg            tgglMd;
  reg  signed [15:0] YAW_RT;
  logic [31:0]   num_cycles;

  wire           A2D_SS_n, A2D_MOSI, A2D_SCLK, A2D_MISO;
  wire           highGrn, lowGrn, highYlw, lowYlw, highBlu, lowBlu;
  wire           hallGrn, hallYlw, hallBlu;
  wire           inertSS_n, inertSCLK, inertMISO, inertMOSI, inertINT;
  logic          cadence;
  wire  [1:0]    LED;
  reg   [11:0]   curr;
  wire  [11:0]   BATT_TX, TORQUE_TX, CURR_TX;
  logic          vld_TX, TX_RX;


  //----------------------------------------------------------------------//
  // BRING IN TASKS                                                         //
  //----------------------------------------------------------------------//
  `include "tb_tasks.sv"

  //----------------------------------------------------------------------//
  // ANALOG & INERTIAL MODELS                                              //
  //----------------------------------------------------------------------//
  AnalogModel iANLG (
    .clk(clk), .rst_n(RST_n),
    .SS_n(A2D_SS_n), .SCLK(A2D_SCLK),
    .MISO(A2D_MISO), .MOSI(A2D_MOSI),
    .BATT(BATT),     .CURR(curr),
    .BRAKE(BRAKE),   .TORQUE(TORQUE)
  );

  eBikePhysics iPHYS (
    .clk(clk),        .RST_n(RST_n),
    .SS_n(inertSS_n), .SCLK(inertSCLK),
    .MISO(inertMISO),.MOSI(inertMOSI),
    .INT(inertINT),   .yaw_rt(YAW_RT),
    .highGrn(highGrn),.lowGrn(lowGrn),
    .highYlw(highYlw),.lowYlw(lowYlw),
    .highBlu(highBlu),.lowBlu(lowBlu),
    .hallGrn(hallGrn),.hallYlw(hallYlw),
    .hallBlu(hallBlu),.avg_curr(curr)
  );

  //----------------------------------------------------------------------//
  // DUT                                                                  //
  //----------------------------------------------------------------------//
  eBike #(FAST_SIM) iDUT (
    .clk       (clk),      .RST_n    (RST_n),
    .A2D_SS_n  (A2D_SS_n), .A2D_MOSI (A2D_MOSI),
    .A2D_SCLK  (A2D_SCLK), .A2D_MISO (A2D_MISO),
    .hallGrn   (hallGrn),  .hallYlw  (hallYlw),
    .hallBlu   (hallBlu),  .highGrn  (highGrn),
    .lowGrn    (lowGrn),   .highYlw  (highYlw),
    .lowYlw    (lowYlw),   .highBlu  (highBlu),
    .lowBlu    (lowBlu),   .inertSS_n(inertSS_n),
    .inertSCLK (inertSCLK),.inertMOSI(inertMOSI),
    .inertMISO (inertMISO),.inertINT (inertINT),
    .cadence   (cadence),  .tgglMd   (tgglMd),
    .TX        (TX_RX),    .LED      (LED)
  );

  //----------------------------------------------------------------------//
  // TEST SEQUENCE                                                        //
  //----------------------------------------------------------------------//
  initial begin
    clk = 0;
    
    $display("Starting test sequence...");
    // set all the initial values
    // reset dut just sets all the initial values
    reset_dut();
    drive_cadence(50_000);
    drive_torque (12'h700);
    repeat (500_000) @(posedge clk);

    // tests when cadence increases
    test_cadence_increasing(50_000);

    // tests when not pedaling is asserted, no cadence rise detected
    test_not_pedaling();

    // tests when torque increases
    drive_cadence(50_000);
    repeat (500_000) @(posedge clk);
    test_torque_increasing(12'hEEE);

    // tests when torque decreases
    repeat (500_000) @(posedge clk);
    test_torque_decreasing(12'h001);

    // tests when we press the brake
    press_brake(12'h000);
    repeat (500_000) @(posedge clk);
    test_brake();

    // stabalize the signals instead of waiting forever then test the uphill yaw rate
    stablize_dut();
    drive_cadence(50_000);
    drive_torque (12'h700);
    repeat (500_000) @(posedge clk);
    test_yaw_uphill(15_000);

    // tests the downhill yaw rate
    repeat (5_000_000) @(posedge clk);
    test_yaw_downhill(-3_000);

    // tests when the battery is below threshold
    repeat (10_000)@(posedge clk);
    test_battery_below_thres(0);

    $display("All tests passed!");
    $stop;
  end

  //----------------------------------------------------------------------//
  // CLOCK & CADENCE GENERATORS                                           //
  //----------------------------------------------------------------------//
  always #10 clk = ~clk;

  always begin
      cadence = 1'b1;
      repeat (num_cycles) @(posedge clk);
      cadence = 1'b0;
      repeat (num_cycles) @(posedge clk);
  end

endmodule

