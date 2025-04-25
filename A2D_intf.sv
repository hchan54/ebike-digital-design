`default_nettype none
// Group: The Timing Violators
// Members: Jake Yun, Hunter Chan, Eddie Lin, Paul Avioli
// this module implements the A2D interface using SPI
module A2D_intf(clk, rst_n, batt, curr, brake, torque, SS_n, SCLK, MOSI, MISO);

    // declare input and output signals
    input logic clk, rst_n, MISO;
    output logic SS_n, SCLK, MOSI;
    output logic [11:0]batt, curr, brake, torque;

    // declare intermediate signals
    logic [2:0]channel; // there are channels 0,1,3,4
    logic [13:0]cnt; // 14 bit counter
    logic start; // start a conversion
    logic cnv_cmplt; // conversion complete

    // SPI transaction signals
    logic snd, done;
    logic [15:0] cmd, resp;

    // enables for each channel
    logic en_batt, en_curr, en_brake, en_torque;

    // create enum for conversion states
	typedef enum reg [1:0] {IDLE, SND, WAIT, RECEIVE} state_t;
    state_t state, nxt_state;

    // instantiate the SPI instance
    SPI_mnrch SPI_inst(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .snd(snd), .cmd(cmd), .done(done), .resp(resp));

    // state machine reset is IDLE state
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) state <= IDLE;
		else state <= nxt_state;
	end

    // state machine transition logic
    always_comb begin
        // default outputs
        snd = 0;
        en_batt = 0;
        en_curr = 0;
        en_brake = 0;
        en_torque = 0;
        cnv_cmplt = 0;
        nxt_state = state;

        case(state)
            // once the transaction is complete, move to wait state
            SND:
                if (done) begin
                    nxt_state = WAIT;
                end
            // wait for one clock
            WAIT: begin
                snd = 1;
                nxt_state = RECEIVE;
            end
            // conversion is complete, set the enable signals and move to idle
            RECEIVE:
                if (done) begin
                    // set the enable signals
                    en_batt = (channel == 3'b000);
                    en_curr = (channel == 3'b001);
                    en_brake = (channel == 3'b011);
                    en_torque = (channel == 3'b100);

                    cnv_cmplt = 1;
                    nxt_state = IDLE;

                end
            // this is the idle state
            default:
                if (start) begin
                    // start the conversion
                    snd = 1;
                    nxt_state = SND;
                end
        endcase
    end

    // always block for channel selection
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            channel <= 0;
        else if (cnv_cmplt) begin
            // increment the channel accordingly for the next conversion
            case(channel)
					3'b000: channel <= 3'b001;
					3'b001: channel <= 3'b011;
					3'b011: channel <= 3'b100;
					3'b100: channel <= 3'b000;
					default: channel <= 3'b000;
			endcase
		end
    end

    // assign the cmd to the concatenation of channel and padding
    assign cmd = {2'b00, channel, 11'h000};


    // always block for 14 bit counter
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            cnt <= 0;
        else 
            cnt <= cnt + 1;
    end

    // start a round of conversions when counter overflows
    assign start = &cnt;

    // flip flop for the battery
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            batt <= 0;
        else if (en_batt) 
            batt <= resp[11:0];
    end

    // flip flop for the current
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            curr <= 0;
        else if (en_curr) 
            curr <= resp[11:0];
    end

    // flip flop for the brake
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            brake <= 0;
        else if (en_brake) 
            brake <= resp[11:0];
    end

     // flip flop for the torque
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            torque <= 0;
        else if (en_torque) 
            torque <= resp[11:0];
    end

endmodule
