`timescale 1ns/1ps

module testbench;

    reg clk, reset_n;
    reg sensor_entrance, sensor_exit;
    reg [1:0] password_1, password_2;

    wire GREEN_LED, RED_LED;
    wire [6:0] HEX_1, HEX_2;

    parking_system DUT (
        .clk(clk),
        .reset_n(reset_n),
        .sensor_entrance(sensor_entrance),
        .sensor_exit(sensor_exit),
        .password_1(password_1),
        .password_2(password_2),
        .GREEN_LED(GREEN_LED),
        .RED_LED(RED_LED),
        .HEX_1(HEX_1),
        .HEX_2(HEX_2)
    );

    initial begin
        clk = 0;
        forever #10 clk = ~clk;   // 50MHz clock
    end

    initial begin
        $dumpfile("code1.vcd");
        $dumpvars(0, testbench);
        $monitor($time, " HEX_1=%b, HEX_2=%b, GREEN_LED=%b, RED_LED=%b, pass1=%b, pass2=%b",
                 HEX_1, HEX_2, GREEN_LED, RED_LED, password_1, password_2);

        reset_n = 0; 
        sensor_entrance = 0; 
        sensor_exit = 0; 
        password_1 = 2'b00; 
        password_2 = 2'b00;

        #100 reset_n = 1;

        // Car arrives
        #100 sensor_entrance = 1;
              password_1 = 2'b01; 
              password_2 = 2'b10;

        // Release entrance
        #200 sensor_entrance = 0;

        // Short wait (instead of 1 sec)
        #500;

        // Car exits
        sensor_exit = 1;
        #100 sensor_exit = 0;

        #500 $finish;
    end

endmodule
