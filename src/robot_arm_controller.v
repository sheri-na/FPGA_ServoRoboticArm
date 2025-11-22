module robot_arm_controller
(
    input  wire CLK,

    output wire LED1,
    output wire LED2,
    output wire LED3,
    output wire LED4,

    // PMOD JSTK2 pins
    output wire PMOD7,
    output wire PMOD8,
    input  wire PMOD9,
    output wire PMOD10, 
    
    //servo outputs
    input SW1,
    input SW2,
    input SW3,
    input SW4,
    output wire PMOD1,
    output wire PMOD2,
    output wire PMOD3,
    output wire PMOD4,

    //Hex outputs
    output S2_A,
    output S2_B,
    output S2_C,
    output S2_D,
    output S2_E,
    output S2_F,
    output S2_G,
    output S1_G
);


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



    // Instantiate hex decoder x-axis
    hex hex1 (
        .pos  (x_pos),
        .S2_A (S2_A),
        .S2_B (S2_B),
        .S2_C (S2_C),
        .S2_D (S2_D),
        .S2_E (S2_E),
        .S2_F (S2_F),
        .S2_G (S2_G),
        .S1_G (S1_G)
    );



//max x 830, min x 228

    // Debug LEDs x_axis
    assign LED4 = (x_pos >  10'd750);
    assign LED3 = (x_pos >= 10'd550 && x_pos < 10'd750);
    assign LED2 = (x_pos >= 10'd250 && x_pos < 10'd500);
    assign LED1 = (x_pos <= 10'd250);

    // Debug LEDs y_axis
    //assign LED1 = (y_pos >  10'd750);
    //assign LED2 = (y_pos >= 10'd550 && y_pos < 10'd750);
    //assign LED3 = (y_pos >= 10'd250 && y_pos < 10'd500);
    //assign LED4 = (y_pos <= 10'd250);


    //conversion from joystick position -> servo positioning
    //output = output_start + ((output_end - output_start) / (input_end - input_start)) * (input - input_start)
    assign control_x = 650 + ((2600 - 650) / (830-228)) * (x_pos - 228);
    assign control_y = 650 + ((2600 - 650) / (830-228)) * (y_pos - 228);




    // Instantiate the servo module x-axis
    servo_sg90 servox (
        .CLK       (CLK),
        .control    (control_x),
        .PMOD (PMOD1)
    );

    // Instantiate the servo module y-axis
    servo_sg90 servoy (
        .CLK       (CLK),
        .control    (control_y),
        .PMOD (PMOD2)
    );


endmodule
