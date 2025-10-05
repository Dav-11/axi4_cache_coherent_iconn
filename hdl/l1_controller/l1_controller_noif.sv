import param_pkg::*;
module l1_controller_noif #(
    parameter logic [CPU_ID_WIDTH-1:0] CPU_ID = 0
)(
    input clk, 
    input resetn,

    input req_m2dbiu,
    input [DBUS_AW-1:0] adr_m2dbiu,
    input [DBUS_DW-1:0] dat_m2dbiu,
    input we_m2dbiu,
    input [DBUS_ISEL-1:0] sel_m2dbiu,

    output logic [DBUS_DW-1:0] dat_dbiu2m,
    output logic ack_dbiu2m,

    output logic wack,
    output logic rack,
    
    output logic ac_ready,

    input [ADDR_WIDTH-1:0]   ac_addr,
    input [2:0]  ac_prot,
    input [3:0]  ac_snoop,
    input ac_valid,
//=============== CR CHANNEL ==============
    input cr_ready,

    output logic cr_valid,
    output logic [CRRESP_WIDTH-1:0]  cr_resp,
//=============== CD CHANNEL ==============
    input cd_ready,

    output logic cd_valid,
    output logic cd_last,
    output logic [DATA_WIDTH-1:0]  cd_data,

    //=============== AR CHANNEL ===============
    input ar_ready,
    
    output logic [ID_WIDTH-1:0]     ar_id,
    output logic [ADDR_WIDTH-1:0]   ar_addr,
    output logic [7:0]  ar_len,
    output logic [2:0]  ar_size,
    output logic [1:0]  ar_burst,
    output logic [2:0]  ar_prot,
    output logic [3:0]  ar_snoop,
    output logic [1:0]  ar_domain,
    output logic ar_valid,
//=============== R CHANNEL ===============
    input r_valid,
    input r_last,
    input [RESP_WIDTH-1:0]  r_resp,
    input [ID_WIDTH-1:0]    r_id,
    input [DATA_WIDTH-1:0]  r_data,
    
    output logic r_ready,

//=============== AW CHANNEL ===============
    input aw_ready,

    output logic [ID_WIDTH-1:0]     aw_id,
    output logic [ADDR_WIDTH-1:0]   aw_addr,
    output logic [7:0]  aw_len,
    output logic [2:0]  aw_size,
    output logic [1:0]  aw_burst,
    output logic [2:0]  aw_prot,
    output logic [2:0]  aw_snoop,
    output logic [1:0]  aw_domain,
    output logic aw_valid,
//=============== W CHANNEL ===============
    input w_ready,

    output logic w_valid,
    output logic w_last,
    output logic[STRB_WIDTH-1:0]  w_strb,
    output logic [DATA_WIDTH-1:0]  w_data,
//=============== B CHANNEL ===============
    input b_valid,
    input [ID_WIDTH-1:0]    b_id,

    output logic b_ready

    );   

    logic ready_a2c;
    logic ack_a2c;
    response_a2c_t response_a2c;
    logic [L1_INTERNAL_DW-1:0] data_a2c;
    logic valid_a2c;


    logic ack_c2a;
    transaction_type_t transaction_c2a;
    logic [L1_INTERNAL_AW-1:0] adr_c2a;
    logic valid_c2a;
    logic [L1_INTERNAL_DW-1:0] data_c2a;
    //C -> B
    response_c2b_t response_c2b;
    logic [L1_INTERNAL_DW-1:0] data_c2b;
    logic ack_c2b;
    //B -> C
    logic valid_b2c;
    logic acq_b2c;
    logic rel_b2c;
    logic [L1_INTERNAL_AW-1:0] adr_b2c;
    snoop_req_t snoop_req_b2c;
    //A -> B
    logic hit_a2b;
    transient_state_t transient_state_a2b;
    logic ack_a2b;
    //B-> A
    snoop_req_t snoop_req_b2a;
    logic [L1_INTERNAL_AW-1:0] adr_b2a;
    logic valid_b2a;
    logic acq_b2a;

    fsm_c inst0_c (
        .clk(clk),
        .resetn(resetn),
        .req_m2dbiu(req_m2dbiu),
        .adr_m2dbiu(adr_m2dbiu),
        .dat_m2dbiu(dat_m2dbiu), 
        .we_m2dbiu(we_m2dbiu),
        .sel_m2dbiu(sel_m2dbiu),

        .ready_a2c(ready_a2c),
        .ack_a2c(ack_a2c),
        .response_a2c(response_a2c),
        .data_a2c(data_a2c),
        .valid_a2c(valid_a2c),

        .valid_b2c(valid_b2c),
        .acq_b2c(acq_b2c),
        .rel_b2c(rel_b2c),
        .adr_b2c(adr_b2c),
        .snoop_req_b2c(snoop_req_b2c),

        .dat_dbiu2m(dat_dbiu2m),
        .ack_dbiu2m(ack_dbiu2m),

        .ack_c2a(ack_c2a),
        .transaction_c2a(transaction_c2a),
        .adr_c2a(adr_c2a),
        .valid_c2a(valid_c2a),
        .data_c2a(data_c2a),

        .response_c2b(response_c2b),
        .data_c2b(data_c2b),
        .ack_c2b(ack_c2b)
    );

    fsm_a_noif #(.CPU_ID(CPU_ID)) inst0_a (
        .aclk(clk),
        .aresetn(resetn),

        .adr_c2a(adr_c2a),
        .ack_c2a(ack_c2a),
        .data_c2a(data_c2a),
        .valid_c2a(valid_c2a),
        .transaction_c2a(transaction_c2a),

        .data_a2c(data_a2c),
        .valid_a2c(valid_a2c),
        .response_a2c(response_a2c),
        .ready_a2c(ready_a2c),
        .ack_a2c(ack_a2c),

        .hit_a2b(hit_a2b),
        .transient_state_a2b(transient_state_a2b),
        .ack_a2b(ack_a2b),
        .snoop_req_b2a(snoop_req_b2a),
        .adr_b2a(adr_b2a),
        .valid_b2a(valid_b2a),
        .acq_b2a(acq_b2a),
        
        .wack(wack),
        .rack(rack),
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
        .r_ready(r_ready),
        .r_valid(r_valid),
        .r_last(r_last),
        .r_resp(r_resp),
        .r_id(r_id),
        .r_data(r_data),
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
        .w_last(w_last),
        .w_strb(w_strb),
        .w_data(w_data),
        .b_ready(b_ready),
        .b_valid(b_valid),
        .b_id(b_id)

    );

    fsm_b_noif inst0_b (
        .clk(clk),
        .resetn(resetn),
        .response_c2b(response_c2b),
        .data_c2b(data_c2b),
        .ack_c2b(ack_c2b),
        .ack_a2b(ack_a2b),
        .hit_a2b(hit_a2b),
        .transient_state_a2b(transient_state_a2b),
        .valid_b2a(valid_b2a),
        .acq_b2a(acq_b2a),
        .valid_b2c(valid_b2c),
        .adr_b2c(adr_b2c),
        .acq_b2c(acq_b2c),
        .rel_b2c(rel_b2c),
        .adr_b2a(adr_b2a),
        .snoop_req_b2a(snoop_req_b2a),
        .snoop_req_b2c(snoop_req_b2c),
        .ac_ready(ac_ready),
        .ac_addr(ac_addr),
        .ac_prot(ac_prot),
        .ac_snoop(ac_snoop),
        .ac_valid(ac_valid),
        .cr_ready(cr_ready),
        .cr_valid(cr_valid),
        .cr_resp(cr_resp),
        .cd_ready(cd_ready),
        .cd_valid(cd_valid),
        .cd_last(cd_last),
        .cd_data(cd_data)
    );
endmodule
