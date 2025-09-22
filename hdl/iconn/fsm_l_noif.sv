import param_pkg::*;

module fsm_l_noif (
    input clk,
    input resetn,

    input [N_CPU-1:0] ac_ready,

    output logic [N_CPU-1:0] [ADDR_WIDTH-1:0]   ac_addr,
    output logic [N_CPU-1:0] [2:0]  ac_prot,
    output logic [N_CPU-1:0] [3:0]  ac_snoop,
    output logic [N_CPU-1:0] ac_valid,

    output logic [N_CPU-1:0] r_valid,
    output logic [N_CPU-1:0] r_last,
    output logic [N_CPU-1:0][RESP_WIDTH-1:0]  r_resp,
    output logic [N_CPU-1:0][ID_WIDTH-1:0]    r_id,
    output logic [N_CPU-1:0][DATA_WIDTH-1:0]  r_data,
    
    input [N_CPU-1:0] r_ready,
    
    input rack,
    input ar_empty_i,
    input cr_empty_i,
    input cd_empty_i,
    input [AR_Q_DATA_WIDTH-1:0] ar_request_i,
    input [CR_Q_DATA_WIDTH-1:0] cr_response_i,
    input [CD_Q_DATA_WIDTH-1:0] cd_data_i,

    input ack_d2l,
    input [N_CPU-1:0] sharers_d2l,

    input ack_m2l,
    input [(BYTES_PER_LINE*8)-1:0] data_m2l,

    output logic ar_pop_o,
    output logic cr_pop_o,
    output logic cd_pop_o,

    output logic valid_l2d,
    output op_dir_t operation_l2d,
    output logic [DCACHE_TAG_WIDTH-1:0] tag_l2d,
    output logic [DCACHE_INDEX_WIDTH-1:0] index_l2d,
    output logic [CPU_ID_WIDTH-1:0] cpu_id_l2d,

    output logic [MAIN_MEM_LINE_AW-1:0] raddr_l2m,
    output logic rcyc_l2m,
    output logic [MAIN_MEM_LINE_AW-1:0] waddr_l2m,
    output logic wcyc_l2m,
    output logic [(BYTES_PER_LINE*8)-1:0] wdata_l2m
);

logic [(BYTES_PER_LINE*8)-1:0]  data_r, data_next;
logic [AR_LEN_WIDTH-1:0] burst_cnt_r, burst_cnt_next, r_ptr_r, r_ptr_next;

logic [AR_ID_WIDTH-1:0]     id, id_r, id_next;
logic [AR_LINE_ADDR_WIDTH-1:0]  line_addr , line_addr_r, line_addr_next;
logic [AR_LEN_WIDTH-1:0]  len , len_r, len_next;
logic [AR_SNOOP_WIDTH-1:0]  snoop , snoop_r, snoop_next;

logic [N_CPU-1:0] sharers_r, sharers_next;
logic data_valid_r, data_valid_next;
logic [N_CPU-1:0][CPU_ID_WIDTH-1:0] snoopPtr_vect;
logic [CPU_ID_WIDTH-1:0] snoopPtr;
logic [CPU_ID_WIDTH-1:0] cpu_id;
logic [N_CPU-1:0] sharers_mask, masked_sharers;





assign id = ar_request_i[AR_ID_MSB:AR_ID_LSB];
assign line_addr = ar_request_i[AR_LINE_ADDR_MSB:AR_LINE_ADDR_LSB];
assign len = ar_request_i[AR_LEN_MSB:AR_LEN_LSB];
assign snoop = ar_request_i[AR_SNOOP_MSB:AR_SNOOP_LSB];

assign cpu_id = id_r[CPU_ID_WIDTH-1:0];
assign masked_sharers = sharers_r & sharers_mask;

//(* dont_touch = "yes" *) fsm_l_state_t  l_state_r, l_state_next;
fsm_l_state_t  l_state_r, l_state_next;




generate
    assign snoopPtr_vect[0] = '0;
    for(genvar i = 1; i < N_CPU; i = i+1) begin
        assign snoopPtr_vect[i] = (masked_sharers[i]) ? i : snoopPtr_vect[i-1];
    end
    assign snoopPtr = snoopPtr_vect[N_CPU-1];
endgenerate 

always_comb begin
    sharers_mask = '1;
    sharers_mask[cpu_id] = '0;
end

always_ff @(posedge clk) begin
    if (!resetn) begin
        l_state_r <= IDLE_L;
        id_r <= '0;
        line_addr_r <= '0;
        len_r <= '0;
        snoop_r <= '0;
        sharers_r <= '0;
        data_r <= '0;
        r_ptr_r <= '0;
        burst_cnt_r <= '0;
        data_valid_r <= 1'b0;
    end else begin
        l_state_r <= l_state_next;
        id_r <= id_next;
        line_addr_r <= line_addr_next;
        len_r <= len_next;
        snoop_r <= snoop_next;
        sharers_r <= sharers_next;
        data_r <= data_next;
        r_ptr_r <= r_ptr_next;
        burst_cnt_r <= burst_cnt_next;
        data_valid_r <= data_valid_next;
    end
end

always_comb begin
    l_state_next = l_state_r;
    id_next = id_r;
    line_addr_next = line_addr_r;
    len_next = len_r;
    snoop_next = snoop_r;
    sharers_next = sharers_r;
    data_next = data_r;
    r_ptr_next = r_ptr_r;
    burst_cnt_next = burst_cnt_r;
    data_valid_next = data_valid_r;

    ar_pop_o = 1'b0;
    cr_pop_o = 1'b0;
    cd_pop_o = 1'b0;

    valid_l2d = 1'b0;
    operation_l2d = READ_OP;
    tag_l2d = '0;
    index_l2d = '0;
    cpu_id_l2d = '0;

    raddr_l2m = '0;
    rcyc_l2m = 1'b0;
    waddr_l2m = '0;
    wcyc_l2m = 1'b0;
    wdata_l2m = '0;


    ac_valid    = '0;
    ac_snoop    = '0;
    ac_prot     = '0;
    ac_addr     = '0;

    r_valid = '0;
    r_id    = '0;
    r_resp  = '0;
    r_data  = '0;
    r_last  = '0;

    case (l_state_r)
        IDLE_L: begin
            if (~ar_empty_i) begin
                id_next = id;
                line_addr_next = line_addr;
                len_next = len;
                snoop_next = snoop;
                ar_pop_o = 1'b1;
                l_state_next = READ_INFO_L;
            end
        end
        READ_INFO_L: begin
            valid_l2d = 1'b1;
            operation_l2d = READ_OP;
            tag_l2d = line_addr_r[AR_LINE_ADDR_WIDTH-1:AR_LINE_ADDR_WIDTH-DCACHE_TAG_WIDTH];
            index_l2d = line_addr_r[DCACHE_INDEX_WIDTH-1:0];
            if(ack_d2l) begin
                l_state_next = (snoop_r == 4'b0010) ? HANDLE_RC_L : HANDLE_RU_L;
                sharers_next = sharers_d2l;
            end
        end
        HANDLE_RC_L: begin
            // is ~|sharers_r better?
            if(sharers_r == '0) begin // no sharer read from memory
                raddr_l2m = line_addr_r[MAIN_MEM_LINE_AW-1:0];
                rcyc_l2m = 1'b1;
                if (ack_m2l) begin
                    sharers_next[cpu_id] = 1'b1;
                    //l_state_next = RECV_DATA_FROM_MEM_L;
                    data_next = data_m2l;
                    l_state_next = SET_INFO_L;
                    // TODO: complete this part, we need to sync the data read with the memory delay
                end
            end
            else begin // Theoretically using the masked sharers here is unnecessary
                ac_valid[snoopPtr] = 1'b1;
                ac_snoop[snoopPtr] = 4'b0010;
                ac_prot[snoopPtr] = 3'b111;
                ac_addr[snoopPtr] = {line_addr_r, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}};
                if (ac_ready[snoopPtr]) begin
                    l_state_next = RECV_SNOOP_RESP_L;
                end
            end
        end
        RECV_SNOOP_RESP_L: begin
            if (~cr_empty_i) begin
                if (cr_response_i[0] == 1'b1) begin // Data transfer true
                    l_state_next = WAIT_SNOOP_DATA_L;
                    data_valid_next = 1'b1;
                end
                else if (cr_response_i == '0) begin
                    sharers_next[snoopPtr] = 1'b0;
                    cr_pop_o = 1'b1;
                    l_state_next = (snoop_r == 4'b0010) ? HANDLE_RC_L : HANDLE_RU_L;
                end
            end
        end
        WAIT_SNOOP_DATA_L: begin 
            if (~cd_empty_i) begin
                data_next = cd_data_i;
                cd_pop_o = 1'b1;
                cr_pop_o = 1'b1;
                sharers_next[cpu_id] = 1'b1;
                if (snoop_r == 4'b0010) begin
                    if(cr_response_i[2] == 1'b1) begin // if we got dirty data and snoop was a readClean
                        l_state_next = WRITE_BACK_L;
                    end 
                    else begin
                        l_state_next = SET_INFO_L;
                    end
                end
                else begin // The snoop is 4'b0111 ReadUnique
                    sharers_next[snoopPtr] = 1'b0;
                    l_state_next = HANDLE_RU_L;
                end
            end
        end
        WRITE_BACK_L: begin
            wcyc_l2m = 1'b1;
            waddr_l2m = line_addr_r[MAIN_MEM_LINE_AW-1:0];
            wdata_l2m = data_r;
            if(ack_m2l == 1'b1) begin
                l_state_next = SET_INFO_L;
            end
        end
        HANDLE_RU_L: begin
            if((~|masked_sharers) & (~data_valid_r)) begin // no sharer read from memory
                raddr_l2m = line_addr_r[MAIN_MEM_LINE_AW-1:0];
                rcyc_l2m = 1'b1;
                if (ack_m2l) begin
                    sharers_next[cpu_id] = 1'b1;
                    //l_state_next = RECV_DATA_FROM_MEM_L;
                    data_next = data_m2l;
                    l_state_next = SET_INFO_L;
                end
            end
            else if (|masked_sharers) begin // Theoretically using the masked sharers here is unnecessary
                sharers_next[cpu_id] = 1'b1;
                ac_valid[snoopPtr] = 1'b1;
                ac_snoop[snoopPtr] = 4'b0111;
                ac_prot[snoopPtr] = 3'b111;
                ac_addr[snoopPtr] = {line_addr_r, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}};
                if (ac_ready[snoopPtr]) begin
                    l_state_next = RECV_SNOOP_RESP_L;
                end
            end
            else begin
                sharers_next[cpu_id] = 1'b1; // It's already a sharer in theory
                l_state_next = SET_INFO_L;
            end
        end
        /*RECV_DATA_FROM_MEM_L: begin
            data_next = data_m2l;
            l_state_next = SET_INFO_L;
        end*/
        SEND_R_RESP_L: begin
            r_valid[cpu_id] = 1'b1;
            r_id[cpu_id] = id_r;
            r_resp[cpu_id] = 2'b00;
            r_data[cpu_id] = data_r[r_ptr_r*DATA_WIDTH+:DATA_WIDTH];
            if (burst_cnt_r == 0) begin
                r_last[cpu_id] = 1'b1;
            end
            if(r_ready[cpu_id]) begin
                burst_cnt_next = burst_cnt_r - 1;
                r_ptr_next = r_ptr_r + 1'b1;
            end
            if (r_ready[cpu_id] && burst_cnt_r == 0) begin
                l_state_next = WAIT_RACK_L;
            end
        end
        WAIT_RACK_L: begin
            if (rack) begin
                data_valid_next = 1'b0;
                l_state_next = IDLE_L;
            end
        end
        SET_INFO_L: begin
            valid_l2d = 1'b1;
            operation_l2d = (snoop_r == 4'b0010) ? SET_RC_OP : SET_RU_OP;
            tag_l2d = line_addr_r[AR_LINE_ADDR_WIDTH-1:AR_LINE_ADDR_WIDTH-DCACHE_TAG_WIDTH];
            index_l2d = line_addr_r[DCACHE_INDEX_WIDTH-1:0];
            cpu_id_l2d = cpu_id;
            if(ack_d2l) begin
                r_ptr_next = '0;
                burst_cnt_next = len_r;
                l_state_next = SEND_R_RESP_L;
            end
        end
        default: begin
            l_state_next = IDLE_L;
        end
    endcase
end

endmodule