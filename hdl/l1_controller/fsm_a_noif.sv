`include "../common/utils.sv"
import param_pkg::*;
//(* dont_touch = "yes" *)
module fsm_a_noif #(
    parameter logic [CPU_ID_WIDTH-1:0] CPU_ID = 0
)(
input aclk,
input aresetn,
input [L1_INTERNAL_AW-1:0] adr_c2a,
input ack_c2a,
input [L1_INTERNAL_DW-1:0] data_c2a,
input valid_c2a,
input transaction_type_t transaction_c2a,

input [L1_INTERNAL_AW-1:0] adr_b2a,
input snoop_req_t snoop_req_b2a,
input valid_b2a,
input acq_b2a,

output logic ack_a2b,

output logic [L1_INTERNAL_DW-1:0] data_a2c,
output logic valid_a2c,
output response_a2c_t response_a2c,
output logic ready_a2c,
output logic ack_a2c,

output logic wack,
output logic rack,

output logic hit_a2b,
output transient_state_t transient_state_a2b,

//=============== AR CHANNEL ===============
    input ar_ready,
    
    output logic [ID_WIDTH-1:0]     ar_id,
    output logic [ADDR_WIDTH-1:0]   ar_addr,
    output logic [7:0]  ar_len,
    output logic [2:0]  ar_size,
    output logic [1:0]  ar_burst,
    output logic [2:0]  ar_prot,
    output logic [3:0]  ar_snoop,
    output logic [1:0]  ar_domain,
    output logic ar_valid,
//=============== R CHANNEL ===============
    input r_valid,
    input r_last,
    input [RESP_WIDTH-1:0]  r_resp,
    input [ID_WIDTH-1:0]    r_id,
    input [DATA_WIDTH-1:0]  r_data,
    
    output logic r_ready,

//=============== AW CHANNEL ===============
    input aw_ready,

    output logic [ID_WIDTH-1:0]     aw_id,
    output logic [ADDR_WIDTH-1:0]   aw_addr,
    output logic [7:0]  aw_len,
    output logic [2:0]  aw_size,
    output logic [1:0]  aw_burst,
    output logic [2:0]  aw_prot,
    output logic [2:0]  aw_snoop,
    output logic [1:0]  aw_domain,
    output logic aw_valid,
//=============== W CHANNEL ===============
    input w_ready,

    output logic w_valid,
    output logic w_last,
    output logic[STRB_WIDTH-1:0]  w_strb,
    output logic [DATA_WIDTH-1:0]  w_data,
//=============== B CHANNEL ===============
    input b_valid,
    input [ID_WIDTH-1:0]    b_id,

    output logic b_ready

);


//mshr signals
logic mshr_we_i, mshr_re_i;
logic mshr_snoop_req_i;
logic [DCACHE_TAG_WIDTH+DCACHE_INDEX_WIDTH-1:0] mshr_snoop_adr_i;
logic [1:0] mshr_wr_ptr_sel;
transient_state_t mshr_transient_state_i;
logic [DCACHE_TAG_WIDTH+DCACHE_INDEX_WIDTH-1:0] mshr_adr_i, snoop_adr_i;
logic mshr_valid_i;
logic [MSHR_AW-1:0] mshr_wrPtr_i, mshr_readID_i;
logic [MSHR_AW-1:0] mshr_freePtr_o;
logic [DCACHE_TAG_WIDTH+DCACHE_INDEX_WIDTH-1:0] adr_r, adr_next;
transient_state_t mshr_transient_state_o;
logic mshr_read_hit_o;
logic mshr_full_o;

logic [MSHR_AW-1:0] mshr_id_r, mshr_id_next;

logic [DCACHE_BLOCK_WIDTH-1:0] r_ptr_r, r_ptr_next, w_ptr_r, w_ptr_next;
logic [`MAX2($clog2(AW_LEN+1)-1, 0):0] burst_cnt_r, burst_cnt_next, w_ptr_axi_r, w_ptr_axi_next, r_ptr_axi_r, r_ptr_axi_next;

logic [(DCACHE_WORDS_PER_BLOCK*WAYMEM_DW)-1:0] w_buffer_r, w_buffer_next, r_buffer_r, r_buffer_next;

logic [ID_WIDTH-1:0] b_id_r, b_id_next;
logic [ID_WIDTH-1:0] r_id_r, r_id_next;

logic ready_a2c_r, ready_a2c_next;
logic ack_a2c_r, ack_a2c_next;
transient_state_t transient_state_r, transient_state_next;

snoop_req_t snoop_req_b2a_r, snoop_req_b2a_next;
logic [L1_INTERNAL_AW-1:0] snoop_adr_b2a_r, snoop_adr_b2a_next;

assign ready_a2c = ready_a2c_r;
assign ack_a2c = ack_a2c_r;

//(* dont_touch = "yes" *) fsm_a_state_t a_state_r, a_state_next;
fsm_a_state_t a_state_r, a_state_next;

always_ff @(posedge aclk) begin
    if (!aresetn) begin
        a_state_r <= IDLE_A;
        r_ptr_r <= '0;
        r_ptr_axi_r <= '0;
        w_ptr_r <= '0;
        w_ptr_axi_r <= '0;
        r_buffer_r <= '0;
        w_buffer_r <= '0;
        burst_cnt_r <= '0;
        b_id_r <= '0;
        r_id_r <= '0;
        mshr_id_r <= '0;
        adr_r <= '0;
        ready_a2c_r <= 1'b1;
        ack_a2c_r <= 1'b0;
        transient_state_r <= IM;
        snoop_req_b2a_r <= SNOOP_READ_CLEAN;
        snoop_adr_b2a_r <= '0;
    end else begin
        a_state_r <= a_state_next;
        r_ptr_r <= r_ptr_next;
        r_ptr_axi_r <= r_ptr_axi_next;
        r_buffer_r <= r_buffer_next;
        w_buffer_r <= w_buffer_next;
        w_ptr_r <= w_ptr_next;
        w_ptr_axi_r <= w_ptr_axi_next;
        burst_cnt_r <= burst_cnt_next;
        b_id_r <= b_id_next;
        r_id_r <= r_id_next;
        mshr_id_r <= mshr_id_next;
        adr_r <= adr_next;
        ready_a2c_r <= ready_a2c_next;
        ack_a2c_r <= ack_a2c_next;
        transient_state_r <= transient_state_next;
        snoop_req_b2a_r <= snoop_req_b2a_next;
        snoop_adr_b2a_r <= snoop_adr_b2a_next;
    end
end

always_comb begin
    a_state_next = a_state_r;
    transient_state_next = transient_state_r;
    snoop_req_b2a_next = snoop_req_b2a_r;
    snoop_adr_b2a_next = snoop_adr_b2a_r;
    adr_next = adr_r;
    ready_a2c_next = ready_a2c_r;
    ack_a2c_next = ack_a2c_r;
    valid_a2c = 1'b0;
    data_a2c = '0;
    response_a2c = REPLACEMENT_OKAY;
    wack = 1'b0;
    rack = 1'b0;
    hit_a2b = 1'b0;
    transient_state_a2b = IM;
    ack_a2b = 1'b0;

    // mshr
    mshr_we_i = 1'b0;
    mshr_re_i = 1'b0;
    mshr_snoop_req_i = 1'b0;
    mshr_snoop_adr_i = '0;
    mshr_wr_ptr_sel = '0;
    mshr_transient_state_i = IM;
    mshr_adr_i = '0;
    snoop_adr_i = '0;
    mshr_valid_i = 1'b0;
    mshr_wrPtr_i = '0;
    mshr_readID_i = '0;
    mshr_id_next = mshr_id_r;
    
    //AR CHANNEL
    ar_valid    = 1'b0;
    ar_addr     = '0;
    r_ready     = 1'b0;
    ar_len      = '0;
    ar_size     = '0;
    ar_burst    = '0;
    ar_prot     = '0;
    ar_snoop    = '0;
    ar_domain   = '0;
    ar_id       = '0;

    //AW CHANNEL
    aw_valid    = 1'b0;
    aw_addr     = '0;
    aw_len      = '0;
    aw_size     = '0;
    aw_burst    = '0;
    aw_prot     = '0;
    aw_snoop    = '0;
    aw_domain   = '0;
    aw_id       = '0;

    //W CHANNEL
    w_valid    = 1'b0;
    w_data     = '0;
    w_strb     = '0;
    w_last     = '0;
    w_buffer_next = w_buffer_r;

    //R CHANNEL
    r_ready = 1'b0;
    r_ptr_next = r_ptr_r;
    r_ptr_axi_next = r_ptr_axi_r;
    r_buffer_next = r_buffer_r;
    //B CHANNEL
    b_ready = 1'b0;
    b_id_next = b_id_r;
    r_id_next = r_id_r;
    
    w_ptr_next = w_ptr_r;
    w_ptr_axi_next = w_ptr_axi_r;
    burst_cnt_next = burst_cnt_r;

    case (a_state_r)
        IDLE_A: begin
            `DEBUG_PRINT_L1_HW(("(A) Now in IDLE_A"), STATE_MSG_L1_HW)
            if (b_valid) begin
                a_state_next = RECV_B_RESP_A;
            end 
            else if (r_valid) begin
                a_state_next = RECV_R_RESP_A;
                r_ptr_axi_next = '0;
            end
            else if (acq_b2a) begin
                ack_a2b = 1'b1;
                /*ready_a2c_next = 1'b0;
                mshr_snoop_req_i = 1'b1;
                mshr_snoop_adr_i = adr_b2a[DCACHE_TAG_MSB:DCACHE_INDEX_LSB];
                snoop_req_b2a_next = snoop_req_b2a;
                snoop_adr_b2a_next = adr_b2a;*/
                a_state_next = WAIT_SNOOP_A;
            end
            else if ((valid_c2a == 1'b1) && (mshr_full_o == 1'b0) ) begin
                //update mshr
                ready_a2c_next = 1'b0;
                mshr_we_i = 1'b1;
                mshr_adr_i = adr_c2a[DCACHE_TAG_MSB:DCACHE_INDEX_LSB];
                adr_next = adr_c2a[DCACHE_TAG_MSB:DCACHE_INDEX_LSB];
                mshr_id_next = mshr_freePtr_o;
                case (transaction_c2a)
                    READ_CLEAN: begin
                        mshr_transient_state_i = IS;
                        transient_state_next = IS;
                        a_state_next = SEND_AR_REQ_A;
                    end
                    READ_UNIQUE: begin
                        mshr_transient_state_i = IM;
                        transient_state_next = IM;
                        a_state_next = SEND_AR_REQ_A;
                    end
                    READ_UNIQUE_HIT: begin
                        mshr_transient_state_i = SM;
                        transient_state_next = SM;
                        a_state_next = SEND_AR_REQ_A;
                    end
                    EVICT: begin
                        mshr_transient_state_i = SI;
                        transient_state_next = SI;
                        a_state_next = SEND_AW_REQ_A;
                    end
                    WRITE_BACK: begin
                        mshr_transient_state_i = MI;
                        transient_state_next = MI;
                        ack_a2c_next = 1'b1;
                        w_ptr_next = '0;
                        a_state_next = RECV_DATA_FROM_C_A;
                    end
                    default: begin
                        // Still need to decide what to do here
                        // mshr_valid_i will go high if we leave the code as is
                        a_state_next = IDLE_A;
                    end
                endcase
                mshr_valid_i = 1'b1;
            end
        end
        SEND_AR_REQ_A: begin
            `DEBUG_PRINT_L1_HW(("(A) Now in SEND_AR_REQ_A"), STATE_MSG_L1_HW)
            ar_valid    = 1'b1;
            ar_len      = AR_LEN;
            ar_addr     = {adr_r, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}};
            ar_size     = AR_SIZE;
            ar_burst    = AR_BURST;
            ar_prot     = 3'b000;   // Data, Secure, Unprivileged
            if (transient_state_r == IS) begin
                ar_snoop    = 4'b0010;  // ReadClean                      
            end 
            else begin //if we are here then mshr_transient_state_o == IM or SM
                ar_snoop    = 4'b0111;  // RadUnique
            end
            ar_domain   = 2'b11;    // System
            ar_id       = {mshr_id_r, CPU_ID};
            if(ar_ready) begin
                a_state_next = IDLE_A;
                //ptr_next = '0;
            end
        end
        RECV_DATA_FROM_C_A: begin
            ack_a2c_next = 1'b0;
            `DEBUG_PRINT_L1_HW(("(A) Now in RECV_DATA_FROM_C_A"), STATE_MSG_L1_HW)
            w_buffer_next[w_ptr_r*WAYMEM_DW+:WAYMEM_DW] = data_c2a;
            w_ptr_next = w_ptr_r + 1'b1;
            /*$write("[T: %0d][L1 CONTROLLER %0d] (A) Data received is ", $time, CPU_ID);
            for (int i=4-1; i>=0; i=i-1) begin
                $write("%b, ", data_c2a[i*8+:8]);
            end
            $write("\n");*/
            if (w_ptr_next == '0) begin // check if the condition is ok
                a_state_next = SEND_AW_REQ_A;
            end
        end        
        SEND_AW_REQ_A: begin
            `DEBUG_PRINT_L1_HW(("(A) Now in SEND_AW_REQ_A"), STATE_MSG_L1_HW)
            aw_valid    = 1'b1;
            aw_addr     = {adr_r, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}};
            aw_len      = AW_LEN;
            aw_size     = AW_SIZE;
            aw_burst    = AW_BURST;
            aw_prot     = 3'b000;   // Data, Secure, Unprivileged
            if(transient_state_r == SI) begin
                aw_snoop    = 3'b100;   // Evict
            end 
            else begin //if we are here then mshr_transient_state_o == MI
                aw_snoop    = 3'b011;   // No Snoop
            end
            aw_domain   = 2'b11;    // System
            aw_id       = {mshr_id_r, CPU_ID};
            if(aw_ready) begin
                a_state_next = (transient_state_r == MI) ? SEND_W_DATA_A : IDLE_A;
                w_ptr_axi_next = '0;
                burst_cnt_next = AW_LEN;
            end
        end
        SEND_W_DATA_A: begin
            `DEBUG_PRINT_L1_HW(("(A) Now in SEND_W_DATA_A"), STATE_MSG_L1_HW)
            /*$write("[T: %0d][L1 CONTROLLER %0d] Data to be written back is ", $time, CPU_ID);
            for (int i=4*DCACHE_WORDS_PER_BLOCK-1; i>=0; i=i-1) begin
                $write("%b, ", w_buffer_r[i*8+:8]);
            end
            $write("\n");*/
            w_valid = 1'b1;
            w_data = w_buffer_r[w_ptr_axi_r*DATA_WIDTH+:DATA_WIDTH];
            w_strb = '1; // All byte enable
            if (burst_cnt_r == 0) begin
                w_last = 1'b1;
            end
            if(w_ready) begin
                burst_cnt_next = burst_cnt_r - 1;
                w_ptr_axi_next = w_ptr_axi_r + 1'b1;
            end
            if (w_ready && burst_cnt_r == 0) begin
                a_state_next = IDLE_A;
            end
        end
        RECV_R_RESP_A: begin
            `DEBUG_PRINT_L1_HW(("(A) Now in RECV_R_RESP_A"), STATE_MSG_L1_HW)
            r_ready = 1'b1;
            // If we get to this state we are sure that r_valid is high, but only for the first beat, so we have to check anyway
            if(r_valid) begin
                // Read data
                r_buffer_next[r_ptr_axi_r*DATA_WIDTH+:DATA_WIDTH] = r_data;
                r_id_next = r_id;
                r_ptr_axi_next = r_ptr_axi_r + 1'b1;
            end
            if (r_valid && r_last) begin
                a_state_next = SEND_R_RESP_TO_C_A;
                mshr_readID_i = r_id[MSHR_ID_MSB:MSHR_ID_LSB];
                mshr_re_i = 1'b1;
            end
        end
        RECV_B_RESP_A: begin
            `DEBUG_PRINT_L1_HW(("(A) Now in RECV_B_RESP_A"), STATE_MSG_L1_HW)
            // If we get to this state we are sure that b_valid is high
            b_ready = 1'b1;
            b_id_next = b_id;
            a_state_next = SEND_B_RESP_TO_C_A;
    end
        SEND_B_RESP_TO_C_A: begin
            `DEBUG_PRINT_L1_HW(("(A) Now in SEND_B_RESP_TO_C_A"), STATE_MSG_L1_HW)
            valid_a2c = 1'b1;
            response_a2c = REPLACEMENT_OKAY;
            if (ack_c2a) begin
                // Remove the line from the MSHR
                mshr_we_i = 1'b1;
                mshr_valid_i = 1'b0;
                mshr_wrPtr_i = b_id_r[MSHR_ID_MSB:MSHR_ID_LSB];
                mshr_wr_ptr_sel = 2'b11;
                a_state_next = IDLE_A;
                ready_a2c_next = 1'b1;
                //set wack
                wack = 1'b1;
            end
        end
        SEND_R_RESP_TO_C_A: begin
            `DEBUG_PRINT_L1_HW(("(A) Now in SEND_R_RESP_TO_C_A"), STATE_MSG_L1_HW)
            valid_a2c = 1'b1;
            r_ptr_next = '0;
            data_a2c = r_buffer_r[r_ptr_next*WAYMEM_DW+:WAYMEM_DW];
            response_a2c = (mshr_transient_state_o == IS) ? READ_CLEAN_OKAY : READ_UNIQUE_OKAY;
            if (ack_c2a) begin
                a_state_next = SEND_DATA_RESP_TO_C_A;
            end
        end
        SEND_DATA_RESP_TO_C_A: begin
            `DEBUG_PRINT_L1_HW(("(A) Now in SEND_DATA_RESP_TO_C_A"), STATE_MSG_L1_HW)
            valid_a2c = 1'b1;
            r_ptr_next = r_ptr_r + 1'b1;
            response_a2c = (mshr_transient_state_o == IS) ? READ_CLEAN_OKAY : READ_UNIQUE_OKAY;
            data_a2c = r_buffer_r[r_ptr_next*WAYMEM_DW+:WAYMEM_DW];
            if (r_ptr_next == DCACHE_WORDS_PER_BLOCK-1) begin // check if the condition is ok
                a_state_next = IDLE_A;
                //set rack
                rack = 1'b1;
                // Remove the line from the MSHR
                mshr_we_i = 1'b1;
                mshr_valid_i = 1'b0;
                mshr_wrPtr_i = r_id_r[MSHR_ID_MSB:MSHR_ID_LSB];
                mshr_wr_ptr_sel = 2'b11;
                ready_a2c_next = 1'b1;
            end
        end
        WAIT_SNOOP_A: begin
            if (valid_b2a == 1'b1) begin
                ready_a2c_next = 1'b0;
                mshr_snoop_req_i = 1'b1;
                mshr_snoop_adr_i = adr_b2a[DCACHE_TAG_MSB:DCACHE_INDEX_LSB];
                snoop_req_b2a_next = snoop_req_b2a;
                snoop_adr_b2a_next = adr_b2a;
                a_state_next = HANDLE_SNOOP_A;
            end
        end
        HANDLE_SNOOP_A: begin
            `DEBUG_PRINT_L1_HW(("(A) Now in HANDLE_SNOOP_A"), STATE_MSG_L1_HW)
            hit_a2b = mshr_read_hit_o;
            transient_state_a2b = mshr_transient_state_o;
            if (mshr_read_hit_o == 1'b1 && snoop_req_b2a_r == SNOOP_READ_UNIQUE) begin 
                mshr_we_i = 1'b1;
                mshr_valid_i = 1'b1;
                mshr_wr_ptr_sel = 2'b10;
                mshr_adr_i = snoop_adr_b2a_r[DCACHE_TAG_MSB:DCACHE_INDEX_LSB];
                case (mshr_transient_state_o)
                    SM: begin
                        mshr_transient_state_i = IM;
                    end
                    SI: begin
                        mshr_transient_state_i = II;
                    end
                    default: begin
                        mshr_transient_state_i = mshr_transient_state_o;
                    end
                endcase
            end
            if (mshr_full_o == 1'b0) begin
                ready_a2c_next = 1'b1;
            end
            a_state_next = IDLE_A;
            // we have to set/unset ready_a2c, if there is a valid transaction in the MSHR, ready_next = 0, otherwise ready_next = 1
        end
        default: begin
            a_state_next = IDLE_A;
        end
    endcase

end

mshr mshr_inst (
        .clk(aclk),
        .resetn(aresetn),
        .we_i(mshr_we_i),
        .re_i(mshr_re_i),
        .adr_i(mshr_adr_i),
        .valid_i(mshr_valid_i),
        .transient_state_i(mshr_transient_state_i),
        .wrPtr_i(mshr_wrPtr_i),
        .snoop_adr_i(mshr_snoop_adr_i),
        .snoop_req_i(mshr_snoop_req_i),
        .readID_i(mshr_readID_i),
        .read_hit_o(mshr_read_hit_o),
        .full_o(mshr_full_o),
        .transient_state_o(mshr_transient_state_o),
        .wr_ptr_sel(mshr_wr_ptr_sel),
        .freePtr_o(mshr_freePtr_o)
    );

endmodule
