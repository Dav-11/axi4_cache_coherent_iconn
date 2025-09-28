import func_param_pkg::*;
import clock_pkg::*;
typedef class RandomTester;
typedef class bridge_cpu;

class Check;
    check_state_t m_status;
    byte unsigned m_value;
    int m_address;
    int unsigned m_store_count;
    RandomTester m_tester_ptr;

    function new(int address, RandomTester m_tester_ptr);
        m_address = address;
        m_status = IDLE_T;
        m_store_count = 0;
        this.m_tester_ptr = m_tester_ptr;
        pickRandomValue();
    endfunction

    function void pickRandomValue();
        m_value = $urandom_range(0, 255);
    endfunction

    function void setState(check_state_t state);
        m_status = state;
    endfunction

    function void initiate();
        case (m_status)
            IDLE_T:
                initiateAction();
            READY_T:
                initiateCheck();
            default:
                `DEBUG_PRINT_TESTER(("[Check %0d] Check/Action pending, skipping", m_address), TESTER_PENDING_FLAG)
                ;
        endcase
    endfunction

    function void initiateAction();
        int random_cpu = $urandom_range(0, N_CPUS-1);
        bit [DBUS_DW-1:0] value = (m_value + m_store_count) << (8*m_store_count);
        bit [DBUS_ISEL-1:0] sel = 1'b1 << m_store_count;
        m_tester_ptr.cpu_bridges[random_cpu].store(m_address+m_store_count, value, sel);
        m_status = ACTION_PENDING_T;
    endfunction

    function void initiateCheck();
        int random_cpu = $urandom_range(0, N_CPUS-1);
        m_tester_ptr.cpu_bridges[random_cpu].load(m_address);
        m_status = CHECK_PENDING_T;
    endfunction

    function void performCallback(int cpu_id, bit[DBUS_DW-1:0] value);
        case (m_status)
            ACTION_PENDING_T: begin
                m_store_count++;
                if (m_store_count == CHECK_SIZE) begin
                    m_status = READY_T;
                    m_store_count = 0;
                    return;
                end
                m_status = IDLE_T;
                return;
            end
            CHECK_PENDING_T: begin
                for (byte i = 0; i < CHECK_SIZE; i++) begin
                    `DEBUG_PRINT_TESTER(("Testing if %b == %b", value[i*8+:8], m_value + i), TESTER_DBG_FLAG)
                    if (value[i*8+:8] != m_value + i) begin
                        $display("Expected %b, got %b", m_value + i, value[i*8+:8]);
                        $fatal(1, "Check %0d failed", m_address);
                        return;
                    end
                end

                `DEBUG_PRINT_TESTER(("Check %0d passed succesfully", m_address), TESTER_DBG_FLAG)
                m_status = IDLE_T;
                m_tester_ptr.incrementChecksCompleted();
                pickRandomValue();
            end
            default: begin
               `DEBUG_PRINT_TESTER(("Callback called in IDLE_T state, skipping"), TESTER_DBG_FLAG)
                ;
            end
        endcase
    endfunction
endclass

class CheckTable;
    Check m_check_vector[$];
    Check m_lookup_map[int];
    RandomTester m_tester_ptr;

    function new(RandomTester tester_ptr);
        const int size1 = 16;
        const int size2 = 100;
        int physical = 0;

        if (size2 < size1) begin
            $fatal(1, "size2 must be greater than size1");
        end

        if (CHECK_SIZE + (size2*4*LINE_SIZE) > MEM_SIZE-1) begin
            $fatal(1, "Check table size too large, exceeds physical memory address space");
        end

        this.m_tester_ptr = tester_ptr;

        for (int i = 0; i < size1; i++) begin
            addCheck(physical);
            physical += CHECK_SIZE;
        end

        physical = 0;
        for (int i = 0; i < size2; i++) begin
            addCheck(physical);
            physical += 4*LINE_SIZE; // 4*line_size to be proportional to gem5 ruby tester
        end

        physical = 0 + CHECK_SIZE;
        for (int i = 0; i < size2; i++) begin
            addCheck(physical);
            physical += 4*LINE_SIZE;
        end
    endfunction

    function void addCheck(int address);
        Check new_check;
        // Check that the address is aligned with CHECK_SIZE
        if (address % CHECK_SIZE != 0) begin
            $fatal(1, "Address not aligned with CHECK_SIZE");
        end

        // Check that the address is not already in the table
        if (m_lookup_map.exists(address)) begin
            $display("Address already in table, skipping");
            return;
        end

        new_check = new(address, m_tester_ptr);
        m_check_vector.push_back(new_check);
        for (int i = 0; i < CHECK_SIZE; i++) begin
            m_lookup_map[address+i] = new_check;
        end
    endfunction

    function Check getRandomCheck();
        int random_index;
        if (m_check_vector.size() == 0) begin
            $fatal(1, "Called getRandomCheck with no checks in table");
        end
        random_index = $urandom_range(0, m_check_vector.size()-1);
        return m_check_vector[random_index];
    endfunction

    function Check getCheck(int address);
        if (!m_lookup_map.exists(address)) begin
            $fatal(1, "Called getCheck with address not in table");
        end
        return m_lookup_map[address];
    endfunction
endclass



class RandomTester;
    localparam CHECKS_TO_COMPLETE = 100_000;
    localparam WAKEUP_LATENCY = 5;
    localparam DEADLOCK_THRESHOLD = 50000;

    int m_checks_completed;
    CheckTable m_check_table_ptr;
    bridge_cpu cpu_bridges[N_CPUS];
    ClockDomain clk_domain;
    longint m_last_progress_vector[N_CPUS];
    longint current_cycle;

    function new(ClockDomain clk_domain);
        this.clk_domain = clk_domain;
        m_checks_completed = 0;
        current_cycle = 0;
        m_check_table_ptr = new(this);
        for (int i = 0; i < N_CPUS; i++) begin
            m_last_progress_vector[i] = 0;
        end
    endfunction



    //add cpu bridge to the tester
    function void addCpuBridge(bridge_cpu cpu_bridge, int cpu_id);
        this.cpu_bridges[cpu_id] = cpu_bridge;
    endfunction

    function void checkForDeadlock();
        for (int i = 0; i < N_CPUS; i++) begin
            if (current_cycle - m_last_progress_vector[i] > DEADLOCK_THRESHOLD ) begin
                `DEBUG_PRINT_TESTER(("current_cycle - m_last_progress_vector[%0d] = %0d - %0d = %0d", i, current_cycle, m_last_progress_vector[i], current_cycle - m_last_progress_vector[i]), TESTER_DBG_FLAG)
                $fatal(1, "Deadlock detected on cpu %0d", i);
            end
        end
    endfunction

    function void recvTimingResp(int address, int cpu_id, bit[DBUS_DW-1:0] value);
        `DEBUG_PRINT_TESTER(("Received response from cpu %0d", cpu_id), TESTER_DBG_FLAG)
        hitCallback(address, cpu_id, value);

    endfunction

    function void hitCallback(int address, int cpu_id, bit[DBUS_DW-1:0] value);
        Check check;
        m_last_progress_vector[cpu_id] = current_cycle;
        `DEBUG_PRINT_TESTER(("Updated last progress of CPU %0d to cycle %0d", cpu_id, current_cycle), TESTER_DBG_FLAG)
        check = m_check_table_ptr.getCheck(address);
        check.performCallback(cpu_id, value);
    endfunction

    function void print_obj_report();

        for (int i = 0; i < N_CPUS; i++) begin
            $display("L1 Controller %0d", i);
            $display("|\tmandatory_q: %0d", cpu_bridges[i].cpu_request_q.size());
        end
    endfunction

    function void incrementChecksCompleted();
        m_checks_completed++;
        if(m_checks_completed % 1000 == 0) begin
            $display("%0d/%0d CHECKS COMPLETED SUCCEFULLY", m_checks_completed, CHECKS_TO_COMPLETE);

        end
    endfunction

    task cycleCounter();
        while (m_checks_completed < CHECKS_TO_COMPLETE) begin
            repeat (1) @(posedge clk_domain.clk);
            current_cycle++;
        end
    endtask

    task main_loop();
        Check check;
        $display("[Tester] Starting cycle counter");
        fork
            cycleCounter();
        join_none

        $display("[Tester] Starting main loop");
        while (m_checks_completed < CHECKS_TO_COMPLETE) begin
            repeat (WAKEUP_LATENCY) @(posedge clk_domain.clk);
            check = m_check_table_ptr.getRandomCheck();
            check.initiate();
            checkForDeadlock();
        end
        for (int i = 0; i < N_CPUS; i++) begin
            cpu_bridges[i].print_statistics();
        end
        $display("[Tester] %0d/%0d CHECKS COMPLETED SUCCEFULLY", m_checks_completed, CHECKS_TO_COMPLETE);
    endtask
endclass
