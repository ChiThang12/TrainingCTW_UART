`include "baud_gen.v"
`include "uart_rx_core.v"
`include "fifo.v"

module uart_rx #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD       = 115200,
    parameter DATA_BITS  = 8,
    parameter STOP_BITS  = 1,
    parameter FIFO_DEPTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire rx,
    input wire rd_en,
    
    output wire full,
    output wire empty,
    output wire [DATA_BITS-1:0] d_out,
    output wire rx_error,
    output wire fifo_overflow
);

    // Internal signals
    wire baud_tick_16x;
    wire [DATA_BITS-1:0] rx_data;
    wire rx_valid;
    
    // FIFO overflow detection (pulse signal)
    reg fifo_overflow_pulse;
    
    // Baud rate generator
    baud_gen #(
        .BAUD(BAUD),
        .CLOCK_FREQ(CLOCK_FREQ)
    ) baud_gen_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick_16x(baud_tick_16x)
    );
    
    // UART RX core
    uart_rx_core #(
        .DATA_BITS(DATA_BITS),
        .STOP_BITS(STOP_BITS)
    ) uart_rx_core_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .baud_tick_16x(baud_tick_16x),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_error(rx_error)
    );
    
    // FIFO buffer
    fifo #(
        .WIDTH(DATA_BITS),
        .DEPTH(FIFO_DEPTH)
    ) fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(rx_valid && !full),
        .d_in(rx_data),
        .rd_en(rd_en),
        .full(full),
        .empty(empty),
        .d_out(d_out)
    );
    

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            fifo_overflow_pulse <= 1'b0;
        end else begin
            fifo_overflow_pulse <= (rx_valid && full);
        end
    end
    
    assign fifo_overflow = fifo_overflow_pulse;

endmodule