import params_pkg::*;

module cache_controller (
    input logic aclk,
    input logic arst_n,

    // -----------------------------
    //  AW (Write Address) Channel
    // -----------------------------
    output logic          [  ID_WIDTH-1:0] aw_id,
    output logic          [ADDR_WIDTH-1:0] aw_addr,
    output logic          [           7:0] aw_len,
    output axi_burst_size                  aw_size,
    output axi_burst                       aw_burst,
    output axi_lock                        aw_lock,
    output axi_aw_cache                    aw_cache,
    output axi_prot                        aw_prot,
    output logic          [           3:0] aw_qos,
    output logic          [           3:0] aw_region,
    output logic          [USER_WIDTH-1:0] aw_user,
    output logic                           aw_valid,
    input  logic                           aw_ready,
    output logic          [           1:0] aw_domain,
    output logic          [           2:0] aw_snoop,
    output logic          [           1:0] aw_bar,
    output logic                           aw_unique,

    // -----------------------------
    //  W (Write Data) Channel
    // -----------------------------
    output logic [    ID_WIDTH-1:0] w_id,
    output logic [  DATA_WIDTH-1:0] w_data,
    output logic [DATA_WIDTH/8-1:0] w_strb,
    output logic                    w_last,
    output logic [  USER_WIDTH-1:0] w_user,
    output logic                    w_valid,
    input  logic                    w_ready,

    // -----------------------------
    //  B (Write Response) Channel
    // -----------------------------
    input  logic    [  ID_WIDTH-1:0] b_id,
    input  axi_resp                  b_resp,
    input  logic    [USER_WIDTH-1:0] b_user,
    input  logic                     b_valid,
    output logic                     b_ready,

    // -----------------------------
    //  AR (Address Read) Channel
    // -----------------------------
    output logic          [  ID_WIDTH-1:0] ar_id,
    output logic          [ADDR_WIDTH-1:0] ar_addr,
    output logic          [           7:0] ar_len,
    output axi_burst_size                  ar_size,
    output axi_burst                       ar_burst,
    output axi_lock                        ar_lock,
    output axi_ar_cache                    ar_cache,
    output axi_prot                        ar_prot,
    output logic          [           3:0] ar_qos,
    output logic          [           3:0] ar_region,
    output logic          [USER_WIDTH-1:0] ar_user,
    output logic                           ar_valid,
    input  logic                           ar_ready,
    output logic          [           1:0] ar_domain,
    output logic          [           3:0] ar_snoop,
    output logic          [           1:0] ar_bar,

    // -----------------------------
    //  R (Data Read) Channel
    // -----------------------------
    input  logic    [  ID_WIDTH-1:0] r_id,
    input  logic    [DATA_WIDTH-1:0] r_data,
    input  axi_resp                  r_resp_axi,
    input  logic    [           1:0] r_resp_ace,
    input  logic                     r_last,
    input  logic    [USER_WIDTH-1:0] r_user,
    input  logic                     r_valid,
    output logic                     r_ready,

    // -----------------------------
    //  AC (Snoop Address) Channel
    // -----------------------------
    input  logic                                    ac_valid,
    output logic                                    ac_ready,
    input  logic        [SNOOP_ADD_BUS_WIDTH - 1:0] ac_addr,
    input  ace_ac_snoop                             ac_snoop,
    input  logic        [                      2:0] ac_prot,

    // -----------------------------
    //  CR (Snoop Response) Channel
    // -----------------------------
    output logic       cr_valid,
    input  logic       cr_ready,
    output logic [4:0] cr_resp,

    // -----------------------------
    //  CD (Snoop Data) Channel
    // -----------------------------
    output logic                            cd_valid,
    input  logic                            cd_ready,
    output logic [SNOOP_DATA_BUS_WIDTH-1:0] cd_data,
    output logic                            cd_last,

    // -----------------------------
    //  ACE ACK signals
    // -----------------------------
    output logic r_ack,
    output logic w_ack
);

endmodule : cache_controller
