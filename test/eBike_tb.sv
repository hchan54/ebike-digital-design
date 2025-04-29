`default_nettype none

// module eBike_tb();
 
//   // include or import tasks?
//   import tb_tasks::*; 

//   localparam FAST_SIM = 1;		// accelerate simulation by default

//   ///////////////////////////
//   // Stimulus of type reg //
//   /////////////////////////
//   reg clk,RST_n;
//   reg [11:0] BATT;				// analog values
//   reg [11:0] BRAKE,TORQUE;		// analog values
//   reg tgglMd;					// push button for assist mode
//   reg [15:0] YAW_RT;			// models angular rate of incline (+ => uphill)


//   //////////////////////////////////////////////////
//   // Declare any internal signal to interconnect //
//   ////////////////////////////////////////////////
//   wire A2D_SS_n,A2D_MOSI,A2D_SCLK,A2D_MISO;
//   wire highGrn,lowGrn,highYlw,lowYlw,highBlu,lowBlu;
//   wire hallGrn,hallBlu,hallYlw;
//   wire inertSS_n,inertSCLK,inertMISO,inertMOSI,inertINT;
//   wire cadence;
//   logic [1:0] LED;			// hook to setting from PB_intf
  
//   wire signed [11:0] coilGY,coilYB,coilBG;
//   logic [11:0] curr;		// comes from hub_wheel_model
//   wire [11:0] BATT_TX, TORQUE_TX, CURR_TX;
//   logic vld_TX, TX_RX;
  
//   //////////////////////////////////////////////////
//   // Instantiate model of analog input circuitry //
//   ////////////////////////////////////////////////
//   AnalogModel iANLG(.clk(clk),.rst_n(RST_n),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
//                     .MISO(A2D_MISO),.MOSI(A2D_MOSI),.BATT(BATT),
// 		    .CURR(curr),.BRAKE(BRAKE),.TORQUE(TORQUE));

//   ////////////////////////////////////////////////////////////////
//   // Instantiate model inertial sensor used to measure incline //
//   //////////////////////////////////////////////////////////////
//   eBikePhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(inertSS_n),.SCLK(inertSCLK),
// 	             .MISO(inertMISO),.MOSI(inertMOSI),.INT(inertINT),
// 		     .yaw_rt(YAW_RT),.highGrn(highGrn),.lowGrn(lowGrn),
// 		     .highYlw(highYlw),.lowYlw(lowYlw),.highBlu(highBlu),
// 		     .lowBlu(lowBlu),.hallGrn(hallGrn),.hallYlw(hallYlw),
// 		     .hallBlu(hallBlu),.avg_curr(curr));

//   //////////////////////
//   // Instantiate DUT //
//   ////////////////////
//   eBike #(FAST_SIM) iDUT(.clk(clk),.RST_n(RST_n),.A2D_SS_n(A2D_SS_n),.A2D_MOSI(A2D_MOSI),
//                          .A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),.hallGrn(hallGrn),
// 			 .hallYlw(hallYlw),.hallBlu(hallBlu),.highGrn(highGrn),
// 			 .lowGrn(lowGrn),.highYlw(highYlw),.lowYlw(lowYlw),
// 			 .highBlu(highBlu),.lowBlu(lowBlu),.inertSS_n(inertSS_n),
// 			 .inertSCLK(inertSCLK),.inertMOSI(inertMOSI),
// 			 .inertMISO(inertMISO),.inertINT(inertINT),
// 			 .cadence(cadence),.tgglMd(tgglMd),.TX(TX_RX),
// 			 .LED(LED));
			 
			 
//   ////////////////////////////////////////////////////////////
//   // Instantiate UART_rcv or some other telemetry monitor? //
//   //////////////////////////////////////////////////////////

//   //////////////////////
//   // Testbench begins //
//   //////////////////////
//   logic mtr_state [6];
//   assign mtr_state = {highGrn, lowGrn, highYlw, lowYlw, highBlu, lowBlu};

//   int cadence_period;

//   initial begin
//     // Initialize all signals
//     init(clk, RST_n, tgglMd);
//     BATT = '1;
//     BRAKE = 12'h800; // Keep brake above 12'h800 so brake_n is not triggered
//     TORQUE = '0;
//     YAW_RT = '0;
    
//     // Toggle through all states to make sure they work
//     for (int i = 0; i < 4; i++) begin 
//       test_toggle_mode(clk, tgglMd, LED, omega); 
//     end

//     // for (int i = 0; i < 4; i++)
//     //     toggle(clk, tgglMd, LED);

//     // Test that the motor is not driven when the battery has a low voltage
// //    test_battery(clk, BATT, mtr_state);

//     // Test slow effort ride
// //    test_slow_ride(clk, cadence_period, BATT, BRAKE, TORQUE, YAW_RT);

// //    test_downhill(clk, cadence_period, TORQUE, YAW_RT);

//     test_triangle(clk, cadence_period, TORQUE, YAW_RT);

//     $display("Testing stopped at %t", $realtime());
//     $stop();
//   end
  
//   ///////////////////
//   // Generate clk //
//   /////////////////
//   initial begin
//     clk = 0;
//     forever #5 clk = ~clk;
//   end

//   ///////////////////////////////////////////
//   // Block for cadence signal generation? //
//   /////////////////////////////////////////
//   cadence_gen cadence_sig_gen(
//     .clk,
//     .rst_n(RST_n),
//     .cadence_period,
//     .cadence
//   );
	
// endmodule



















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
    BATT     = 12'hFFF;
    BRAKE    = 12'h800;
    TORQUE   = 12'h700;
    tgglMd   = 0;
     YAW_RT   = 0;
     clr_rdy  = 0;
     max_curr = 0;
     cadence = 0;

    // reset sequence
     reset_dut();
     press_toggle_mode();
     apply_torque(TORQUE, 12'h700);
    

  //    // hill climb
  //    set_yaw(16'sd2000);
  //    apply_torque(12'h900, 5_000_000);
  //    repeat (400) cadence_pulse;

  //    // coast-down period
  //    repeat (1_000_000) @(posedge clk);

  //    // grab some UART bytes for simple coverage
  //    repeat (16) uart_get_byte;

  //    // self-checks
  //    if (uart_cnt < 10) begin
  //      $error("UART produced only %0d byte(s)", uart_cnt);
  //      error_cnt++;
  //    end
  //    if (max_curr <= 12'h100) begin
  //      $error("Motor current never exceeded 0x100 (peak 0x%0h)", max_curr);
  //      error_cnt++;
  //    end
  //    if (curr >= 12'h050) begin
  //      $error("Motor current still 0x%0h after coast-down", curr);
  //      error_cnt++;
  //    end

  //    if (error_cnt == 0)
  //      $display("ALL CHECKS PASS");
  //    else
  //      $fatal(1, "%0d CHECK(S) FAILED", error_cnt);

   end
  
//   ///////////////////
//   // Generate clk //
//   /////////////////
   always #10 clk = ~clk;

   ///////////////////////////////////////////
   // Block for cadence signal generation? //
   /////////////////////////////////////////
   initial
     forever begin
         cadence = 1'b1;
         repeat (HI_CYCLES) @(posedge clk);
         cadence = 1'b0;
         repeat (LO_CYCLES) @(posedge clk);
     end

 endmodule
