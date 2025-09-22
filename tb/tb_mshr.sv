
module tb_mshr;
    import param_pkg::*;

    parameter HALF_CLK = 1;

    // Inputs
    logic clk = 0;
    logic resetn = 1;

    // MSHR Write inputs
    logic we_i;
    logic [DCACHE_TAG_WIDTH+DCACHE_INDEX_WIDTH-1:0] adr_i;
    logic valid_i;
    transient_state_t transient_state_i;
    logic [MSHR_AW-1:0] wrPtr_i;

    // MSHR Snoop read inputs
    logic [DCACHE_TAG_WIDTH+DCACHE_INDEX_WIDTH-1:0] snoop_adr_i;
    logic snoop_req_i;

    // MSHR Read inputs
    logic [MSHR_AW-1:0] readID_i;
    
    // Outputs
    logic read_hit_o;
    logic [MSHR_AW-1:0] freePtr_o;
    logic full_o;
    logic [MSHR_AW-1:0] snoopPtr_o;
    transient_state_t transient_state_o;

    logic [1:0] wr_ptr_sel;
    logic [MSHR_AW-1:0] extID_sig;

    // Instantiate the module
    mshr dut (
        .clk(clk),
        .resetn(resetn),
        .we_i(we_i),
        .adr_i(adr_i),
        .valid_i(valid_i),
        .transient_state_i(transient_state_i),
        .wrPtr_i(wrPtr_i),
        .snoop_adr_i(snoop_adr_i),
        .snoop_req_i(snoop_req_i),
        .readID_i(readID_i),
        .read_hit_o(read_hit_o),
        .full_o(full_o),
        .transient_state_o(transient_state_o),
        .wr_ptr_sel(wr_ptr_sel)
    );

    // Clock generation
    always #HALF_CLK clk = ~clk;

    initial begin
        
        // Initializations
        clk = 0;
        resetn = 1;
        we_i = 0;
        adr_i = '0;
        transient_state_i = II;
        valid_i = 0;
        snoop_adr_i = '0;
        snoop_req_i = 0;
        readID_i = '0;
        wr_ptr_sel = 2'b00;
        extID_sig = '0;
        

        repeat (2) @(posedge clk);
        // Set some values to the MSHR
        we_i <= 1;
        transient_state_i <= MI;
        adr_i <= 32'h11111111;
        valid_i <= 1;
        repeat (1) @(posedge clk);
        transient_state_i <= IS;
        adr_i <= 32'h00000001;
        valid_i <= 1;
        repeat (1) @(posedge clk);
        we_i <= 0;
        repeat (1) @(posedge clk);
        snoop_req_i <= 1;
        snoop_adr_i <= 32'h11111111;
        repeat (1) @(posedge clk);
        snoop_req_i <= 0;
        we_i <= 1;
        wr_ptr_sel <= 2'b10;
        transient_state_i <= II;
        valid_i <= 1;
        adr_i <= 32'h11111111;
        repeat (1) @(posedge clk);
        
        readID_i <= 2'b10;
        // Set some values for all othe rinputs
        repeat (3) @(posedge clk);
        $finish;
    end
endmodule
