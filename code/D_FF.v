`timescale 1ns/1ps

module D_FF(
    input  wire clk,
    input  wire in,
    output reg  out
);
    initial begin
        out = 1'b0;
    end

    always @(posedge clk) begin
        out <= in;
    end

endmodule
