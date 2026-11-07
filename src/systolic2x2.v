module systolic2x2 (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               clear,
    input  wire signed [7:0]  a0, a1,   // left edge: row 0, row 1 (already skewed)
    input  wire signed [7:0]  b0, b1,   // top edge: col 0, col 1 (already skewed)
    output wire signed [23:0] c00, c01, c10, c11
);
    // wires between neighbors
    wire signed [7:0] a00_to_01, a10_to_11;   // horizontal
    wire signed [7:0] b00_to_10, b01_to_11;   // vertical

    //            clk  rst    clear   a_in       b_in       a_out       b_out       acc
    pe pe00 (.clk(clk), .rst_n(rst_n), .clear(clear),
             .a_in(a0),        .b_in(b0),
             .a_out(a00_to_01), .b_out(b00_to_10), .acc(c00));

    pe pe01 (.clk(clk), .rst_n(rst_n), .clear(clear),
             .a_in(a00_to_01), .b_in(b1),
             .a_out(),          .b_out(b01_to_11), .acc(c01));   // a_out: edge of array, unused

    pe pe10 (.clk(clk), .rst_n(rst_n), .clear(clear),
             .a_in(a1),        .b_in(b00_to_10),
             .a_out(a10_to_11), .b_out(),          .acc(c10));

    pe pe11 (.clk(clk), .rst_n(rst_n), .clear(clear),
             .a_in(a10_to_11), .b_in(b01_to_11),
             .a_out(),          .b_out(),          .acc(c11));
endmodule
