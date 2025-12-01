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

    // KHAI BAO CAC BIEN
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr;
    reg [$clog2(DEPTH):0] rd_ptr;

    // Full: write pointer wrapped around and caught up to read pointer
    assign full = (wr_ptr[$clog2(DEPTH)] != rd_ptr[$clog2(DEPTH)]) && 
                  (wr_ptr[$clog2(DEPTH)-1:0] == rd_ptr[$clog2(DEPTH)-1:0]);
    
    // Empty: pointers are equal
    assign empty = (wr_ptr == rd_ptr);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            wr_ptr <= 0; 
            rd_ptr <= 0;
        end
        else begin
            // Write operation
            if(wr_en && !full) begin
                mem[wr_ptr[$clog2(DEPTH)-1:0]] <= d_in;
                wr_ptr <= wr_ptr + 1;
            end
            
            // Read operation
            if(rd_en && !empty) begin
                d_out <= mem[rd_ptr[$clog2(DEPTH)-1:0]];
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

endmodule