interface cpu_iface;
    import param_pkg::*;

    logic req_m2dbiu;
    logic [DBUS_AW-1:0] adr_m2dbiu;
    logic [DBUS_DW-1:0] dat_m2dbiu;
    logic  we_m2dbiu;
    logic [DBUS_ISEL-1:0] sel_m2dbiu;

    logic [DBUS_DW-1:0] dat_dbiu2m;
    logic ack_dbiu2m;

    modport master (
        input ack_dbiu2m,
        input dat_dbiu2m,

        output req_m2dbiu,
        output adr_m2dbiu,
        output dat_m2dbiu,
        output we_m2dbiu,
        output sel_m2dbiu
    );
    modport slave (
        output ack_dbiu2m,
        output dat_dbiu2m,

        input req_m2dbiu,
        input adr_m2dbiu,
        input dat_m2dbiu,
        input we_m2dbiu,
        input sel_m2dbiu
    );

endinterface