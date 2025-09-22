import param_pkg::*;
//(* dont_touch = "yes" *)
module rrArb_AR_noif #(
    parameter logic [N_CPU-1:0] PRIO_DEF = 1
)(
    input                           clk,
    input                           resetn,
    //input           [N_CPU-1:0] prio_i,

    // AR channels input
    output logic [N_CPU-1:0] ar_ready_i,
    
    input [N_CPU-1:0][ID_WIDTH-1:0]     ar_id_i,
    input [N_CPU-1:0][ADDR_WIDTH-1:0]   ar_addr_i,
    input [N_CPU-1:0][7:0]  ar_len_i,
    input [N_CPU-1:0][2:0]  ar_size_i,
    input [N_CPU-1:0][1:0]  ar_burst_i,
    input [N_CPU-1:0][2:0]  ar_prot_i,
    input [N_CPU-1:0][3:0]  ar_snoop_i,
    input [N_CPU-1:0][1:0]  ar_domain_i,
    input [N_CPU-1:0]ar_valid_i,

    // AR channel output
    input ar_ready_o,
    
    output logic [ID_WIDTH-1:0]     ar_id_o,
    output logic [ADDR_WIDTH-1:0]   ar_addr_o,
    output logic [7:0]  ar_len_o,
    output logic [2:0]  ar_size_o,
    output logic [1:0]  ar_burst_o,
    output logic [2:0]  ar_prot_o,
    output logic [3:0]  ar_snoop_o,
    output logic [1:0]  ar_domain_o,
    output logic ar_valid_o
    );

    logic [N_CPU-1:0] req_i;

    logic [N_CPU-1:0]      g_r, g_n;
    logic [N_CPU-1:0]      p_r, p_n;

    logic [2*N_CPU-1:0]    p_tmp;
    logic [N_CPU-1:0]      mblock_n [N_CPU-1:0];

    // gIdentifier - 
    logic [$clog2(N_CPU):0]  gIdTmp [N_CPU-1:0];
    logic [$clog2(N_CPU):0]  gId;

    logic [N_CPU-1:0]       grant_vec;

    assign grant_vec = g_r & {N_CPU{ar_ready_o}};

    generate 
        for(genvar i=0;i<N_CPU;i=i+1) begin
            assign req_i[i] = ar_valid_i[i];
            assign ar_ready_i[i] = grant_vec[i] & req_i[i];
        end
    endgenerate

    assign p_n[0] = (ar_valid_o & ar_ready_o) ? p_r[N_CPU-1] : p_r[0];
    generate
        genvar z;
        for (z=0;z<N_CPU-1;z=z+1)
            assign p_n[z+1] = (ar_valid_o & ar_ready_o) ? p_r[z] : p_r[z+1];
    endgenerate

    always_comb begin
        ar_valid_o  = '0;
        ar_addr_o   = '0;
        ar_id_o     = '0;
        ar_size_o   = '0;
        ar_burst_o  = '0;
        ar_len_o    = '0;
        ar_prot_o   = '0;
        ar_snoop_o  = '0;
        ar_domain_o = '0;
        if (gId != '0) begin
            ar_valid_o  = ar_valid_i[gId-1] & (|grant_vec);
            ar_addr_o   = ar_addr_i[gId-1];
            ar_id_o     = ar_id_i[gId-1];
            ar_size_o   = ar_size_i[gId-1];
            ar_burst_o  = ar_burst_i[gId-1];
            ar_len_o    = ar_len_i[gId-1];
            ar_prot_o   = ar_prot_i[gId-1];
            ar_snoop_o  = ar_snoop_i[gId-1];
            ar_domain_o = ar_domain_i[gId-1];
        end
    end

    /////////////////////////////////////////////////////////////////////////
    // sequential logic
    always_ff@(posedge clk)
        if(!resetn) begin
            g_r<='0;
            p_r<=PRIO_DEF;
        end	
        else begin
            g_r<=g_n;
            //if (ar_valid_o & ar_ready_o)
            p_r<=p_n;
        end

    generate
        assign gIdTmp[0] = (g_r[0]==1) ? 1:0;
        for(z=1;z<N_CPU;z=z+1)
            assign gIdTmp[z] = (g_r[z]==1) ? z+1 : gIdTmp[z-1];
    endgenerate
    assign gId=gIdTmp[N_CPU-1];

    /////////////////////////////////////////////////////////////////////////
    // grant logic
    generate
        for(genvar k=0;k<N_CPU;k=k+1)
            assign g_n[k] = (req_i[k] & ~|(req_i & mblock_n[k]));
    endgenerate
    
    // mblock - blockage matrix
    assign p_tmp={p_r,p_r};
    generate
        genvar i,j;
        for(i=0;i<N_CPU;i=i+1)
            for(j=0;j<N_CPU;j=j+1)
                if(i==j)
                    assign mblock_n[i][j]=0;
                else if(i<j)
                    assign mblock_n[i][j]= |p_tmp[i+1+:j-i] ? 1:0;
                else if(i>j)
                    assign mblock_n[i][j]= |p_tmp[i+1+:N_CPU-(i-j)] ? 1:0;
    endgenerate
    
endmodule

module rrArb_AW_W_noif #(
    parameter logic [N_CPU-1:0] PRIO_DEF = 1
)(
    input                       clk,
    input                       resetn,
    //input           [N_CPU-1:0] prio_i,

    // AW channels input
    output logic [N_CPU-1:0] aw_ready_i,

    input [N_CPU-1:0][ID_WIDTH-1:0]     aw_id_i,
    input [N_CPU-1:0][ADDR_WIDTH-1:0]   aw_addr_i,
    input [N_CPU-1:0][7:0]  aw_len_i,
    input [N_CPU-1:0][2:0]  aw_size_i,
    input [N_CPU-1:0][1:0]  aw_burst_i,
    input [N_CPU-1:0][2:0]  aw_prot_i,
    input [N_CPU-1:0][2:0]  aw_snoop_i,
    input [N_CPU-1:0][1:0]  aw_domain_i,
    input [N_CPU-1:0] aw_valid_i,

    // W channels input
    output logic [N_CPU-1:0] w_ready_i,

    input [N_CPU-1:0] w_valid_i,
    input [N_CPU-1:0] w_last_i,
    input [N_CPU-1:0][STRB_WIDTH-1:0]  w_strb_i,
    input [N_CPU-1:0][DATA_WIDTH-1:0]  w_data_i,
    
    // AW channel output
    input aw_ready_o,

    output logic [ID_WIDTH-1:0]     aw_id_o,
    output logic [ADDR_WIDTH-1:0]   aw_addr_o,
    output logic [7:0]  aw_len_o,
    output logic [2:0]  aw_size_o,
    output logic [1:0]  aw_burst_o,
    output logic [2:0]  aw_prot_o,
    output logic [2:0]  aw_snoop_o,
    output logic [1:0]  aw_domain_o,
    output logic aw_valid_o,
    // W channel output
    input w_ready_o,

    output logic w_valid_o,
    output logic w_last_o,
    output logic[STRB_WIDTH-1:0]  w_strb_o,
    output logic [DATA_WIDTH-1:0]  w_data_o
    );

    logic [N_CPU-1:0] req_i;

    logic [N_CPU-1:0]      aw_grant_r, aw_grant_next, w_grant_r, w_grant_next, aw_grant_vec;
    logic [N_CPU-1:0]      p_r, p_n;

    logic [2*N_CPU-1:0]    p_tmp;
    logic [N_CPU-1:0]      mblock_n [N_CPU-1:0];

    // gIdentifier - 
    logic [$clog2(N_CPU):0]  gIdTmp [N_CPU-1:0];
    logic [$clog2(N_CPU):0]  gId, gId_w_r, gId_w_next;

    logic recv_w;
    //(* dont_touch = "yes" *) arb_state_t arb_state_r, arb_state_next;
    arb_state_t arb_state_r, arb_state_next;

    assign aw_grant_vec = aw_grant_r & {N_CPU{aw_ready_o}};

    generate 
        for(genvar i=0;i<N_CPU;i=i+1) begin
            assign req_i[i] = aw_valid_i[i];
            assign aw_ready_i[i] = aw_grant_vec[i] & req_i[i];
            assign w_ready_i[i] = w_grant_r[i];
        end
    endgenerate

    assign p_n[0] = (aw_valid_o & aw_ready_o) ? p_r[N_CPU-1] : p_r[0];
    generate
        genvar z;
        for (z=0;z<N_CPU-1;z=z+1)
            assign p_n[z+1] = (aw_valid_o & aw_ready_o) ? p_r[z] : p_r[z+1];
    endgenerate

    always_ff @(posedge clk) begin
        if(!resetn) begin
            arb_state_r <= HANDLE_AW_ARB;
            gId_w_r <= gId;
            w_grant_r <= '0;
        end
        else begin
            arb_state_r <= arb_state_next;
            gId_w_r <= gId_w_next;
            w_grant_r <= w_grant_next;
        end
    end

    always_comb begin
        arb_state_next = arb_state_r;
        gId_w_next = gId_w_r;
        w_grant_next = w_grant_r;
        recv_w = 1'b0;
        case (arb_state_r)
            HANDLE_AW_ARB: begin
                if(|aw_grant_vec) begin
                    if(aw_snoop_i[gId-1] == 3'b011) begin // WriteBack request
                        gId_w_next = gId;
                        recv_w = 1'b1;
                        w_grant_next[gId-1] = 1'b1;
                        arb_state_next = HANDLE_W_ARB;
                    end
                end
            end
            HANDLE_W_ARB: begin
                recv_w = 1'b1;
                if(w_last_i[gId_w_r-1] == 1'b1) begin
                    w_grant_next[gId_w_r-1] = 1'b0;
                    recv_w = 1'b0;
                    arb_state_next = HANDLE_AW_ARB;
                end
            end
        endcase
    end

    always_comb begin
        aw_valid_o  = '0;
        aw_addr_o   = '0;
        aw_id_o     = '0;
        aw_size_o   = '0;
        aw_burst_o  = '0;
        aw_len_o    = '0;
        aw_prot_o   = '0;
        aw_snoop_o  = '0;
        aw_domain_o = '0;
        if (gId != '0) begin
            aw_valid_o  = aw_valid_i[gId-1] & (|aw_grant_vec);
            aw_addr_o   = aw_addr_i[gId-1];
            aw_id_o     = aw_id_i[gId-1];
            aw_size_o   = aw_size_i[gId-1];
            aw_burst_o  = aw_burst_i[gId-1];
            aw_len_o    = aw_len_i[gId-1];
            aw_prot_o   = aw_prot_i[gId-1];
            aw_snoop_o  = aw_snoop_i[gId-1];
            aw_domain_o = aw_domain_i[gId-1];
        end
    end

    always_comb begin
        w_valid_o   = '0;
        w_strb_o    = '0;
        w_data_o    = '0;
        w_last_o    = '0;
        if (gId_w_r != '0) begin
            w_valid_o   = w_valid_i[gId_w_r-1] & (|w_grant_r);
            w_strb_o    = w_strb_i[gId_w_r-1];
            w_data_o    = w_data_i[gId_w_r-1];
            w_last_o    = w_last_i[gId_w_r-1];
        end
    end

    /////////////////////////////////////////////////////////////////////////
    // sequential logic
    always_ff@(posedge clk)
        if(!resetn) begin
            aw_grant_r<='0;
            p_r<=PRIO_DEF;
        end
        else begin
            aw_grant_r<=aw_grant_next;
            //if (aw_valid_o & aw_ready_o)
            p_r<=p_n;
        end

    generate
        assign gIdTmp[0] = (aw_grant_r[0]==1) ? 1:0;
        for(z=1;z<N_CPU;z=z+1)
            assign gIdTmp[z] = (aw_grant_r[z]==1) ? z+1 : gIdTmp[z-1];
    endgenerate
    assign gId=gIdTmp[N_CPU-1];

    /////////////////////////////////////////////////////////////////////////
    // grant logic
    generate
        for(genvar k=0;k<N_CPU;k=k+1)
            assign aw_grant_next[k] = (req_i[k] & ~|(req_i & mblock_n[k])) & ~recv_w;
    endgenerate

    // mblock - blockage matrix
    assign p_tmp={p_r,p_r};
    generate
        genvar i,j;
        for(i=0;i<N_CPU;i=i+1)
            for(j=0;j<N_CPU;j=j+1)
                if(i==j)
                    assign mblock_n[i][j]=0;
                else if(i<j)
                    assign mblock_n[i][j]= |p_tmp[i+1+:j-i] ? 1:0;
                else if(i>j)
                    assign mblock_n[i][j]= |p_tmp[i+1+:N_CPU-(i-j)] ? 1:0;
    endgenerate
    
endmodule


module rrArb_CR_CD_noif #(
    parameter logic [N_CPU-1:0] PRIO_DEF = 1
)(
    input                       clk,
    input                       resetn,
    //input           [N_CPU-1:0] prio_i,

    // CR channels input
    output logic [N_CPU-1:0] cr_ready_i,

    input [N_CPU-1:0] cr_valid_i,
    input [N_CPU-1:0][CRRESP_WIDTH-1:0] cr_resp_i,

    // CD channels input
    output logic [N_CPU-1:0] cd_ready_i,

    input [N_CPU-1:0] cd_valid_i,
    input [N_CPU-1:0] cd_last_i,
    input [N_CPU-1:0][DATA_WIDTH-1:0] cd_data_i,

    // CR channel output
    input cr_ready_o,

    output logic cr_valid_o,
    output logic [CRRESP_WIDTH-1:0] cr_resp_o,
    // CD channel output
    input cd_ready_o,

    output logic cd_valid_o,
    output logic cd_last_o,
    output logic [DATA_WIDTH-1:0] cd_data_o
    );

    
    logic [N_CPU-1:0] req_i;

    logic [N_CPU-1:0]      cr_grant_r, cr_grant_next, cd_grant_r, cd_grant_next, cr_grant_vec;
    logic [N_CPU-1:0]      p_r, p_n;

    logic [2*N_CPU-1:0]    p_tmp;
    logic [N_CPU-1:0]      mblock_n [N_CPU-1:0];

    // gIdentifier - 
    logic [$clog2(N_CPU):0]  gIdTmp [N_CPU-1:0];
    logic [$clog2(N_CPU):0]  gId, gId_cd_r, gId_cd_next;

    logic recv_cd;
    //(* dont_touch = "yes" *) arb_snoop_state_t arb_state_r, arb_state_next;
    arb_snoop_state_t arb_state_r, arb_state_next;

    assign cr_grant_vec = cr_grant_r & {N_CPU{cr_ready_o}};

    generate 
        for(genvar i=0;i<N_CPU;i=i+1) begin
            assign req_i[i] = cr_valid_i[i];
            assign cr_ready_i[i] = cr_grant_vec[i] & req_i[i];

            assign cd_ready_i[i] = cd_grant_r[i];
        end
    endgenerate

    assign p_n[0] = (cr_valid_o & cr_ready_o) ? p_r[N_CPU-1] : p_r[0];
    generate
        genvar z;
        for (z=0;z<N_CPU-1;z=z+1)
            assign p_n[z+1] = (cr_valid_o & cr_ready_o) ? p_r[z] : p_r[z+1];
    endgenerate

    always_ff @(posedge clk) begin
        if(!resetn) begin
            arb_state_r <= HANDLE_CR_ARB;
            gId_cd_r <= gId;
            cd_grant_r <= '0;
        end
        else begin
            arb_state_r <= arb_state_next;
            gId_cd_r <= gId_cd_next;
            cd_grant_r <= cd_grant_next;
        end
    end

    always_comb begin
        arb_state_next = arb_state_r;
        gId_cd_next = gId_cd_r;
        cd_grant_next = cd_grant_r;
        recv_cd = 1'b0;
        case (arb_state_r)
            HANDLE_CR_ARB: begin
                if(|cr_grant_vec) begin
                    if(cr_resp_i[gId-1][0] == 1'b1) begin // yes data transfer
                        gId_cd_next = gId;
                        recv_cd = 1'b1;
                        cd_grant_next[gId-1] = 1'b1;
                        arb_state_next = HANDLE_CD_ARB;
                    end
                end
            end
            HANDLE_CD_ARB: begin
                recv_cd = 1'b1;
                if(cd_last_i[gId_cd_r-1] == 1'b1) begin
                    cd_grant_next[gId_cd_r-1] = 1'b0;
                    recv_cd = 1'b0;
                    arb_state_next = HANDLE_CR_ARB;
                end
            end
        endcase
    end

    always_comb begin
        cr_valid_o  = '0;
        cr_resp_o   = '0;
        if (gId != '0) begin
            cr_valid_o = cr_valid_i[gId-1] & (|cr_grant_vec);
            cr_resp_o = cr_resp_i[gId-1];
        end
    end

    always_comb begin
        cd_valid_o  = '0;
        cd_data_o   = '0;
        cd_last_o   = '0;
        if (gId_cd_r != '0) begin
            cd_valid_o  = cd_valid_i[gId_cd_r-1] & (|cd_grant_r);
            cd_data_o   = cd_data_i[gId_cd_r-1];
            cd_last_o   = cd_last_i[gId_cd_r-1];
        end
    end

    /////////////////////////////////////////////////////////////////////////
    // sequential logic
    always_ff@(posedge clk)
        if(!resetn) begin
            cr_grant_r<='0;
            p_r<=PRIO_DEF;
        end
        else begin
            cr_grant_r <= cr_grant_next;
            //if (cr_valid_o & cr_ready_o)
            p_r<=p_n;
        end

    generate
        assign gIdTmp[0] = (cr_grant_r[0]==1) ? 1:0;
        for(z=1;z<N_CPU;z=z+1)
            assign gIdTmp[z] = (cr_grant_r[z]==1) ? z+1 : gIdTmp[z-1];
    endgenerate
    assign gId=gIdTmp[N_CPU-1];

    /////////////////////////////////////////////////////////////////////////
    // grant logic
    generate
        for(genvar k=0;k<N_CPU;k=k+1)
            assign cr_grant_next[k] = (req_i[k] & ~|(req_i & mblock_n[k])) & ~recv_cd;
    endgenerate
    
    // mblock - blockage matrix
    assign p_tmp={p_r,p_r};
    generate
        genvar i,j;
        for(i=0;i<N_CPU;i=i+1)
            for(j=0;j<N_CPU;j=j+1)
                if(i==j)
                    assign mblock_n[i][j]=0;
                else if(i<j)
                    assign mblock_n[i][j]= |p_tmp[i+1+:j-i] ? 1:0;
                else if(i>j)
                    assign mblock_n[i][j]= |p_tmp[i+1+:N_CPU-(i-j)] ? 1:0;
    endgenerate
    
endmodule