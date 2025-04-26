`default_nettype none

module desiredDrive(avg_torque, cadence, not_pedaling, incline, scale, target_curr);

    input logic [11:0] avg_torque;
    input logic [4:0] cadence;
    input logic [12:0] incline;
    input logic [2:0] scale;
    input logic not_pedaling;

    output logic [11:0] target_curr;

    // saturating incline signal down
    logic[9:0] incline_sat;
    assign incline_sat = (incline[12] && (~&incline[11:9])) ? 10'b10_0000_0000 :
                        (~incline[12] && (|incline[11:9])) ? 10'b01_1111_1111 :
                        incline[9:0];

    // create new vairble and sign extend it
    // new signal should be incline_sat + 256
    logic signed [10:0] incline_factor;
    assign incline_factor = {incline_sat[9], incline_sat} + 11'd256;


    logic [8:0] incline_lim;
    assign incline_lim = (incline_factor[10]) ? 9'h000 :  // If negative, clip to 0
                        (incline_factor > 9'd511) ? 9'd511 :  // If > 511, saturate to 511
                         incline_factor[8:0];  // Otherwise, keep valid range

    // if cadence > 1 add 32 to it, else just set it to zero
    logic[5:0] cadence_factor;
    assign cadence_factor = (cadence > 5'd1) ? cadence + 6'd32 :
                            6'h00;

    // create signals to store the results
    logic[12:0] torque_off;
    logic[11:0] TORQUE_MIN = 12'h380;
    assign torque_off = {1'b0, avg_torque} - {1'b0, TORQUE_MIN}; // sign extend both avg_torque and TORQUE_MIN so that it can result in a neg number
                                                                 // so we zero extend the two signals

    // create new signal called torque_pos that is N-1 of torque off
    // if torque off is negative set it to zero otherwise set it to the lower N-1 bits of torque off
    logic[11:0] torque_pos;
    assign torque_pos = (torque_off[12]) ? 11'd0 : torque_off[11:0];


    //TODO: OPTIMIZE
    
    // assign assist_prod to be the product of torque_pos, incline_lim, cadence_factor, and scale
    // it should be 30 becasue the length of torque_pos + incline_lim + cadence_factor + scale is 30 bits long
    logic[29:0] assist_prod;
    assign assist_prod = (not_pedaling) ? 30'd0 :
                        torque_pos * incline_lim * cadence_factor * scale;

    // assign target curr to 12'bFFF if any bits from 29 to 27 are set, other wise set it to assit_prod bits 26 to 15
    assign target_curr = (|assist_prod[29:27]) ? 12'hFFF :
                        assist_prod[26:15];

endmodule
