import param_pkg::*;
module fsm_i_noif(
    input clk,
    input resetn,

    output logic [N_CPU-1:0] b_valid,
    output logic [N_CPU-1:0] [ID_WIDTH-1:0] b_id,
    input [N_CPU-1:0] b_ready,
    
    input wack,

    input aw_empty_i,
    input w_empty_i,
    input [AW_Q_DATA_WIDTH-1:0] aw_request_i,
    input [W_Q_DATA_WIDTH-1:0] w_data_i,
    input ack_m2i,
    input ack_d2i,
    output logic aw_pop_o,
    output logic w_pop_o,
    output logic valid_i2m,
    output logic [MAIN_MEM_LINE_AW-1:0] addr_i2m,
    output logic [(BYTES_PER_LINE*8)-1:0] data_i2m,

    output logic valid_i2d,
    output logic [DCACHE_TAG_WIDTH-1:0] tag_i2d,
    output logic [DCACHE_INDEX_WIDTH-1:0] index_i2d,
    output op_dir_t operation_i2d,
    output logic [CPU_ID_WIDTH-1:0] cpu_id_i2d
);

//(* dont_touch = "yes" *) fsm_i_state_t i_state_r, i_state_next;
fsm_i_state_t i_state_r, i_state_next;

logic [AW_ID_WIDTH-1:0]         id, id_r, id_next;
logic [AW_LINE_ADDR_WIDTH-1:0]  line_addr, line_addr_r, line_addr_next;
logic [2:0]  snoop , snoop_r, snoop_next;

logic [W_Q_DATA_WIDTH-1:0] w_data_r, w_data_next;


assign id = aw_request_i[AW_ID_MSB:AW_ID_LSB];
assign line_addr = aw_request_i[AW_LINE_ADDR_MSB:AW_LINE_ADDR_LSB];
assign snoop = aw_request_i[AW_SNOOP_MSB:AW_SNOOP_LSB];

always_ff @(posedge clk) begin
    if(!resetn) begin
        i_state_r <= IDLE_I;
        id_r <= '0;
        line_addr_r <= '0;
        snoop_r <= '0;
        w_data_r <= '0;
    end else begin
        i_state_r <= i_state_next;
        id_r <= id_next;
        line_addr_r <= line_addr_next;
        snoop_r <= snoop_next;
        w_data_r <= w_data_next;
    end
end
/* AW REQUEST internal layout:
       +--------------------------------------------------------------------------------+
       | aw_id | aw_addr | aw_len | aw_size | aw_burst | aw_prot | aw_snoop | aw_domain | 
       +--------------------------------------------------------------------------------+
*/

/* DIR internal layout:
       +-------------------------+
       | VALID | DIRTY | SHARERS | ADDR
       +-------------------------+
*/
always_comb begin
    i_state_next = i_state_r;
    id_next = id_r;
    line_addr_next = line_addr_r;
    snoop_next = snoop_r;
    w_data_next = w_data_r;
    
    aw_pop_o    = 1'b0;
    w_pop_o     = 1'b0;

    valid_i2m   = 1'b0;
    addr_i2m    = '0;
    data_i2m    = '0;
    
    valid_i2d   = 1'b0;
    tag_i2d     = '0;
    index_i2d   = '0;
    operation_i2d = READ_OP;
    cpu_id_i2d  = '0;
    
    b_valid = '0;
    b_id = '0;

    case (i_state_r) 
        IDLE_I: begin
            if(~aw_empty_i) begin
                aw_pop_o = 1'b1;
                
                id_next = id;
                line_addr_next = line_addr;
                snoop_next = snoop;

                i_state_next = (snoop == 3'b011) ? WAIT_DATA_I : UNSET_DIR_I;
            end
        end
        
        WAIT_DATA_I : begin
            if(~w_empty_i) begin
                w_data_next = w_data_i;
                w_pop_o = 1'b1;
                i_state_next = WB_MEM_I;
            end
        end

        WB_MEM_I : begin
            valid_i2m = 1'b1;
            addr_i2m = line_addr_r[MAIN_MEM_LINE_AW-1:0];
            data_i2m = w_data_r;
            if(ack_m2i == 1'b1) begin
                i_state_next = UNSET_DIR_I;
            end
        end

        UNSET_DIR_I : begin
            valid_i2d = 1'b1;
            tag_i2d = line_addr_r[AW_LINE_ADDR_WIDTH-1:AW_LINE_ADDR_WIDTH-DCACHE_TAG_WIDTH];
            index_i2d = line_addr_r[DCACHE_INDEX_WIDTH-1:0];
            operation_i2d = (snoop_r == 3'b011) ? WRITE_BACK_OP : EVICT_OP;
            cpu_id_i2d = id_r[CPU_ID_WIDTH-1:0];
            if(ack_d2i) begin
                i_state_next = SEND_B_RESP_I;
            end
        end

        SEND_B_RESP_I : begin
            b_valid[id_r[CPU_ID_WIDTH-1:0]] = 1'b1;
            b_id[id_r[CPU_ID_WIDTH-1:0]] = id_r;
            if (b_ready[id_r[CPU_ID_WIDTH-1:0]] == 1'b1) begin
                i_state_next = WAIT_WACK_I;
            end
        end

        WAIT_WACK_I : begin
            if (wack == 1'b1) begin
                i_state_next = IDLE_I;
            end
        end
        default: begin
            i_state_next = IDLE_I;
        end
    endcase

end
endmodule