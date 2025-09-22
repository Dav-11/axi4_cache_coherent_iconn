import param_pkg::*;

module fixedArb_main_mem (
    input clk,
    input resetn,
    input [NUM_MASTER-1:0] req_i,
    input [NUM_MASTER-1:0][(BYTES_PER_LINE*8)-1:0] wdata_i,
    input [NUM_MASTER-1:0][MAIN_MEM_LINE_AW-1:0] waddr_i,
    input [NUM_MASTER-1:0][MAIN_MEM_LINE_AW-1:0] raddr_i,
    input [NUM_MASTER-1:0] wcyc_i,
    input [NUM_MASTER-1:0] rcyc_i,
    input ack_i,
    output logic [NUM_MASTER-1:0] ack_o,
    output logic [(BYTES_PER_LINE*8)-1:0] wdata_o,
    output logic [MAIN_MEM_LINE_AW-1:0] waddr_o,
    output logic [MAIN_MEM_LINE_AW-1:0] raddr_o,
    output logic rcyc_o,
    output logic wcyc_o
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
            g_r <= '0;
            outstanding_r <= 0;
        end
        else begin
            g_r <= g_n;
            outstanding_r <= outstanding_next;
        end
    end

    assign outstanding_next = ~ack_i & |g_n;

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
            assign g_n[k] = (outstanding_r == 1'b1) ? g_r[k] : req_i[k] & ~|(req_i & mblock_n[k]);
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
        /*case (gId)
            1: begin
                wdata_o = wdata_i[0];
                waddr_o = waddr_i[0];
                raddr_o = raddr_i[0];
                wcyc_o  = wcyc_i[0];
                rcyc_o  = rcyc_i[0];
            end
            2: begin
                wdata_o = wdata_i[1];
                waddr_o = waddr_i[1];
                raddr_o = raddr_i[1];
                wcyc_o  = wcyc_i[1];
                rcyc_o  = rcyc_i[1];
            end
            default: begin
                wdata_o = '0;
                waddr_o = '0;
                raddr_o = '0;
                wcyc_o  = '0;
                rcyc_o  = '0;
            end
        endcase*/

        /*if (gId == '0) begin
            wdata_o = '0;
            waddr_o = '0;
            raddr_o = '0;
            wcyc_o  = '0;
            rcyc_o  = '0;
        end
        else begin
            wdata_o = wdata_i[gId-1];
            waddr_o = waddr_i[gId-1];
            raddr_o = raddr_i[gId-1];
            wcyc_o  = wcyc_i[gId-1];
            rcyc_o  = rcyc_i[gId-1];
        end*/

        
        wdata_o = '0;
        waddr_o = '0;
        raddr_o = '0;
        wcyc_o  = '0;
        rcyc_o  = '0;
        ack_o = '0;
        if (gId != '0) begin
            wdata_o = wdata_i[gId-1];
            waddr_o = waddr_i[gId-1];
            raddr_o = raddr_i[gId-1];
            wcyc_o  = wcyc_i[gId-1];
            rcyc_o  = rcyc_i[gId-1];
            ack_o[gId-1] = ack_i;
        end
    end

endmodule
