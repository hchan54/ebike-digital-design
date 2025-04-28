`default_nettype none 

// this module initalizes the gyroscope through SPI communication and reads it's data to determine the 
// current pitch, yaw, orientation, etc  
module inert_intf(clk, rst_n, INT, SS_n, SCLK, MOSI, MISO, incline, vld);
     
    input logic clk, rst_n;  
    input logic MISO, INT; // INT indicates change in IMU data
    output logic SS_n, SCLK, MOSI, vld; 
    output logic [12:0] incline; // incline reading

    // SPI signals 
    logic snd, done; // cmds for SPI mnrch
    logic [15:0] resp; // 8 bit response from IMU 
    logic [15:0] cmd; // determine which read/write operation 

    // inertial integrator signals
    logic [15:0] roll_rt, yaw_rt, AY, AZ; // AY and yaw are pitch other two are for rotation
    logic [7:0] LED; // negligible 
    logic spi_vld, spi1_vld, spi2_vld; // spi transaction is complete  

    logic prev_done; // avoid using wait state in fsm
    logic done_edge; 

    // flopped signals to prevent setup time violations
    logic [15:0] next_cmd;
    logic next_snd; 

    // instantiate SPI 
    SPI_mnrch SPI(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .snd(snd), .cmd(cmd), .done(done), .resp(resp));

    // instantate inertial integrator 
    inertial_integrator integrator(.clk(clk), .rst_n(rst_n), .vld(spi_vld), .roll_rt(roll_rt) , .yaw_rt(yaw_rt) , .AY(AY) , .AZ(AZ), .incline(incline), .LED(LED));

    typedef enum logic [3:0] {INIT1, INIT2, INIT3, INIT4, INIT5, ROLL_L, ROLL_H, YAW_L, YAW_H, AY_L, AY_H, AZ_L, AZ_H} state_t; // states
    state_t next_state, state; 

    logic C_R_H, C_R_L, C_Y_H, C_Y_L, C_AY_H, C_AY_L, C_AZ_H, C_AZ_L; // enables for the registers
    logic [7:0] H_Roll_ff, L_Roll_ff, H_Yaw_ff, L_Yaw_ff, H_AY_ff, L_AY_ff, H_AZ_ff, L_AZ_ff; // 8 bit holding reg
    
    logic int_ff1, int_ff2; // synchronize INT
    logic [15:0] timer; // timer to begin imu initialization

    // synchronize the INT input
    always_ff @(posedge clk, negedge rst_n) begin  
        if (!rst_n) begin
            int_ff1 <= 0;
            int_ff2 <= 0;
        end else begin 
            int_ff1 <= INT; 
            int_ff2 <= int_ff1;
        end
    end

    // timer to begin gyroscope/accelerometer initialization
    always_ff @(posedge clk, negedge rst_n) begin 
        if (!rst_n) 
            timer <= 0;
        else 
            timer <= timer + 1'b1;
    end

    /** Holding Registers **/

    // holding register for Roll High
    always_ff @(posedge clk, negedge rst_n) begin 
        if (!rst_n)
            H_Roll_ff <= 0;
        else if (C_R_H) 
            H_Roll_ff <= resp[7:0];
    end 
    
    // holding register for Roll Low
    always_ff @(posedge clk, negedge rst_n) begin 
        if (!rst_n)
            L_Roll_ff <= 0;
        else if (C_R_L) 
            L_Roll_ff <= resp[7:0];
    end 
    
    // holding register for Yaw High 
    always_ff @(posedge clk, negedge rst_n) begin 
        if (!rst_n)
            H_Yaw_ff <= 0;
        else if (C_Y_H) 
            H_Yaw_ff <= resp[7:0];
    end 

    // holding register for Yaw Low
    always_ff @(posedge clk, negedge rst_n) begin 
        if (!rst_n)
            L_Yaw_ff <= 0;
        else if (C_Y_L) 
            L_Yaw_ff <= resp[7:0];
    end 

    // holding register for AY High
    always_ff @(posedge clk, negedge rst_n) begin 
        if (!rst_n) 
            H_AY_ff <= 0;
        else if (C_AY_H) 
            H_AY_ff <= resp[7:0];
    end 

    // holding register for AY Low 
    always_ff @(posedge clk, negedge rst_n) begin 
        if (!rst_n) 
            L_AY_ff <= 0;
        else if (C_AY_L) 
            L_AY_ff <= resp[7:0];
    end 

    // holding register for AZ High
    always_ff @(posedge clk, negedge rst_n) begin 
        if (!rst_n) 
            H_AZ_ff <= 0;
        else if (C_AZ_H) 
            H_AZ_ff <= resp[7:0];
    end 

    // holding register for AZ Low 
    always_ff @(posedge clk, negedge rst_n) begin 
        if (!rst_n) 
            L_AZ_ff <= 0;
        else if (C_AZ_L) 
            L_AZ_ff <= resp[7:0];
    end 

    /** End of Holding Registers **/

    // flop the previous done
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            prev_done <= 0;
        else 
            prev_done <= done;
    end

    assign done_edge = done & ~prev_done; // change detection logic

    // avoid overlapping done and send signal
    always_ff @(posedge clk, negedge rst_n) begin 
        if (!rst_n) begin
            snd <= 1'b0;
            cmd <= 16'h0000;
        end else begin
            snd <= next_snd;
            cmd <= next_cmd;
        end
    end

    // combine holding registers for valid output
    always_comb begin 
        roll_rt = {H_Roll_ff, L_Roll_ff};
        yaw_rt = {H_Yaw_ff, L_Yaw_ff};
        AY = {H_AY_ff, L_AY_ff};
        AZ = {H_AZ_ff, L_AZ_ff};
    end

    // delay drive to valid signal 
    always_ff @(posedge clk, negedge rst_n) begin 
        if (!rst_n) begin
            spi1_vld <= 0;
            spi2_vld <= 0;
        end else begin 
            spi1_vld <= spi_vld; 
            spi2_vld <= spi1_vld;
        end
    end 

    assign vld = spi2_vld; // transaction complete 

    always_ff @(posedge clk, negedge rst_n) begin // infer state logic
        if (!rst_n) 
            state <= INIT1;
        else 
            state <= next_state; 
    end

    // state machine logic 
    // send SPI commands based on the current states
    always_comb begin
        // default output signals
        next_state = state; 
        next_snd = 1'b0;
        next_cmd = 16'h0000;
        spi_vld = 1'b0;

        // defaulted enables
        C_R_H = 1'b0;
        C_R_L = 1'b0;
        C_Y_H = 1'b0;
        C_Y_L = 1'b0;
        C_AY_H = 1'b0;
        C_AY_L = 1'b0;
        C_AZ_H = 1'b0;
        C_AZ_L = 1'b0; 

        case (state)
            INIT1: begin // enable interrupt
                if (&timer) begin
                    next_state = INIT2;
                    next_snd = 1'b1;
                    next_cmd = 16'h0D02;
                end
            end 
            INIT2: begin // first accelerometer setup
                if (done_edge) begin
                    next_state = INIT3;
                    next_snd = 1'b1;
                    next_cmd = 16'h1053;
                end
            end
            INIT3: begin // second accelerometer setup
                if (done_edge) begin
                    next_state = INIT4; 
                    next_snd = 1'b1;
                    next_cmd = 16'h1150;
                end
            end
            INIT4: begin // activate accelerometer and gyro
                if (done_edge) begin 
                    next_state = INIT5;
                    next_snd = 1'b1;
                    next_cmd = 16'h1460;
                end
            end
            INIT5: begin // wait for int_ff2
                if (int_ff2) begin 
                    next_state = ROLL_L;
                    next_snd = 1'b1;
                    next_cmd = 16'hA400;
                end 
            end 
            ROLL_L: begin 
                if (done_edge) begin 
                    next_state = ROLL_H;
                    next_snd = 1'b1;
                    next_cmd = 16'hA500;
                    C_R_L = 1'b1;
                end 
            end
            ROLL_H: begin  
                if (done_edge) begin 
                    next_state = YAW_L;
                    next_snd = 1'b1;
                    next_cmd = 16'hA600;
                    C_R_H = 1'b1;
                end 
            end
            YAW_L: begin
                if (done_edge) begin 
                    next_state = YAW_H;
                    next_snd = 1'b1;
                    next_cmd = 16'hA700;
                    C_Y_L = 1'b1;
                end
            end
            YAW_H: begin   
                if (done_edge) begin 
                    next_state = AY_L;
                    next_snd = 1'b1; 
                    next_cmd = 16'hAA00;
                    C_Y_H = 1'b1;
                end
            end
            AY_L: begin
                if (done_edge) begin 
                    next_state = AY_H;
                    next_snd = 1'b1;
                    next_cmd = 16'hAB00;
                    C_AY_L = 1'b1;
                end 
            end
            AY_H: begin
                  if (done_edge) begin 
                    next_state = AZ_L;
                    next_snd = 1'b1;
                    next_cmd = 16'hAC00;
                    C_AY_H = 1'b1;
                end 
            end
            AZ_L: begin
                if (done_edge) begin 
                    next_state = AZ_H;
                    next_snd = 1'b1;
                    next_cmd = 16'hAD00;
                    C_AZ_L = 1'b1;
                end 
            end
            AZ_H: begin
                if (done_edge) begin 
                    spi_vld = 1'b1;
                    next_state = INIT5;
                    C_AZ_H = 1'b1;
                end 
            end 
            default:
                next_state = INIT1;
        endcase 
    end

endmodule

