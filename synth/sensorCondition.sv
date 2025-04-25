`default_nettype none
module sensorCondition(clk, rst_n, torque, cadence_raw, curr, incline, scale, batt, error, not_pedaling, TX);
    input logic clk, rst_n, cadence_raw;
    input logic [11:0] torque, curr, batt;
    input logic [12:0] incline;
    input logic [2:0] scale;
    output logic not_pedaling, TX;
    output logic [12:0] error;

    parameter FAST_SIM = 1'b0;

    logic cadence_filt, cadence_rise;
    logic [7:0] cadence_per;
    logic [4:0] cadence;

    logic [21:0] cnt;                           //Counter to count 2^22 clocks
    logic [13:0] accum_curr;                    //accum curr is 2 bits larger than samples, so 14 bits
    logic [15:0] currMult;                  
    logic [16:0] accum_torque;                  //accum torque is 5 bits larger than sample
    logic [22:0] torqueMult;

    logic [13:0] muxInCurr, muxOutCurr;         //Same bits wide as accum curr
    logic [16:0] muxInTorque, muxOutTorque;     //same bits wide as accum torque

    logic cnt_full;
    logic [11:0] avg_curr, avg_torque;

    localparam LOW_BATT_THRES = 12'hA98;

    logic pedaling_resumes;     //Asserted if a falling edge on not_pedaling
    logic pedalingflop1out, pedalingflop2out;      //Intermediate flop signals for not_pedaling edge detection
    logic [11:0] target_curr;
    
    //Instantiating cadence duts
    cadence_filt #(.FAST_SIM (FAST_SIM)) cadence1(.clk(clk), .rst_n(rst_n), .cadence(cadence_raw), .cadence_filt(cadence_filt), .cadence_rise(cadence_rise));
    cadence_meas meas1(.clk(clk), .rst_n(rst_n), .cadence_filt(cadence_filt), .cadence_per(cadence_per), .not_pedaling(not_pedaling));
    cadence_LU LU1(.cadence_per(cadence_per), .cadence(cadence));
    desiredDrive drive1(.avg_torque(avg_torque), .cadence(cadence), .not_pedaling(not_pedaling), .incline(incline), .scale(scale), .target_curr(target_curr));
    telemetry uart1 (.batt_v(batt), .avg_curr(avg_curr), .avg_torque(avg_torque), .clk(clk), .rst_n(rst_n), .TX(TX));
    
    always_comb begin
        pedaling_resumes = ~pedalingflop1out & pedalingflop2out; //Negative edge detecting
        //exponential average for curr
        currMult = accum_curr * 3;
        muxInCurr = (currMult[15:2]) + curr;  //Input to mux
        muxOutCurr = (cnt_full) ? (muxInCurr) : (accum_curr);    //Choosing new sample or old accum based on include_smpl
        avg_curr = accum_curr[13:2];

        //exponential average for torque
        torqueMult = accum_torque * 31;
        muxInTorque = (torqueMult[22:5]) + torque;  //Input to mux
        muxOutTorque = (pedaling_resumes) ? ({1'b0, torque, 4'h0}) :    //If pedaling resumes, putting base value
        ((cadence_rise) ? (muxInTorque) : (accum_torque));    //Choosing new sample or old accum based on cadence rise
        avg_torque = accum_torque[16:5];

        // set the error equal to target_curr - avg_curr, sign extend to 13 bits
        // if battery < LOW_BATT_THRES, set error to 0
        // if not_pedaling, set error to 0
        error = ((batt < LOW_BATT_THRES) || (not_pedaling)) ? 13'b0 : {target_curr[11], target_curr} - {avg_curr[11], avg_curr};

    end
    
    
    //not_pedaling falling edge detector flops
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            pedalingflop1out <= 1'b0;
            pedalingflop2out <= 1'b0;
        end
        else begin
            pedalingflop1out <= not_pedaling;
            pedalingflop2out <= pedalingflop1out;
        end
    end
    //Accum flop for current
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            accum_curr <= 14'b0;
        end
        else begin
            accum_curr <= muxOutCurr;
        end
    end

    //Accum flop for torque
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            accum_torque <= 17'b0;
        end
        else begin
            accum_torque <= muxOutTorque;
        end
    end

    generate if (FAST_SIM) begin
            assign cnt_full = &cnt[15:0];
        end else begin
            assign cnt_full = &cnt;
        end
    endgenerate

    //Counter flop
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            cnt <= 22'b0;
        end
        else begin
            cnt <= cnt+1;
        end
    end

endmodule
