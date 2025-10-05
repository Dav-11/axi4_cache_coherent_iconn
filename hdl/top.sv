import param_pkg::*;
module top (
    input clk,
    input resetn,

    input [N_CPU-1:0] req_m2dbiu,
    input [N_CPU * DBUS_AW - 1:0] adr_m2dbiu_flat,
    input [N_CPU * DBUS_DW - 1:0] dat_m2dbiu_flat,
    input [N_CPU-1:0] we_m2dbiu,
    input [N_CPU * DBUS_ISEL - 1:0] sel_m2dbiu_flat,

    output logic [N_CPU * DBUS_DW - 1:0] dat_dbiu2m_flat,
    output logic [N_CPU-1:0] ack_dbiu2m
);

  logic [N_CPU-1:0][     DBUS_AW-1:0] adr_m2dbiu;
  logic [N_CPU-1:0][     DBUS_DW-1:0] dat_m2dbiu;
  logic [N_CPU-1:0][   DBUS_ISEL-1:0] sel_m2dbiu;
  logic [N_CPU-1:0][     DBUS_DW-1:0] dat_dbiu2m;

  //=============== AR CHANNEL ===============
  logic [N_CPU-1:0]                   ar_ready;

  logic [N_CPU-1:0][    ID_WIDTH-1:0] ar_id;
  logic [N_CPU-1:0][  ADDR_WIDTH-1:0] ar_addr;
  logic [N_CPU-1:0][             7:0] ar_len;
  logic [N_CPU-1:0][             2:0] ar_size;
  logic [N_CPU-1:0][             1:0] ar_burst;
  logic [N_CPU-1:0][             2:0] ar_prot;
  logic [N_CPU-1:0][             3:0] ar_snoop;
  logic [N_CPU-1:0][             1:0] ar_domain;
  logic [N_CPU-1:0]                   ar_valid;

  //=============== R CHANNEL ===============
  logic [N_CPU-1:0]                   r_valid;
  logic [N_CPU-1:0]                   r_last;
  logic [N_CPU-1:0][  RESP_WIDTH-1:0] r_resp;
  logic [N_CPU-1:0][    ID_WIDTH-1:0] r_id;
  logic [N_CPU-1:0][  DATA_WIDTH-1:0] r_data;

  logic [N_CPU-1:0]                   r_ready;

  //=============== AW CHANNEL ===============
  logic [N_CPU-1:0]                   aw_ready;

  logic [N_CPU-1:0][    ID_WIDTH-1:0] aw_id;
  logic [N_CPU-1:0][  ADDR_WIDTH-1:0] aw_addr;
  logic [N_CPU-1:0][             7:0] aw_len;
  logic [N_CPU-1:0][             2:0] aw_size;
  logic [N_CPU-1:0][             1:0] aw_burst;
  logic [N_CPU-1:0][             2:0] aw_prot;
  logic [N_CPU-1:0][             2:0] aw_snoop;
  logic [N_CPU-1:0][             1:0] aw_domain;
  logic [N_CPU-1:0]                   aw_valid;

  //=============== W CHANNEL ===============
  logic [N_CPU-1:0]                   w_ready;

  logic [N_CPU-1:0]                   w_valid;
  logic [N_CPU-1:0]                   w_last;
  logic [N_CPU-1:0][  STRB_WIDTH-1:0] w_strb;
  logic [N_CPU-1:0][  DATA_WIDTH-1:0] w_data;

  //=============== B CHANNEL ===============
  logic [N_CPU-1:0]                   b_valid;
  logic [N_CPU-1:0][    ID_WIDTH-1:0] b_id;

  logic [N_CPU-1:0]                   b_ready;

  //=============== AC CHANNEL===============
  logic [N_CPU-1:0]                   ac_ready;

  logic [N_CPU-1:0][  ADDR_WIDTH-1:0] ac_addr;
  logic [N_CPU-1:0][             2:0] ac_prot;
  logic [N_CPU-1:0][             3:0] ac_snoop;
  logic [N_CPU-1:0]                   ac_valid;

  //=============== CR CHANNEL ==============
  logic [N_CPU-1:0]                   cr_ready;

  logic [N_CPU-1:0]                   cr_valid;
  logic [N_CPU-1:0][CRRESP_WIDTH-1:0] cr_resp;

  //=============== CD CHANNEL ==============
  logic [N_CPU-1:0]                   cd_ready;

  logic [N_CPU-1:0]                   cd_valid;
  logic [N_CPU-1:0]                   cd_last;
  logic [N_CPU-1:0][  DATA_WIDTH-1:0] cd_data;

  logic [N_CPU-1:0]                   wack_vect;
  logic [N_CPU-1:0]                   rack_vect;

  generate
    for (genvar i = 0; i < N_CPU; i++) begin
      assign adr_m2dbiu[i] = adr_m2dbiu_flat[i*DBUS_AW+:DBUS_AW];
      assign dat_m2dbiu[i] = dat_m2dbiu_flat[i*DBUS_DW+:DBUS_DW];
      assign sel_m2dbiu[i] = sel_m2dbiu_flat[i*DBUS_ISEL+:DBUS_ISEL];
      assign dat_dbiu2m_flat[i*DBUS_DW+:DBUS_DW] = dat_dbiu2m[i];
    end
  endgenerate

  generate
    for (genvar i = 0; i < N_CPU; i = i + 1) begin : l1
      l1_controller_noif #(
          .CPU_ID(i)
      ) l1_controller_inst (
          .clk(clk),
          .resetn(resetn),

          .req_m2dbiu(req_m2dbiu[i]),
          .adr_m2dbiu(adr_m2dbiu[i]),
          .dat_m2dbiu(dat_m2dbiu[i]),
          .we_m2dbiu(we_m2dbiu[i]),
          .sel_m2dbiu(sel_m2dbiu[i]),
          .dat_dbiu2m(dat_dbiu2m[i]),
          .ack_dbiu2m(ack_dbiu2m[i]),
          .wack(wack_vect[i]),
          .rack(rack_vect[i]),

          .ar_ready(ar_ready[i]),
          .ar_id(ar_id[i]),
          .ar_addr(ar_addr[i]),
          .ar_len(ar_len[i]),
          .ar_size(ar_size[i]),
          .ar_burst(ar_burst[i]),
          .ar_prot(ar_prot[i]),
          .ar_snoop(ar_snoop[i]),
          .ar_domain(ar_domain[i]),
          .ar_valid(ar_valid[i]),

          .r_valid(r_valid[i]),
          .r_last(r_last[i]),
          .r_resp(r_resp[i]),
          .r_id(r_id[i]),
          .r_data(r_data[i]),
          .r_ready(r_ready[i]),

          .aw_ready(aw_ready[i]),
          .aw_id(aw_id[i]),
          .aw_addr(aw_addr[i]),
          .aw_len(aw_len[i]),
          .aw_size(aw_size[i]),
          .aw_burst(aw_burst[i]),
          .aw_prot(aw_prot[i]),
          .aw_snoop(aw_snoop[i]),
          .aw_domain(aw_domain[i]),
          .aw_valid(aw_valid[i]),

          .w_ready(w_ready[i]),
          .w_valid(w_valid[i]),
          .w_last (w_last[i]),
          .w_strb (w_strb[i]),
          .w_data (w_data[i]),

          .b_valid(b_valid[i]),
          .b_id(b_id[i]),
          .b_ready(b_ready[i]),

          .ac_ready(ac_ready[i]),
          .ac_addr (ac_addr[i]),
          .ac_prot (ac_prot[i]),
          .ac_snoop(ac_snoop[i]),
          .ac_valid(ac_valid[i]),

          .cr_ready(cr_ready[i]),
          .cr_valid(cr_valid[i]),
          .cr_resp (cr_resp[i]),

          .cd_ready(cd_ready[i]),
          .cd_valid(cd_valid[i]),
          .cd_last (cd_last[i]),
          .cd_data (cd_data[i])
      );
    end

    iconn_noif iconn_inst (
        .clk(clk),
        .resetn(resetn),

        .wack_vect_i(wack_vect),
        .rack_vect_i(rack_vect),

        .ar_ready(ar_ready),
        .ar_id(ar_id),
        .ar_addr(ar_addr),
        .ar_len(ar_len),
        .ar_size(ar_size),
        .ar_burst(ar_burst),
        .ar_prot(ar_prot),
        .ar_snoop(ar_snoop),
        .ar_domain(ar_domain),
        .ar_valid(ar_valid),

        .r_valid(r_valid),
        .r_last(r_last),
        .r_resp(r_resp),
        .r_id(r_id),
        .r_data(r_data),
        .r_ready(r_ready),

        .aw_ready(aw_ready),
        .aw_id(aw_id),
        .aw_addr(aw_addr),
        .aw_len(aw_len),
        .aw_size(aw_size),
        .aw_burst(aw_burst),
        .aw_prot(aw_prot),
        .aw_snoop(aw_snoop),
        .aw_domain(aw_domain),
        .aw_valid(aw_valid),

        .w_ready(w_ready),
        .w_valid(w_valid),
        .w_last (w_last),
        .w_strb (w_strb),
        .w_data (w_data),

        .b_valid(b_valid),
        .b_id(b_id),
        .b_ready(b_ready),

        .ac_ready(ac_ready),
        .ac_addr (ac_addr),
        .ac_prot (ac_prot),
        .ac_snoop(ac_snoop),
        .ac_valid(ac_valid),

        .cr_ready(cr_ready),
        .cr_valid(cr_valid),
        .cr_resp (cr_resp),

        .cd_ready(cd_ready),
        .cd_valid(cd_valid),
        .cd_last (cd_last),
        .cd_data (cd_data)
    );

  endgenerate
endmodule
