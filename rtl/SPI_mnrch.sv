`default_nettype none
module spi_mnrch(clk, rst_n, SS_n, SCLK, MOSI, MISO, snd, cmd, done, resp);
    
    input logic clk, rst_n, MISO, snd;
    input logic [15:0] cmd;
    output logic SS_n, SCLK, MOSI, done;
    output logic [15:0] resp;

    logic [4:0] SCLK_div, bit_cntr; 

    logic [15:0] shft_reg;  //Shift register

    logic init, shft, ld_SCLK, full, done16, set_done;   //SM signals
     
    typedef enum reg [1:0] {IDLE, SHFT, DONE} state_t;  //Machine has an idle state, a state for shifting all the bits, then the done state

    state_t state, nxt_state;

    always_ff @(posedge clk, negedge rst_n) begin   //State transition sequential logic
        if(!rst_n) begin
            state <= IDLE;
        end
        else begin
            state <= nxt_state;
        end
    end

    always_comb begin
        ld_SCLK = 1'b0;
        init = 1'b0;
        set_done = 1'b0;
        nxt_state = state;
        case (state)
            SHFT:   //State where we wait until all shifting has been done
            if (done16) begin
                nxt_state = DONE;
            end

            DONE:       //State after shifting in 16 bits, waiting for SCLK_div to be full to move on
            if (full) begin
                set_done = 1'b1;
                nxt_state = IDLE;
				ld_SCLK = 1'b1;
            end
            
            default:    //Starting state where we wait for snd to be asserted to begin transaction
            if (snd) begin
                init = 1'b1;
                nxt_state = SHFT;
            end
            else 
                ld_SCLK = 1'b1;
        endcase
    end

    always_ff @(posedge clk, negedge rst_n) begin   //SS_n flop
        if(!rst_n) begin    //Presetting SS_n on reset
            SS_n <= 1'b1;
        end
        else if (init) begin    //When the transaction starts, setting SS_n low
            SS_n <= 1'b0;
        end
        else if (set_done)begin  //Setting SS_n back high when transaction finishes
            SS_n <= 1'b1;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin   //done flop
        if(!rst_n) begin   
            done <= 1'b0;
        end
        else if(init) begin //If a new transaction starts resetting done
            done <= 1'b0;
        end
        else if (set_done) begin  //Setting done high when transaction finishes
            done <= 1'b1;
        end
    end

    always_comb begin
        resp = shft_reg;
        SCLK = SCLK_div[4];
        MOSI = shft_reg[15];
        full = &SCLK_div;    //Full if every bit is a 1
        
        shft = (SCLK_div == 5'b10001) ? 1'b1 : 1'b0;    //shifting if SCLK_div is 10001

        done16 = bit_cntr[4]; //Asserting done16 if we've shifted out all bits 
        
    end

    always_ff @(posedge clk, negedge rst_n) begin  //Shift register
        if (!rst_n) begin
            shft_reg <= 16'b0;
        end
        else if(init) begin
            shft_reg <= cmd;
        end
        else if(shft) begin
            shft_reg <= {shft_reg[14:0],MISO};
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin   //SCLK_div counter flop
        if (!rst_n) begin
            SCLK_div <= 5'b0;
        end
        else if (ld_SCLK) begin
            SCLK_div <= 5'b10111;
        end
        else begin
            SCLK_div <= SCLK_div+1;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin   //Bits shifted counter
        if(!rst_n) begin
            bit_cntr <= 5'b0;
        end
        else if (init) begin
            bit_cntr <= 5'b0;
        end
        else if (shft) begin
            bit_cntr <= bit_cntr + 1;
        end
    end

endmodule
