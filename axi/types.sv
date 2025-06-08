// -------------------------
//  AXI4 Type Definitions
// -------------------------

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

typedef enum logic [1:0] {
    OKAY        = 2'b00,
    EXOKAY      = 2'b01,
    SLVERR      = 2'b10,
    DECERR      = 2'b11
} axi_resp;

typedef enum logic [2:0] {
    S_001       = 3'b000,
    S_002       = 3'b001,
    S_004       = 3'b010,
    S_008       = 3'b011,
    S_016       = 3'b100,
    S_032       = 3'b101,
    S_064       = 3'b110,
    S_128       = 3'b111
} axi_burst_size;

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

typedef enum logic  [3:0] {
    READ_ONCE               = 4'b0000,
    READ_SHARED             = 4'b0001,
    READ_CLEAN              = 4'b0010,
    READ_NOT_SHARED_DIRTY   = 4'b0011,
    READ_UNIQUE             = 4'b0111,
    CLEAN_SHARED            = 4'b1000,
    CLEAN_INVALID           = 4'b1001,
    MAKE_INVALID            = 4'b1101,
    DVM_COMPLETE            = 4'b1110,
    DVM_MESSAGE             = 4'b1111,
} ace_ac_snoop;
