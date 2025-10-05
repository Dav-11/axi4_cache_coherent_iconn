import param_pkg::*;

module noif2if_cpu (
    output logic req_m2dbiu,
    output logic [DBUS_AW-1:0] adr_m2dbiu,
    output logic [DBUS_DW-1:0] dat_m2dbiu,
    output logic we_m2dbiu,
    output logic [DBUS_ISEL-1:0] sel_m2dbiu,

    input [DBUS_DW-1:0] dat_dbiu2m,
    input ack_dbiu2m,

    cpu_iface.slave cpu_if
);
  assign req_m2dbiu = cpu_if.req_m2dbiu;
  assign adr_m2dbiu = cpu_if.adr_m2dbiu;
  assign dat_m2dbiu = cpu_if.dat_m2dbiu;
  assign we_m2dbiu = cpu_if.we_m2dbiu;
  assign sel_m2dbiu = cpu_if.sel_m2dbiu;

  assign cpu_if.dat_dbiu2m = dat_dbiu2m;
  assign cpu_if.ack_dbiu2m = ack_dbiu2m;
endmodule
