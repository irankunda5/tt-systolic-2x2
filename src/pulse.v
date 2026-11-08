module pulse (
    input  wire clk,
    input  wire rst_n,
    input  wire strobe,   // slow signal from outside
    output wire go        // exactly one clock high per strobe
);
    reg [2:0] q;

    always @(posedge clk) begin
        if (!rst_n) q <= 3'b000;
        else        q <= {q[1:0], strobe};   // shorthand for the three lines above
    end

    assign go = q[1] & ~q[2];
endmodule 
