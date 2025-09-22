import param_pkg::*;
//(* dont_touch = "yes" *)
module fsm_b_noif #(
    parameter logic [CPU_ID_WIDTH-1:0] CPU_ID = 0
)(
    input clk,
    input resetn,

    input response_c2b_t response_c2b,
    input [L1_INTERNAL_DW-1:0] data_c2b,
    input ack_a2b,
    input ack_c2b,
    //input ready_a2b,
    //input ready_c2b,
    // A -> B
    input hit_a2b,
    input transient_state_t transient_state_a2b,

    output logic valid_b2a,
    output logic acq_b2a,
    output logic valid_b2c,
    output logic acq_b2c,
    output logic rel_b2c,
    //output logic ready_b2c, 
   // output logic ready_b2a,
    output logic [L1_INTERNAL_AW-1:0] adr_b2a,
    output logic [L1_INTERNAL_AW-1:0] adr_b2c,
    output snoop_req_t snoop_req_b2a,
    output snoop_req_t snoop_req_b2c,

    output logic ac_ready,

    input [ADDR_WIDTH-1:0]   ac_addr,
    input [2:0]  ac_prot,
    input [3:0]  ac_snoop,
    input ac_valid,
//=============== CR CHANNEL ==============
    input cr_ready,

    output logic cr_valid,
    output logic [CRRESP_WIDTH-1:0]  cr_resp,
//=============== CD CHANNEL ==============
    input cd_ready,

    output logic cd_valid,
    output logic cd_last,
    output logic [DATA_WIDTH-1:0]  cd_data
);

//(* dont_touch = "yes" *) fsm_b_state_t b_state_r, b_state_next;
fsm_b_state_t b_state_r, b_state_next;

logic [ADDR_WIDTH-1:0] adr_r, adr_next;
snoop_req_t snoop_req_r, snoop_req_next;
logic outstanding_r, outstanding_next;
logic rep_outstanding_r, rep_outstanding_next;
logic [DCACHE_BLOCK_WIDTH-1:0] ptr_r, ptr_next;
logic [`MAX2($clog2(AW_LEN+1)-1, 0):0] burst_cnt_r, burst_cnt_next, cd_ptr_r, cd_ptr_next;
response_c2b_t snoop_resp_r, snoop_resp_next;

logic [(DCACHE_WORDS_PER_BLOCK*WAYMEM_DW)-1:0] buffer_data_r, buffer_data_next;

always_ff @(posedge clk) begin
    if (!resetn) begin
        b_state_r <= IDLE_B;
        adr_r <= '0;
        snoop_req_r <= SNOOP_READ_CLEAN;
        outstanding_r <= 1'b0;
        rep_outstanding_r <= 1'b0;
        ptr_r <= '0;
        cd_ptr_r <= '0;
        snoop_resp_r <= INVALID;
        burst_cnt_r <= '0;
        buffer_data_r <= '0;
    end else begin
        b_state_r <= b_state_next;
        adr_r <= adr_next;
        snoop_req_r <= snoop_req_next;
        outstanding_r <= outstanding_next;
        rep_outstanding_r <= rep_outstanding_next;
        ptr_r <= ptr_next;
        cd_ptr_r <= cd_ptr_next;
        snoop_resp_r <= snoop_resp_next;
        burst_cnt_r <= burst_cnt_next;
        buffer_data_r <= buffer_data_next;
    end
end

always_comb begin
    b_state_next = b_state_r;
    adr_next = adr_r;
    snoop_req_next = snoop_req_r;
    outstanding_next = outstanding_r;
    rep_outstanding_next = rep_outstanding_r;
    ptr_next = ptr_r;
    cd_ptr_next = cd_ptr_r;
    snoop_resp_next = snoop_resp_r;
    burst_cnt_next = burst_cnt_r;
    buffer_data_next = buffer_data_r;

    ac_ready = 1'b0;
    valid_b2a = 1'b0;
    valid_b2c = 1'b0;
    adr_b2a = '0;
    adr_b2c = '0;
    snoop_req_b2a = SNOOP_READ_CLEAN;
    snoop_req_b2c = SNOOP_READ_CLEAN;

    acq_b2c = 1'b0;
    rel_b2c = 1'b0;
    
    acq_b2a = 1'b0;

    // ----------- ACE SIGNALS -------------
    // AC SIGNALS
    ac_ready = 1'b0;
    // CR SIGNALS
    cr_valid = 1'b0;
    cr_resp = '0;
    // CD SIGNALS
    cd_valid = 1'b0;
    cd_data = '0;
    cd_last = '0;

    case (b_state_r) 
        IDLE_B: begin
            if (rep_outstanding_r == 1'b1) begin
                b_state_next = ACQUIRE_A_B;
            end
            else begin
                ac_ready = 1'b1;
                if (ac_valid) begin
                    adr_next = ac_addr;
                    snoop_req_next = (ac_snoop == 4'b0010) ? SNOOP_READ_CLEAN : SNOOP_READ_UNIQUE;
                    //acq_b2c = 1'b1;
                    b_state_next = ACQUIRE_A_B;
                end
            end
        end

        ACQUIRE_A_B: begin
            acq_b2a = 1'b1;
            if (ack_a2b) begin
                if (rep_outstanding_r == 1'b1) 
                    b_state_next = SEND_FWD_B;
                else
                    b_state_next = ACQUIRE_C_B;
            end
        end

        ACQUIRE_C_B: begin
            acq_b2c = 1'b1;
            if (ack_c2b) begin
                b_state_next = SEND_FWD_B;
            end
        end
        // THIS STATE CAN BE BLOCKING BECAUSE WE CAN RECV ONE SNOOP AT THE TIME AS THE SPECIFICATION SAYS 
        SEND_FWD_B: begin
            valid_b2a = 1'b1;
            adr_b2a = adr_r;
            snoop_req_b2a = snoop_req_r;
            /*if (ack_a2b) begin
                b_state_next = CHECK_FWD_B;
            end*/
            b_state_next = CHECK_FWD_B;
        end
        
        CHECK_FWD_B: begin
            // Read the forward response from A
            if (hit_a2b) begin
                outstanding_next = 1'b1;
                `DEBUG_PRINT_L1_HW(("(B) snoop adress is in MSHR"), HIT_MISS_L1_HW)
                if (transient_state_a2b == MI) begin //problem
                    rel_b2c = 1'b1;
                    rep_outstanding_next = 1'b1;
                    b_state_next = IDLE_B;
                end
                else begin
                    b_state_next = SEND_SNOOP_TO_C_B;
                end
            end
            else begin
                outstanding_next = 1'b0;
                b_state_next = SEND_SNOOP_TO_C_B;

                if (rep_outstanding_r == 1'b1) begin //(ottimizzazione)
                    b_state_next = SEND_CRRESP_B;
                    snoop_resp_next = INVALID;
                    rep_outstanding_next = 1'b0;
                end
            end
        end

        SEND_SNOOP_TO_C_B: begin
            valid_b2c = 1'b1;
            adr_b2c = adr_r;
            snoop_req_b2c = (outstanding_r == 1'b1) ? SNOOP_READ_CLEAN : snoop_req_r;
            /*if (ack_c2b) begin
                b_state_next = READ_RESP_FROM_C_B;
            end*/
            b_state_next = READ_RESP_FROM_C_B;
        end

        READ_RESP_FROM_C_B: begin
            snoop_resp_next = response_c2b;
            if (response_c2b == INVALID) begin
                b_state_next = SEND_CRRESP_B;
            end
            else begin
                ptr_next = '0;
                buffer_data_next[ptr_next*WAYMEM_DW+:WAYMEM_DW] = data_c2b;
                b_state_next = RECV_DATA_FROM_C_B;
            end
        end

        RECV_DATA_FROM_C_B: begin
            ptr_next = ptr_r + 1'b1;
            buffer_data_next[ptr_next*WAYMEM_DW+:WAYMEM_DW] = data_c2b;
            if (ptr_next == DCACHE_WORDS_PER_BLOCK-1) begin // check if the condition is ok
                b_state_next = SEND_CRRESP_B;
            end
        end

        SEND_CRRESP_B: begin
            cr_valid = 1'b1;
            cr_resp[4:3] = (snoop_req_r == SNOOP_READ_UNIQUE) ? 2'b00 : 2'b01;
            case (snoop_resp_r)
                VALID_CLEAN: cr_resp[2:0] = 3'b001;
                VALID_DIRTY: cr_resp[2:0] = 3'b101;
                INVALID: cr_resp = 5'b00000;
                default: cr_resp = 5'b00000;
            endcase
            if(cr_ready) begin
                if (snoop_resp_r == INVALID) begin
                    b_state_next = IDLE_B;
                end
                else begin
                    b_state_next = SEND_CDDATA_B;
                    cd_ptr_next = '0;
                    burst_cnt_next = AW_LEN;
                end
            end
        end

        SEND_CDDATA_B: begin
            cd_valid = 1'b1;
            cd_data = buffer_data_r[cd_ptr_r*DATA_WIDTH+:DATA_WIDTH];
            if (burst_cnt_r == 0) begin
                cd_last = 1'b1;
            end
            if(cd_ready) begin
                burst_cnt_next = burst_cnt_r - 1;
                cd_ptr_next = cd_ptr_r + 1'b1;
            end
            if (cd_ready && burst_cnt_r == 0) begin
                b_state_next = IDLE_B;
            end
        end
        default: begin
            b_state_next = IDLE_B;
        end
    endcase
end
endmodule