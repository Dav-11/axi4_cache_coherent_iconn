import message_pkg::*;
typedef class RandomTester;
class bridge_cpu;

    virtual cpu_iface cpu_if;
    CPU_request cpu_request_q[$];
    bit running;
    RandomTester tester;
    int cpu_id;
    longint current_cycle;
    longint start_time;
    int delay;
    int read_hit_count;
    longint read_hit_delay;
    int read_miss_count;
    longint read_miss_delay;
    int store_hit_count;
    longint store_hit_delay;
    int store_miss_count;
    longint store_miss_delay;
    function new(virtual cpu_iface.master cpu_if[0:N_CPU-1], int cpu_id, RandomTester tester);
        this.cpu_id = cpu_id;
        this.cpu_if = cpu_if[cpu_id];
        this.tester = tester;
        running = 1'b0;
        current_cycle = 0;
        start_time = 0;
        delay = 0;
        read_hit_count = 0;
        read_hit_delay = 0;
        read_miss_count = 0;
        read_miss_delay = 0;
        store_hit_count = 0;
        store_hit_delay = 0;
        store_miss_count = 0;
        store_miss_delay = 0;
    endfunction

    task mandatory_q_loop(ref clk);
        CPU_request popped_cpu_request;
        running = 1'b1;
        cpu_if.req_m2dbiu = 1'b0;
        cpu_if.we_m2dbiu = 1'b0;
        cpu_if.adr_m2dbiu = '0;
        cpu_if.dat_m2dbiu = '0;
        cpu_if.sel_m2dbiu = '0;
        $display("BridgeCPU %0d: mandatory_q_loop started", cpu_id);
        while (running) begin
            @(posedge clk);
            if (cpu_request_q.size() > 0) begin
                popped_cpu_request = cpu_request_q.pop_front();
                evaluate_time();
                cpu_if.req_m2dbiu = 1'b1;
                cpu_if.adr_m2dbiu = popped_cpu_request.addr.addr;
                if (popped_cpu_request.req_type == CPU_WRITE) begin
                    cpu_if.we_m2dbiu = 1'b1;
                    `DEBUG_PRINT_BRIDGE_CPU(("HANDLING REQ FROM CPU %0d", cpu_id), BRIDGE_CPU_FLAG)
                    `DEBUG_PRINT_BRIDGE_CPU(("addr = %0d", popped_cpu_request.addr.addr), BRIDGE_CPU_FLAG)
                    `DEBUG_PRINT_BRIDGE_CPU(("value = %b/%0d", popped_cpu_request.value, popped_cpu_request.value), BRIDGE_CPU_FLAG)
                    `DEBUG_PRINT_BRIDGE_CPU(("sel = %b", popped_cpu_request.sel), BRIDGE_CPU_FLAG)
                    cpu_if.dat_m2dbiu = popped_cpu_request.value;
                    cpu_if.sel_m2dbiu = popped_cpu_request.sel;
                end
                while (cpu_if.ack_dbiu2m == 1'b0) @(posedge clk);

                cpu_if.req_m2dbiu = 1'b0;
                cpu_if.we_m2dbiu = 1'b0;
                cpu_if.adr_m2dbiu = '0;
                cpu_if.dat_m2dbiu = '0;

                if (popped_cpu_request.req_type == CPU_READ) begin
                    statistic_evaluation_read();
                    tester.recvTimingResp(popped_cpu_request.addr.addr, cpu_id, cpu_if.dat_dbiu2m);
                end
                else begin
                    statistic_evaluation_write();
                    tester.recvTimingResp(popped_cpu_request.addr.addr, cpu_id, 0);
                end
            end

        end

    endtask

    task cycleCounter(ref clk);
        running = 1'b1;
        while (running) begin
            repeat (1) @(posedge clk);
            current_cycle++;
        end
    endtask

    function void evaluate_time;
        start_time = current_cycle;
    endfunction

    function void statistic_evaluation_read;
        delay = current_cycle - start_time;
        if (delay < 20) begin
           read_hit_count = read_hit_count + 1;
           read_hit_delay = read_hit_delay + delay;
        end else begin
           read_miss_count = read_miss_count + 1;
           read_miss_delay = read_miss_delay + delay;
        end
    endfunction

    function void statistic_evaluation_write;
        delay = current_cycle - start_time;
        if (delay < 20) begin
           store_hit_count = store_hit_count + 1;
           store_hit_delay = store_hit_delay + delay;
        end else begin
           store_miss_count = store_miss_count + 1;
           store_miss_delay = store_miss_delay + delay;
        end
    endfunction

    function void print_statistics;
        $display("--------------------------------- L1_CONTROLLER %0d ---------------------------------", cpu_id);
        $display("read_hit_count = %0d | read_hit_delay (tot) = %0d | read_hit_delay (avg) = %0d\n", read_hit_count, read_hit_delay, read_hit_delay/read_hit_count);
        $display("store_hit_count = %0d |store_hit_delay (tot) = %0d | store_hit_delay (avg) = %0d\n", store_hit_count, store_hit_delay, store_hit_delay/store_hit_count);
        $display("read_miss_count = %0d | read_miss_delay (tot) = %0d | read_miss_delay (avg) = %0d\n", read_miss_count, read_miss_delay, read_miss_delay/read_miss_count);
        $display("store_miss_count = %0d | store_miss_delay (tot) = %0d | store_miss_delay (avg) = %0d\n", store_miss_count, store_miss_delay, store_miss_delay/store_miss_count);

    endfunction

    function void store(int unsigned addr_int, bit [DBUS_DW-1:0] value, bit [DBUS_ISEL-1:0] sel);
        Address addr;
        CPU_request cpu_request;
        addr = new(addr_int);
        cpu_request = new(CPU_WRITE, addr, value, sel);
        enqueue_CPU_request(cpu_request);
    endfunction

    function void load(int unsigned addr_int);
        Address addr = new(addr_int);
        CPU_request cpu_request = new(CPU_READ, addr, 0, 0);
        enqueue_CPU_request(cpu_request);
    endfunction

    function void enqueue_CPU_request(CPU_request cpu_request);
        `DEBUG_PRINT_BRIDGE_CPU(("Enqueuing CPU request"), BRIDGE_CPU_FLAG)
        cpu_request_q.push_back(cpu_request);
    endfunction

    function void stop();
        running = 1'b0;
    endfunction
endclass
