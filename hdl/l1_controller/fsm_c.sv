import param_pkg::*;
//(* dont_touch = "yes" *)
module fsm_c (
    input clk,
    input resetn,

    input req_m2dbiu,
    input [DBUS_AW-1:0] adr_m2dbiu,
    input [DBUS_DW-1:0] dat_m2dbiu,
    input we_m2dbiu,
    input [DCACHE_BYTES_PER_WORD-1:0] sel_m2dbiu,

    input ready_a2c,
    input ack_a2c,
    input response_a2c_t response_a2c,
    input [L1_INTERNAL_DW-1:0] data_a2c,
    input valid_a2c,

    input valid_b2c,
    input acq_b2c,
    input rel_b2c,
    input [L1_INTERNAL_AW-1:0] adr_b2c,
    input snoop_req_t snoop_req_b2c,

    output logic [DBUS_DW-1:0] dat_dbiu2m,
    output logic ack_dbiu2m,

    output logic ack_c2a,
    output transaction_type_t transaction_c2a,
    output logic [L1_INTERNAL_AW-1:0] adr_c2a,
    output logic valid_c2a,
    output logic [L1_INTERNAL_DW-1:0] data_c2a,

    output response_c2b_t response_c2b,
    output logic [L1_INTERNAL_DW-1:0] data_c2b,
    output logic ack_c2b
);
    //(* dont_touch = "yes" *) fsm_c_state_t c_state_r, c_state_next;
    fsm_c_state_t c_state_r, c_state_next;
    logic [DCACHE_BLOCK_WIDTH-1:0] wb_word_pointer_r, wb_word_pointer_next, r_word_pointer_r, r_word_pointer_next, snoop_word_pointer_r, snoop_word_pointer_next;

    logic [DCACHE_TAG_WIDTH-1:0] tag, tag_snoop;
    logic [DCACHE_INDEX_WIDTH-1:0] index;
    logic [DCACHE_BLOCK_WIDTH-1:0] block;

    logic [DCACHE_WAYS-1:0] [DCACHE_TAG_WIDTH-1:0]     check_tag;
    logic [DCACHE_WAYS-1:0]                            check_adr_match, check_adr_match_snoop;
    logic [DCACHE_WAYS-1:0]                            check_entry_hit, check_entry_hit_snoop;
    logic                                              hit, hit_snoop;

    logic [$clog2(DCACHE_WAYS)-1:0]                    readLinePtr, readLinePtr_snoop;
    logic [DCACHE_WAYS-1:0] [$clog2(DCACHE_WAYS)-1:0]  readLinePtr_vect, readLinePtr_vect_snoop;

    logic                                              tag_rcyc, tag_wcyc;
    logic                                              way_rcyc;
    logic [DCACHE_WAYS-1:0]                            way_wcyc;
    logic [DCACHE_INDEX_WIDTH-1:0]                     tag_rindex;
    logic [DCACHE_INDEX_WIDTH-1:0]                     tag_windex;
    logic [DCACHE_INDEX_WIDTH+DCACHE_BLOCK_WIDTH-1:0]  way_rindex;
    logic [DCACHE_INDEX_WIDTH+DCACHE_BLOCK_WIDTH-1:0]  way_windex;
    logic [TAGMEM_DW-1:0]                              tag_din, tag_dout;
    logic [(DCACHE_WAYS*WAYMEM_DW)-1:0]                way_din, way_dout;
    logic [DBUS_ISEL-1:0][7:0]                         way_din_word;

    logic [$clog2(DCACHE_WAYS)-1:0]                    wrLinePtr;
    logic [DCACHE_WAYS-1:0] [TAGMEM_WAY_WIDTH-1:0]     tagWay_out;
    logic [DCACHE_WAYS-1:0] [DCACHE_TAG_WIDTH-1:0]     tagWay_tag_out;
    logic [DCACHE_WAYS-1:0]                            tagWay_valid_out;
    logic [DCACHE_WAYS-1:0]                            tagWay_dirty_out;
    logic [DCACHE_WAYS-1:0]                            tagWay_outstanding_out;

    // Signals to perform tag_din composition
    logic [$clog2(DCACHE_WAYS)-1:0]                    wrLinePtr_in;
    logic [DCACHE_WAYS-1:0] [TAGMEM_WAY_WIDTH-1:0]     tagWay_in;
    logic [DCACHE_WAYS-1:0] [DCACHE_TAG_WIDTH-1:0]     tagWay_tag_in;
    logic [DCACHE_WAYS-1:0]                            tagWay_valid_in;
    logic [DCACHE_WAYS-1:0]                            tagWay_dirty_in;
    logic [DCACHE_WAYS-1:0]                            tagWay_outstanding_in;

    // Registers
    logic [DBUS_AW-1:0] adr_m2dbiu_r, adr_m2dbiu_next;
    logic [DBUS_DW-1:0] dat_m2dbiu_r, dat_m2dbiu_next;
    logic [DCACHE_BYTES_PER_WORD-1:0] sel_m2dbiu_r, sel_m2dbiu_next;
    logic we_m2dbiu_r, we_m2dbiu_next;

    response_a2c_t response_a2c_r, response_a2c_next;
    logic [L1_INTERNAL_DW-1:0] data_a2c_r, data_a2c_next;

    logic [L1_INTERNAL_AW-1:0] adr_b2c_r, adr_b2c_next;
    snoop_req_t snoop_req_r, snoop_req_next;

    assign tag   = adr_m2dbiu_r[DCACHE_TAG_MSB:DCACHE_TAG_LSB];
    assign index = adr_m2dbiu_r[DCACHE_INDEX_MSB:DCACHE_INDEX_LSB];
    assign block = adr_m2dbiu_r[DCACHE_BLOCK_MSB:DCACHE_BLOCK_LSB];
    assign tag_snoop = adr_b2c_r[DCACHE_TAG_MSB:DCACHE_TAG_LSB];
    /* TAG MEMORY internal layout:
       +---------------------------------------------------------------------------------------------------------------------------------+
       | wrLinePtr | wayOutstanding_n | wayDirty_n | wayValid_n | tagWay_n | ... | wayOutstanding_0 | wayDirty_0 | wayValid_0 | tagWay_0 | set_x
       +---------------------------------------------------------------------------------------------------------------------------------+
    */

    // Compose tag_din fields
    generate
        for(genvar i=0; i < DCACHE_WAYS; i = i+1) begin
            assign tagWay_in[i] = {tagWay_outstanding_in[i], tagWay_dirty_in[i], tagWay_valid_in[i], tagWay_tag_in[i]};
            assign tag_din[i*TAGMEM_WAY_WIDTH+:TAGMEM_WAY_WIDTH] = tagWay_in[i];
        end
    endgenerate

    assign tag_din[TAGMEM_WRPTR_MSB:TAGMEM_WRPTR_LSB] = wrLinePtr_in;

    // Decompose tag_dout fields: tags, valid bits, dirty bits and write pointer
    generate
        for(genvar i = 0; i < DCACHE_WAYS; i = i+1) begin
            assign tagWay_out[i]       = tag_dout[i*TAGMEM_WAY_WIDTH+:TAGMEM_WAY_WIDTH];
            assign tagWay_tag_out[i]   = tagWay_out[i][DCACHE_TAG_WIDTH-1:0];
            assign tagWay_valid_out[i] = tagWay_out[i][TAGMEM_WAY_VALID];
            assign tagWay_dirty_out[i] = tagWay_out[i][TAGMEM_WAY_DIRTY];
            assign tagWay_outstanding_out[i] = tagWay_out[i][TAGMEM_WAY_OUTSTANDING];

            assign check_tag[i]       = tagWay_tag_out[i];
        end
    endgenerate

    assign wrLinePtr = tag_dout[TAGMEM_WRPTR_MSB:TAGMEM_WRPTR_LSB];

    // Associative check on the tags of one set
    generate
        for(genvar i = 0; i < DCACHE_WAYS; i = i+1) begin
            assign check_adr_match[i] = (tag == check_tag[i]);
            assign check_entry_hit[i] = tagWay_valid_out[i] & check_adr_match[i];
        end
    endgenerate

    assign hit = |check_entry_hit;

    // Combinational logic to compute the cache line read pointer in case of hit
    generate
        assign readLinePtr_vect[0] = '0;
        for(genvar i = 1; i < DCACHE_WAYS; i = i+1) begin
            assign readLinePtr_vect[i] = (check_entry_hit[i]) ? i : readLinePtr_vect[i-1];
        end
        assign readLinePtr = readLinePtr_vect[DCACHE_WAYS-1];
    endgenerate

    // Associative check on the snoop tags of one set
    generate
        for(genvar i = 0; i < DCACHE_WAYS; i = i+1) begin
            assign check_adr_match_snoop[i] = (tag_snoop == check_tag[i]);
            assign check_entry_hit_snoop[i] = tagWay_valid_out[i] & check_adr_match_snoop[i];
        end
    endgenerate

    assign hit_snoop = |check_entry_hit_snoop;

    // Combinational logic to compute the cache line read pointer in case of hit
    generate
        assign readLinePtr_vect_snoop[0] = '0;
        for(genvar i = 1; i < DCACHE_WAYS; i = i+1) begin
            assign readLinePtr_vect_snoop[i] = (check_entry_hit_snoop[i]) ? i : readLinePtr_vect_snoop[i-1];
        end
        assign readLinePtr_snoop = readLinePtr_vect_snoop[DCACHE_WAYS-1];
    endgenerate

    // C Finite State Machine

    always_ff @(posedge clk) begin
        if (!resetn) begin
            c_state_r <= IDLE_C;
            wb_word_pointer_r <= '0;
            r_word_pointer_r <= '0;
            snoop_word_pointer_r <= '0;
            adr_m2dbiu_r <= '0;
            dat_m2dbiu_r <= '0;
            sel_m2dbiu_r <= '0;
            we_m2dbiu_r <= '0;
            response_a2c_r <= REPLACEMENT_OKAY;
            data_a2c_r <= '0;
            adr_b2c_r <= '0;
            snoop_req_r <= SNOOP_READ_UNIQUE;
        end else begin
            c_state_r <= c_state_next;
            wb_word_pointer_r <= wb_word_pointer_next;
            r_word_pointer_r <= r_word_pointer_next;
            snoop_word_pointer_r <= snoop_word_pointer_next;
            adr_m2dbiu_r <= adr_m2dbiu_next;
            dat_m2dbiu_r <= dat_m2dbiu_next;
            sel_m2dbiu_r <= sel_m2dbiu_next;
            we_m2dbiu_r <= we_m2dbiu_next;
            response_a2c_r <= response_a2c_next;
            data_a2c_r <= data_a2c_next;
            adr_b2c_r <= adr_b2c_next;
            snoop_req_r <= snoop_req_next;

        end
    end

    always_comb begin
        c_state_next        = c_state_r;

        wb_word_pointer_next = wb_word_pointer_r;
        r_word_pointer_next = r_word_pointer_r;
        snoop_word_pointer_next = snoop_word_pointer_r;

        adr_m2dbiu_next     = adr_m2dbiu_r;
        dat_m2dbiu_next     = dat_m2dbiu_r;
        sel_m2dbiu_next     = sel_m2dbiu_r;
        we_m2dbiu_next      = we_m2dbiu_r;
        response_a2c_next   = response_a2c_r;
        data_a2c_next       = data_a2c_r;
        adr_b2c_next        = adr_b2c_r;
        snoop_req_next      = snoop_req_r;



        ack_c2a = 1'b0;
        ack_c2b = 1'b0;
        valid_c2a = 1'b0;
        adr_c2a = '0;
        transaction_c2a = READ_CLEAN;
        data_c2a = '0;
        data_c2b = '0;
        response_c2b = INVALID;

        ack_dbiu2m = 1'b0;
        dat_dbiu2m = '0;

        tag_rcyc = 1'b0;
        tag_rindex = '0;
        tag_wcyc = 1'b0;
        tag_windex = '0;

        way_rcyc = 1'b0;
        way_rindex = '0;
        way_wcyc = '0;
        way_windex = '0;

        way_din = '0;
        way_din_word = '0;

        for(integer i = 0; i < DCACHE_WAYS; i = i+1) begin
            tagWay_tag_in[i]   = tagWay_tag_out[i];
            tagWay_valid_in[i] = tagWay_valid_out[i];
            tagWay_dirty_in[i] = tagWay_dirty_out[i];
            tagWay_outstanding_in[i] = tagWay_outstanding_out[i];
        end

        wrLinePtr_in = wrLinePtr;

        case (c_state_r)
            IDLE_C: begin
                if(valid_a2c) begin // There is a response from fsm A
                    ack_c2a = 1'b1;

                    response_a2c_next = response_a2c;
                    data_a2c_next = data_a2c;

                    c_state_next = HANDLE_A_RESP_C;
                    tag_rindex = index;
                    tag_rcyc = 1'b1;
                end
                else if (acq_b2c == 1'b1) begin
                    ack_c2b = 1'b1;
                    c_state_next = WAIT_SNOOP_C;
                    /*adr_b2c_next = adr_b2c;
                    snoop_req_next = snoop_req_b2c;

                    snoop_word_pointer_next = '0;
                    tag_rindex      = adr_b2c[DCACHE_INDEX_MSB:DCACHE_INDEX_LSB];
                    way_rindex      = {adr_b2c[DCACHE_INDEX_MSB:DCACHE_INDEX_LSB],
                                        snoop_word_pointer_next};

                    tag_rcyc        = 1'b1;
                    way_rcyc        = 1'b1;

                    c_state_next = HANDLE_SNOOP_REQ_C;*/
                end
                else if (req_m2dbiu) begin

                    adr_m2dbiu_next = adr_m2dbiu;
                    dat_m2dbiu_next = dat_m2dbiu;
                    sel_m2dbiu_next = sel_m2dbiu;
                    we_m2dbiu_next  = we_m2dbiu;

                    tag_rindex      = adr_m2dbiu[DCACHE_INDEX_MSB:DCACHE_INDEX_LSB];
                    way_rindex      = {adr_m2dbiu[DCACHE_INDEX_MSB:DCACHE_INDEX_LSB],
                                        adr_m2dbiu[DCACHE_BLOCK_MSB:DCACHE_BLOCK_LSB]};

                    tag_rcyc        = 1'b1;
                    way_rcyc        = 1'b1;

                    c_state_next = we_m2dbiu ? HANDLE_CPU_STORE_C : HANDLE_CPU_LOAD_C;
                end
            end
            HANDLE_CPU_LOAD_C: begin
                if (hit) begin
                    dat_dbiu2m = way_dout[readLinePtr*WAYMEM_DW+:WAYMEM_DW];
                    ack_dbiu2m = 1'b1;
                    `DEBUG_PRINT_L1_HW(("LOAD HIT addr = %0d", adr_m2dbiu_r), HIT_MISS_L1_HW)
                    c_state_next = IDLE_C;
                end
                else if(ready_a2c == 1'b0) begin
                    c_state_next = IDLE_C;
                end
                else begin
                    `DEBUG_PRINT_L1_HW(("LOAD MISS addr = %0d", adr_m2dbiu_r), HIT_MISS_L1_HW)
                    // The line to be replaced is already invalid
                    if (tagWay_valid_out[wrLinePtr] == 1'b0) begin
                        `DEBUG_PRINT_L1_HW(("Sending ReadClean request for addr %0d ", adr_m2dbiu_r), REQ_MSG_L1_HW)
                        valid_c2a = 1'b1;
                        adr_c2a = adr_m2dbiu_r;
                        transaction_c2a = READ_CLEAN;
                        c_state_next = IDLE_C;
                    end
                    // The line to be replaced is valid and dirty
                    else if(tagWay_dirty_out[wrLinePtr]) begin
                        `DEBUG_PRINT_L1_HW(("Sending WriteBack request for addr %0d",{tagWay_tag_out[wrLinePtr], index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}}), REQ_MSG_L1_HW)
                        wb_word_pointer_next = '0;
                        way_rcyc = 1'b1;
                        way_rindex = {index, wb_word_pointer_next};
                        valid_c2a = 1'b1;
                        transaction_c2a = WRITE_BACK;
                        adr_c2a = {tagWay_tag_out[wrLinePtr], index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}};
                        c_state_next = CHECK_ACK_A2C_C;
                    end
                    // The line to be replaced is valid and clean
                    else begin
                        `DEBUG_PRINT_L1_HW(("Sending Evict request for addr %0d",{tagWay_tag_out[wrLinePtr], index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}}), REQ_MSG_L1_HW)
                        valid_c2a = 1'b1;
                        adr_c2a = {tagWay_tag_out[wrLinePtr], index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}};
                        transaction_c2a = EVICT;
                        c_state_next = IDLE_C;
                    end
                    tag_wcyc = 1'b1;
                    tag_windex = index;
                    tagWay_outstanding_in[wrLinePtr] = 1'b1;
                end
            end

            HANDLE_WRITE_BACK_C: begin
                valid_c2a = 1'b1;
                transaction_c2a = WRITE_BACK;
                adr_c2a = {tagWay_tag_out[wrLinePtr], index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}};
                data_c2a = way_dout[wrLinePtr*WAYMEM_DW+:WAYMEM_DW];
                wb_word_pointer_next = wb_word_pointer_r + 1;
                way_rcyc = 1'b1;
                way_rindex = {index, wb_word_pointer_next};
                /*$write("[T: %0d][L1 CONTROLLER %0d] (C) [addr: %0d] Data to be written back is ", $time, CPU_ID, adr_c2a);
                for (int i=4-1; i>=0; i=i-1) begin
                    $write("%b, ", data_c2a[i*8+:8]);
                end
                $write("\n");*/
                if(wb_word_pointer_next == '0) begin // Assuming that the number of words per line is a power of 2 (this segment here relies on overflow of the pointer)
                    c_state_next = IDLE_C;
                end
            end
            CHECK_ACK_A2C_C: begin
                `DEBUG_PRINT_L1_HW(("(C) Now in CHECK_ACK_A2C_C", CPU_ID), STATE_MSG_L1_HW)
                if (ack_a2c == 1'b0) begin
                    c_state_next = IDLE_C;
                end
                else begin
                    valid_c2a = 1'b1;
                    transaction_c2a = WRITE_BACK;
                    adr_c2a = {tagWay_tag_out[wrLinePtr], index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}};
                    data_c2a = way_dout[wrLinePtr*WAYMEM_DW+:WAYMEM_DW];
                    /*$write("[T: %0d][L1 CONTROLLER %0d] (C) [addr: %0d] Data to be written back is ", $time, CPU_ID, adr_c2a);
                    for (int i=4-1; i>=0; i=i-1) begin
                        $write("%b, ", data_c2a[i*8+:8]);
                    end
                    $write("\n");*/
                    wb_word_pointer_next = wb_word_pointer_r + 1;
                    way_rcyc = 1'b1;
                    way_rindex = {index, wb_word_pointer_next};
                    c_state_next = HANDLE_WRITE_BACK_C;
                end
            end

            HANDLE_CPU_STORE_C: begin
                // The line is valid and dirty (has write permission)
                if (hit && tagWay_dirty_out[readLinePtr]) begin
                    way_wcyc[readLinePtr] = 1'b1;
                    way_windex            = {index, block};

                    way_din_word = way_dout[readLinePtr*WAYMEM_DW+:WAYMEM_DW];

                    /* Write the target bytes only and preserve the others */
                    //$write("[T: %0d][L1 CONTROLLER %0d] (C) storing data, new values:", $time, CPU_ID);
                    for(integer i = 0; i < DBUS_ISEL; i = i+1) begin
                        if(sel_m2dbiu[i]) begin
                            way_din_word[i] = dat_m2dbiu_r[i*8+:8];
                        end
                        //$write("%b ", way_din_word[i]);
                    end
                    //$write("\n");

                    way_din[readLinePtr*WAYMEM_DW+:WAYMEM_DW] = way_din_word;

                    ack_dbiu2m    = 1'b1;
                    `DEBUG_PRINT_L1_HW(("STORE HIT addr = %0d", adr_m2dbiu_r), HIT_MISS_L1_HW)
                    c_state_next = IDLE_C;
                end
                else if(ready_a2c == 1'b0) begin
                    c_state_next = IDLE_C;
                end
                // the line is valid but it has not the permission to write
                else if(hit) begin
                    `DEBUG_PRINT_L1_HW(("STORE MISS addr = %0d", adr_m2dbiu_r), HIT_MISS_L1_HW)
                    valid_c2a = 1'b1;
                    `DEBUG_PRINT_L1_HW(("Sending ReadUnique_hit request for addr %0d", adr_m2dbiu_r), REQ_MSG_L1_HW)
                    adr_c2a = adr_m2dbiu_r;
                    transaction_c2a = READ_UNIQUE_HIT;
                    c_state_next = IDLE_C;

                    tag_wcyc = 1'b1;
                    tag_windex = index;
                    tagWay_outstanding_in[readLinePtr] = 1'b1;

                end
                else begin
                    `DEBUG_PRINT_L1_HW(("STORE MISS addr = %0d", adr_m2dbiu_r), HIT_MISS_L1_HW)
                    // The line to be replaced is already invalid
                    if (!tagWay_valid_out[wrLinePtr]) begin
                        `DEBUG_PRINT_L1_HW(("Sending ReadUnique request for addr %0d", adr_m2dbiu_r), REQ_MSG_L1_HW)
                        valid_c2a = 1'b1;
                        adr_c2a = adr_m2dbiu_r;
                        transaction_c2a = READ_UNIQUE;
                        c_state_next = IDLE_C;
                    end
                    // The line to be replaced is valid and dirty
                    else if(tagWay_dirty_out[wrLinePtr]) begin
                        `DEBUG_PRINT_L1_HW(("Sending WriteBack request for addr %0d",{tagWay_tag_out[wrLinePtr], index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}}), REQ_MSG_L1_HW)
                        wb_word_pointer_next = '0;
                        way_rcyc = 1'b1;
                        way_rindex = {index, wb_word_pointer_next};
                        valid_c2a = 1'b1;
                        transaction_c2a = WRITE_BACK;
                        adr_c2a = {tagWay_tag_out[wrLinePtr], index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}};
                        c_state_next = CHECK_ACK_A2C_C;
                    end
                    // The line to be replaced is valid and clean
                    else begin
                        `DEBUG_PRINT_L1_HW(("Sending Evict request for addr %0d", {tagWay_tag_out[wrLinePtr], index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}}), REQ_MSG_L1_HW)
                        valid_c2a = 1'b1;
                        adr_c2a = {tagWay_tag_out[wrLinePtr], index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}};
                        transaction_c2a = EVICT;
                        c_state_next = IDLE_C;
                    end
                    tag_wcyc = 1'b1;
                    tag_windex = index;
                    tagWay_outstanding_in[wrLinePtr] = 1'b1;
                end
            end
            HANDLE_A_RESP_C: begin
                if (response_a2c_r == REPLACEMENT_OKAY) begin
                    `DEBUG_PRINT_L1_HW(("(C) UNSET VALID and DIRTY addr %0d", {tagWay_tag_out[wrLinePtr], index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}}), TAG_MSG_L1_HW)
                    tagWay_valid_in[wrLinePtr] = 1'b0;
                    tagWay_dirty_in[wrLinePtr] = 1'b0;
                    tagWay_outstanding_in[wrLinePtr] = 1'b0;
                    // We don't increment wrLinePtr here because we will do that after we load a new line in that space
                    tag_windex = index;
                    tag_wcyc = 1'b1;
                    c_state_next = IDLE_C;
                end
                else begin
                    if(hit) begin
                        way_din[readLinePtr*WAYMEM_DW+:WAYMEM_DW] = data_a2c_r;
                        data_a2c_next = data_a2c;
                        r_word_pointer_next = '0;
                        way_windex = {index, r_word_pointer_next};
                        way_wcyc[readLinePtr] = 1'b1;
                        c_state_next = HANDLE_A_DATA_C;
                    end
                    else begin
                        way_din[wrLinePtr*WAYMEM_DW+:WAYMEM_DW] = data_a2c_r;
                        data_a2c_next = data_a2c;
                        r_word_pointer_next = '0;
                        way_windex = {index, r_word_pointer_next};
                        way_wcyc[wrLinePtr] = 1'b1;
                        c_state_next = HANDLE_A_DATA_C;
                    end
                end
            end
            HANDLE_A_DATA_C: begin
                r_word_pointer_next = r_word_pointer_r + 1;
                way_windex = {index, r_word_pointer_next};
                if (hit) begin // We can get in this condition only for a ReadUnique issued for lack of writing permission (the line was valid but not dirty)
                    way_din[readLinePtr*WAYMEM_DW+:WAYMEM_DW] = data_a2c_r;
                    data_a2c_next = data_a2c;
                    way_wcyc[readLinePtr] = 1'b1;
                    if(r_word_pointer_next == DCACHE_WORDS_PER_BLOCK-1) begin // Assuming that the number of words per line is a power of 2 (this segment here relies on overflow of the pointer)
                        `DEBUG_PRINT_L1_HW(("(C) SET VALID and DIRTY addr %0d", {tag, index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}}), TAG_MSG_L1_HW)
                        tagWay_tag_in[readLinePtr] = tag;
                        `DEBUG_PRINT_L1_HW(("(C) Add TAG %b in WAY %0d", tagWay_tag_in[readLinePtr], readLinePtr), REQ_MSG_L1_HW)
                        tagWay_valid_in[readLinePtr] = 1'b1;
                        tagWay_dirty_in[readLinePtr] = 1'b1;
                        tagWay_outstanding_in[readLinePtr] = 1'b0;
                        tag_windex = index;
                        tag_wcyc = 1'b1;
                        c_state_next = IDLE_C;
                    end
                end
                else begin
                    way_din[wrLinePtr*WAYMEM_DW+:WAYMEM_DW] = data_a2c_r;
                    data_a2c_next = data_a2c;
                    way_wcyc[wrLinePtr] = 1'b1;
                    if(r_word_pointer_next == DCACHE_WORDS_PER_BLOCK-1) begin // Assuming that the number of words per line is a power of 2 (this segment here relies on overflow of the pointer)
                        `DEBUG_PRINT_L1_HW(("(C) SET VALID and DIRTY (if RU) addr %0d", {tag, index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}}), TAG_MSG_L1_HW)
                        tagWay_tag_in[wrLinePtr] = tag;
                        `DEBUG_PRINT_L1_HW(("(C) Add TAG %b in WAY %0d", tagWay_tag_in[wrLinePtr], wrLinePtr), REQ_MSG_L1_HW)
                        tagWay_valid_in[wrLinePtr] = 1'b1;
                        tagWay_outstanding_in[wrLinePtr] = 1'b0;
                        tagWay_dirty_in[wrLinePtr] = (response_a2c_r == READ_UNIQUE_OKAY) ? 1'b1 : 1'b0;
                        wrLinePtr_in = wrLinePtr + 1;
                        tag_windex = index;
                        tag_wcyc = 1'b1;
                        c_state_next = IDLE_C;
                    end
                end
            end

            WAIT_SNOOP_C: begin
                if (rel_b2c == 1'b1) begin
                    c_state_next = IDLE_C;
                end
                else if (valid_b2c) begin
                    adr_b2c_next = adr_b2c;
                    snoop_req_next = snoop_req_b2c;

                    snoop_word_pointer_next = '0;
                    tag_rindex      = adr_b2c[DCACHE_INDEX_MSB:DCACHE_INDEX_LSB];
                    way_rindex      = {adr_b2c[DCACHE_INDEX_MSB:DCACHE_INDEX_LSB],
                                        snoop_word_pointer_next};

                    tag_rcyc        = 1'b1;
                    way_rcyc        = 1'b1;

                    c_state_next = HANDLE_SNOOP_REQ_C;
                end
            end

            HANDLE_SNOOP_REQ_C: begin
                `DEBUG_PRINT_L1_HW(("Received snoop request for address %0d", adr_b2c_r), REQ_MSG_L1_HW)
                `DEBUG_PRINT_L1_HW(("(TAG SNOOP = %b | INDEX SNOOP = %b", adr_b2c_r[DCACHE_TAG_MSB:DCACHE_TAG_LSB],adr_b2c_r[DCACHE_INDEX_MSB:DCACHE_INDEX_LSB]), REQ_MSG_L1_HW)
                `DEBUG_PRINT_L1_HW(("TAG WAY 0 = %b", tagWay_tag_out[0]), REQ_MSG_L1_HW)
                `DEBUG_PRINT_L1_HW(("TAG WAY 1 = %b", tagWay_tag_out[1]), REQ_MSG_L1_HW)
                if(hit_snoop) begin // Questo hit è riferito a adr_m2dbiu e non all'address dello snoop
                    `DEBUG_PRINT_L1_HW(("Snoop Hit"), HIT_MISS_L1_HW)
                    response_c2b = tagWay_dirty_out[readLinePtr_snoop] ? VALID_DIRTY : VALID_CLEAN;
                    data_c2b = way_dout[readLinePtr_snoop*WAYMEM_DW+:WAYMEM_DW];
                    snoop_word_pointer_next = snoop_word_pointer_r + 1;
                    way_rcyc = 1'b1;
                    way_rindex = {adr_b2c_r[DCACHE_INDEX_MSB:DCACHE_INDEX_LSB], snoop_word_pointer_next};
                    `DEBUG_PRINT_L1_HW(("(C) REMOVE DIRTY AND IF RU ALSO INVALIDE addr %0d", adr_b2c_r), TAG_MSG_L1_HW)
                    tagWay_valid_in[readLinePtr_snoop] = (snoop_req_r == SNOOP_READ_UNIQUE) ? 1'b0 : 1'b1;
                    tagWay_dirty_in[readLinePtr_snoop] = 1'b0;
                    tag_windex = adr_b2c_r[DCACHE_INDEX_MSB:DCACHE_INDEX_LSB];
                    tag_wcyc = 1'b1;

                    c_state_next = HANDLE_SNOOP_DATA_C; // the code may be broken if the line has only one word
                end
                else begin
                    `DEBUG_PRINT_L1_HW(("Snoop Miss"), HIT_MISS_L1_HW)
                    response_c2b = INVALID;
                    c_state_next = IDLE_C;
                end
            end
            HANDLE_SNOOP_DATA_C: begin
                response_c2b = tagWay_dirty_out[readLinePtr_snoop] ? VALID_DIRTY : VALID_CLEAN;
                data_c2b = way_dout[readLinePtr_snoop*WAYMEM_DW+:WAYMEM_DW];
                snoop_word_pointer_next = snoop_word_pointer_r + 1;
                way_rcyc = 1'b1;
                way_rindex = {adr_b2c_r[DCACHE_INDEX_MSB:DCACHE_INDEX_LSB], snoop_word_pointer_next};
                if (snoop_word_pointer_next == '0) begin
                    c_state_next = IDLE_C;
                end
            end
            default: begin
                c_state_next = IDLE_C;
            end
        endcase
    end

    generate
        for(genvar i = 0; i < DCACHE_WAYS; i = i+1) begin
            dp_ram_clk #(.DPRAM_AW(WAYMEM_AW), .DPRAM_DW(WAYMEM_DW))
                way_mem (

                .clk        (clk),

                // Always read on port A
                .cyc_a_i    (way_rcyc),
                .we_a_i     (1'b0),
                .adr_a_i    (way_rindex),
                .dat_a_i    ('0),

                // Always write on port B
                .cyc_b_i    (way_wcyc[i]),
                .we_b_i     (1'b1),
                .adr_b_i    (way_windex),
                .dat_b_i    (way_din[i*WAYMEM_DW+:WAYMEM_DW]),

                .dat_a_o    (way_dout[i*WAYMEM_DW+:WAYMEM_DW]),
                .dat_b_o    ()
            );


            `ifndef SYNTHESIS
            initial begin
                $display("Init way_mem (%d) using /home/dcollovigh/git/gem5_sv/src/rtl/mem_dump/mem_zero.hex", i);
                $readmemh("/home/dcollovigh/git/gem5_sv/src/rtl/mem_dump/mem_zero.hex", way_mem.mem);
            end
            `endif
        end
    endgenerate

    dp_ram_clk #(.DPRAM_AW(TAGMEM_AW), .DPRAM_DW(TAGMEM_DW))
        tag_mem0 (

        .clk        (clk),

        // Always read on port A
        .cyc_a_i    (tag_rcyc),
        .we_a_i     (1'b0),
        .adr_a_i    (tag_rindex),
        .dat_a_i    ('0),

        // Always write on port B
        .cyc_b_i    (tag_wcyc),
        .we_b_i     (1'b1),
        .adr_b_i    (tag_windex),
        .dat_b_i    (tag_din),

        .dat_a_o    (tag_dout),
        .dat_b_o    ()
    );

    `ifndef SYNTHESIS
    initial begin
        $display("Init tag_mem0 using /home/dcollovigh/git/gem5_sv/src/rtl/mem_dump/mem_zero.hex");
        $readmemh("/home/dcollovigh/git/gem5_sv/src/rtl/mem_dump/mem_zero.hex", tag_mem0.mem);
    end
    `endif

endmodule