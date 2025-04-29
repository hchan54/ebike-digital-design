`timescale 1ns/1ps

module eBike_tb();
 
  // include or import tasks?

  localparam FAST_SIM = 1;        // accelerate simulation by default

  ///////////////////////////
  // Stimulus of type reg //
  /////////////////////////
  reg clk,RST_n;
  reg [11:0] BATT;               // analog values
  reg [11:0] BRAKE,TORQUE;       // analog values
  reg tgglMd;                    // push button for assist mode
  reg [15:0] YAW_RT;             // models angular rate of incline (+ => uphill)


  //////////////////////////////////////////////////
  // Declare any internal signal to interconnect //
  ////////////////////////////////////////////////
  wire A2D_SS_n,A2D_MOSI,A2D_SCLK,A2D_MISO;
  wire highGrn,lowGrn,highYlw,lowYlw,highBlu,lowBlu;
  wire hallGrn,hallBlu,hallYlw;
  wire inertSS_n,inertSCLK,inertMISO,inertMOSI,inertINT;
  logic cadence;                 // changed to logic so TB can drive it
  wire [1:0] LED;                // hook to setting from PB_intf
  
  wire signed [11:0] coilGY,coilYB,coilBG;
  logic [11:0] curr;             // comes from hub_wheel_model
  wire [11:0] BATT_TX, TORQUE_TX, CURR_TX;
  logic vld_TX;

  // additional monitoring / checking signals
  wire TX_RX;
  wire rdy;
  logic clr_rdy;
  logic [7:0] rx_data;
  int   error_cnt = 0;
  int   uart_cnt  = 0;
  reg [11:0] max_curr;

  //////////////////////////////////////////////////
  // Instantiate model of analog input circuitry //
  ////////////////////////////////////////////////
  AnalogModel iANLG(.clk(clk),.rst_n(RST_n),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
                    .MISO(A2D_MISO),.MOSI(A2D_MOSI),.BATT(BATT),
                    .CURR(curr),.BRAKE(BRAKE),.TORQUE(TORQUE));

  ////////////////////////////////////////////////////////////////
  // Instantiate model inertial sensor used to measure incline //
  //////////////////////////////////////////////////////////////
  eBikePhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(inertSS_n),.SCLK(inertSCLK),
                     .MISO(inertMISO),.MOSI(inertMOSI),.INT(inertINT),
                     .yaw_rt(YAW_RT),.highGrn(highGrn),.lowGrn(lowGrn),
                     .highYlw(highYlw),.lowYlw(lowYlw),.highBlu(highBlu),
                     .lowBlu(lowBlu),.hallGrn(hallGrn),.hallYlw(hallYlw),
                     .hallBlu(hallBlu),.avg_curr(curr));

  //////////////////////
  // Instantiate DUT //
  ////////////////////
  eBike #(FAST_SIM) iDUT(.clk(clk),.RST_n(RST_n),.A2D_SS_n(A2D_SS_n),.A2D_MOSI(A2D_MOSI),
                         .A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),.hallGrn(hallGrn),
                         .hallYlw(hallYlw),.hallBlu(hallBlu),.highGrn(highGrn),
                         .lowGrn(lowGrn),.highYlw(highYlw),.lowYlw(lowYlw),
                         .highBlu(highBlu),.lowBlu(lowBlu),.inertSS_n(inertSS_n),
                         .inertSCLK(inertSCLK),.inertMOSI(inertMOSI),
                         .inertMISO(inertMISO),.inertINT(inertINT),
                         .cadence(cadence),.tgglMd(tgglMd),.TX(TX_RX),
                         .LED(LED));
                         
  ////////////////////////////////////////////////////////////
  // Instantiate UART_rcv or some other telemetry monitor? //
  //////////////////////////////////////////////////////////
  UART_rcv u_uartRCV(.clk(clk), .rst_n(RST_n), .RX(TX_RX), .rdy(rdy), .rx_data(rx_data), .clr_rdy(clr_rdy));

  `include "tb_tasks.sv"

  initial begin
  
    clk      = 0;
    RST_n    = 0;
    BATT     = 12'd3000;
    BRAKE    = 0;
    TORQUE   = 0;
    tgglMd   = 0;
    YAW_RT   = 0;
    clr_rdy  = 0;
    max_curr = 0;
    cadence = 0;

    // reset sequence
    reset_dut();
    press_toggle_mode();

    // apply torque and cadence pulses
    apply_torque(12'h500, 3_000_000);
    repeat (240) cadence_pulse;

    // hill climb
    set_yaw(16'sd2000);
    apply_torque(12'h900, 5_000_000);
    repeat (400) cadence_pulse;

    // coast-down period
    repeat (1_000_000) @(posedge clk);

    // grab some UART bytes for simple coverage
    repeat (16) uart_get_byte;

    // self-checks
    if (uart_cnt < 10) begin
      $error("UART produced only %0d byte(s)", uart_cnt);
      error_cnt++;
    end
    if (max_curr <= 12'h100) begin
      $error("Motor current never exceeded 0x100 (peak 0x%0h)", max_curr);
      error_cnt++;
    end
    if (curr >= 12'h050) begin
      $error("Motor current still 0x%0h after coast-down", curr);
      error_cnt++;
    end

    if (error_cnt == 0)
      $display("ALL CHECKS PASS");
    else
      $fatal(1, "%0d CHECK(S) FAILED", error_cnt);

    $stop;
  end
  
  ///////////////////
  // Generate clk //
  /////////////////
  always #10 clk = ~clk;

  ///////////////////////////////////////////
  // Block for cadence signal generation? //
  /////////////////////////////////////////

endmodule
