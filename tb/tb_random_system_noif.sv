`include "../hdl/common/utils.sv"
`include "tester.sv"
`include "adapters/bridge_cpu.sv"

module tb_random_system_noif ();
  import param_pkg::*;

  logic clk;
  logic resetn;

  logic [0:N_CPU-1] req_m2dbiu;
  logic [0:N_CPU-1][DBUS_AW-1:0] adr_m2dbiu;
  logic [0:N_CPU-1][DBUS_DW-1:0] dat_m2dbiu;
  logic [0:N_CPU-1] we_m2dbiu;
  logic [0:N_CPU-1][DBUS_ISEL-1:0] sel_m2dbiu;

  logic [0:N_CPU-1][DBUS_DW-1:0] dat_dbiu2m;
  logic [0:N_CPU-1] ack_dbiu2m;

  logic [N_CPU * DBUS_AW - 1:0] adr_m2dbiu_flat;
  logic [N_CPU * DBUS_DW - 1:0] dat_m2dbiu_flat;
  logic [N_CPU * DBUS_ISEL - 1:0] sel_m2dbiu_flat;
  logic [N_CPU * DBUS_DW - 1:0] dat_dbiu2m_flat;

  bridge_cpu cpu_bridges[0:N_CPU-1];

  RandomTester tester;
  ClockDomain clk_domain;
  cpu_iface cpu_ifs[0:N_CPU-1] ();

  generate
    for (genvar i = 0; i < N_CPU; i++) begin
      assign adr_m2dbiu_flat[i*DBUS_AW+:DBUS_AW] = adr_m2dbiu[i];
      assign dat_m2dbiu_flat[i*DBUS_DW+:DBUS_DW] = dat_m2dbiu[i];
      assign sel_m2dbiu_flat[i*DBUS_ISEL+:DBUS_ISEL] = sel_m2dbiu[i];
      assign dat_dbiu2m[i] = dat_dbiu2m_flat[i*DBUS_DW+:DBUS_DW];
    end
  endgenerate

  generate
    for (genvar i = 0; i < N_CPU; i++) begin
      noif2if_cpu noif2if_cpu_inst (
          .req_m2dbiu(req_m2dbiu[i]),
          .adr_m2dbiu(adr_m2dbiu[i]),
          .dat_m2dbiu(dat_m2dbiu[i]),
          .we_m2dbiu(we_m2dbiu[i]),
          .sel_m2dbiu(sel_m2dbiu[i]),
          .dat_dbiu2m(dat_dbiu2m[i]),
          .ack_dbiu2m(ack_dbiu2m[i]),
          .cpu_if(cpu_ifs[i])
      );
    end
  endgenerate

  top system_random_inst (
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


  always begin
    #5ns clk = ~clk;
  end

  initial begin
    int trash = $urandom(123);
    clk_domain = new();

    tester = new(clk_domain);

    for (int i = 0; i < N_CPU; i++) begin
      cpu_bridges[i] = new(cpu_ifs, i, tester);
      tester.addCpuBridge(cpu_bridges[i], i);
    end

    for (int i = 0; i < N_CPU; i++) begin
      fork
        automatic int j = i;
        cpu_bridges[j].mandatory_q_loop(clk);
        cpu_bridges[j].cycleCounter(clk);
      join_none
    end

    clk_domain.start();

    tester.main_loop();

    $display("[[[TESTER MAINLOOP EXITED]]]");
    $finish;

  end

  initial begin
    //$dumpfile("dump.vcd");
    //$dumpvars(0, tb_random_system_noif);
    clk = 1'b1;
    resetn = 1'b0;
    repeat (10) @(posedge clk);
    resetn <= 1'b1;
    //$dumpoff;
    //#43ms;
    //$dumpon;
  end

endmodule
