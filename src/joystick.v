module joystick
(
    input  wire CLK,         // 25 MHz clock

    // PMOD connections
    output wire CS_n,        // PMOD1
    output wire MOSI,        // PMOD2
    input  wire MISO,        // PMOD3
    output wire SCK,         // PMOD4

    // Outputs
    output wire [9:0] x_pos,     // Joystick X (0–1023)
    output wire [9:0] y_pos,     // Joystick Y (0–1023)
    output reg  [7:0] buttons,   // Button byte

    // Debug (optional)
    output wire spi_clk_dbg,
    output reg  rx_toggle_dbg
);


    // SPI Master wiring

    wire w_SPI_Clk;
    wire w_SPI_MOSI;
    wire w_TX_Ready;
    wire w_RX_DV;
    wire [7:0] w_RX_Byte;

    reg  r_TX_DV   = 1'b0;
    reg  [7:0] r_TX_Byte = 8'h00;
    reg  r_CS_n   = 1'b1;

    assign CS_n = r_CS_n;
    assign MOSI = w_SPI_MOSI;
    assign SCK  = w_SPI_Clk;

    assign spi_clk_dbg = w_SPI_Clk;

    // Toggle LED on each received byte
    always @(posedge CLK) begin
        if (w_RX_DV)
            rx_toggle_dbg <= ~rx_toggle_dbg;
    end

    // Raw joystick bytes
    reg [7:0] x_low  = 0;
    reg [7:0] x_high = 0;
    reg [7:0] y_low  = 0;
    reg [7:0] y_high = 0;

    reg [2:0] r_RxIndex = 0;

    // SPI Master Instance
    SPI_Master #(
        .SPI_MODE(0),
        .CLKS_PER_HALF_BIT(12)   // approx 1 MHz SCK
    ) spi0 (
        .i_Rst_L   (1'b1),
        .i_Clk     (CLK),

        .i_TX_Byte (r_TX_Byte),
        .i_TX_DV   (r_TX_DV),
        .o_TX_Ready(w_TX_Ready),

        .o_RX_DV   (w_RX_DV),
        .o_RX_Byte (w_RX_Byte),

        .o_SPI_Clk (w_SPI_Clk),
        .i_SPI_MISO(MISO),
        .o_SPI_MOSI(w_SPI_MOSI)
    );


    // Sample timer

    reg [19:0] r_SampleCount = 0;
    wire w_SampleTick = (r_SampleCount == 0);

    always @(posedge CLK)
        r_SampleCount <= r_SampleCount + 1;



    // JSTK2 Timing FSM

    localparam S_IDLE     = 3'd0;
    localparam S_DELAY    = 3'd1;
    localparam S_SEND     = 3'd2;
    localparam S_WAITBYTE = 3'd3;
    localparam S_CSHOLD   = 3'd4;

    reg [2:0]  r_State = S_IDLE;
    reg [2:0]  r_TxCount = 0;
    reg [15:0] r_DelayCnt = 0;

    // Timing constants (25 MHz clock)
    localparam CS_SETUP_CLKS   = 16'd500;   // ~20 us
    localparam INTERBYTE_CLKS  = 16'd300;   // ~12 us
    localparam CS_HOLD_CLKS    = 16'd800;   // ~32 us

    always @(posedge CLK) begin
        r_TX_DV <= 1'b0;

        case (r_State)
            S_IDLE: begin
                if (w_SampleTick) begin
                    r_CS_n     <= 1'b0;
                    r_TxCount  <= 0;
                    r_RxIndex  <= 0;
                    r_DelayCnt <= CS_SETUP_CLKS;
                    r_State    <= S_DELAY;
                end
            end

            S_DELAY: begin
                if (r_DelayCnt != 0)
                    r_DelayCnt <= r_DelayCnt - 1;
                else
                    r_State <= S_SEND;
            end

            S_SEND: begin
                if (w_TX_Ready) begin
                    r_TX_Byte <= 8'h00;
                    r_TX_DV   <= 1'b1;
                    r_State   <= S_WAITBYTE;
                end
            end

            S_WAITBYTE: begin
                if (w_RX_DV) begin
                    case (r_RxIndex)
                        3'd0: x_low   <= w_RX_Byte;
                        3'd1: x_high  <= w_RX_Byte;
                        3'd2: y_low   <= w_RX_Byte;
                        3'd3: y_high  <= w_RX_Byte;
                        3'd4: buttons <= w_RX_Byte;
                        default;
                    endcase

                    r_RxIndex <= r_RxIndex + 1;

                    if (r_TxCount == 3'd4) begin
                        r_CS_n     <= 1'b1;
                        r_DelayCnt <= CS_HOLD_CLKS;
                        r_State    <= S_CSHOLD;
                    end else begin
                        r_TxCount  <= r_TxCount + 1;
                        r_DelayCnt <= INTERBYTE_CLKS;
                        r_State    <= S_DELAY;
                    end
                end
            end

            S_CSHOLD: begin
                if (r_DelayCnt != 0)
                    r_DelayCnt <= r_DelayCnt - 1;
                else
                    r_State <= S_IDLE;
            end
            default;
        endcase
    end

    // Build 10-bit outputs
    assign x_pos = {x_high[1:0], x_low};
    assign y_pos = {y_high[1:0], y_low};

endmodule
