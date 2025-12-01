module uart_rx_core #(
    parameter DATA_BITS = 8,
    parameter STOP_BITS = 1
)(
    input wire clk,
    input wire rst_n,
    input wire rx,
    input wire baud_tick_16x, 

    output reg [DATA_BITS-1:0] rx_data,
    output reg rx_valid,
    output reg rx_error
);

    localparam [1:0] IDLE  = 2'b00;
    localparam [1:0] START = 2'b01;
    localparam [1:0] DATA  = 2'b10;
    localparam [1:0] STOP  = 2'b11;

    reg [1:0] state;
    reg [3:0] bit_cnt;
    reg [DATA_BITS-1:0] shift_reg;
    
    // Synchronizer để tránh metastability
    reg rx_sync1, rx_sync2;
    
    // Đếm mẫu để lấy mẫu ở giữa bit
    reg [3:0] sample_cnt;

    // 2-stage synchronizer
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end

    // RX FSM
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
            bit_cnt <= 0;
            shift_reg <= 0;
            rx_data <= 0;
            rx_valid <= 1'b0;
            rx_error <= 1'b0;
            sample_cnt <= 0;
        end else begin
            rx_valid <= 1'b0; 
            rx_error <= 1'b0;
            
            case(state)
                IDLE: begin
                    sample_cnt <= 0;
                    bit_cnt <= 0;
                    if(rx_sync2 == 1'b0) begin
                        state <= START;
                    end
                end
                
                START: begin
                    if(baud_tick_16x) begin
                        sample_cnt <= sample_cnt + 1;
                        if(sample_cnt == 4'd7) begin
                            if(rx_sync2 == 1'b0) begin
                                state <= DATA;
                                sample_cnt <= 0;
                                bit_cnt <= 0;
                            end else begin
                                state <= IDLE;
                            end
                        end
                    end
                end
                
                DATA: begin
                    if(baud_tick_16x) begin
                        sample_cnt <= sample_cnt + 1;
                        if(sample_cnt == 4'd15) begin
                            shift_reg <= {rx_sync2, shift_reg[DATA_BITS-1:1]};
                            sample_cnt <= 0;
                            bit_cnt <= bit_cnt + 1;
                            
                            if(bit_cnt == DATA_BITS - 1) begin
                                state <= STOP;
                                bit_cnt <= 0;
                            end
                        end
                    end
                end
                
                STOP: begin
                    if(baud_tick_16x) begin
                        sample_cnt <= sample_cnt + 1;
                        if(sample_cnt == 4'd15) begin
                            if(rx_sync2 == 1'b1) begin
                                rx_data <= shift_reg;
                                rx_valid <= 1'b1;
                            end else begin
                                rx_error <= 1'b1;
                            end
                            state <= IDLE;
                        end
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule