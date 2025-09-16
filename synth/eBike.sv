`default_nettype none
module eBike(clk,RST_n,A2D_SS_n,A2D_MOSI,A2D_SCLK,
             A2D_MISO,hallGrn,hallYlw,hallBlu,highGrn,
			 lowGrn,highYlw,lowYlw,highBlu,lowBlu,
			 inertSS_n,inertSCLK,inertMOSI,inertMISO,
			 inertINT,cadence,TX,tgglMd,LED);
			 
  parameter FAST_SIM = 1;		// accelerate simulation by default

  input logic clk;				// 50MHz clk
  input logic RST_n;				// active low RST_n from push button
  output logic A2D_SS_n;			// Slave select to A2D on DE0
  output logic A2D_SCLK;			// SPI clock to A2D on DE0
  output logic A2D_MOSI;			// serial output to A2D (what channel to read)
  input logic A2D_MISO;			// serial input from A2D
  input logic hallGrn;			// hall position input for "Green" phase
  input logic hallYlw;			// hall position input for "Yellow" phase
  input logic hallBlu;			// hall position input for "Blue" phase
  output logic highGrn;			// high side gate drive for "Green" phase
  output logic lowGrn;			// low side gate drive for "Green" phase
  output logic highYlw;			// high side gate drive for "Yellow" phase
  output logic lowYlw;			// low side gate drive for "Yellow" phas
  output logic highBlu;			// high side gate drive for "Blue" phase
  output logic lowBlu;			// low side gate drive for "Blue" phase
  output logic inertSS_n;			// Slave select to inertial (tilt) sensor
  output logic inertSCLK;			// SCLK signal to inertial (tilt) sensor
  output logic inertMOSI;			// Serial out to inertial (tilt) sensor  
  input logic inertMISO;			// Serial in from inertial (tilt) sensor
  input logic inertINT;			// Alerts when inertial sensor has new reading
  input logic cadence;			// pulse input from pedal cadence sensor
  input logic tgglMd;				// used to select setting[1:0] (from PB switch)
  output logic TX;				// serial output of measured batt,curr,torque
  output logic [1:0] LED;			// Lower 2-bits of LED (setting) 11 => easy, 10 => medium, 01 => hard, 00 => off
  
  ////////////////////////////////////////////
  // Declare internal interconnect signals //
  //////////////////////////////////////////
  wire rst_n;									// global reset from reset_synch
  wire [11:0] torque, batt, curr, brake;		// Raw A2D results
  wire signed [12:0] error;
  wire cadence;
  wire not_pedaling;
  wire [10:0] duty;
  wire [1:0] selGrn, selYlw, selBlu;
  wire signed [12:0] incline;
  wire [11:0] drv_mag;
  wire brake_n;
  wire PWM_synch;
  wire [2:0] scale;
  
  ////////////////////////////////////////////////////////
  // Brake lever input is converted as analog, but     //
  // treated as digital (if below mid rail it is low) //
  /////////////////////////////////////////////////////
  assign brake_n = (brake<12'h800) ? 1'b0 : 1'b1;
	
  /////////////////////////////////////
  // Instantiate reset synchronizer //
  ///////////////////////////////////
  //<instantiate reset_synch>
  reset_synch reset(.clk(clk), .RST_n(RST_n), .rst_n(rst_n));
  
  ///////////////////////////////////////////////////////
  // Instantiate A2D_intf to read torque & batt level //
  /////////////////////////////////////////////////////
  //<instantiate A2D_intf>
  A2D_intf A2D (
    .clk   (clk),
    .rst_n (rst_n),
    .batt   (batt),   
    .curr   (curr),  
    .brake  (brake),  
    .torque (torque), 
    .SS_n (A2D_SS_n),   
    .SCLK (A2D_SCLK),  
    .MOSI (A2D_MOSI),  
    .MISO (A2D_MISO));

				 
  ////////////////////////////////////////////////////////////
  // Instantiate SensorCondition block to filter & average //
  // readings and provide cadence_vec, and zero_cadence   //
  /////////////////////////////////////////////////////////
  //<instantiate sensorCondition> (include FAST_SIM)
  sensorCondition #(.FAST_SIM (FAST_SIM)) u_sensorCondition (
    .clk          (clk),
    .rst_n        (rst_n),
    .torque       (torque),
    .cadence_raw  (cadence),
    .curr         (curr),
    .incline      (incline),
    .scale        (scale),
    .batt         (batt),
    .error        (error),
    .not_pedaling (not_pedaling),
    .TX           (TX));
					   
  ///////////////////////////////////////////////////
  // Instantiate PID to determine drive magnitude //
  /////////////////////////////////////////////////		   
  //<instantiate PID> (include FAST_SIM)
  PID #(.FAST_SIM (FAST_SIM)) u_PID (
    .clk          (clk),
    .rst_n        (rst_n),
    .error        (error),
    .not_pedaling (not_pedaling),
    .drv_mag      (drv_mag));

  ////////////////////////////////////////////////
  // Instantiate brushless DC motor controller //
  //////////////////////////////////////////////
  //<instantiate brushless>
  brushless u_brushless (
    .clk       (clk),
    .rst_n     (rst_n),
    .drv_mag   (drv_mag),
    .hallGrn   (hallGrn),
    .hallYlw   (hallYlw),
    .hallBlu   (hallBlu),
    .brake_n   (brake_n),
    .PWM_synch (PWM_synch),
    .duty      (duty),
    .selGrn    (selGrn),
    .selYlw    (selYlw),
    .selBlu    (selBlu));

  ///////////////////////////////
  // Instantiate motor driver //
  /////////////////////////////
  //<instantiate mtr_drv>
  mtr_drv u_mtr_drv (
    .clk       (clk),
    .rst_n     (rst_n),
    .duty      (duty),
    .PWM_synch (PWM_synch),
    .selGrn    (selGrn),
    .selYlw    (selYlw),
    .selBlu    (selBlu),
    .highGrn   (highGrn),
    .lowGrn    (lowGrn),
    .highYlw   (highYlw),
    .lowYlw    (lowYlw),
    .highBlu   (highBlu),
    .lowBlu    (lowBlu));

  /////////////////////////////////////////////////////////////
  // Instantiate inertial sensor to measure incline (pitch) //
  ///////////////////////////////////////////////////////////
  //<instantiate inert_intf>
  inert_intf u_inert (
    .clk     (clk),
    .rst_n   (rst_n),
    .INT     (inertINT),
    .SS_n    (inertSS_n),
    .SCLK    (inertSCLK),
    .MOSI    (inertMOSI),
    .MISO    (inertMISO),
    .incline (incline),
    .vld     ());            // unconnected – add a wire if needed
					
  /////////////////////////////////////////////////////////////////
  // Instantiate PB_intf block to establish setting/LED & scale //
  ///////////////////////////////////////////////////////////////
  //<instantiate PB_intf>
  PB_intf u_PB_intf (
    .clk    (clk),
    .rst_n  (rst_n),
    .tgglMd (tgglMd),
    .setting(LED),
    .scale  (scale));
endmodule
