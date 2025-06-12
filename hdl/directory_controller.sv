import params_pkg::*;

module directory_controller (
    input logic aclk,
    input logic arst_n,

    // -----------------------------
    //  AW (Write Address) Channel
    // -----------------------------
    input  logic            [  ID_WIDTH-1:0] aw_id,
    input  logic            [ADDR_WIDTH-1:0] aw_addr,
    input  logic            [           7:0] aw_len,
    input  axi_burst_size_e                  aw_size,
    input  axi_burst_e                       aw_burst,
    input  axi_lock_e                        aw_lock,
    input  axi_aw_cache_e                    aw_cache,
    input  axi_prot_e                        aw_prot,
    input  logic            [           3:0] aw_qos,
    input  logic            [           3:0] aw_region,
    input  logic            [USER_WIDTH-1:0] aw_user,
    input  logic                             aw_valid,
    output logic                             aw_ready,
    input  logic            [           1:0] aw_domain,
    input  logic            [           2:0] aw_snoop,
    input  logic            [           1:0] aw_bar,
    input  logic                             aw_unique,

    // -----------------------------
    //  W (Write Data) Channel
    // -----------------------------
    input  logic [    ID_WIDTH-1:0] w_id,
    input  logic [  DATA_WIDTH-1:0] w_data,
    input  logic [DATA_WIDTH/8-1:0] w_strb,
    input  logic                    w_last,
    input  logic [  USER_WIDTH-1:0] w_user,
    input  logic                    w_valid,
    output logic                    w_ready,

    // -----------------------------
    //  B (Write Response) Channel
    // -----------------------------
    output logic      [  ID_WIDTH-1:0] b_id,
    output axi_resp_e                  b_resp,
    output logic      [USER_WIDTH-1:0] b_user,
    output logic                       b_valid,
    input  logic                       b_ready,

    // -----------------------------
    //  AR (Address Read) Channel
    // -----------------------------
    input  logic            [  ID_WIDTH-1:0] ar_id,
    input  logic            [ADDR_WIDTH-1:0] ar_addr,
    input  logic            [           7:0] ar_len,
    input  axi_burst_size_e                  ar_size,
    input  axi_burst_e                       ar_burst,
    input  axi_lock_e                        ar_lock,
    input  axi_ar_cache_e                    ar_cache,
    input  axi_prot_e                        ar_prot,
    input  logic            [           3:0] ar_qos,
    input  logic            [           3:0] ar_region,
    input  logic            [USER_WIDTH-1:0] ar_user,
    input  logic                             ar_valid,
    output logic                             ar_ready,
    input  logic            [           1:0] ar_domain,
    input  logic            [           3:0] ar_snoop,
    input  logic            [           1:0] ar_bar,

    // -----------------------------
    //  R (Data Read) Channel
    // -----------------------------
    output logic      [  ID_WIDTH-1:0] r_id,
    output logic      [DATA_WIDTH-1:0] r_data,
    output axi_resp_e                  r_resp_axi,
    output logic      [           1:0] r_resp_ace,
    output logic                       r_last,
    output logic      [USER_WIDTH-1:0] r_user,
    output logic                       r_valid,
    input  logic                       r_ready,

    // -----------------------------
    //  AC (Snoop Address) Channel
    // -----------------------------
    output logic                                      ac_valid,
    input  logic                                      ac_ready,
    output logic          [SNOOP_ADD_BUS_WIDTH - 1:0] ac_addr,
    output ace_ac_snoop_e                             ac_snoop,
    output logic          [                      2:0] ac_prot,

    // -----------------------------
    //  CR (Snoop Response) Channel
    // -----------------------------
    input  logic       cr_valid,
    output logic       cr_ready,
    input  logic [4:0] cr_resp,

    // -----------------------------
    //  CD (Snoop Data) Channel
    // -----------------------------
    input  logic                            cd_valid,
    output logic                            cd_ready,
    input  logic [SNOOP_DATA_BUS_WIDTH-1:0] cd_data,
    input  logic                            cd_last,

    // -----------------------------
    //  ACE ACK signals
    // -----------------------------
    input logic r_ack,
    input logic w_ack
);

endmodule : directory_controller
