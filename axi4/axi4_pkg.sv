package axi4_pkg;

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

    // Bit [2] is Privileged/Unprivileged
    // Bit [1] is Secure/Non-secure
    // Bit [0] is Instruction/Data
    typedef enum logic [2:0] {
        PROT_UNPRIVILEGED_NON_SECURE_DATA     = 3'b000, // Unprivileged, Non-secure, Data
        PROT_UNPRIVILEGED_NON_SECURE_INSTR    = 3'b001, // Unprivileged, Non-secure, Instruction

        PROT_UNPRIVILEGED_SECURE_DATA         = 3'b010, // Unprivileged, Secure, Data
        PROT_UNPRIVILEGED_SECURE_INSTR        = 3'b011, // Unprivileged, Secure, Instruction

        PROT_PRIVILEGED_NON_SECURE_DATA       = 3'b100, // Privileged, Non-secure, Data
        PROT_PRIVILEGED_NON_SECURE_INSTR      = 3'b101, // Privileged, Non-secure, Instruction

        PROT_PRIVILEGED_SECURE_DATA           = 3'b110, // Privileged, Secure, Data
        PROT_PRIVILEGED_SECURE_INSTR          = 3'b111  // Privileged, Secure, Instruction
    } axi_prot;


    // -----------------------------------------------------------
    //  AXI4 Interfaces Definitions
    // -----------------------------------------------------------

    interface axi4_aw_if #(
        parameter ADDR_WIDTH = 32,
        parameter ID_WIDTH   = 4,
        parameter USER_WIDTH = 0 // AXI4-Lite often has 0 user bits
    );

        // AW Channel Signals
        logic   [ID_WIDTH-1:0]      id;
        logic   [ADDR_WIDTH-1:0]    addr;
        logic   [7:0]               len;
        axi_burst                   burst;
        axi_lock                    lock;

        axi_prot                    prot;


        modport Master (
            output id, addr, len, burst, lock,
            input
        );

    endinterface: axi4_aw_if

endpackage: axi4_pkg
