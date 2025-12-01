module uart_tx_core #(
    parameter DATA_BITS = 8,
    parameter STOP_BITS = 1
)(
    input wire clk,
    input wire rst_n,
    input wire tx_start,
    input wire [DATA_BITS-1:0] tx_data,
    input wire baud_tick_16x,

    output reg tx,
    output reg tx_busy
);

    localparam [1:0] IDLE  = 2'b00;
    localparam [1:0] START = 2'b01;
    localparam [1:0] DATA  = 2'b10;
    localparam [1:0] STOP  = 2'b11;

    reg [1:0] state, next_state;
    reg [$clog2(DATA_BITS):0] bit_cnt;
    reg [DATA_BITS-1:0] shift_reg;
    reg [$clog2(STOP_BITS):0] stop_cnt;
    reg [3:0] tick_cnt;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state     <= IDLE;
            tx        <= 1'b1;
            tx_busy   <= 1'b0;
            bit_cnt   <= 0;
            shift_reg <= 0;
            stop_cnt  <= 0;
            tick_cnt  <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    tx_busy <= 1'b0;
                    tick_cnt <= 0;
                    bit_cnt <= 0;
                    stop_cnt <= 0;
                    
                    if(tx_start) begin
                        shift_reg <= tx_data;
                        tx_busy <= 1'b1;
                        state <= START;
                    end
                end
                START: begin
                    tx <= 1'b0;
                    if(baud_tick_16x) begin
                        if(tick_cnt == 4'd15) begin
                            tick_cnt <= 0;
                            state    <= DATA;
                        end else begin
                            tick_cnt <= tick_cnt + 1'b1;
                        end
                    end
                end
                DATA: begin
                    tx <= shift_reg[0];
                    
                    if(baud_tick_16x) begin
                        if(tick_cnt == 4'd15) begin
                            tick_cnt  <= 0;
                            shift_reg <= {1'b0, shift_reg[DATA_BITS-1:1]};                            
                            if(bit_cnt == DATA_BITS - 1) begin
                                state    <= STOP;
                                bit_cnt  <= 0;
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end else begin
                            tick_cnt <= tick_cnt + 1'b1;
                        end
                    end
                end

                STOP: begin
                    tx <= 1'b1; 
                    
                    if(baud_tick_16x) begin
                        if(tick_cnt == 4'd15) begin
                            tick_cnt <= 0;
                            
                            if(stop_cnt == STOP_BITS - 1) begin
                                state    <= IDLE;
                                tx_busy  <= 1'b0;
                                stop_cnt <= 0;
                            end else begin
                                stop_cnt <= stop_cnt + 1'b1;
                            end
                        end else begin
                            tick_cnt <= tick_cnt + 1'b1;
                        end
                    end
                end
        
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
endmodule