`default_nettype none
// this module implements the cadence_meas block
module cadence_meas(clk, rst_n, cadence_filt, cadence_per, not_pedaling);

    // declare input output signals
	input logic clk, rst_n;
    input logic cadence_filt;
    output logic [7:0] cadence_per;
    output logic not_pedaling;

    // declare intermediate signals
    logic cadence_rise;
    logic capture_per;
    logic [23:0] cnt;
    logic cadence_filt_ff;
    logic cnt_third_sec;
    logic [7:0] cadence_cnt; // signal that either holds top or middle bits of cnt
	logic THIRD_SEC;

    // declare local parameters
    localparam THIRD_SEC_REAL = 24'hE4E1C0;
    localparam THIRD_SEC_FAST = 24'h007271;
    localparam THIRD_SEC_UPPER = 8'hE4;
    parameter FAST_SIM = 0;

    // generate block for THIRD_SEC based on fast sim
    generate if (FAST_SIM) begin
        assign THIRD_SEC = THIRD_SEC_FAST;
    end else begin
        assign THIRD_SEC = THIRD_SEC_REAL;
    end endgenerate

    // 24 bit counter, reset if cadence rising edge is detected
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
        end else if (cadence_rise) begin
            cnt <= 0;
        end else if (!cnt_third_sec) begin
            // increment the counter if not at third second
            // otherwise freeze the counter
            cnt <= cnt + 1;
        end
    end

    // check if the counter is at third second
    assign cnt_third_sec = (cnt == THIRD_SEC);

    // flop for cadence_filt for rise detection
    // only need one flop since cadence_filt is clock synchronized already
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            cadence_filt_ff <= 0;
        end else begin
            cadence_filt_ff <= cadence_filt;
        end
    end

    // detect rising edge of cadence_filt
    assign cadence_rise = ~cadence_filt_ff & cadence_filt;

    // capture cadence_per when cadence_rise or cnt_third_sec are high
    assign capture_per = cadence_rise | cnt_third_sec;

    // capture the top bits of counter based on FAST_SIM
    assign cadence_cnt = FAST_SIM ? cnt[23:16] : cnt[14:7];

    // cadence_per flip flop
    always_ff @(posedge clk) begin
        // synchronous reset, put cadence_per to upper bits of cnt
        if (!rst_n) begin
            cadence_per <= THIRD_SEC_UPPER;
        end else if (capture_per) begin
            cadence_per <= cadence_cnt; // place newly captured upper bits
        end
        // otherwise, cadence_per is unchanged
    end

    // not pedaling comparison
    assign not_pedaling = (cadence_per == THIRD_SEC_UPPER);

endmodule


