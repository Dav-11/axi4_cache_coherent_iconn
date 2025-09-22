import param_pkg::*;
module iconn_mem_ctrl_delay #(parameter DELAY = 20) (
    input clk,
    input resetn,

    input [MAIN_MEM_LINE_AW-1:0] waddr_arb2mem,
    input [(BYTES_PER_LINE*8)-1:0] wdata_arb2mem,
    input wcyc_arb2mem,
    input [MAIN_MEM_LINE_AW-1:0] raddr_arb2mem,
    input rcyc_arb2mem,

    output logic [(BYTES_PER_LINE*8)-1:0] data_mem2l,
    output logic ack_mem2arb,

    input [MAIN_MEM_DW-1:0] rdata,

    output logic [MAIN_MEM_AW-1:0] waddr,
    output logic [MAIN_MEM_DW-1:0] wdata,
    output logic wcyc,
    output logic [MAIN_MEM_AW-1:0] raddr,
    output logic rcyc

);

logic [(BYTES_PER_LINE*8)-1:0] buffer_data_r, buffer_data_next;
logic [$clog2(DCACHE_WORDS_PER_BLOCK)-1:0] burst_cnt_r, burst_cnt_next;
logic [$clog2(DELAY)-1:0] delay_cnt_r, delay_cnt_next;

assign data_mem2l = buffer_data_next;

typedef enum logic [1:0] {
    IDLE_MEM_CTRL,
    WRITE_MEM_CTRL,
    READ_MEM_CTRL,
    DELAY_MEM_CTRL
} mem_ctrl_state_t;

//(* dont_touch = "yes" *) mem_ctrl_state_t  mem_ctrl_state_r, mem_ctrl_state_next;
mem_ctrl_state_t  mem_ctrl_state_r, mem_ctrl_state_next;

always_ff @(posedge clk) begin
    if (!resetn) begin
        mem_ctrl_state_r <= IDLE_MEM_CTRL;
        buffer_data_r <= '0;
        burst_cnt_r <= '0;
        delay_cnt_r <= '0;
    end else begin
        mem_ctrl_state_r <= mem_ctrl_state_next;
        buffer_data_r <= buffer_data_next;
        burst_cnt_r <= burst_cnt_next;
        delay_cnt_r <= delay_cnt_next;
    end
end

always_comb begin
    mem_ctrl_state_next = mem_ctrl_state_r;
    buffer_data_next = buffer_data_r;
    burst_cnt_next = burst_cnt_r;
    delay_cnt_next = delay_cnt_r;

    rcyc = 1'b0;
    raddr = '0;
    wcyc = 1'b0;
    waddr = '0;
    wdata = '0;

    ack_mem2arb = 1'b0;
    
    case(mem_ctrl_state_r)
        IDLE_MEM_CTRL: begin
            if (wcyc_arb2mem) begin
                wcyc = 1'b1;
                waddr = {waddr_arb2mem, burst_cnt_r};
                wdata = wdata_arb2mem[burst_cnt_r*MAIN_MEM_DW+:MAIN_MEM_DW];
                burst_cnt_next = burst_cnt_r + 1;
                mem_ctrl_state_next = WRITE_MEM_CTRL;
            end else if (rcyc_arb2mem) begin
                rcyc = 1'b1;
                raddr = {raddr_arb2mem, burst_cnt_r};
                mem_ctrl_state_next = READ_MEM_CTRL;
            end
        end

        READ_MEM_CTRL: begin
            buffer_data_next[burst_cnt_r*MAIN_MEM_DW+:MAIN_MEM_DW] = rdata;

            if (burst_cnt_r == DCACHE_WORDS_PER_BLOCK-1) begin
                burst_cnt_next = '0;
                mem_ctrl_state_next = DELAY_MEM_CTRL;
            end
            else begin
                burst_cnt_next = burst_cnt_r + 1;
                rcyc = 1'b1;
                raddr = {raddr_arb2mem, burst_cnt_next};
            end
        end

        WRITE_MEM_CTRL: begin
            wdata = wdata_arb2mem[burst_cnt_r*MAIN_MEM_DW+:MAIN_MEM_DW];
            wcyc = 1'b1;
            waddr = {waddr_arb2mem, burst_cnt_r};
            if (burst_cnt_r == DCACHE_WORDS_PER_BLOCK-1) begin
                burst_cnt_next = '0;
                mem_ctrl_state_next = DELAY_MEM_CTRL;
            end else begin
                burst_cnt_next = burst_cnt_r + 1;
            end
        end

        DELAY_MEM_CTRL: begin
            if (delay_cnt_r == DELAY-1) begin
                ack_mem2arb = 1'b1;
                mem_ctrl_state_next = IDLE_MEM_CTRL;
                delay_cnt_next = '0;
            end else begin
                delay_cnt_next = delay_cnt_r + 1;
                //mem_ctrl_state_next = DELAY_MEM_CTRL;
            end
        end
    endcase
end

endmodule