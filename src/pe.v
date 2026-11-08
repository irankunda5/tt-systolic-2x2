module pe (
    input  wire               clk,
    input ut  wire               rst_n,
    input  wire               clear,   // start a new result (and keep this cycle's product)
    input  wire signed [7:0]  a_in,    // from the left
    input  wire signed [7:0]  b_in,    // from above
    output reg  signed [7:0]  a_out,   // to the right, one clock later
    output reg  signed [7:0]  b_out,   // downward, one clock later
    output reg  signed [23:0] acc
);
    wire signed [15:0] prod = a_in * b_in;

    always @(posedge clk) begin
        if (!rst_n) begin
            a_out <= 8'sd0;
            b_out <= 8'sd0;
            acc   <= 24'sd0;
        end else begin
            a_out <= a_in;                      // the shift register from Step 3
            b_out <= b_in;
            if (clear) acc <= prod;             // your Step 5 design-question fix
            else       acc <= acc + prod;
        end
    end
endmodule 
