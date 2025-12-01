`timescale 1ns/1ps
`include "uart_rx.v"

module tb_uart_rx;

    parameter CLOCK_FREQ = 100_000_000;
    parameter BAUD       = 115200;
    parameter DATA_BITS  = 8;
    parameter STOP_BITS  = 1;
    parameter FIFO_DEPTH = 16;
    
    // Tinh bit period (trong nanoseconds)
    // BAUD = 115200 -> 1 bit = 1/115200 giay = 8680.56 ns
    localparam real BIT_PERIOD_REAL = 1_000_000_000.0 / BAUD;
    localparam BIT_PERIOD = 8681;  // ns (lam tron)

    reg clk;
    reg rst_n;
    reg rx;
    reg rd_en;

    wire full;
    wire empty;
    wire [DATA_BITS-1:0] d_out;
    wire rx_error;
    wire fifo_overflow;

    // Instantiate DUT
    uart_rx #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD(BAUD),
        .DATA_BITS(DATA_BITS),
        .STOP_BITS(STOP_BITS),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .rd_en(rd_en),
        .full(full),
        .empty(empty),
        .d_out(d_out),
        .rx_error(rx_error),
        .fifo_overflow(fifo_overflow)
    );

    // Clock generation: 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        $display("=== UART RX Test Start ===");
        $display("Bit Period = %0d ns", BIT_PERIOD);
        $display("Clock Period = 10 ns (100 MHz)");
        $display("FIFO Depth = %0d", FIFO_DEPTH);
        
        // Initialize
        rx = 1'b1;  // Idle state
        rst_n = 0;
        rd_en = 0;
        
        #100;
        rst_n = 1;
        $display("Time=%0t: Reset released", $time);
        
        #1000;
        
        // Test 1: Gui chuoi "HELLO 123"
        $display("\n=== Test 1: Sending 'HELLO 123' ===");
        send_byte(8'h48);  // 'H'
        send_byte(8'h45);  // 'E'
        send_byte(8'h4C);  // 'L'
        send_byte(8'h4C);  // 'L'
        send_byte(8'h4F);  // 'O'
        send_byte(8'h20);  // ' ' (space)
        send_byte(8'h31);  // '1'
        send_byte(8'h32);  // '2'
        send_byte(8'h33);  // '3'
        
        // Doi mot chut truoc khi doc
        #10000;
        
        // Doc tat ca du lieu tu FIFO
        $display("\n=== Reading Data from FIFO ===");
        read_all_fifo();
        
        // Test 2: Kiem tra FIFO overflow
        #10000;
        $display("\n=== Test 2: FIFO Overflow Test ===");
        $display("Sending %0d bytes without reading...", FIFO_DEPTH + 3);
        
        repeat(FIFO_DEPTH + 3) begin
            send_byte(8'h41);  // 'A'
        end
        
        #10000;
        $display("Reading all data after overflow...");
        read_all_fifo();
        
        // Test 3: Kiem tra framing error
        #10000;
        $display("\n=== Test 3: Framing Error Test ===");
        send_byte_with_error(8'h42);  // Gui byte voi STOP bit sai
        
        #10000;
        
        $display("\n=== Test Completed ===");
        $display("Total simulation time: %0t ns", $time);
        $finish;
    end

    // Task de gui 1 byte qua UART
    task send_byte(input [DATA_BITS-1:0] data);
        integer i;
        begin
            $display("Time=%0t: Sending byte 0x%h ('%c')", $time, data, data);
            
            // START bit
            rx = 1'b0;
            #BIT_PERIOD;
            
            // DATA bits (LSB first)
            for(i = 0; i < DATA_BITS; i = i + 1) begin
                rx = data[i];
                #BIT_PERIOD;
            end
            
            // STOP bit
            rx = 1'b1;
            #BIT_PERIOD;
            
            // Inter-frame gap
            #(BIT_PERIOD * 2);
        end
    endtask

    // Task gui byte voi framing error
    task send_byte_with_error(input [DATA_BITS-1:0] data);
        integer i;
        begin
            $display("Time=%0t: Sending byte with framing error 0x%h", $time, data);
            
            // START bit
            rx = 1'b0;
            #BIT_PERIOD;
            
            // DATA bits (LSB first)
            for(i = 0; i < DATA_BITS; i = i + 1) begin
                rx = data[i];
                #BIT_PERIOD;
            end
            
            // STOP bit SAI (gui 0 thay vi 1)
            rx = 1'b0;
            #BIT_PERIOD;
            
            // Tra ve idle
            rx = 1'b1;
            #(BIT_PERIOD * 2);
        end
    endtask

    // Task doc tat ca du lieu tu FIFO
    task read_all_fifo;
        integer count;
        begin
            count = 0;
            while(!empty) begin
                @(posedge clk);
                rd_en <= 1'b1;
                @(posedge clk);
                rd_en <= 1'b0;
                @(posedge clk);
                @(posedge clk);  // Doi them 1 cycle de d_out stable
                
                if(d_out >= 32 && d_out <= 126) begin
                    $display("Time=%0t: Read[%0d] from FIFO: 0x%h ('%c')", 
                             $time, count, d_out, d_out);
                end else begin
                    $display("Time=%0t: Read[%0d] from FIFO: 0x%h", 
                             $time, count, d_out);
                end
                count = count + 1;
            end
            $display("Total bytes read: %0d", count);
        end
    endtask

    // Monitor rx_error
    always @(posedge clk) begin
        if(rx_error) begin
            $display("Time=%0t: *** ERROR *** Framing error detected!", $time);
        end
    end

    // Monitor FIFO overflow
    always @(posedge clk) begin
        if(fifo_overflow) begin
            $display("Time=%0t: *** WARNING *** FIFO overflow detected!", $time);
        end
    end

    // Monitor FIFO status changes
    reg prev_full, prev_empty;
    initial begin
        prev_full = 0;
        prev_empty = 1;
    end
    
    always @(posedge clk) begin
        if(full && !prev_full) begin
            $display("Time=%0t: FIFO is now FULL", $time);
        end
        if(empty && !prev_empty) begin
            $display("Time=%0t: FIFO is now EMPTY", $time);
        end
        prev_full <= full;
        prev_empty <= empty;
    end

    // Monitor RX valid data
    always @(posedge clk) begin
        if(dut.rx_valid) begin
            if(dut.rx_data >= 32 && dut.rx_data <= 126) begin
                $display("Time=%0t: RX received valid data: 0x%h ('%c')", 
                         $time, dut.rx_data, dut.rx_data);
            end else begin
                $display("Time=%0t: RX received valid data: 0x%h", 
                         $time, dut.rx_data);
            end
        end
    end

    // Dump waveform
    initial begin
        $dumpfile("tb_uart_rx.vcd");
        $dumpvars(0, tb_uart_rx);
    end

endmodule