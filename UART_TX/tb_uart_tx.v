`timescale 1ns/1ps
`include "uart_tx.v"

module tb_uart_tx;

    parameter CLOCK_FREQ = 100_000_000;
    parameter BAUD       = 115200;
    parameter DATA_BITS  = 8;
    parameter STOP_BITS  = 1;
    parameter FIFO_DEPTH = 16;

    reg clk;
    reg rst_n;
    reg wr_en;
    reg [DATA_BITS-1:0] d_in;

    wire full;
    wire empty;
    wire tx;

    // Instantiate DUT
    uart_tx #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD(BAUD),
        .DATA_BITS(DATA_BITS),
        .STOP_BITS(STOP_BITS),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .d_in(d_in),
        .full(full),
        .empty(empty),
        .tx(tx)
    );

    // Clock generation: 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;  // 10 ns period

    // Test sequence
    initial begin
        $display("=== UART TX Test Start (16x Oversampling) ===");
        
        // Reset
        rst_n = 0;
        wr_en = 0;
        d_in = 0;
        #100;
        rst_n = 1;
        $display("Time=%0t: Reset released", $time);

        // Wait a little
        #100;

        // Write a series of bytes into FIFO
        $display("Time=%0t: Writing data to FIFO", $time);
        write_byte(8'h41); // 'A' = 0100_0001
        write_byte(8'h42); // 'B' = 0100_0010
        write_byte(8'h43); // 'C' = 0100_0011
        write_byte(8'h44); // 'D' = 0100_0100

        // Wait for transmission
        #500000;

        $display("Time=%0t: Test completed", $time);
        $finish;
    end

    // Task to write a byte into FIFO
    task write_byte(input [DATA_BITS-1:0] byte);
        begin
            @(posedge clk);
            d_in <= byte;
            wr_en <= 1;
            $display("Time=%0t: Write byte 0x%h (binary: %b) to FIFO", $time, byte, byte);
            @(posedge clk);
            wr_en <= 0;
        end
    endtask

    // Monitor TX line changes with more detail
    always @(tx) begin
        $display("Time=%0t: TX = %b | State=%b | tick_cnt=%0d | bit_cnt=%0d", 
                 $time, tx, dut.u_core.state, dut.u_core.tick_cnt, dut.u_core.bit_cnt);
    end

    // Dump waveform
    initial begin
        $dumpfile("tb_uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);
        $dumpvars(0, dut.u_core.state);
        $dumpvars(0, dut.u_core.tick_cnt);
        $dumpvars(0, dut.u_core.bit_cnt);
        $dumpvars(0, dut.u_core.shift_reg);
        $dumpvars(0, dut.u_baud.baud_tick_16x);
    end

    // Debug information
    initial begin
        #300;
        $display("=== Configuration ===");
        $display("CLOCK_FREQ = %0d Hz", CLOCK_FREQ);
        $display("BAUD = %0d", BAUD);
        $display("BIT_TICKS (16x) = %0d", dut.u_baud.BIT_TICKS);
        $display("baud_cnt width = %0d bits", $clog2(dut.u_baud.BIT_TICKS)+1);
        $display("Expected bit period = %0d ns", dut.u_baud.BIT_TICKS * 16 * 10);
        $display("Expected byte period = %0d ns", dut.u_baud.BIT_TICKS * 16 * 10 * 10);
        $display("===================");
    end

    // Monitor baud tick pulses (first 20 pulses only)
    integer tick_count;
    initial begin
        tick_count = 0;
        @(posedge rst_n);
        #200;
        repeat(20) begin
            @(posedge dut.u_baud.baud_tick_16x);
            tick_count = tick_count + 1;
            $display("Time=%0t: baud_tick_16x pulse #%0d | State=%b | tick_cnt=%0d", 
                     $time, tick_count, dut.u_core.state, dut.u_core.tick_cnt);
        end
    end

    // Monitor FSM state changes
    always @(dut.u_core.state) begin
        case(dut.u_core.state)
            2'b00: $display("Time=%0t: State changed to IDLE", $time);
            2'b01: $display("Time=%0t: State changed to START | shift_reg=0x%h", $time, dut.u_core.shift_reg);
            2'b10: $display("Time=%0t: State changed to DATA | shift_reg=0x%h", $time, dut.u_core.shift_reg);
            2'b11: $display("Time=%0t: State changed to STOP", $time);
        endcase
    end

    // Monitor FIFO read
    always @(posedge clk) begin
        if(dut.rd_en) begin
            $display("Time=%0t: FIFO READ | fifo_dout=0x%h | empty=%b", $time, dut.fifo_dout, dut.empty);
        end
        if(dut.tx_start) begin
            $display("Time=%0t: TX_START | tx_data=0x%h | shift_reg=0x%h", $time, dut.tx_data, dut.u_core.shift_reg);
        end
    end

endmodule