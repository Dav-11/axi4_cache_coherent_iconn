package clock_pkg;

  import func_param_pkg::*;

  class ClockDomain;
    bit clk;

    function new();
      clk = 1;
    endfunction

    task start();
      fork
        forever begin
          #`HALF_CLK_PERIOD clk = ~clk;
        end
      join_none
    endtask
  endclass

endpackage
