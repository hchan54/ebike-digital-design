`default_nettype none
module cadence_filt(clk, rst_n, cadence, cadence_filt, cadence_rise);
    parameter FAST_SIM = 1'b1;
    input logic clk, rst_n, cadence;
    output logic cadence_filt, cadence_rise;

    //16 bit counter and counter flop input
    logic [15:0] stbl_cnt, stbl_cnt1, cnt_flop_in;
    logic stbl_cnt_full;
    logic meta1, meta2, flop3_out, chngd_n, cadence_filt_in;

    //The first two metastability flops
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            meta1 <= 1'b0;
            meta2 <= 1'b0;
        end
        else begin
            meta1 <= cadence;
            meta2 <= meta1;
        end
    end

    //The third flop
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            flop3_out <= 1'b0;
        end
        else begin
            flop3_out <= meta2;
        end
    end

    always_comb begin
        //Asserting cadence_rise and chngd_n
        chngd_n = flop3_out ~^ meta2;
        cadence_rise = ~flop3_out & meta2;

        stbl_cnt1 = stbl_cnt + 16'd1;   //Incrementing clock

        //The input to the counter flop
        cnt_flop_in = stbl_cnt1 & {16{chngd_n}};

        //Determining input to cadence_filt flop
        cadence_filt_in = (stbl_cnt_full) ? (flop3_out) : (cadence_filt);
    end
    
    //Flop that asserts the count
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            stbl_cnt <= 16'b0;
        end
        else begin
        stbl_cnt <= cnt_flop_in;    //Flop input/output
        end
    end

    //Flip flop that asserts cadence_filt
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            cadence_filt <= 1'b0;
        end
        else begin
            cadence_filt <= cadence_filt_in;
        end
    end
    
    generate if (FAST_SIM) begin
        assign stbl_cnt_full = &stbl_cnt[8:0];
    end else begin
        assign stbl_cnt_full = &stbl_cnt;
    end
    endgenerate
endmodule
