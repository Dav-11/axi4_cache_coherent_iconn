import param_pkg::*;

// The dirty bit might not be necessary

module dir_mem(
    input clk,
    input resetn,
    input [DCACHE_INDEX_WIDTH-1:0]  index,
    input [DCACHE_TAG_WIDTH-1:0]    tag,
    input op_dir_t                  operation,
    input [CPU_ID_WIDTH-1:0]        cpu_id,
    input                           req,
    output logic [N_CPU-1:0]        sharers_o,
    output logic                    ack
    );

    //(* dont_touch = "yes" *) dir_state_t dir_state_r, dir_state_next;
    dir_state_t dir_state_r, dir_state_next;

    logic [DIR_MEM_WAYS-1:0] [DCACHE_TAG_WIDTH-1:0]     check_tag;
    logic [DIR_MEM_WAYS-1:0]                            check_adr_match;
    logic [DIR_MEM_WAYS-1:0]                            check_entry_hit;
    logic                                               hit;

    logic [$clog2(DIR_MEM_WAYS)-1:0]                    readLinePtr;
    logic [DIR_MEM_WAYS-1:0] [$clog2(DIR_MEM_WAYS)-1:0] readLinePtr_vect;

    logic                                               dir_rcyc, dir_wcyc;
    logic [DCACHE_INDEX_WIDTH-1:0]                      dir_rindex;
    logic [DCACHE_INDEX_WIDTH-1:0]                      dir_windex;
    logic [DIR_MEM_DW-1:0]                               dir_din, dir_dout;
    
    // Signals to perform dir_dout decomposition
    logic [$clog2(DIR_MEM_WAYS)-1:0]                    wrLinePtr;
    logic [DIR_MEM_WAYS-1:0] [$clog2(DIR_MEM_WAYS)-1:0] wrLinePtr_vect;
    logic [DIR_MEM_WAYS-1:0] [DIR_MEM_WAY_WIDTH-1:0]    dirWay_out;
    logic [DIR_MEM_WAYS-1:0] [DCACHE_TAG_WIDTH-1:0]     dirWay_tag_out;
    logic [DIR_MEM_WAYS-1:0]                            dirWay_valid_out;
    logic [DIR_MEM_WAYS-1:0]                            dirWay_dirty_out;
    logic [DIR_MEM_WAYS-1:0] [N_CPU-1:0]                dirWay_sharers_out;

    // Signals to perform dir_din composition
    logic [DIR_MEM_WAYS-1:0] [DIR_MEM_WAY_WIDTH-1:0]    dirWay_in;
    logic [DIR_MEM_WAYS-1:0] [DCACHE_TAG_WIDTH-1:0]     dirWay_tag_in;
    logic [DIR_MEM_WAYS-1:0]                            dirWay_valid_in;
    logic [DIR_MEM_WAYS-1:0]                            dirWay_dirty_in;
    logic [DIR_MEM_WAYS-1:0] [N_CPU-1:0]                dirWay_sharers_in;

    generate
        for(genvar i = 0; i < DIR_MEM_WAYS; i = i+1) begin
            assign dirWay_out[i]       = dir_dout[i*DIR_MEM_WAY_WIDTH+:DIR_MEM_WAY_WIDTH];
            assign dirWay_tag_out[i]   = dirWay_out[i][DCACHE_TAG_WIDTH-1:0];
            assign dirWay_valid_out[i] = dirWay_out[i][DIR_MEM_VALID];
            assign dirWay_dirty_out[i] = dirWay_out[i][DIR_MEM_DIRTY];
            assign dirWay_sharers_out[i] = dirWay_out[i][DIR_MEM_SHARERS_MSB:DIR_MEM_SHARERS_LSB];
        end
    endgenerate

    // Compose dir_din fields
    generate
        for(genvar i=0; i < DIR_MEM_WAYS; i = i+1) begin
            assign dirWay_in[i] = {dirWay_valid_in[i], dirWay_dirty_in[i], dirWay_sharers_in[i], dirWay_tag_in[i]};
            assign dir_din[i*DIR_MEM_WAY_WIDTH+:DIR_MEM_WAY_WIDTH] = dirWay_in[i];
        end
    endgenerate

    // Associative check on the tags of one set
    generate
        for(genvar i = 0; i < DIR_MEM_WAYS; i = i+1) begin
            assign check_tag[i]       = dirWay_tag_out[i];
            assign check_adr_match[i] = (tag == check_tag[i]);
            assign check_entry_hit[i] = dirWay_valid_out[i] & check_adr_match[i];
        end
    endgenerate

    assign hit = |check_entry_hit;

    // Combinational logic to compute the cache line read pointer in case of hit
    generate
        assign readLinePtr_vect[0] = '0;
        for(genvar i = 1; i < DIR_MEM_WAYS; i = i+1) begin
            assign readLinePtr_vect[i] = (check_entry_hit[i]) ? i : readLinePtr_vect[i-1];
        end
        assign readLinePtr = readLinePtr_vect[DIR_MEM_WAYS-1];
    endgenerate

    // Combinational logic to compute the cache line write pointer
    generate
        assign wrLinePtr_vect[0] = '0;
        for(genvar i = 1; i < DIR_MEM_WAYS; i = i+1) begin
            assign wrLinePtr_vect[i] = dirWay_valid_out[i] ? wrLinePtr_vect[i-1] : i;
        end
        assign wrLinePtr = wrLinePtr_vect[DIR_MEM_WAYS-1];
    endgenerate

    always_ff @(posedge clk) begin
        if (!resetn) begin
            dir_state_r <= IDLE_DIR;
        end
        else begin
            dir_state_r <= dir_state_next;
        end
    end

    always_comb begin
        dir_state_next = dir_state_r;
        dir_rcyc = 1'b0;
        dir_rindex = '0;
        dir_wcyc = 1'b0;
        dir_windex = '0;

        sharers_o = '0;
        ack = 1'b0;

        for (int i=0; i < DIR_MEM_WAYS; i = i+1) begin
            dirWay_valid_in[i]      = dirWay_valid_out[i];
            dirWay_dirty_in[i]      = dirWay_dirty_out[i];
            dirWay_sharers_in[i]    = dirWay_sharers_out[i];
            dirWay_tag_in[i]        = dirWay_tag_out[i];
        end

        case (dir_state_r)
            IDLE_DIR: begin
                if (req == 1'b1) begin
                    dir_rindex = index;
                    dir_rcyc = 1'b1;
                    case (operation)
                        EVICT_OP: dir_state_next = HANDLE_EVICT_DIR;

                        WRITE_BACK_OP: dir_state_next = HANDLE_WRITE_BACK_DIR;

                        READ_OP: dir_state_next = HANDLE_READ_INFO_DIR;

                        SET_RU_OP: dir_state_next = HANDLE_SET_RU_DIR;

                        SET_RC_OP: dir_state_next = HANDLE_SET_RC_DIR;

                        default: dir_state_next = IDLE_DIR;
                    endcase
                end
                else begin
                    dir_rcyc = 1'b0;
                    dir_rindex = '0;
                    dir_state_next = IDLE_DIR;
                end
            end

            HANDLE_EVICT_DIR: begin
                // TODO: Should we remove the if hit? It should be always true if everything is correct
                if (hit) begin
                    dirWay_sharers_in[readLinePtr][cpu_id]= 1'b0;
                    if (!(|dirWay_sharers_in[readLinePtr])) begin // If no more sharers, the line is not valid anymore
                        dirWay_valid_in[readLinePtr] = 1'b0;
                    end
                    dir_windex = index;
                    dir_wcyc = 1'b1;
                    ack = 1'b1;
                    dir_state_next = IDLE_DIR;
                end
                /*else begin
                    $fatal(0, "DIR: Evicting a non-existing line [%0d]", {tag, index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}});
                end*/
            end

            HANDLE_WRITE_BACK_DIR: begin
                if (hit) begin // Writeback always evicts the line
                    dirWay_dirty_in[readLinePtr] = 1'b0;
                    dirWay_sharers_in[readLinePtr][cpu_id] = 1'b0;
                    dirWay_valid_in[readLinePtr] = 1'b0;
                    dir_windex = index;
                    dir_wcyc = 1'b1;
                    ack = 1'b1;
                    dir_state_next = IDLE_DIR;
                end
                /*else begin
                    $fatal(0, "DIR: Writing back a non-existing line [%0d]", {tag, index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}});
                end*/
            end

            HANDLE_READ_INFO_DIR: begin
                if (hit) begin
                    sharers_o = dirWay_sharers_out[readLinePtr];
                end
                else begin
                    /*if (dirWay_valid_out[wrLinePtr]) // We may fall in this condition even if false when the signal is changing (it's not registered)
                        $fatal(0, "Overwriting a valid line [%0d] in way %0d with [%0d]", {dirWay_tag_out[wrLinePtr], index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}}, wrLinePtr, {tag, index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}});
                    */
                    dirWay_valid_in[wrLinePtr] = 1'b1;
                    dirWay_dirty_in[wrLinePtr] = 1'b0;
                    dirWay_tag_in[wrLinePtr] = tag;
                    dirWay_sharers_in[wrLinePtr] = '0;
                    sharers_o = '0;
                    dir_windex = index;
                    dir_wcyc = 1'b1;
                end
                ack = 1'b1;
                dir_state_next = IDLE_DIR;
            end

            HANDLE_SET_RU_DIR: begin
                if (hit) begin
                    dirWay_sharers_in[readLinePtr] = '0;
                    dirWay_sharers_in[readLinePtr][cpu_id] = 1'b1;
                    dirWay_dirty_in[readLinePtr] = 1'b1;
                end
                else begin
                    // This case is not impossible anymore. It can happen when a line is evicted and then set info is called
                    // $fatal(0, "DIR: Setting info in a non-existing line [%0d]", {tag, index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}});
                    
                    /*if (dirWay_valid_out[wrLinePtr]) // We may fall in this condition even if false when the signal is changing (it's not registered)
                        $fatal(0, "Overwriting a valid line [%0d] in way %0d with [%0d]", {dirWay_tag_out[wrLinePtr], index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}}, wrLinePtr, {tag, index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}});
                    */
                    dirWay_valid_in[wrLinePtr] = 1'b1;
                    dirWay_dirty_in[wrLinePtr] = 1'b1;
                    dirWay_tag_in[wrLinePtr] = tag;
                    dirWay_sharers_in[wrLinePtr] = '0;
                    dirWay_sharers_in[wrLinePtr][cpu_id] = 1'b1;
                end
                ack = 1'b1;
                dir_windex = index;
                dir_wcyc = 1'b1;
                dir_state_next = IDLE_DIR;
            end

            HANDLE_SET_RC_DIR: begin
                if (hit) begin
                    dirWay_sharers_in[readLinePtr][cpu_id] = 1'b1;
                    dirWay_dirty_in[readLinePtr] = 1'b0;
                end
                else begin
                    /*if (dirWay_valid_out[wrLinePtr]) // We may fall in this condition even if false when the signal is changing (it's not registered)
                        $fatal(0, "Overwriting a valid line [%0d] in way %0d with [%0d]", {dirWay_tag_out[wrLinePtr], index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}}, wrLinePtr, {tag, index, {(DCACHE_BLOCK_WIDTH+DCACHE_BYTE_OFFSET){1'b0}}});
                    */
                    dirWay_valid_in[wrLinePtr] = 1'b1;
                    dirWay_dirty_in[wrLinePtr] = 1'b0;
                    dirWay_tag_in[wrLinePtr] = tag;
                    dirWay_sharers_in[wrLinePtr] = '0; // Make sure there are no sharers left in the newly allocated line
                    dirWay_sharers_in[wrLinePtr][cpu_id] = 1'b1;
                end
                ack = 1'b1;
                dir_windex = index;
                dir_wcyc = 1'b1;
                dir_state_next = IDLE_DIR;
            end
            default: dir_state_next = IDLE_DIR;
        endcase
    end

    dp_ram_clk #(.DPRAM_AW(DIR_MEM_AW), .DPRAM_DW(DIR_MEM_DW))
        dir_mem0 (

        .clk        (clk),

        // Always read on port A
        .cyc_a_i    (dir_rcyc),
        .we_a_i     (1'b0),
        .adr_a_i    (dir_rindex),
        .dat_a_i    ('0),

        // Always write on port B
        .cyc_b_i    (dir_wcyc),
        .we_b_i     (1'b1),
        .adr_b_i    (dir_windex),
        .dat_b_i    (dir_din),

        .dat_a_o    (dir_dout),
        .dat_b_o    ()

    );

endmodule