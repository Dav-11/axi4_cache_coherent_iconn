
// -----------------------------------------------------------
//  AXI4 Channels Definitions
// -----------------------------------------------------------

typedef struct packed {
    logic   [ID_WIDTH-1:0]      id;
    logic   [ADDR_WIDTH-1:0]    addr;
    logic   [7:0]               len;
    axi_burst_size              size;
    axi_burst                   burst;
    axi_lock                    lock;
    axi_aw_cache                cache;
    axi_prot                    prot;
    logic   [3:0]               qos;
    logic   [3:0]               region;
    logic   [USER_WIDTH-1:0]    user;
    logic                       valid;
    logic                       ready;
} axi4_aw_t;

typedef struct packed {
    logic   [ID_WIDTH-1:0]      id;
    logic   [DATA_WIDTH-1:0]    data;
    logic   [DATA_WIDTH/8-1:0]  strb;
    logic                       last;
    logic   [USER_WIDTH-1:0]    user;
    logic                       valid;
    logic                       ready;
} axi4_w_t;

typedef struct packed {
    logic   [ID_WIDTH-1:0]      id;
    axi_resp                    resp;
    logic   [USER_WIDTH-1:0]    user;
    logic                       valid;
    logic                       ready;
} axi4_b_t;

typedef struct packed {
    logic   [ID_WIDTH-1:0]      id;
    logic   [ADDR_WIDTH-1:0]    addr;
    logic   [7:0]               len;
    axi_burst_size              size;
    axi_burst                   burst;
    axi_lock                    lock;
    axi_ar_cache                cache;
    axi_prot                    prot;
    logic   [3:0]               qos;
    logic   [3:0]               region;
    logic   [USER_WIDTH-1:0]    user;
    logic                       valid;
    logic                       ready;
} axi4_ar_t;

typedef struct packed {
    logic   [ID_WIDTH-1:0]      id;
    logic   [DATA_WIDTH-1:0]    data;
    axi_resp                    resp;
    logic                       last;
    logic   [USER_WIDTH-1:0]    user;
    logic                       valid;
    logic                       ready;
} axi4_r_t;
