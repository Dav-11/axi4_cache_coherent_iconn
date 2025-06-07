package axi4_pkg;

    import params_pkg::*;

    // -----------------------------------------------------------
    //  AXI4 Type Definitions
    // -----------------------------------------------------------

    typedef enum logic [1:0] {
        FIXED       = 2'b00,
        INCR        = 2'b01,
        WRAP        = 2'b10,
        RESERVED    = 2'b11
    } axi_burst;

    typedef enum logic {
        NORMAL      = 1'b0,
        EXCLUSIVE   = 1'b1
    } axi_lock;

    typedef enum logic[3:0] {
        DEV_NON_BUFFERABLE                  = 4'b0000,
        DEV_BUFFERABLE                      = 4'b0001,

        NORMAL_NC_NBUF                      = 4'b0010, // Normal Non-cacheable Non-bufferable
        NORMAL_NC_BUF                       = 4'b0011, // Normal Non-cacheable Bufferable

        WRITE_THROUGH_NO_ALLOCATE           = 4'b0110,
        WRITE_THROUGH_READ_ALLOCATE         = 4'b0110,
        WRITE_THROUGH_WRITE_ALLOCATE        = 4'b1110,
        WRITE_THROUGH_READ_WRITE_ALLOCATE   = 4'b1110,

        WRITE_BACK_NO_ALLOCATE              = 4'b0111,
        WRITE_BACK_READ_ALLOCATE            = 4'b0111,
        WRITE_BACK_WRITE_ALLOCATE           = 4'b1111,
        WRITE_BACK_READ_WRITE_ALLOCATE      = 4'b1111
    } axi_aw_cache;

    typedef enum logic[3:0] {
        DEV_NON_BUFFERABLE                  = 4'b0000,
        DEV_BUFFERABLE                      = 4'b0001,

        NORMAL_NC_NBUF                      = 4'b0010, // Normal Non-cacheable Non-bufferable
        NORMAL_NC_BUF                       = 4'b0011, // Normal Non-cacheable Bufferable

        WRITE_THROUGH_NO_ALLOCATE           = 4'b1010,
        WRITE_THROUGH_READ_ALLOCATE         = 4'b1110,
        WRITE_THROUGH_WRITE_ALLOCATE        = 4'b1010,
        WRITE_THROUGH_READ_WRITE_ALLOCATE   = 4'b1110,

        WRITE_BACK_NO_ALLOCATE              = 4'b1011,
        WRITE_BACK_READ_ALLOCATE            = 4'b1111,
        WRITE_BACK_WRITE_ALLOCATE           = 4'b1011,
        WRITE_BACK_READ_WRITE_ALLOCATE      = 4'b1111
    } axi_ar_cache;

    // Bit [2] is Privileged/Unprivileged
    // Bit [1] is Secure/Non-secure
    // Bit [0] is Instruction/Data
    typedef enum logic [2:0] {
        PROT_UNPRIVILEGED_NON_SECURE_DATA   = 3'b000, // Unprivileged, Non-secure, Data
        PROT_UNPRIVILEGED_NON_SECURE_INSTR  = 3'b001, // Unprivileged, Non-secure, Instruction

        PROT_UNPRIVILEGED_SECURE_DATA       = 3'b010, // Unprivileged, Secure, Data
        PROT_UNPRIVILEGED_SECURE_INSTR      = 3'b011, // Unprivileged, Secure, Instruction

        PROT_PRIVILEGED_NON_SECURE_DATA     = 3'b100, // Privileged, Non-secure, Data
        PROT_PRIVILEGED_NON_SECURE_INSTR    = 3'b101, // Privileged, Non-secure, Instruction

        PROT_PRIVILEGED_SECURE_DATA         = 3'b110, // Privileged, Secure, Data
        PROT_PRIVILEGED_SECURE_INSTR        = 3'b111  // Privileged, Secure, Instruction
    } axi_prot;

    typedef enum logic [1:0] {
        OKAY    = 2'b00,
        EXOKAY  = 2'b01,
        SLVERR  = 2'b10,
        DECERR  = 2'b11
    } axi_resp;


    // -----------------------------------------------------------
    //  AXI4 Channels Definitions
    // -----------------------------------------------------------

    interface axi4_aw_if;

        // AW Channel Signals
        logic   [ID_WIDTH-1:0]      id;
        logic   [ADDR_WIDTH-1:0]    addr;
        logic   [7:0]               len;
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
            output id, addr, len, burst, lock, cache, prot, qos, region, user, valid,
            input ready
        );

        modport Slave (
            input id, addr, len, burst, lock, cache, prot, qos, region, user, valid,
            output ready
        );

    endinterface: axi4_aw_if

    interface axi4_w_if #(
        parameter DATA_WIDTH = 32,
        parameter ID_WIDTH   = 4,
        parameter USER_WIDTH = 0
    );

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
