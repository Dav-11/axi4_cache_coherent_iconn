package func_param_pkg;
  // Define a macro that return the largest between its 2 inputs
  `define MAX2(v1, v2) ((v1) > (v2) ? (v1) : (v2))
  //`define DEBUG_ON
  `define DEBUG_START_TIME 0
  //`define QUEUE_MSG_FLAG
  //`define LOAD_STORE_MSG_FLAG
  //`define R_B_RESPONSE_FLAG
  //`define QUEUE_MSG_FLAG
  //`define SNOOP_MSG_FLAG
  //`define REPLACE_MSG_FLAG
  //`define AR_MSG_FLAG
  //`define MEMORY_DBG_FLAG
  //`define CACHE_DBG_FLAG
  `define TESTER_DBG_FLAG
  //`define TESTER_PENDING_FLAG
  //`define OBJ_COUNT_REPORT
  //`define HIT_MISS_L1_HW
  //`define REQ_MSG_L1_HW
  //`define TAG_MSG_L1_HW
  //`define BRIDGE_CPU_FLAG
  //`define REQ_BRIDGE_DIR_FLAG
  //`define HS_BRIDGE_DIR_FLAG
  `define HALF_CLK_PERIOD 5ns

  `define DUMMY_DELAY_ON 0
  parameter int DIR_MANAGE_INFO_DELAY = 2;
  // Parameters for the envirorment simulation
  parameter int N_CPUS = 4;  // number of CPUs / L1 controllers
  parameter int CPU_ID_BITS = `MAX2($clog2(N_CPUS), 1);
  parameter int MSHR_SIZE = 1;  // number of MSHR slots per CPU
  parameter int MSHR_ID_BITS = `MAX2($clog2(MSHR_SIZE), 1);
  parameter longint unsigned MEM_SIZE = 2 ** 30;  // size of main memory in bytes
  parameter int N_SETS = 128;  // number of sets in cache
  parameter int N_WAY = 2;  // number of ways in cache (# lines per set)
  parameter int LINE_SIZE = 16;  // size of cache line in bytes
  parameter int CACHE_SIZE = N_SETS * N_WAY * LINE_SIZE;  // size of cache in bytes
  parameter int BUS_WIDTH_BYTE = 8;
  parameter int MAX_DELAY_REQUEST = 0;


  // Address structure [Tag][Index][Byte offset]
  parameter int FULL_ADDRESS_BITS = $clog2(MEM_SIZE);
  parameter int BYTE_OFFSET_BITS = $clog2(LINE_SIZE);
  parameter int INDEX_BITS = $clog2(N_SETS);
  parameter int TAG_BITS = FULL_ADDRESS_BITS - INDEX_BITS - BYTE_OFFSET_BITS;

  // Access delay of MAIN memory
  parameter int MEMORY_DELAY_READ = 50;  // delay for read access
  parameter int MEMORY_DELAY_WRITE = 50;  // delay for write access

  // Access delay of L1 cache
  parameter int CACHE_DELAY_READ = 1;  // delay for read access in cache
  parameter int CACHE_DELAY_WRITE = 1;  // delay for write access in cache

  // delay for scanning queue in L1 controller
  parameter int L1_DELAY_PEAK_QUEUE = 1;  // delay for scanning queue in L1 controller
  parameter int L1_DELAY_SCAN_QUEUE = 1;

  // delay for scanning queue in directory
  parameter int DIR_DELAY_PEAK_QUEUE = 1;
  parameter int DIR_DELAY_SCAN_QUEUE = 1;

  parameter int ARID_BITS = MSHR_ID_BITS + CPU_ID_BITS;
  parameter int RID_BITS = MSHR_ID_BITS + CPU_ID_BITS;
  parameter int AWID_BITS = MSHR_ID_BITS + CPU_ID_BITS;
  parameter int BID_BITS = MSHR_ID_BITS + CPU_ID_BITS;

  parameter int CHECK_SIZE = 8;

  // custom types
  typedef enum bit [1:0] {
    INVALID,
    SHARED,
    MODIFIED
  } func_state_t;
  typedef enum bit [2:0] {
    IS,
    IM,
    SM,
    SI,
    MI,
    II
  } func_transient_state_t;
  typedef enum {
    IDLE_T,
    READY_T,
    ACTION_PENDING_T,
    CHECK_PENDING_T
  } check_state_t;
  typedef enum bit [1:0] {
    CPU_READ,
    CPU_WRITE
  } cpu_request_type_t;
  typedef bit [MSHR_ID_BITS + CPU_ID_BITS-1:0] req_id_t;
  typedef bit [CPU_ID_BITS-1:0] cpu_id_t;
  typedef byte line_arr_t[LINE_SIZE];

endpackage
