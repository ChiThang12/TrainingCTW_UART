module baud_gen #(
    parameter BAUD = 115200,
    parameter CLOCK_FREQ = 100_000_000
)(
    input wire clk,
    input wire rst_n,

    output reg baud_tick_16x
);

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