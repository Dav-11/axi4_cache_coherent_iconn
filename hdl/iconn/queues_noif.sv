import param_pkg::*;
//(* dont_touch = "yes" *)
module ar_queue_noif (
    input clk, 
    input resetn,
    input pop_i,
    output logic empty_o,
    output logic [AR_Q_DATA_WIDTH-1:0] data_o,

    output logic ar_ready,
    
    input [ID_WIDTH-1:0] ar_id,
    input [ADDR_WIDTH-1:0] ar_addr,
    input [7:0]  ar_len,
    input [2:0]  ar_size,
    input [1:0]  ar_burst,
    input [2:0]  ar_prot,
    input [3:0]  ar_snoop,
    input [1:0]  ar_domain,
    input ar_valid
);
    logic [AR_Q_DATA_WIDTH-1:0] data_i;
    

    circular_buffer_req #(.CBUFF_WIDTH(AR_Q_DATA_WIDTH), .CBUFF_DEPTH(AR_Q_DEPTH)) ar_buf (
        .clk(clk),
        .resetn(resetn),
        .data_i(data_i),
        .valid_i(ar_valid),
        .pop_i(pop_i),
        .ready_o(ar_ready),
        .data_o(data_o),
        .empty_o(empty_o)
    );

    /* AR REQUEST internal layout:
       +--------------------------------------------------------------------------------+
       | ar_id | ar_addr | ar_len | ar_size | ar_burst | ar_prot | ar_snoop | ar_domain | 
       +--------------------------------------------------------------------------------+
    */

    always_comb begin
        data_i = {ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_prot, ar_snoop, ar_domain};
    end

endmodule

module aw_queue_noif (
    input clk, 
    input resetn,
    input pop_i,
    output logic empty_o,
    output logic [AW_Q_DATA_WIDTH-1:0] data_o,

    output logic  aw_ready,

    input [ID_WIDTH-1:0]     aw_id,
    input [ADDR_WIDTH-1:0]   aw_addr,
    input [7:0]  aw_len,
    input [2:0]  aw_size,
    input [1:0]  aw_burst,
    input [2:0]  aw_prot,
    input [2:0]  aw_snoop,
    input [1:0]  aw_domain,
    input  aw_valid
);
    logic [AW_Q_DATA_WIDTH-1:0] data_i;

    circular_buffer_req #(.CBUFF_WIDTH(AW_Q_DATA_WIDTH), .CBUFF_DEPTH(AW_Q_DEPTH)) aw_buf (
        .clk(clk),
        .resetn(resetn),
        .data_i(data_i),
        .valid_i(aw_valid),
        .pop_i(pop_i),
        .ready_o(aw_ready),
        .data_o(data_o),
        .empty_o(empty_o)
    );

    /* AW REQUEST internal layout:
       +--------------------------------------------------------------------------------+
       | aw_id | aw_addr | aw_len | aw_size | aw_burst | aw_prot | aw_snoop | aw_domain | 
       +--------------------------------------------------------------------------------+
    */

    always_comb begin
        data_i = {aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_prot, aw_snoop, aw_domain};
    end
endmodule

module w_queue_noif (
    input clk, 
    input resetn,
    input pop_i,
    output logic empty_o,
    output logic [W_Q_DATA_WIDTH-1:0] data_o,

    output logic  w_ready,

    input  w_valid,
    input  w_last,
    input [STRB_WIDTH-1:0]  w_strb,
    input [DATA_WIDTH-1:0]  w_data
);

    circular_buffer_data #(.CBUFF_WIDTH_I(DATA_WIDTH), .CBUFF_DEPTH(W_Q_DEPTH), .CBUFF_WIDTH_O(W_Q_DATA_WIDTH)) w_buf (
        .clk(clk),
        .resetn(resetn),
        .data_i(w_data),
        .valid_i(w_valid),
        .pop_i(pop_i),
        .last_i(w_last),
        .ready_o(w_ready),
        .data_o(data_o),
        .empty_o(empty_o)
    );

endmodule

module cr_queue_noif (
    input clk, 
    input resetn,
    input pop_i,
    output logic empty_o,
    output logic [CR_Q_DATA_WIDTH-1:0] data_o,

    output logic  cr_ready,

    input  cr_valid,
    input [CRRESP_WIDTH-1:0] cr_resp
);
    circular_buffer_req #(.CBUFF_WIDTH(CR_Q_DATA_WIDTH), .CBUFF_DEPTH(CR_Q_DEPTH)) cr_buf (
        .clk(clk),
        .resetn(resetn),
        .data_i(cr_resp),
        .valid_i(cr_valid),
        .pop_i(pop_i),
        .ready_o(cr_ready),
        .data_o(data_o),
        .empty_o(empty_o)
    );
endmodule

module cd_queue_noif (
    input clk, 
    input resetn,
    input pop_i,
    output logic empty_o,
    output logic [CD_Q_DATA_WIDTH-1:0] data_o,

    output logic  cd_ready,

    input  cd_valid,
    input  cd_last,
    input [DATA_WIDTH-1:0] cd_data
);
    circular_buffer_data #(.CBUFF_WIDTH_I(DATA_WIDTH), .CBUFF_DEPTH(CD_Q_DEPTH), .CBUFF_WIDTH_O(CD_Q_DATA_WIDTH)) cd_buf (
        .clk(clk),
        .resetn(resetn),
        .data_i(cd_data),
        .valid_i(cd_valid),
        .pop_i(pop_i),
        .last_i(cd_last),
        .ready_o(cd_ready),
        .data_o(data_o),
        .empty_o(empty_o)
    );

endmodule