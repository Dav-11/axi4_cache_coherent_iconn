//(* dont_touch = "yes" *)
module circular_buffer_req #(
    parameter CBUFF_WIDTH = 32,
    parameter CBUFF_DEPTH = 4
)(
    input clk,
    input resetn,
    input [CBUFF_WIDTH-1:0] data_i,
    input valid_i,
    input pop_i,
    output [CBUFF_WIDTH-1:0] data_o,
    output ready_o,
    output empty_o
);
    import param_pkg::*;

    //If CBUFF_DEPTH is not a power of 2, raise an error
    if (CBUFF_DEPTH & (CBUFF_DEPTH - 1) != 0) begin
        $error("CBUFF_DEPTH must be a power of 2");
    end
    
    logic [$clog2(CBUFF_DEPTH)-1:0] head_ptr_r, head_ptr_next, tail_ptr_r, tail_ptr_next, windex, rindex;
    logic rcyc, wcyc;
    
    logic full_next, empty_next, full_r, empty_r;
    logic we;
        
    assign ready_o = ~full_r;
    assign empty_o = empty_r;
    assign we = valid_i & ~full_r;
    
    
    dp_ram_fwd #(.DPRAM_AW($clog2(CBUFF_DEPTH)), .DPRAM_DW(CBUFF_WIDTH)) 
        buf_mem0 (

        .clk        (clk),

        // Always read on port A
        .cyc_a_i    (rcyc),
        .we_a_i     (1'b0),
        .adr_a_i    (rindex),
        .dat_a_i    ('0),

        // Always write on port B
        .cyc_b_i    (wcyc),
        .we_b_i     (1'b1),
        .adr_b_i    (windex),
        .dat_b_i    (data_i),

        .dat_a_o    (data_o),
        .dat_b_o    ()

    );

    always_ff @(posedge clk) begin
        if (!resetn) begin
            head_ptr_r <= 0;
            tail_ptr_r <= 0;
            full_r <= 1'b0;
            empty_r <= 1'b1;
        end else begin
            head_ptr_r <= head_ptr_next;
            tail_ptr_r <= tail_ptr_next;
            full_r <= full_next;
            empty_r <= empty_next;
        end
    end

    always_comb begin
        head_ptr_next = head_ptr_r;
        tail_ptr_next = tail_ptr_r;
        full_next = full_r;
        empty_next = empty_r;
        wcyc = 1'b0;
        windex = '0;
        rcyc = 1'b1;
        rindex = tail_ptr_r;
        if(we & pop_i) begin
            wcyc = 1'b1;
            windex = head_ptr_r;
            head_ptr_next = head_ptr_r + 1;
            tail_ptr_next = tail_ptr_r + 1;
            /*rcyc = 1'b1;
            rindex = tail_ptr_next;*/
        end
        else if(we) begin
            wcyc = 1'b1;
            windex = head_ptr_r;
            head_ptr_next = head_ptr_r + 1;
            empty_next = 1'b0;
            full_next = (head_ptr_next == tail_ptr_r) ? 1'b1 : 1'b0;
        end
        else if(pop_i) begin
            tail_ptr_next = tail_ptr_r + 1;
            /*rcyc = 1'b1;
            rindex = tail_ptr_next;*/
            full_next = 1'b0;
            empty_next = (tail_ptr_next == head_ptr_r) ? 1'b1 : 1'b0;
        end
    end

endmodule

module circular_buffer_data #(
    parameter CBUFF_WIDTH_I = 32,
    parameter CBUFF_WIDTH_O = 128,
    parameter CBUFF_DEPTH = 4
)(
    input clk,
    input resetn,
    input [CBUFF_WIDTH_I-1:0] data_i,
    input valid_i,
    input last_i,
    input pop_i,
    output [CBUFF_WIDTH_O-1:0] data_o,
    output ready_o,
    output empty_o
);
    import param_pkg::*;

    if (CBUFF_WIDTH_O <= CBUFF_WIDTH_I) begin
        $error("CBUFF_WIDTH_O must be greater than CBUFF_WIDTH_I");
    end
    if (CBUFF_WIDTH_O % CBUFF_WIDTH_I != 0) begin
        $error("CBUFF_WIDTH_O must be a multiple of CBUFF_WIDTH_I");
    end
    //If CBUFF_DEPTH is not a power of 2, raise an error
    if (CBUFF_DEPTH & (CBUFF_DEPTH - 1) != 0) begin
        $error("CBUFF_DEPTH must be a power of 2");
    end
    
    logic [$clog2(CBUFF_DEPTH)-1:0] head_ptr_r, head_ptr_next, tail_ptr_r, tail_ptr_next, windex, rindex;
    logic rcyc, wcyc;

    logic [(CBUFF_WIDTH_O-CBUFF_WIDTH_I)-1:0] buffer_r, buffer_next;
    logic [$clog2(CBUFF_WIDTH_O/CBUFF_WIDTH_I)-1:0] burst_ptr_r, burst_ptr_next;
    
    logic full_next, empty_next, full_r, empty_r;
    logic we;

    logic [CBUFF_WIDTH_O-1:0] data_sig;
        
    assign ready_o = ~full_r;
    assign empty_o = empty_r;
    assign we = valid_i & ~full_r;
    
    assign data_sig = {data_i, buffer_r};
    
    dp_ram_fwd #(.DPRAM_AW($clog2(CBUFF_DEPTH)), .DPRAM_DW(CBUFF_WIDTH_O)) 
        buf_mem0 (

        .clk        (clk),

        // Always read on port A
        .cyc_a_i    (rcyc),
        .we_a_i     (1'b0),
        .adr_a_i    (rindex),
        .dat_a_i    ('0),

        // Always write on port B
        .cyc_b_i    (wcyc),
        .we_b_i     (1'b1),
        .adr_b_i    (windex),
        .dat_b_i    (data_sig),

        .dat_a_o    (data_o),
        .dat_b_o    ()

    );

    always_ff @(posedge clk) begin
        if (!resetn) begin
            head_ptr_r <= 0;
            tail_ptr_r <= 0;
            full_r <= 1'b0;
            empty_r <= 1'b1;
            burst_ptr_r <= 0;
            buffer_r <= '0;
        end else begin
            head_ptr_r <= head_ptr_next;
            tail_ptr_r <= tail_ptr_next;
            burst_ptr_r <= burst_ptr_next;
            full_r <= full_next;
            empty_r <= empty_next;
            buffer_r <= buffer_next;
        end
    end

    always_comb begin
        head_ptr_next = head_ptr_r;
        tail_ptr_next = tail_ptr_r;
        burst_ptr_next = burst_ptr_r;
        full_next = full_r;
        empty_next = empty_r;
        buffer_next = buffer_r;
        wcyc = 1'b0;
        windex = '0;
        rcyc = 1'b1;
        rindex = tail_ptr_r;
        if(we & pop_i) begin
            tail_ptr_next = tail_ptr_r + 1;
            if (last_i) begin
                wcyc = 1'b1;
                windex = head_ptr_r;
                head_ptr_next = head_ptr_r + 1;
                burst_ptr_next = '0;
            end
            else begin
                buffer_next[burst_ptr_r*CBUFF_WIDTH_I +: CBUFF_WIDTH_I] = data_i;
                burst_ptr_next = burst_ptr_r + 1;
                empty_next = (tail_ptr_next == head_ptr_r) ? 1'b1 : 1'b0;
            end            
        end
        else if(we) begin
            if (last_i) begin
                wcyc = 1'b1;
                windex = head_ptr_r;
                head_ptr_next = head_ptr_r + 1;
                empty_next = 1'b0;
                full_next = (head_ptr_next == tail_ptr_r) ? 1'b1 : 1'b0;
                burst_ptr_next = '0;
            end
            else begin
                buffer_next[burst_ptr_r*CBUFF_WIDTH_I +: CBUFF_WIDTH_I] = data_i;
                burst_ptr_next = burst_ptr_r + 1;
            end
        end
        else if(pop_i) begin
            tail_ptr_next = tail_ptr_r + 1;
            full_next = 1'b0;
            empty_next = (tail_ptr_next == head_ptr_r) ? 1'b1 : 1'b0;
        end
    end
endmodule