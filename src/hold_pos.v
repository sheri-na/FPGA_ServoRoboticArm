module hold_pos
#(
    // 10-bit range: 0..1023
    parameter [9:0] MIN_POS   = 10'd228,   // leftmost joystick value
    parameter [9:0] MAX_POS   = 10'd830,   // rightmost joystick value
    parameter [9:0] DEAD_BAND = 10'd30     // center deadband around midpoint
)
(
    input  wire       CLK,
    input  wire       SW1,        // active-high reset
    input  wire [9:0] r_pos,      // raw joystick input (228..830)
    output wire  [9:0] o_pos       // accumulated/clamped output position
);

reg  [9:0] min;
reg  [9:0] max;
reg  [9:0] current;

reg [15:0] div = 0;
reg [9:0] r_pos_sampled;

always @(posedge CLK) begin
    div <= div + 1;
    if (div == 0)
        r_pos_sampled <= r_pos;
end


always @(posedge CLK) begin
    if (SW1) begin
        min <= 10'd529;
        max <= 10'd529;
        current <= 10'd529;
    end
    else begin
        if (current > r_pos_sampled) 
            current <= r_pos_sampled;

        if (current < r_pos_sampled)
            min <= r_pos_sampled;
    end

    //if ((r_pos < 550) && (r_pos > 510))
      //  current <= max - min;
end
assign o_pos = current;
endmodule