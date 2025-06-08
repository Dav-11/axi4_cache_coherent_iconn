interface axi4_aw_if (input logic aclk, input logic arst_n);

    // AW Channel Signals
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

    modport Master (
        output id, addr, len, burst, lock, cache, prot, qos, region, user, valid, size,
        input ready
    );

    modport Slave (
        input id, addr, len, burst, lock, cache, prot, qos, region, user, valid, size,
        output ready
    );

endinterface: axi4_aw_if

interface axi4_w_if;

    logic   [ID_WIDTH-1:0]      id;
    logic   [DATA_WIDTH-1:0]    data;
    logic   [DATA_WIDTH/8-1:0]  strb;
    logic                       last;
    logic   [USER_WIDTH-1:0]    user;
    logic                       valid;
    logic                       ready;

    modport Master (
        output id, data, strb, last, user, valid,
        input ready
    );

    modport Slave (
        input id, data, strb, last, user, valid,
        output ready
    );

endinterface: axi4_w_if

interface axi4_b_if #(
    parameter ID_WIDTH   = 4,
    parameter USER_WIDTH = 0
);

    logic   [ID_WIDTH-1:0]      id;
    axi_resp                    resp;
    logic   [USER_WIDTH-1:0]    user;
    logic                       valid;
    logic                       ready;

    modport Slave (
        output id, resp, user, valid,
        input ready
    );

    modport Master (
        input id, resp, user, valid,
        output ready
    );

endinterface: axi4_b_if

endpackage: axi4_pkg
