module robot_arm_controller
(
    input  wire CLK,

    // joystick pins
    output wire PMOD7,   // CS
    output wire PMOD8,   // MOSI
    input  wire PMOD9,   // MISO
    output wire PMOD10,  // SCK

    // LEDs
    output wire LED1,    // shows servo 1 is selected
    output wire LED2,    // shows servo 2 is selected
    output wire LED3,    // shows servo 3 is selected
    output wire LED4,    // shows servo 4 is selected

    // pushbuttons to select active servo
    input  wire SW1,     // select servo 1
    input  wire SW2,     // select servo 2
    input  wire SW3,     // select servo 3
    input  wire SW4,     // select servo 4

    // connection for pwm to servos
    output wire PMOD1,   // servo 1 signal
    output wire PMOD2,   // servo 2 signal
    output wire PMOD3,   // servo 3 signal
    output wire PMOD4    // servo 4 signal
);

    // ───────────── Joystick interface ─────────────
    wire [31:0] x_pos, y_pos;
    wire [7:0]  buttons;
    wire        spi_clk_dbg;
    wire        rx_toggle_dbg;

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

    // ───────────── Map joystick positions to pulse width (µs) ─────────────
    // x_pos, y_pos ~ 228..830  → pulse width ~ 1000..2000 us (clamped)

    wire signed [31:0] raw_x;
    wire signed [31:0] raw_y;
    reg  [31:0]        control_x;
    reg  [31:0]        control_y;

    assign raw_x = 650 + ((2600 - 650) / (830 - 228)) * (x_pos - 228);
    assign raw_y = 650 + ((2600 - 650) / (830 - 228)) * (y_pos - 228);

    always @(*) begin
        // clamp X
        if (raw_x < 1000)
            control_x = 1000;
        else if (raw_x > 2000)
            control_x = 2000;
        else
            control_x = raw_x[31:0];

        // clamp Y
        if (raw_y < 1000)
            control_y = 1000;
        else if (raw_y > 2000)
            control_y = 2000;
        else
            control_y = raw_y[31:0];
    end

    localparam integer SERVO_CENTER_US = 1500;   // 1.5 ms center pulse

    // ───────────── Active servo selection (using buttons) ─────────────
    // 0 = servo 1, 1 = servo 2, 2 = servo 3, 3 = servo 4

    reg [1:0] current_servo = 2'd0;  // start on servo 1
    reg       sw1_prev = 1'b0;
    reg       sw2_prev = 1'b0;
    reg       sw3_prev = 1'b0;
    reg       sw4_prev = 1'b0;

    always @(posedge CLK) begin
        // edge detect: detect rising edges of SW1–SW4
        sw1_prev <= SW1;
        sw2_prev <= SW2;
        sw3_prev <= SW3;
        sw4_prev <= SW4;

        // if SW1 goes from 0 -> 1, select servo 1
        if (!sw1_prev && SW1)
            current_servo <= 2'd0;

        // if SW2 goes from 0 -> 1, select servo 2
        else if (!sw2_prev && SW2)
            current_servo <= 2'd1;

        // if SW3 goes from 0 -> 1, select servo 3
        else if (!sw3_prev && SW3)
            current_servo <= 2'd2;

        // if SW4 goes from 0 -> 1, select servo 4
        else if (!sw4_prev && SW4)
            current_servo <= 2'd3;
    end

    // LEDs show which servo is currently selected
    assign LED1 = (current_servo == 2'd0);
    assign LED2 = (current_servo == 2'd1);
    assign LED3 = (current_servo == 2'd2);
    assign LED4 = (current_servo == 2'd3);

    // ───────────── Servo commands (only update selected one) ─────────────
    reg [31:0] servo0_cmd = SERVO_CENTER_US;   // servo 1 (PMOD1)
    reg [31:0] servo1_cmd = SERVO_CENTER_US;   // servo 2 (PMOD2)
    reg [31:0] servo2_cmd = SERVO_CENTER_US;   // servo 3 (PMOD3)
    reg [31:0] servo3_cmd = SERVO_CENTER_US;   // servo 4 (PMOD4)

    always @(posedge CLK) begin
        case (current_servo)
            2'd0: begin
                // servo 1 active: use X axis (for example)
                servo0_cmd <= control_x;
            end
            2'd1: begin
                // servo 2 active: use Y axis (for example)
                servo1_cmd <= control_y;
            end
            2'd2: begin
                // servo 3 active: you can choose X or Y; here I use X again
                servo2_cmd <= control_x;
            end
            2'd3: begin
                // servo 4 active: use Y axis again
                servo3_cmd <= control_y;
            end
            default: begin
                // nothing
            end
        endcase
        // non-selected servos keep their last cmd → they hold position
    end

    // ───────────── Servo PWM generators ─────────────
    servo servo0 (
        .CLK     (CLK),
        .control (servo0_cmd),
        .PMOD    (PMOD1)
    );

    servo servo1 (
        .CLK     (CLK),
        .control (servo1_cmd),
        .PMOD    (PMOD2)
    );

    servo servo2 (
        .CLK     (CLK),
        .control (servo2_cmd),
        .PMOD    (PMOD3)
    );

    servo servo3 (
        .CLK     (CLK),
        .control (servo3_cmd),
        .PMOD    (PMOD4)
    );

endmodule
