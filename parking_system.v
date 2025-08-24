module parking_system(
    input  clk,
    input  reset_n,
    input  sensor_entrance,
    input  sensor_exit,
    input  [1:0] password_1,
    input  [1:0] password_2,
    output GREEN_LED,
    output RED_LED,
    output reg [6:0] HEX_1,
    output reg [6:0] HEX_2
);

    // FSM states
    parameter IDLE          = 3'b000;
    parameter WAIT_PASSWORD = 3'b001;
    parameter WRONG_PASS    = 3'b010;
    parameter RIGHT_PASS    = 3'b011;
    parameter STOP          = 3'b100;

    // Registers
    reg [2:0] current_state, next_state;
    reg [31:0] counter_wait;       // wait counter
    reg [25:0] blink_counter;      // slow counter for blinking
    reg red_tmp, green_tmp;

    // State register
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // Counter for password wait
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n)
            counter_wait <= 0;
        else if(current_state == WAIT_PASSWORD)
            counter_wait <= counter_wait + 1;
        else
            counter_wait <= 0;
    end

    // Slow blink counter
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n)
            blink_counter <= 0;
        else
            blink_counter <= blink_counter + 1;
    end

    // Next state logic
    always @(*) begin
        case(current_state)
            IDLE: begin
                if(sensor_entrance)
                    next_state = WAIT_PASSWORD;
                else
                    next_state = IDLE;
            end

            WAIT_PASSWORD: begin
                if(counter_wait < 32'd50_000_000)   // ~1 second @ 50 MHz
                    next_state = WAIT_PASSWORD;
                else if((password_1==2'b01)&&(password_2==2'b10))
                    next_state = RIGHT_PASS;
                else
                    next_state = WRONG_PASS;
            end

            WRONG_PASS: begin
                if((password_1==2'b01)&&(password_2==2'b10))
                    next_state = RIGHT_PASS;
                else
                    next_state = WRONG_PASS;
            end

            RIGHT_PASS: begin
                if(sensor_entrance && sensor_exit)
                    next_state = STOP;
                else if(sensor_exit)
                    next_state = IDLE;
                else
                    next_state = RIGHT_PASS;
            end

            STOP: begin
                if((password_1==2'b01)&&(password_2==2'b10))
                    next_state = RIGHT_PASS;
                else
                    next_state = STOP;
            end

            default: next_state = IDLE;
        endcase
    end

    // Output logic (Moore FSM)
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            red_tmp   <= 1'b0;
            green_tmp <= 1'b0;
            HEX_1     <= 7'b1111111; // off
            HEX_2     <= 7'b1111111; // off
        end else begin
            case(current_state)

                IDLE: begin
                    green_tmp <= 1'b0;
                    red_tmp   <= 1'b0;
                    HEX_1     <= 7'b1111111;
                    HEX_2     <= 7'b1111111;
                end

                WAIT_PASSWORD: begin
                    green_tmp <= 1'b0;
                    red_tmp   <= 1'b1;
                    HEX_1     <= 7'b0000110; // E
                    HEX_2     <= 7'b0101011; // n
                end

                WRONG_PASS: begin
                    green_tmp <= 1'b0;
                    red_tmp   <= blink_counter[25]; // slow blink
                    HEX_1     <= 7'b0000110; // E
                    HEX_2     <= 7'b0000110; // E
                end

                RIGHT_PASS: begin
                    green_tmp <= blink_counter[25]; // slow blink
                    red_tmp   <= 1'b0;
                    HEX_1     <= 7'b0000010; // 6
                    HEX_2     <= 7'b1000000; // 0
                end

                STOP: begin
                    green_tmp <= 1'b0;
                    red_tmp   <= blink_counter[25]; // slow blink
                    HEX_1     <= 7'b0010010; // 5
                    HEX_2     <= 7'b0001100; // P
                end
            endcase
        end
    end

    assign RED_LED   = red_tmp;
    assign GREEN_LED = green_tmp;

endmodule
