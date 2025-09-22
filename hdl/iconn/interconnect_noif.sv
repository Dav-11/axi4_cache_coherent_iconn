import param_pkg::*;

module iconn_noif (
    input clk,
    input resetn,

    input [N_CPU-1:0] wack_vect_i,
    input [N_CPU-1:0] rack_vect_i,

    input [N_CPU-1:0] ac_ready,

    output logic [N_CPU-1:0] [ADDR_WIDTH-1:0]   ac_addr,
    output logic [N_CPU-1:0] [2:0]  ac_prot,
    output logic [N_CPU-1:0] [3:0]  ac_snoop,
    output logic [N_CPU-1:0] ac_valid,
//=============== CR CHANNEL ==============
    output logic [N_CPU-1:0] cr_ready,

    input [N_CPU-1:0]cr_valid,
    input [N_CPU-1:0][CRRESP_WIDTH-1:0]  cr_resp,
//=============== CD CHANNEL ==============
    output logic [N_CPU-1:0] cd_ready,

    input [N_CPU-1:0]cd_valid,
    input [N_CPU-1:0]cd_last,
    input [N_CPU-1:0][DATA_WIDTH-1:0]  cd_data,

    //=============== AR CHANNEL ===============
    output logic [N_CPU-1:0] ar_ready,
    
    input [N_CPU-1:0][ID_WIDTH-1:0]     ar_id,
    input [N_CPU-1:0][ADDR_WIDTH-1:0]   ar_addr,
    input [N_CPU-1:0][7:0]  ar_len,
    input [N_CPU-1:0][2:0]  ar_size,
    input [N_CPU-1:0][1:0]  ar_burst,
    input [N_CPU-1:0][2:0]  ar_prot,
    input [N_CPU-1:0][3:0]  ar_snoop,
    input [N_CPU-1:0][1:0]  ar_domain,
    input [N_CPU-1:0]ar_valid,
//=============== R CHANNEL ===============
    output logic [N_CPU-1:0] r_valid,
    output logic [N_CPU-1:0] r_last,
    output logic [N_CPU-1:0][RESP_WIDTH-1:0]  r_resp,
    output logic [N_CPU-1:0][ID_WIDTH-1:0]    r_id,
    output logic [N_CPU-1:0][DATA_WIDTH-1:0]  r_data,
    
    input [N_CPU-1:0] r_ready,

//=============== AW CHANNEL ===============
    output logic [N_CPU-1:0] aw_ready,

    input [N_CPU-1:0][ID_WIDTH-1:0]     aw_id,
    input [N_CPU-1:0][ADDR_WIDTH-1:0]   aw_addr,
    input [N_CPU-1:0][7:0]  aw_len,
    input [N_CPU-1:0][2:0]  aw_size,
    input [N_CPU-1:0][1:0]  aw_burst,
    input [N_CPU-1:0][2:0]  aw_prot,
    input [N_CPU-1:0][2:0]  aw_snoop,
    input [N_CPU-1:0][1:0]  aw_domain,
    input [N_CPU-1:0] aw_valid,
//=============== W CHANNEL ===============
    output logic [N_CPU-1:0] w_ready,

    input [N_CPU-1:0] w_valid,
    input [N_CPU-1:0] w_last,
    input [N_CPU-1:0][STRB_WIDTH-1:0]  w_strb,
    input [N_CPU-1:0][DATA_WIDTH-1:0]  w_data,
//=============== B CHANNEL ===============
    output logic [N_CPU-1:0] b_valid,
    output logic [N_CPU-1:0][ID_WIDTH-1:0]    b_id,

    input [N_CPU-1:0]b_ready
);
    // AR channel output
    logic ar_ready_o;
    
    logic [ID_WIDTH-1:0]     ar_id_o;
    logic [ADDR_WIDTH-1:0]   ar_addr_o;
    logic [7:0]  ar_len_o;
    logic [2:0]  ar_size_o;
    logic [1:0]  ar_burst_o;
    logic [2:0]  ar_prot_o;
    logic [3:0]  ar_snoop_o;
    logic [1:0]  ar_domain_o;
    logic ar_valid_o;
    // AW channel output
    logic aw_ready_o;

    logic [ID_WIDTH-1:0]     aw_id_o;
    logic [ADDR_WIDTH-1:0]   aw_addr_o;
    logic [7:0]  aw_len_o;
    logic [2:0]  aw_size_o;
    logic [1:0]  aw_burst_o;
    logic [2:0]  aw_prot_o;
    logic [2:0]  aw_snoop_o;
    logic [1:0]  aw_domain_o;
    logic aw_valid_o;
    // W channel output
    logic w_ready_o;

    logic w_valid_o;
    logic w_last_o;
    logic [STRB_WIDTH-1:0]  w_strb_o;
    logic [DATA_WIDTH-1:0]  w_data_o;

    // CR channel output
    logic cr_ready_o;

    logic cr_valid_o;
    logic [CRRESP_WIDTH-1:0] cr_resp_o;
    // CD channel output
    logic cd_ready_o;

    logic cd_valid_o;
    logic cd_last_o;
    logic [DATA_WIDTH-1:0] cd_data_o;

    //logic [N_CPU-1:0] prio_default = 1;
    
    logic aw_empty;
    logic w_empty;
    logic [AW_Q_DATA_WIDTH-1:0] aw_request;
    logic [W_Q_DATA_WIDTH-1:0] w_data_q;
    logic ack_m2i;
    logic ack_d2i;
    logic [N_CPU-1:0] sharers_d2i;
    logic aw_pop;
    logic w_pop;
    logic valid_i2m;
    logic [MAIN_MEM_LINE_AW-1:0] addr_i2m;
    logic [(BYTES_PER_LINE*8)-1:0] data_i2m;

    logic valid_i2d;
    logic [DCACHE_TAG_WIDTH-1:0] tag_i2d;
    logic [DCACHE_INDEX_WIDTH-1:0] index_i2d;
    op_dir_t operation_i2d;
    logic [CPU_ID_WIDTH-1:0] cpu_id_i2d;


    logic ar_empty;
    logic cr_empty;
    logic cd_empty;
    logic [AR_Q_DATA_WIDTH-1:0] ar_request;
    logic [CR_Q_DATA_WIDTH-1:0] cr_response;
    logic [CD_Q_DATA_WIDTH-1:0] cd_data_q;

    logic ack_d2l;
    logic [N_CPU-1:0] sharers_d2l;

    logic ack_m2l;
    logic [(BYTES_PER_LINE*8)-1:0] data_m2l;

    logic ar_pop;
    logic cr_pop;
    logic cd_pop;

    logic valid_l2d;
    op_dir_t operation_l2d;
    logic [DCACHE_TAG_WIDTH-1:0] tag_l2d;
    logic [DCACHE_INDEX_WIDTH-1:0] index_l2d;
    logic [CPU_ID_WIDTH-1:0] cpu_id_l2d;

    logic [MAIN_MEM_LINE_AW-1:0] raddr_l2m;
    logic rcyc_l2m;
    logic [MAIN_MEM_LINE_AW-1:0] waddr_l2m;
    logic wcyc_l2m;
    logic [(BYTES_PER_LINE*8)-1:0] wdata_l2m;

    logic [DCACHE_INDEX_WIDTH-1:0]  index_arb2dir;
    logic [DCACHE_TAG_WIDTH-1:0]    tag_arb2dir;
    op_dir_t                        op_arb2dir;
    logic [CPU_ID_WIDTH-1:0]        cpu_id_arb2dir;
    logic                           req_arb2dir;
    logic [N_CPU-1:0]               sharers_dir2arb;
    logic                           ack_dir2arb;

    logic [(BYTES_PER_LINE*8)-1:0] wdata_arb2mem;
    logic [MAIN_MEM_LINE_AW-1:0] waddr_arb2mem;
    logic [MAIN_MEM_LINE_AW-1:0] raddr_arb2mem;
    logic rcyc_arb2mem;
    logic wcyc_arb2mem;
    logic ack_mem2arb;
    
    logic [MAIN_MEM_DW-1:0] rdata;
    logic [MAIN_MEM_AW-1:0] raddr;
    logic [MAIN_MEM_AW-1:0] waddr;
    logic [MAIN_MEM_DW-1:0] wdata;
    logic wcyc;
    logic rcyc;

    logic wack_sig, rack_sig;

    assign wack_sig = |wack_vect_i;
    assign rack_sig = |rack_vect_i;

    rrArb_AR_noif rrArb_AR_inst (
        .clk(clk),
        .resetn(resetn),
        //.prio_i(prio_default),

        .ar_ready_i(ar_ready),
        .ar_id_i(ar_id),
        .ar_addr_i(ar_addr),
        .ar_len_i(ar_len),
        .ar_size_i(ar_size),
        .ar_burst_i(ar_burst),
        .ar_prot_i(ar_prot),
        .ar_snoop_i(ar_snoop),
        .ar_domain_i(ar_domain),
        .ar_valid_i(ar_valid),

        .ar_ready_o(ar_ready_o),
        .ar_id_o(ar_id_o),
        .ar_addr_o(ar_addr_o),
        .ar_len_o(ar_len_o),
        .ar_size_o(ar_size_o),
        .ar_burst_o(ar_burst_o),
        .ar_prot_o(ar_prot_o),
        .ar_snoop_o(ar_snoop_o),
        .ar_domain_o(ar_domain_o),
        .ar_valid_o(ar_valid_o)
    );

    rrArb_AW_W_noif rrArb_AW_W_inst (
        .clk(clk),
        .resetn(resetn),
        //.prio_i(prio_default),

        .aw_ready_i(aw_ready),
        .aw_id_i(aw_id),
        .aw_addr_i(aw_addr),
        .aw_len_i(aw_len),
        .aw_size_i(aw_size),
        .aw_burst_i(aw_burst),
        .aw_prot_i(aw_prot),
        .aw_snoop_i(aw_snoop),
        .aw_domain_i(aw_domain),
        .aw_valid_i(aw_valid),

        .w_ready_i(w_ready),
        .w_valid_i(w_valid),
        .w_last_i(w_last),
        .w_strb_i(w_strb),
        .w_data_i(w_data),

        .aw_ready_o(aw_ready_o),
        .aw_id_o(aw_id_o),
        .aw_addr_o(aw_addr_o),
        .aw_len_o(aw_len_o),
        .aw_size_o(aw_size_o),
        .aw_burst_o(aw_burst_o),
        .aw_prot_o(aw_prot_o),
        .aw_snoop_o(aw_snoop_o),
        .aw_domain_o(aw_domain_o),
        .aw_valid_o(aw_valid_o),

        .w_ready_o(w_ready_o),
        .w_valid_o(w_valid_o),
        .w_last_o(w_last_o),
        .w_strb_o(w_strb_o),
        .w_data_o(w_data_o)
    );

    rrArb_CR_CD_noif rrArb_CR_CD_inst (
        .clk(clk),
        .resetn(resetn),
        //.prio_i(prio_default),

        .cr_ready_i(cr_ready),
        .cr_valid_i(cr_valid),
        .cr_resp_i(cr_resp),

        .cd_ready_i(cd_ready),
        .cd_valid_i(cd_valid),
        .cd_last_i(cd_last),
        .cd_data_i(cd_data),

        .cr_ready_o(cr_ready_o),
        .cr_valid_o(cr_valid_o),
        .cr_resp_o(cr_resp_o),

        .cd_ready_o(cd_ready_o),
        .cd_valid_o(cd_valid_o),
        .cd_last_o(cd_last_o),
        .cd_data_o(cd_data_o)
    );

    ar_queue_noif ar_queue_inst (
        .clk(clk),
        .resetn(resetn),
        .pop_i(ar_pop),
        .empty_o(ar_empty),
        .data_o(ar_request),

        .ar_ready(ar_ready_o),
        .ar_id(ar_id_o),
        .ar_addr(ar_addr_o),
        .ar_len(ar_len_o),
        .ar_size(ar_size_o),
        .ar_burst(ar_burst_o),
        .ar_prot(ar_prot_o),
        .ar_snoop(ar_snoop_o),
        .ar_domain(ar_domain_o),
        .ar_valid(ar_valid_o)
    );

    aw_queue_noif aw_queue_inst (
        .clk(clk),
        .resetn(resetn),
        .pop_i(aw_pop),
        .empty_o(aw_empty),
        .data_o(aw_request),

        .aw_ready(aw_ready_o),
        .aw_id(aw_id_o),
        .aw_addr(aw_addr_o),
        .aw_len(aw_len_o),
        .aw_size(aw_size_o),
        .aw_burst(aw_burst_o),
        .aw_prot(aw_prot_o),
        .aw_snoop(aw_snoop_o),
        .aw_domain(aw_domain_o),
        .aw_valid(aw_valid_o)
    );

    w_queue_noif w_queue_inst (
        .clk(clk),
        .resetn(resetn),
        .pop_i(w_pop),
        .empty_o(w_empty),
        .data_o(w_data_q),
        
        .w_ready(w_ready_o),
        .w_valid(w_valid_o),
        .w_last(w_last_o),
        .w_strb(w_strb_o),
        .w_data(w_data_o)
    );

    cr_queue_noif cr_queue_inst (
        .clk(clk),
        .resetn(resetn),
        .pop_i(cr_pop),
        .empty_o(cr_empty),
        .data_o(cr_response),

        .cr_ready(cr_ready_o),
        .cr_valid(cr_valid_o),
        .cr_resp(cr_resp_o)
    );

    cd_queue_noif cd_queue_inst (
        .clk(clk),
        .resetn(resetn),
        .pop_i(cd_pop),
        .empty_o(cd_empty),
        .data_o(cd_data_q),

        .cd_ready(cd_ready_o),
        .cd_valid(cd_valid_o),
        .cd_data(cd_data_o),
        .cd_last(cd_last_o)
    );

    fsm_i_noif fsm_i_inst (
        .clk(clk),
        .resetn(resetn),
        
        .b_valid(b_valid),
        .b_id(b_id),
        .b_ready(b_ready),

        .wack(wack_sig),

        .aw_empty_i(aw_empty),
        .aw_request_i(aw_request),
        .aw_pop_o(aw_pop),
        
        .w_empty_i(w_empty),
        .w_data_i(w_data_q),
        .w_pop_o(w_pop),
        
        .valid_i2m(valid_i2m),
        .addr_i2m(addr_i2m),
        .data_i2m(data_i2m),
        .ack_m2i(ack_m2i),

        .valid_i2d(valid_i2d),
        .tag_i2d(tag_i2d),
        .index_i2d(index_i2d),
        .operation_i2d(operation_i2d),
        .cpu_id_i2d(cpu_id_i2d),
        .ack_d2i(ack_d2i)
    );

    fsm_l_noif fsm_l_inst (
        .clk(clk),
        .resetn(resetn),

        .ac_ready(ac_ready),
        .ac_addr(ac_addr),
        .ac_prot(ac_prot),
        .ac_snoop(ac_snoop),
        .ac_valid(ac_valid),

        .r_ready(r_ready),
        .r_valid(r_valid),
        .r_last(r_last),
        .r_resp(r_resp),
        .r_id(r_id),
        .r_data(r_data),

        .rack(rack_sig),
        
        .ar_empty_i(ar_empty),
        .ar_request_i(ar_request),
        .ar_pop_o(ar_pop),

        .cr_empty_i(cr_empty),
        .cr_response_i(cr_response),
        .cr_pop_o(cr_pop),

        .cd_empty_i(cd_empty),
        .cd_data_i(cd_data_q),
        .cd_pop_o(cd_pop),

        .ack_d2l(ack_d2l),
        .sharers_d2l(sharers_d2l),
        .valid_l2d(valid_l2d),
        .operation_l2d(operation_l2d),
        .tag_l2d(tag_l2d),
        .index_l2d(index_l2d),
        .cpu_id_l2d(cpu_id_l2d),

        .ack_m2l(ack_m2l),
        .data_m2l(data_m2l),
        .raddr_l2m(raddr_l2m),
        .rcyc_l2m(rcyc_l2m),
        .waddr_l2m(waddr_l2m),
        .wcyc_l2m(wcyc_l2m),
        .wdata_l2m(wdata_l2m)
    );

    fixedArb_dir_mem fixedArb_dir_mem_inst (
        .clk(clk),
        .resetn(resetn),

        .valid_f2d_i({valid_i2d, valid_l2d}),
        .op_f2d_i({operation_i2d, operation_l2d}),
        .tag_f2d_i({tag_i2d, tag_l2d}),
        .index_f2d_i({index_i2d, index_l2d}),
        .cpu_id_f2d_i({cpu_id_i2d, cpu_id_l2d}),

        .ack_d2f_i(ack_dir2arb),
        .sharers_d2f_i(sharers_dir2arb),

        .valid_f2d_o(req_arb2dir),
        .op_f2d_o(op_arb2dir),
        .tag_f2d_o(tag_arb2dir),
        .index_f2d_o(index_arb2dir),
        .cpu_id_f2d_o(cpu_id_arb2dir),

        .ack_d2f_o({ack_d2i, ack_d2l}),
        .sharers_d2f_o({sharers_d2i, sharers_d2l})
    );

    dir_mem dir_mem_inst (
        .clk(clk),
        .resetn(resetn),

        .index(index_arb2dir),
        .tag(tag_arb2dir),
        .operation(op_arb2dir),
        .cpu_id(cpu_id_arb2dir),
        .req(req_arb2dir),
        
        .sharers_o(sharers_dir2arb),
        .ack(ack_dir2arb)
    );

    fixedArb_main_mem fixedArb_main_mem_inst (
        .clk(clk),
        .resetn(resetn),

        .req_i({valid_i2m, rcyc_l2m | wcyc_l2m}),
        .wdata_i({data_i2m, wdata_l2m}),
        .waddr_i({addr_i2m, waddr_l2m}),
        .wcyc_i({valid_i2m, wcyc_l2m}),
        .raddr_i({{(MAIN_MEM_LINE_AW){1'b0}}, raddr_l2m}),
        .rcyc_i({1'b0, rcyc_l2m}),
        .ack_i(ack_mem2arb),

        .ack_o({ack_m2i, ack_m2l}),
        .wdata_o(wdata_arb2mem),
        .waddr_o(waddr_arb2mem),
        .raddr_o(raddr_arb2mem),
        .wcyc_o(wcyc_arb2mem),
        .rcyc_o(rcyc_arb2mem)
    );

    iconn_mem_ctrl_delay iconn_mem_ctrl_inst (
        .clk                 (clk),
        .resetn              (resetn),
        .waddr_arb2mem       (waddr_arb2mem),
        .wdata_arb2mem       (wdata_arb2mem),
        .wcyc_arb2mem        (wcyc_arb2mem),
        .raddr_arb2mem       (raddr_arb2mem),
        .rcyc_arb2mem        (rcyc_arb2mem),

        .data_mem2l        (data_m2l),
        .ack_mem2arb       (ack_mem2arb),

        .rdata(rdata),

        .waddr(waddr),
        .wdata(wdata),
        .wcyc(wcyc),
        .raddr(raddr),
        .rcyc(rcyc)
    );

    mem_hw main_mem_inst (
        .clk(clk),

        .rcyc(rcyc),
        .wcyc(wcyc),
        .waddr(waddr),
        .raddr(raddr),
        .wdata(wdata),
        
        .rdata(rdata)
    );

endmodule
