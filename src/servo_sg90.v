module servo_sg90 (
    input  CLK,
    input  wire [31:0] control,
    output PMOD1
);

// 25MHz clock
reg [31:0] counter;
reg        servo_reg;

//reg [31:0] control = 1500;   // µs pulse width
reg        toggle  = 1;

localparam integer TICKS_PER_US = 25;

localparam integer MIN_US  = 650;
localparam integer MAX_US  = 2600;
localparam integer STEP_US = 10;

// --- New: Precomputed pulse widths ---
localparam integer DEG0_US = 650;
localparam integer DEG180_US = 2600;
localparam integer DEG90_US  = 1625;   // standard servo
localparam integer DEG45_US = 1137;   // approx: 120° = 2/3 of 180°
                                       // pulse = 650 + (120/180)*1950 ≈ 1667

										//Pulse = MIN_US + (120/180)*(MAX_US - MIN_US)
   										//	  = 650 + (2/3)*1950
										//    ≈ 1667 µs


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

assign PMOD1 = servo_reg;

endmodule
