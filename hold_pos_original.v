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
    output reg  [9:0] o_pos       // accumulated/clamped output position
);

    // Compute center point (10-bit)
    localparam [9:0] CENTER    = (MIN_POS + MAX_POS) >> 1; // (228+830)/2 = 529
    localparam [9:0] ZERO_LOW  = CENTER - DEAD_BAND;       // 519
    localparam [9:0] ZERO_HIGH = CENTER + DEAD_BAND;       // 539

    // State machine
    localparam [1:0]
        STATE_CENTER = 2'd0,
        STATE_LEFT   = 2'd1,
        STATE_RIGHT  = 2'd2;

    reg [1:0]  state;
    reg [9:0]  min_pos;    // track furthest left
    reg [9:0]  max_pos;    // track furthest right
    reg signed [10:0] new_o_pos; // one extra bit for +/- math

    // Region indicators
    wire in_center  = (r_pos >= ZERO_LOW  && r_pos <= ZERO_HIGH);
    wire left_side  = (r_pos <  ZERO_LOW);
    wire right_side = (r_pos >  ZERO_HIGH);

    // ----------- CLAMP FUNCTION -----------
    function [9:0] clamp;
        input signed [10:0] value;
        begin
            if (value < $signed({1'b0, MIN_POS}))
                clamp = MIN_POS;
            else if (value > $signed({1'b0, MAX_POS}))
                clamp = MAX_POS;
            else
                clamp = value[9:0];
        end
    endfunction
    // --------------------------------------

    always @(posedge CLK or posedge SW1) begin
        if (SW1) begin
            state   <= STATE_CENTER;
            min_pos <= CENTER;
            max_pos <= CENTER;
            o_pos   <= CENTER;   // start at center
        end else begin
            case (state)
                // ------------------------------------
                // IDLE IN CENTER
                // ------------------------------------
                STATE_CENTER: begin
                    if (left_side) begin
                        state   <= STATE_LEFT;
                        min_pos <= r_pos;  // start new left excursion
                    end else if (right_side) begin
                        state   <= STATE_RIGHT;
                        max_pos <= r_pos;  // start new right excursion
                    end
                end

                // ------------------------------------
                // TRACKING LEFT EXCURSION
                // ------------------------------------
                STATE_LEFT: begin
                    if (left_side) begin
                        if (r_pos < min_pos)
                            min_pos <= r_pos;  // update min
                    end 
                    else if (in_center) begin
                        // excursion ended → accumulate
                        new_o_pos = $signed({1'b0,o_pos}) - 
                                    $signed({1'b0,(CENTER - min_pos)});
                        o_pos     <= clamp(new_o_pos);
                        state     <= STATE_CENTER;
                    end
                    else if (right_side) begin
                        // crossed all the way to right → finish left first
                        new_o_pos = $signed({1'b0,o_pos}) - 
                                    $signed({1'b0,(CENTER - min_pos)});
                        o_pos     <= clamp(new_o_pos);
                        // begin right excursion
                        state   <= STATE_RIGHT;
                        max_pos <= r_pos;
                    end
                end

                // ------------------------------------
                // TRACKING RIGHT EXCURSION
                // ------------------------------------
                STATE_RIGHT: begin
                    if (right_side) begin
                        if (r_pos > max_pos)
                            max_pos <= r_pos;  // update max
                    end 
                    else if (in_center) begin
                        // excursion ended → accumulate
                        new_o_pos = $signed({1'b0,o_pos}) + 
                                    $signed({1'b0,(max_pos - CENTER)});
                        o_pos     <= clamp(new_o_pos);
                        state     <= STATE_CENTER;
                    end
                    else if (left_side) begin
                        // crossed all the way to left → finish right first
                        new_o_pos = $signed({1'b0,o_pos}) + 
                                    $signed({1'b0,(max_pos - CENTER)});
                        o_pos     <= clamp(new_o_pos);
                        // begin left excursion
                        state   <= STATE_LEFT;
                        min_pos <= r_pos;
                    end
                end

                // catch-all (fixes CASEINCOMPLETE)
                default: begin
                    state <= STATE_CENTER;
                end
            endcase
        end
    end

endmodule
