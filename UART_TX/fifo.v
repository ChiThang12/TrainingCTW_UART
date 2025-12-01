module fifo#(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire [WIDTH-1:0] d_in,
    input wire rd_en,

    output wire full,
    output wire empty,
    output reg [WIDTH-1:0] d_out
);

    // KHAI BAO CÁC BIẾN
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr; // 5bit _|4bit từ 0000->1111
    reg [$clog2(DEPTH):0] rd_ptr; // 5bit



    assign full = (wr_ptr[$clog2(DEPTH)] != rd_ptr[$clog2(DEPTH)]) && 
                  (wr_ptr[$clog2(DEPTH)-1:0] == rd_ptr[$clog2(DEPTH)-1:0]) ? 1'b1 : 1'b0;
    assign empty = (wr_ptr == rd_ptr) ? 1'b1 : 1'b0;


    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            wr_ptr <= 5'b0;
            rd_ptr <= 5'b0;
        end
        else begin
            if(wr_en && !full) begin
                mem[wr_ptr[$clog2(DEPTH)-1:0]] <= d_in;
                wr_ptr <= wr_ptr + 1;
            end
            if(rd_en && !empty) begin
                d_out <= mem[rd_ptr[$clog2(DEPTH)-1:0]];
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

endmodule