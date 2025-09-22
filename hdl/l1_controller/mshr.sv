import param_pkg::*;

module mshr(
    clk, 
    resetn, 
    we_i, 
    transient_state_i, 
    adr_i, 
    valid_i, 
    wr_ptr_sel,
    transient_state_o, 
    freePtr_o, 
    re_i,
    snoop_adr_i, 
    full_o, 
    read_hit_o, 
    wrPtr_i, 
    readID_i, 
    snoop_req_i
);    
    input clk, resetn, we_i;
    input snoop_req_i;
    input [1:0] wr_ptr_sel;
    input transient_state_t transient_state_i;
    input [DCACHE_TAG_WIDTH+DCACHE_INDEX_WIDTH-1:0] adr_i;
    input valid_i;
    input [DCACHE_TAG_WIDTH+DCACHE_INDEX_WIDTH-1:0] snoop_adr_i;
    input [MSHR_AW-1:0] wrPtr_i;
    input [MSHR_AW-1:0] readID_i;
    input re_i;
    output transient_state_t transient_state_o;
    output logic full_o;
    output logic read_hit_o;
    output logic [MSHR_AW-1:0] freePtr_o;
    
    /*  |-------------------------------------------------------|
        |   transient_state    |         adr(tag+index)         |
        |-------------------------------------------------------|*/
    logic [MSHR_DEPTH-1:0] [DCACHE_TAG_WIDTH+DCACHE_INDEX_WIDTH-1:0] mshr_adr_mem;
    transient_state_t [MSHR_DEPTH-1:0] mshr_transient_mem;
    logic [MSHR_DEPTH-1:0] valid_vect = '0;
    logic [MSHR_DEPTH-1:0] [MSHR_AW-1:0] freePtr_vect, snoopPtr_vect;
    logic [MSHR_AW-1:0] freePtr, snoopPtr, snoopPtr_r;
    logic hit;
    logic [MSHR_AW-1:0] wrPtr_sig;
    
    transient_state_t [MSHR_DEPTH-1:0] mshr_transient_out;
    logic [MSHR_DEPTH-1:0] [DCACHE_TAG_WIDTH+DCACHE_INDEX_WIDTH-1:0] mshr_adr_out;
    logic [MSHR_DEPTH-1:0] check_adr_match, check_entry_hit;


    // get address of empty slot
    generate
        assign freePtr_vect[0] = '0;
        for(genvar i = 1; i < MSHR_DEPTH; i = i+1) begin
            assign freePtr_vect[i] = (!valid_vect[i]) ? i : freePtr_vect[i-1];
        end
        assign freePtr = freePtr_vect[MSHR_DEPTH-1];
    endgenerate
    assign full_o = &valid_vect;
    assign freePtr_o = freePtr;

    generate
        for(genvar i = 0; i < MSHR_DEPTH; i = i+1) begin
            assign mshr_transient_out[i] = mshr_transient_mem[i];
            assign mshr_adr_out[i]   = mshr_adr_mem[i];
        end
    endgenerate

    // Associative check on the tags of the MSHR
    generate
        for(genvar i = 0; i < MSHR_DEPTH; i = i+1) begin
            assign check_adr_match[i] = (mshr_adr_out[i] == snoop_adr_i);
            assign check_entry_hit[i] = valid_vect[i] & check_adr_match[i];
        end
    endgenerate

    assign hit = |check_entry_hit;

    generate
        assign snoopPtr_vect[0] = '0;
        for(genvar i = 1; i < MSHR_DEPTH; i = i+1) begin
            assign snoopPtr_vect[i] = (check_entry_hit[i]) ? i : snoopPtr_vect[i-1];
        end
        assign snoopPtr = snoopPtr_vect[MSHR_DEPTH-1];
    endgenerate
    

    always_ff @(posedge clk) begin
        if (!resetn) begin
            mshr_adr_mem <= '0;
            for (int i = 0; i < MSHR_DEPTH; i = i+1)
                mshr_transient_mem[i] <= IM;
            valid_vect <= '0;
            snoopPtr_r <= '0;
            read_hit_o <= 0;
            transient_state_o <= IM;
        end
        else begin
            if (we_i) begin 
                mshr_adr_mem[wrPtr_sig] <= adr_i;
                mshr_transient_mem[wrPtr_sig] <= transient_state_i;
                valid_vect[wrPtr_sig] <= valid_i;
            end
            if (snoop_req_i) begin
                transient_state_o <= mshr_transient_out[snoopPtr];
                snoopPtr_r <= snoopPtr;
                read_hit_o <= hit;
            end
            else if (re_i) begin
                transient_state_o <= mshr_transient_out[readID_i];
            end
        end
    end
    
    always_comb begin
        // Modify the line that was addressed by the previous snoop request
        if (wr_ptr_sel == 2'b10) begin
            wrPtr_sig = snoopPtr_r;
        end
        // Modify the line that is addressed by the current external pointer
        else if (wr_ptr_sel == 2'b11) begin
            wrPtr_sig = wrPtr_i;
        end
        // Add a new line to the MSHR
        else begin
            wrPtr_sig = freePtr;
        end
    end

endmodule
