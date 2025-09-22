import param_pkg::*;

module fixedArb_dir_mem (
    input clk,
    input resetn,
    // from fsms to dir_mem
    input [NUM_MASTER-1:0] valid_f2d_i,
    input op_dir_t [NUM_MASTER-1:0] op_f2d_i,
    input [NUM_MASTER-1:0][DCACHE_TAG_WIDTH-1:0] tag_f2d_i,
    input [NUM_MASTER-1:0][DCACHE_INDEX_WIDTH-1:0] index_f2d_i,
    input [NUM_MASTER-1:0][CPU_ID_WIDTH-1:0] cpu_id_f2d_i,
    // from dir_mem to fsms
    input ack_d2f_i,
    input [N_CPU-1:0] sharers_d2f_i,
    // from fsms to dir_mem
    output logic valid_f2d_o,
    output op_dir_t op_f2d_o,
    output logic [DCACHE_TAG_WIDTH-1:0] tag_f2d_o,
    output logic [DCACHE_INDEX_WIDTH-1:0] index_f2d_o,
    output logic [CPU_ID_WIDTH-1:0] cpu_id_f2d_o,
    // from dir_mem to fsms
    output logic [NUM_MASTER-1:0] ack_d2f_o,
    output logic [NUM_MASTER-1:0][N_CPU-1:0] sharers_d2f_o
);
    localparam NUM_MASTER = 2; // Do not change

    parameter logic [NUM_MASTER-1:0] prio = 2'b01; // Master 0 (fsm_i) has highest priority

    logic [NUM_MASTER-1:0]      g_r, g_n;

    logic [2*NUM_MASTER-1:0]    p_tmp;
    logic [NUM_MASTER-1:0]      mblock_n [NUM_MASTER-1:0];

    // gIdentifier - 
    logic [$clog2(NUM_MASTER):0]  gIdTmp [NUM_MASTER-1:0];
    logic [$clog2(NUM_MASTER):0]  gId;

    logic outstanding_r, outstanding_next;

    /////////////////////////////////////////////////////////////////////////
    // sequential logic
    always_ff@(posedge clk) begin
        if(!resetn) begin
            g_r<='0;
            outstanding_r<='0;
        end
        else
        begin
            g_r<=g_n;
            outstanding_r<=outstanding_next;
        end
    end

    assign outstanding_next = ~ack_d2f_i & |g_n;

    generate
        assign gIdTmp[0] = (g_r[0]==1) ? 1:0;
        genvar z;
        for(z=1;z<NUM_MASTER;z=z+1)
            assign gIdTmp[z] = (g_r[z]==1) ? z+1 : gIdTmp[z-1];
    endgenerate
    assign gId=gIdTmp[NUM_MASTER-1];

    /////////////////////////////////////////////////////////////////////////
    // grant logic
    generate
        genvar k;
        for(k=0;k<NUM_MASTER;k=k+1)
            assign g_n[k] = (outstanding_r == 1'b1) ? g_r[k] : valid_f2d_i[k] & ~|(valid_f2d_i & mblock_n[k]);
    endgenerate

    // mblock - blockage matrix
    assign p_tmp={prio, prio};
    generate
    genvar i,j;
        for(i=0;i<NUM_MASTER;i=i+1)
            for(j=0;j<NUM_MASTER;j=j+1)
                if(i==j)
                    assign mblock_n[i][j]=0;
                else if(i<j)
                    assign mblock_n[i][j]= |p_tmp[i+1+:j-i] ? 1:0;
                else if(i>j)
                    assign mblock_n[i][j]= |p_tmp[i+1+:NUM_MASTER-(i-j)] ? 1:0;
    endgenerate

    always_comb begin

        /*if (gId == '0) begin
            valid_f2d_o     = 1'b0;
            op_f2d_o        = READ_INFO;
            tag_f2d_o       = '0;
            index_f2d_o     = '0;
            cpu_id_f2d_o    = '0;
            sharers_f2d_o   = '0;
            dirty_f2d_o     = 1'b0;

            ack_d2f_o       = '0;
            sharers_d2f_o   = '0;
        end
        else begin
            valid_f2d_o     = valid_f2d_i[gId-1];
            op_f2d_o        = op_f2d_i[gId-1];
            tag_f2d_o       = tag_f2d_i[gId-1];
            index_f2d_o     = index_f2d_i[gId-1];
            cpu_id_f2d_o    = cpu_id_f2d_i[gId-1];
            sharers_f2d_o   = sharers_f2d_i[gId-1];
            dirty_f2d_o     = dirty_f2d_i[gId-1];

            ack_d2f_o[gId-1]       = ack_d2f_i;
            sharers_d2f_o[gId-1]   = sharers_d2f_i;
        end*/

        
        valid_f2d_o     = 1'b0;
        op_f2d_o        = READ_OP;
        tag_f2d_o       = '0;
        index_f2d_o     = '0;
        cpu_id_f2d_o    = '0;

        ack_d2f_o       = '0;
        sharers_d2f_o   = '0;
        if (gId != '0) begin
            valid_f2d_o     = valid_f2d_i[gId-1];
            op_f2d_o        = op_f2d_i[gId-1];
            tag_f2d_o       = tag_f2d_i[gId-1];
            index_f2d_o     = index_f2d_i[gId-1];
            cpu_id_f2d_o    = cpu_id_f2d_i[gId-1];

            ack_d2f_o[gId-1]       = ack_d2f_i;
            sharers_d2f_o[gId-1]   = sharers_d2f_i;
        end

    end
endmodule