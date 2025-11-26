module robot_arm_controller
(
    input  wire CLK,

    //joystick pins
    output wire PMOD7,
    output wire PMOD8,
    input  wire PMOD9,
    output wire PMOD10, 
    //LEDs
    input LED1,
    input LED2,
    input LED3,
    input LED4

    //switch to choose joystick
    input SW1,
    input SW2,
    input SW3,
    input SW4,
    //connection for pwm to servos
    output wire PMOD1,
    output wire PMOD2,
    output wire PMOD3,
    output wire PMOD4

);

    //led tells which switch is being controlled
    assign LED1 = SW1;          
    assign LED2 = SW2;
    assign LED3 = SW3;          
    assign LED4 = SW4;

    //inputs for servo
    wire [31:0] control_x;
    wire [31:0] control_y;

    // Outputs from joystick reader
    wire [31:0] x_pos, y_pos;
    wire [7:0] buttons;

    wire spi_clk_dbg;
    wire rx_toggle_dbg;

    // Instantiate the JSTK2 module
    joystick joystick1 (
        .CLK       (CLK),

        .CS_n      (PMOD7),
        .MOSI      (PMOD8),
        .MISO      (PMOD9),
        .SCK       (PMOD10),

        .x_pos     (x_pos),
        .y_pos     (y_pos),
        .buttons   (buttons),

        .spi_clk_dbg   (spi_clk_dbg),
        .rx_toggle_dbg (rx_toggle_dbg)
    );




//max x 830, min x 228


    assign joystick_x = 650 + ((2600 - 650) / (830-228)) * (x_pos - 228);
    assign joystick_y = 650 + ((2600 - 650) / (830-228)) * (y_pos - 228);

    localparam integer SERVO_CENTER_US = 1500;   // 1.5 ms center pulse

    wire center_btn = buttons[0];

    reg [31:0] servo0_cmd = SERVO_CENTER_US;
    reg [31:0] servo1_cmd = SERVO_CENTER_US;

    always @(posedge CLK) begin
        if (center_btn) begin
            if (SW1 && !SW2)
                servo0_cmd <= SERVO_CENTER_US;
            else if (SW2 && !SW1)
                servo1_cmd <= SERVO_CENTER_US;
        end else begin
            if (SW1)
                servo0_cmd <= joy_x_us;
            if (SW2)
                servo1_cmd <= joy_y_us;
        end
    end


    // Instantiate the servo module x-axis
    servos servo1 (
        .CLK       (CLK),
        .control    (servo0_cmd),
        .PMOD1 (PMOD1)
    );
    servo_sg90 servo0 (
    .CLK     (CLK),
    .control (servo1_cmd),
    .PMOD    (PMOD2)
);
    servo_sg90 servo1 (
        .CLK     (CLK),
        .control (servo2_cmd),
        .PMOD    (PMOD3)
    );
    servo_sg90 servo0 (
    .CLK     (CLK),
    .control (servo3_cmd),
    .PMOD    (PMOD4)
);


endmodule
