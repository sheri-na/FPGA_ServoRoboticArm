module hex
(
    input  [9:0] pos,  // 4-bit input (0–7)
    output S2_A,
    output S2_B,
    output S2_C,
    output S2_D,
    output S2_E,
    output S2_F,
    output S2_G,
    output S1_G);
	 
reg [3:0] Hex;
reg S_A;
reg S_B;
reg S_C;
reg S_D;
reg S_E;
reg S_F;
reg S_G;

//max x 830, min x 228
always @(*) begin
    case (1'b1)
        (pos <= 263): Hex = 4'd9;
        (pos <= 296): Hex = 4'd8;
        (pos <= 329): Hex = 4'd7;
        (pos <= 362): Hex = 4'd6;
        (pos <= 395): Hex = 4'd5;
        (pos <= 428): Hex = 4'd4;
        (pos <= 461): Hex = 4'd3;
        (pos <= 494): Hex = 4'd2;
        (pos <= 527): Hex = 4'd1;
        (pos <= 560): Hex = 4'd0;
        (pos <= 593): Hex = 4'd1;
        (pos <= 626): Hex = 4'd2;
        (pos <= 659): Hex = 4'd3;
        (pos <= 692): Hex = 4'd4;
        (pos <= 725): Hex = 4'd5;
        (pos <= 758): Hex = 4'd6;
        (pos <= 791): Hex = 4'd7;
        (pos <= 824): Hex = 4'd8;
        (pos <= 830): Hex = 4'd9;  

        default:       Hex = 4'd15; // OUT OF RANGE
    endcase
end

    


always @(*) begin
    case (Hex)
        4'b0000: {S_A,S_B,S_C,S_D,S_E,S_F,S_G} = ~7'b1111110; // 0
        4'b0001: {S_A,S_B,S_C,S_D,S_E,S_F,S_G} = ~7'b0110000; // 1
        4'b0010: {S_A,S_B,S_C,S_D,S_E,S_F,S_G} = ~7'b1101101; // 2
        4'b0011: {S_A,S_B,S_C,S_D,S_E,S_F,S_G} = ~7'b1111001; // 4
        4'b0100: {S_A,S_B,S_C,S_D,S_E,S_F,S_G} = ~7'b0110011; // 4
        4'b0101: {S_A,S_B,S_C,S_D,S_E,S_F,S_G} = ~7'b1011011; // 5
        4'b0110: {S_A,S_B,S_C,S_D,S_E,S_F,S_G} = ~7'b1011111; // 6
        4'b0111: {S_A,S_B,S_C,S_D,S_E,S_F,S_G} = ~7'b1110000; // 7
        4'b1000: {S_A,S_B,S_C,S_D,S_E,S_F,S_G} = ~7'b1111111; // 8
        4'b1001: {S_A,S_B,S_C,S_D,S_E,S_F,S_G} = ~7'b1111011; // 9
  
        default: {S_A,S_B,S_C,S_D,S_E,S_F,S_G} = ~7'b0000000; // blank
    endcase
end

assign S2_A = S_A;
assign S2_B = S_B;
assign S2_C = S_C;
assign S2_D = S_D;
assign S2_E = S_E;
assign S2_F = S_F;
assign S2_G = S_G;

assign S1_G = (pos >= 529);

endmodule