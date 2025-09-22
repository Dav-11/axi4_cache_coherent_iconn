package param_pkg;
    // Define a macro that return the largest between its 2 inputs
    `define MAX2(v1, v2) ((v1) > (v2) ? (v1) : (v2))

    typedef enum logic [3:0] {
        IDLE,
        BUSY,
        SEND_DATA,
        RECV_DATA,
        SEND_REQUEST,
        RECV_REQUEST,
        SEND_RESPONSE,
        RECV_RESPONSE,
        SEND_SNOOP,
        RECV_SNOOP
    } state_t;

    typedef enum logic [2:0] {
        L1_IDLE,
        LOOKUP_LD,
        LOOKUP_ST
    } l1c_state_t;

    parameter TRANSIENT_STATE_WIDTH = 3;
    typedef enum logic [TRANSIENT_STATE_WIDTH-1:0] {IM, IS, SM, SI, MI, II} transient_state_t;

    typedef enum logic [3:0] {
        IDLE_C,
        HANDLE_CPU_LOAD_C,
        HANDLE_CPU_STORE_C,
        WAIT_SNOOP_C,
        HANDLE_SNOOP_REQ_C,
        HANDLE_SNOOP_DATA_C,
        HANDLE_A_RESP_C,
        HANDLE_A_DATA_C,
        HANDLE_WRITE_BACK_C,
        CHECK_ACK_A2C_C
    } fsm_c_state_t;

    typedef enum logic [3:0] {
        IDLE_B,
        ACQUIRE_C_B,
        ACQUIRE_A_B,
        CHECK_FWD_B,
        HANDLE_HIT_B,
        SEND_SNOOP_TO_C_B,
        READ_RESP_FROM_C_B,
        RECV_DATA_FROM_C_B,
        SEND_CRRESP_B,
        SEND_CDDATA_B,
        SEND_FWD_B
    } fsm_b_state_t;

    typedef enum logic [3:0] {
        IDLE_A,
        RECV_DATA_FROM_C_A,
        SEND_AW_REQ_A,
        SEND_AR_REQ_A,
        SEND_W_DATA_A,
        RECV_B_RESP_A,
        RECV_R_RESP_A,
        SEND_B_RESP_TO_C_A,
        SEND_R_RESP_TO_C_A,
        SEND_DATA_RESP_TO_C_A,
        WAIT_SNOOP_A,
        HANDLE_SNOOP_A
    } fsm_a_state_t;

    typedef enum logic [2:0] {
        IDLE_I,
        WAIT_DATA_I,
        WB_MEM_I,
        UNSET_DIR_I,
        SEND_B_RESP_I,
        WAIT_WACK_I
    } fsm_i_state_t;

    typedef enum logic [3:0] {
        IDLE_L,
        READ_INFO_L,
        SET_INFO_L,
        HANDLE_RC_L,
        RECV_SNOOP_RESP_L,
        WAIT_SNOOP_DATA_L,
        WRITE_BACK_L,
        HANDLE_RU_L,
        SEND_R_RESP_L,
        WAIT_RACK_L
    } fsm_l_state_t;

    typedef enum logic [1:0] {
        REPLACEMENT_OKAY,
        READ_UNIQUE_OKAY,
        READ_CLEAN_OKAY
    } response_a2c_t;

    typedef enum logic [1:0] {
        INVALID,
        VALID_CLEAN,
        VALID_DIRTY
    } response_c2b_t;

    typedef enum logic [1:0] {
        SNOOP_READ_UNIQUE,
        SNOOP_READ_CLEAN
    } snoop_req_t;

    typedef enum logic [2:0] {
        READ_CLEAN,
        READ_UNIQUE,
        READ_UNIQUE_HIT,
        EVICT,
        WRITE_BACK
    } transaction_type_t;

    typedef enum logic [0:0] {
        HANDLE_AW_ARB,
        HANDLE_W_ARB
    } arb_state_t;

    typedef enum logic [0:0] {
        HANDLE_CR_ARB,
        HANDLE_CD_ARB
    } arb_snoop_state_t;

    typedef enum logic [2:0] {
        READ_OP,
        SET_RU_OP,
        SET_RC_OP,
        EVICT_OP,
        WRITE_BACK_OP
    } op_dir_t;

    typedef enum logic [2:0] {
        IDLE_DIR,
        HANDLE_EVICT_DIR,
        HANDLE_WRITE_BACK_DIR,
        HANDLE_READ_INFO_DIR,
        HANDLE_SET_RU_DIR,
        HANDLE_SET_RC_DIR
    } dir_state_t;

    parameter N_CPU = 2;
    parameter MSHR_DEPTH = 1;

    parameter BYTES_PER_WORD = 8;
    parameter BYTES_PER_LINE = 32;
    parameter CPU_ID_WIDTH = $clog2(N_CPU);
    parameter MSHR_ID_WIDTH = `MAX2($clog2(MSHR_DEPTH), 1);
    parameter ID_WIDTH = MSHR_ID_WIDTH + CPU_ID_WIDTH;
    parameter RESP_WIDTH = 3;
    parameter DATA_WIDTH = 32;
    parameter STRB_WIDTH = DATA_WIDTH/8;
    parameter ADDR_WIDTH = 32;
    parameter MEM_DEPTH = 2**ADDR_WIDTH;
    parameter CRRESP_WIDTH = 5;

    // AXI constants
    parameter bit [7:0] AR_LEN = ((BYTES_PER_LINE*8)/DATA_WIDTH) - 1; // 2^AR_LEN = beats in the transaction
    parameter bit [2:0] AR_SIZE = $clog2(DATA_WIDTH/8); // 2^AR_SIZE = bytes per beat (full bus width)
    parameter bit [1:0] AR_BURST = 2'b01; // INCR

    parameter bit [7:0] AW_LEN = ((BYTES_PER_LINE*8)/DATA_WIDTH) - 1; // 2^AW_LEN = beats in the transaction
    parameter bit [2:0] AW_SIZE = $clog2(DATA_WIDTH/8); // 2^AW_SIZE = bytes per beat (full bus width)
    parameter bit [1:0] AW_BURST = 2'b01; // INCR

    // ****************************************************************************
    // *****                       DCACHE PARAMETERS                          *****
    // ****************************************************************************

    parameter OPERAND_WIDTH         = 64;    // Operand width in bits

    // User changeable
    parameter DCACHE_WORDS_PER_BLOCK = BYTES_PER_LINE / BYTES_PER_WORD; // Number of words per block
    parameter DCACHE_SETS = 64;
    parameter DCACHE_WAYS = 4;

    // Fixed. Do not touch!
    parameter DCACHE_BYTES_PER_WORD  = 8;
    parameter DCACHE_BYTE_OFFSET     = $clog2(DCACHE_BYTES_PER_WORD);
    parameter DCACHE_BLOCK_WIDTH     = $clog2(DCACHE_WORDS_PER_BLOCK);
    parameter DCACHE_INDEX_WIDTH     = (DCACHE_SETS == 1) ? 1 : $clog2(DCACHE_SETS);
    parameter DCACHE_TAG_WIDTH       = ADDR_WIDTH - DCACHE_INDEX_WIDTH - DCACHE_BLOCK_WIDTH - DCACHE_BYTE_OFFSET;
    parameter DCACHE_TAG_MSB         = ADDR_WIDTH - 1;
    parameter DCACHE_TAG_LSB         = DCACHE_INDEX_WIDTH + DCACHE_BLOCK_WIDTH + DCACHE_BYTE_OFFSET;
    parameter DCACHE_INDEX_MSB       = DCACHE_TAG_LSB - 1;
    parameter DCACHE_INDEX_LSB       = DCACHE_BLOCK_WIDTH + DCACHE_BYTE_OFFSET;
    parameter DCACHE_BLOCK_MSB       = DCACHE_BLOCK_WIDTH + DCACHE_BYTE_OFFSET - 1;
    parameter DCACHE_BLOCK_LSB       = DCACHE_BYTE_OFFSET;

    // Configuration parameters for tag and data memories. Fixed. Do not touch!
    parameter TAGMEM_AW              = DCACHE_INDEX_WIDTH;
    parameter TAGMEM_DW              = DCACHE_WAYS*(DCACHE_TAG_WIDTH + 1 + 1 + 1) + $clog2(DCACHE_WAYS); // for each way: (tag bits + valid + dirty + outstanding flag), plus write pointer
    parameter TAGMEM_WRPTR_MSB       = TAGMEM_DW - 1;
    parameter TAGMEM_WRPTR_LSB       = TAGMEM_DW - $clog2(DCACHE_WAYS);
    parameter TAGMEM_WAY_WIDTH       = DCACHE_TAG_WIDTH + 2 + 1;
    parameter TAGMEM_WAY_VALID       = DCACHE_TAG_WIDTH;
    parameter TAGMEM_WAY_DIRTY       = DCACHE_TAG_WIDTH + 1;
    parameter TAGMEM_WAY_OUTSTANDING = DCACHE_TAG_WIDTH + 2;
    parameter WAYMEM_AW              = DCACHE_INDEX_WIDTH + DCACHE_BLOCK_WIDTH;
    parameter WAYMEM_DW              = OPERAND_WIDTH;

    // MEM stage -> L1 Controller Bus properties
    parameter DBUS_DW	= 64;
    parameter DBUS_AW	= 32;
    parameter DBUS_ISEL	= DBUS_DW/8;

    // MSHR Parameters
    parameter MSHR_DW = TRANSIENT_STATE_WIDTH + DCACHE_TAG_WIDTH + DCACHE_INDEX_WIDTH;
    parameter MSHR_AW = MSHR_ID_WIDTH;

    parameter TRANSIENT_STATE_MSB = MSHR_DW-1;
    parameter TRANSIENT_STATE_LSB = MSHR_DW-TRANSIENT_STATE_WIDTH;
    parameter MSHR_ADR_MSB = TRANSIENT_STATE_LSB-1;

    parameter MSHR_ID_MSB = ID_WIDTH-1;
    parameter MSHR_ID_LSB = MSHR_ID_MSB - MSHR_ID_WIDTH + 1;

    parameter L1_INTERNAL_DW = 64;
    parameter L1_INTERNAL_AW = 32;

    // Main memory parameters
    parameter MAIN_MEM_DW = BYTES_PER_WORD * 8;
    parameter MAIN_MEM_AW = 27;
    parameter MAIN_MEM_LINE_AW = MAIN_MEM_AW - $clog2(DCACHE_WORDS_PER_BLOCK);

    // Directory memory parameters
    parameter DIR_MEM_WAYS = DCACHE_WAYS*N_CPU;
    parameter DIR_MEM_WAY_WIDTH = DCACHE_TAG_WIDTH + 1 + 1 + N_CPU;
    parameter DIR_MEM_DW = DIR_MEM_WAYS*DIR_MEM_WAY_WIDTH;
    parameter DIR_MEM_AW = DCACHE_INDEX_WIDTH;

    parameter DIR_MEM_VALID = DIR_MEM_WAY_WIDTH - 1;
    parameter DIR_MEM_DIRTY = DIR_MEM_VALID - 1;
    parameter DIR_MEM_SHARERS_MSB = DIR_MEM_DIRTY - 1;
    parameter DIR_MEM_SHARERS_LSB = DIR_MEM_SHARERS_MSB - N_CPU + 1;

    // AXI signals size parameters
    parameter AR_ID_WIDTH = ID_WIDTH;
    parameter AR_ADDR_WIDTH = ADDR_WIDTH;
    parameter AR_LINE_ADDR_WIDTH = DCACHE_TAG_WIDTH + DCACHE_INDEX_WIDTH;
    parameter AR_LEN_WIDTH = 8;
    parameter AR_SIZE_WIDTH = 3;
    parameter AR_BURST_WIDTH = 2;
    parameter AR_PROT_WIDTH = 3;
    parameter AR_SNOOP_WIDTH = 4;
    parameter AR_DOMAIN_WIDTH = 2;


    parameter AW_ID_WIDTH = ID_WIDTH;
    parameter AW_ADDR_WIDTH = ADDR_WIDTH;
    parameter AW_LINE_ADDR_WIDTH = DCACHE_TAG_WIDTH + DCACHE_INDEX_WIDTH;
    parameter AW_LEN_WIDTH = 8;
    parameter AW_SIZE_WIDTH = 3;
    parameter AW_BURST_WIDTH = 2;
    parameter AW_PROT_WIDTH = 3;
    parameter AW_SNOOP_WIDTH = 3;
    parameter AW_DOMAIN_WIDTH = 2;

    parameter CD_DATA_WIDTH = DATA_WIDTH;
    parameter CD_LEN = 8*BYTES_PER_LINE/CD_DATA_WIDTH - 1; // 2 (1+1) beats in the transaction

    parameter AC_PROT_WIDTH = 3;
    parameter AC_SNOOP_WIDTH = 4;
    parameter AC_ADDR_WIDTH = ADDR_WIDTH;

    // Queues parameters
    parameter AR_Q_DATA_WIDTH = AR_ID_WIDTH + AR_ADDR_WIDTH + AR_LEN_WIDTH + AR_SIZE_WIDTH + AR_BURST_WIDTH + AR_PROT_WIDTH + AR_SNOOP_WIDTH + AR_DOMAIN_WIDTH;
    parameter AR_Q_DEPTH = MSHR_DEPTH * N_CPU;

    parameter AW_Q_DATA_WIDTH = AW_ID_WIDTH + AW_ADDR_WIDTH + AW_LEN_WIDTH + AW_SIZE_WIDTH + AW_BURST_WIDTH + AW_PROT_WIDTH + AW_SNOOP_WIDTH + AW_DOMAIN_WIDTH;
    parameter AW_Q_DEPTH = MSHR_DEPTH * N_CPU;

    parameter W_Q_DATA_WIDTH = DATA_WIDTH * (AW_LEN + 1);
    parameter W_Q_DEPTH = MSHR_DEPTH * N_CPU;

    parameter CR_Q_DATA_WIDTH = CRRESP_WIDTH;
    parameter CR_Q_DEPTH = N_CPU;

    parameter CD_Q_DATA_WIDTH = BYTES_PER_LINE * 8;
    parameter CD_Q_DEPTH = N_CPU;

    // AXI signals MSB, LSB parameters
    parameter AW_ID_MSB = AW_Q_DATA_WIDTH-1;
    parameter AW_ID_LSB = AW_ID_MSB - AW_ID_WIDTH + 1;
    parameter AW_ADDR_MSB = AW_ID_LSB - 1;
    parameter AW_ADDR_LSB = AW_ADDR_MSB - AW_ADDR_WIDTH + 1;
    parameter AW_LINE_ADDR_MSB = AW_ADDR_MSB;
    parameter AW_LINE_ADDR_LSB = AW_LINE_ADDR_MSB - AW_LINE_ADDR_WIDTH + 1;
    parameter AW_LEN_MSB = AW_ADDR_LSB - 1;
    parameter AW_LEN_LSB = AW_LEN_MSB - AW_LEN_WIDTH + 1;
    parameter AW_SIZE_MSB = AW_LEN_LSB - 1;
    parameter AW_SIZE_LSB = AW_SIZE_MSB - AW_SIZE_WIDTH + 1;
    parameter AW_BURST_MSB = AW_SIZE_LSB - 1;
    parameter AW_BURST_LSB = AW_BURST_MSB - AW_BURST_WIDTH + 1;
    parameter AW_PROT_MSB = AW_BURST_LSB - 1;
    parameter AW_PROT_LSB = AW_PROT_MSB - AW_PROT_WIDTH + 1;
    parameter AW_SNOOP_MSB = AW_PROT_LSB - 1;
    parameter AW_SNOOP_LSB = AW_SNOOP_MSB - AW_SNOOP_WIDTH + 1;
    parameter AW_DOMAIN_MSB = AW_SNOOP_LSB - 1;
    parameter AW_DOMAIN_LSB = AW_DOMAIN_MSB - AW_DOMAIN_WIDTH + 1;

    parameter AR_ID_MSB = AR_Q_DATA_WIDTH-1;
    parameter AR_ID_LSB = AR_ID_MSB - AR_ID_WIDTH + 1;
    parameter AR_ADDR_MSB = AR_ID_LSB - 1;
    parameter AR_ADDR_LSB = AR_ADDR_MSB - AR_ADDR_WIDTH + 1;
    parameter AR_LINE_ADDR_MSB = AR_ADDR_MSB;
    parameter AR_LINE_ADDR_LSB = AR_LINE_ADDR_MSB - AR_LINE_ADDR_WIDTH + 1;
    parameter AR_LEN_MSB = AR_ADDR_LSB - 1;
    parameter AR_LEN_LSB = AR_LEN_MSB - AR_LEN_WIDTH + 1;
    parameter AR_SIZE_MSB = AR_LEN_LSB - 1;
    parameter AR_SIZE_LSB = AR_SIZE_MSB - AR_SIZE_WIDTH + 1;
    parameter AR_BURST_MSB = AR_SIZE_LSB - 1;
    parameter AR_BURST_LSB = AR_BURST_MSB - AR_BURST_WIDTH + 1;
    parameter AR_PROT_MSB = AR_BURST_LSB - 1;
    parameter AR_PROT_LSB = AR_PROT_MSB - AR_PROT_WIDTH + 1;
    parameter AR_SNOOP_MSB = AR_PROT_LSB - 1;
    parameter AR_SNOOP_LSB = AR_SNOOP_MSB - AR_SNOOP_WIDTH + 1;
    parameter AR_DOMAIN_MSB = AR_SNOOP_LSB - 1;
    parameter AR_DOMAIN_LSB = AR_DOMAIN_MSB - AR_DOMAIN_WIDTH + 1;

endpackage
