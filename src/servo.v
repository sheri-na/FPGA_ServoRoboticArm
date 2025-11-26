module servo (
    input  CLK,
    input  wire [31:0] control,
    output PMOD
);

// 25MHz clock
reg [31:0] counter;
reg        servo_reg;

//reg [31:0] control = 1500;   // µs pulse width
reg        toggle  = 1;

localparam integer TICKS_PER_US = 25;


wire [31:0] high_ticks = control * TICKS_PER_US;

always @(posedge CLK)
begin 
    counter <= counter + 1;
    if(counter == 499999)
        counter <= 0;

    // PWM output
    if(counter < high_ticks)
        servo_reg <= 1;
    else
        servo_reg <= 0;
end

assign PMOD = servo_reg;

endmodule