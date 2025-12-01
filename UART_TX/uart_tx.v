`include "uart_tx_core.v"
`include "baud_gen.v"
`include "fifo.v"

module uart_tx #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD       = 115200,
    parameter DATA_BITS  = 8,
    parameter STOP_BITS  = 1,
    parameter FIFO_DEPTH = 16
)(
    input  wire clk,
    input  wire rst_n,
    input  wire wr_en,
    input  wire [DATA_BITS-1:0] d_in,
    
    output wire full,
    output wire empty,
    
    output wire tx
);

    wire tx_busy;
    reg rd_en;
    wire [DATA_BITS-1:0] fifo_dout;

    // FIFO instance
    fifo #(
        .WIDTH(DATA_BITS),
        .DEPTH(FIFO_DEPTH)
    ) u_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .d_in(d_in),
        .rd_en(rd_en),
        .full(full),
        .empty(empty),
        .d_out(fifo_dout)
    );

    // Baud generator
    wire baud_tick_16x;
    baud_gen #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD(BAUD)
    ) u_baud (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick_16x(baud_tick_16x)
    );

    // UART TX core
    reg tx_start;
    reg [DATA_BITS-1:0] tx_data;
    uart_tx_core #(
        .DATA_BITS(DATA_BITS),
        .STOP_BITS(STOP_BITS)
    ) u_core (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .baud_tick_16x(baud_tick_16x),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    localparam [1:0] ST_IDLE    = 2'b00;
    localparam [1:0] ST_READ    = 2'b01;
    localparam [1:0] ST_CAPTURE = 2'b10;  
    localparam [1:0] ST_WAIT    = 2'b11;
    
    reg [1:0] state;
    reg tx_busy_prev;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= ST_IDLE;
            rd_en <= 1'b0;
            tx_start <= 1'b0;
            tx_data <= 0;
            tx_busy_prev <= 1'b0;
        end else begin 
            rd_en <= 1'b0;
            tx_start <= 1'b0;
            tx_busy_prev <= tx_busy;
            
            case(state)
                ST_IDLE: begin
                    if(!tx_busy && !empty) begin
                        rd_en <= 1'b1;    
                        state <= ST_READ;
                    end
                end
                
                ST_READ: begin
                    state <= ST_CAPTURE;
                end
                
                ST_CAPTURE: begin
                    tx_data <= fifo_dout;
                    tx_start <= 1'b1;
                    state <= ST_WAIT;
                end
                
                ST_WAIT: begin
                    if(tx_busy_prev && !tx_busy) begin
                        state <= ST_IDLE;
                    end
                end
                
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule