// True dual port synchronous ram

module dp_ram_fwd #(
    parameter DPRAM_AW = 32,
    parameter DPRAM_DW = 32
)(clk,
    cyc_a_i, we_a_i, adr_a_i, dat_a_i,
    cyc_b_i, we_b_i, adr_b_i, dat_b_i,

    dat_a_o, dat_b_o
);

    input                  clk;
    
    input                  cyc_a_i;
    input                  we_a_i;
    input [DPRAM_AW-1:0]   adr_a_i;
    input [DPRAM_DW-1:0]   dat_a_i;
    
    input                  cyc_b_i;
    input                  we_b_i;
    input [DPRAM_AW-1:0]   adr_b_i;
    input [DPRAM_DW-1:0]   dat_b_i;
    
    output [DPRAM_DW-1:0]  dat_a_o;
    output [DPRAM_DW-1:0]  dat_b_o;


    logic [DPRAM_DW-1:0]  mem [(2**DPRAM_AW)-1:0];
    logic [DPRAM_DW-1:0]  dat_a_r, dat_b_r;


    always_ff @(posedge clk) begin
        if(cyc_a_i && we_a_i) mem[adr_a_i] <= dat_a_i;
        if(cyc_a_i && !we_a_i) begin
            if (cyc_b_i && we_b_i && (adr_a_i == adr_b_i))
                dat_a_r <= dat_b_i;
            else
                dat_a_r <= mem[adr_a_i];
        end
    end
    
    always_ff @(posedge clk) begin
        if(cyc_b_i && we_b_i)  mem[adr_b_i] <= dat_b_i;
        if(cyc_b_i && !we_b_i) begin
            if (cyc_a_i && we_a_i && (adr_a_i == adr_b_i))
                dat_b_r <= dat_a_i;
            else
                dat_b_r <= mem[adr_b_i];
        end
        
    end

    assign dat_a_o = dat_a_r;
    assign dat_b_o = dat_b_r;
    
    initial begin
        for(integer i = 0; i < 2**DPRAM_AW; i = i+1)
            mem[i] = '0;
    end

endmodule
