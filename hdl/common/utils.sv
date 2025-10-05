// `ifdef DEBUG_ON
`define DEBUG_PRINT_L1(A) \
        if ($time >= `DEBUG_START_TIME) begin \
            $write("[T: %0d]", $time); \
            $write("[L1Controller %0d] ", cpu_id); \
            $display("%s", $sformatf A); \
        end

`define DEBUG_PRINT_DIR(A) \
        if ($time >= `DEBUG_START_TIME) begin \
            $write("[T: %0d]", $time); \
            $write("[Directory] "); \
            $display("%s", $sformatf A); \
        end

`define DEBUG_PRINT_L1_NEW(MSG, FLAG) \
        `ifdef FLAG \
            if ($time >= `DEBUG_START_TIME) begin \
                $write("[T: %0d]", $time); \
                $write("[L1Controller %0d] ", cpu_id); \
                $display("%s", $sformatf MSG); \
            end \
        `endif

`define DEBUG_PRINT_L1_HW(MSG, FLAG) \
        `ifdef FLAG \
            if ($time >= `DEBUG_START_TIME) begin \
                $write("[T: %0d]", $time); \
                $write("[L1Controller %0d] ", CPU_ID); \
                $display("%s", $sformatf MSG); \
            end \
        `endif

`define DEBUG_PRINT_BRIDGE_CPU(MSG, FLAG) \
        `ifdef FLAG \
            if ($time >= `DEBUG_START_TIME) begin \
                $write("[T: %0d]", $time); \
                $write("[BridgeCPU %0d] ", cpu_id); \
                $display("%s", $sformatf MSG); \
            end \
        `endif

`define DEBUG_PRINT_BRIDGE_DIR(MSG, FLAG) \
        `ifdef FLAG \
            if ($time >= `DEBUG_START_TIME) begin \
                $write("[T: %0d]", $time); \
                $write("[BridgeDIR %0d] ", cpu_id); \
                $display("%s", $sformatf MSG); \
            end \
        `endif

`define DEBUG_PRINT_DIR_NEW(MSG, FLAG) \
        `ifdef FLAG \
            if ($time >= `DEBUG_START_TIME) begin \
                $write("[T: %0d]", $time); \
                $write("[Directory] "); \
                $display("%s", $sformatf MSG); \
            end \
        `endif

`define DEBUG_PRINT_TESTER(MSG, FLAG) \
        `ifdef FLAG \
            if ($time >= `DEBUG_START_TIME) begin \
                $write("[T: %0d]", $time); \
                $write("[Tester] "); \
                $display("%s", $sformatf MSG); \
            end \
        `endif

`define DEBUG_PRINT_GENERAL(ACTOR, MESSAGE, FLAG) \
        `ifdef FLAG \
            if ($time >= `DEBUG_START_TIME) begin \
                $write("[T: %0d]", $time); \
                $write("[%s] ", $sformatf ACTOR); \
                $display("%s", $sformatf MESSAGE); \
            end \
        `endif
// `else
// `define DEBUG_PRINT_L1(A)
// `define DEBUG_PRINT_DIR(A)
// `define DEBUG_PRINT_L1_NEW(MSG, FLAG)
// `define DEBUG_PRINT_L1_HW(MSG, FLAG)
// `define DEBUG_PRINT_BRIDGE_CPU(MSG, FLAG)
// `define DEBUG_PRINT_BRIDGE_DIR(MSG, FLAG)
// `define DEBUG_PRINT_DIR_NEW(MSG, FLAG)
// `define DEBUG_PRINT_GENERAL(ACTOR, MESSAGE, FLAG)
// `define DEBUG_PRINT_TESTER(MSG, FLAG)
// `endif

`define PRINT_TITLE(A) \
    $display("========================================="); \
    $display("%s", $sformatf A); \
    $display("=========================================");

`define PRINT_SECTION(A) \
    $display("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"); \
    $display("%s", $sformatf A); \
    $display("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
