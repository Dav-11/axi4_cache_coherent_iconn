`timescale 1ns / 10ps

import param_pkg::*;

module tb_l0_s0 ();

  parameter int HALF_CLK = 1;

  parameter logic WORD_ADDR = 8'b0000_0000;

  logic clk = 0;
  logic resetn = 0;

  /*************************************
   * WISHBONE CPU
   ************************************/

  // input
  logic [N_CPU-1:0] req_m2dbiu;
  logic [N_CPU * DBUS_AW - 1:0] adr_m2dbiu_flat;
  logic [N_CPU * DBUS_DW - 1:0] dat_m2dbiu_flat;
  logic [N_CPU-1:0] we_m2dbiu;
  logic [N_CPU * DBUS_ISEL - 1:0] sel_m2dbiu_flat;

  // output
  logic [N_CPU * DBUS_DW - 1:0] dat_dbiu2m_flat;
  logic [N_CPU-1:0] ack_dbiu2m;


  top dut (
      .clk(clk),
      .resetn(resetn),

      .req_m2dbiu(req_m2dbiu),
      .adr_m2dbiu_flat(adr_m2dbiu_flat),
      .dat_m2dbiu_flat(dat_m2dbiu_flat),
      .we_m2dbiu(we_m2dbiu),
      .sel_m2dbiu_flat(sel_m2dbiu_flat),

      .dat_dbiu2m_flat(dat_dbiu2m_flat),
      .ack_dbiu2m(ack_dbiu2m)
  );

  // Clock generation
  always #HALF_CLK clk = ~clk;

  initial begin

    // Initialize all inputs to a known state
    req_m2dbiu = '0;
    adr_m2dbiu_flat = '0;
    dat_m2dbiu_flat = '0;
    we_m2dbiu = '0;
    sel_m2dbiu_flat = '0;

    // assert reset
    resetn <= '0;

    #4

    // unassert reset
    resetn <= '1;

    #2

    // start print
    $display(
        "--------------------------------------------------"
    );
    $display("[T: %0d] Starting Load from CPU 0", $time);

    req_m2dbiu[0] <= 1'b1;
    we_m2dbiu[0] <= 1'b0;
    adr_m2dbiu_flat[0*DBUS_AW+:DBUS_AW] <= WORD_ADDR;

    // sets all bytes used by cpu0 to 1
    sel_m2dbiu_flat[0*DBUS_ISEL+:DBUS_ISEL] <= {DBUS_ISEL{1'b1}};


    wait (ack_dbiu2m[0] == 1'b1);
    $display("[T: %0d] Load Acknowledged for CPU 0. Data received: %h", $time,
             dat_dbiu2m_flat[0*DBUS_DW+:DBUS_DW]);

    #2

    // unassert signals
    req_m2dbiu[0] <= 1'b0;
    we_m2dbiu[0] <= 1'b0;
    adr_m2dbiu_flat[0*DBUS_AW+:DBUS_AW] <= '0;
    sel_m2dbiu_flat[0*DBUS_ISEL+:DBUS_ISEL] <= {DBUS_ISEL{1'b0}};

    #2

    // start store from CPU 0
    $display(
        "--------------------------------------------------"
    );
    $display("[T: %0d] Starting Store from CPU 0", $time);

    req_m2dbiu[0] <= 1'b1;
    we_m2dbiu[0] <= 1'b1;  // STORE
    adr_m2dbiu_flat[0*DBUS_AW+:DBUS_AW] <= WORD_ADDR;

    // data to write
    dat_m2dbiu_flat[0*DBUS_DW+:DBUS_DW] <= 64'hFFFF_FFFF_FFFF_FFFF;

    // sets all bytes used by cpu0 to 1
    sel_m2dbiu_flat[0*DBUS_ISEL+:DBUS_ISEL] <= {DBUS_ISEL{1'b1}};


    wait (ack_dbiu2m[0] == 1'b1);
    $display("[T: %0d] Store Acknowledged for CPU 0. Data written: %h", $time,
             dat_m2dbiu_flat[0*DBUS_DW+:DBUS_DW]);


    #2

    // unassert signals
    req_m2dbiu[0] <= 1'b0;
    we_m2dbiu[0]    <= 1'b0;
    adr_m2dbiu_flat[1*DBUS_AW +: DBUS_AW] <= '0;
    sel_m2dbiu_flat[1*DBUS_ISEL +: DBUS_ISEL] <= {DBUS_ISEL{1'b0}};

    #2

    // print final
    $display(
        "--------------------------------------------------"
    );
    $display("[T: %0d] Simulation Finished.", $time);
    $finish;
  end

endmodule
