`timescale 1ns / 100ps
;

module tb;

    // -----------------------------
    // params
    // -----------------------------
    parameter HALF_CLK = 1;

    // -----------------------------
    // instantiation
    // -----------------------------
    logic clk = 0;

    // -----------------------------
    // sim
    // -----------------------------

    always #HALF_CLK clk = ~clk;

    initial begin

    end

endmodule : tb
