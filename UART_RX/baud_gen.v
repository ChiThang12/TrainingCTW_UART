module baud_gen #(
    parameter BAUD = 115200,
    parameter CLOCK_FREQ = 100_000_000
)(
    input wire clk,
    input wire rst_n,

    output reg baud_tick_16x  // Baud tick với 16x oversampling
);

    // Tính số clock cycles cho mỗi baud tick 16x
    // VD: BAUD=115200, CLOCK=100MHz
    // BIT_TICKS = 100_000_000 / (115200 * 16) = 54.25 ≈ 54
    localparam BIT_TICKS = CLOCK_FREQ / (BAUD * 16);

    reg [$clog2(BIT_TICKS):0] baud_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_cnt      <= 0;
            baud_tick_16x <= 0;
        end else begin
            if (baud_cnt == BIT_TICKS - 1) begin
                baud_cnt      <= 0;
                baud_tick_16x <= 1;
            end else begin
                baud_cnt      <= baud_cnt + 1;
                baud_tick_16x <= 0;
            end
        end
    end

endmodule