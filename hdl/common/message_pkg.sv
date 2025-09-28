package message_pkg;

  import func_param_pkg::*;
  import param_pkg::*;

  `define WRITE_BACK 3'b011
  `define EVICT 3'b100
  `define DUMMY_DELAY_ON 0

  class Address;
    bit [FULL_ADDRESS_BITS-1:0] addr;

    function new(bit [FULL_ADDRESS_BITS-1:0] addr = '0);
      this.addr = addr;
    endfunction

    function bit [FULL_ADDRESS_BITS-TAG_BITS-1:BYTE_OFFSET_BITS] Index();
      return addr[FULL_ADDRESS_BITS-TAG_BITS-1:BYTE_OFFSET_BITS];
    endfunction

    function bit [FULL_ADDRESS_BITS-1:FULL_ADDRESS_BITS-TAG_BITS] Tag();
      return addr[FULL_ADDRESS_BITS-1:FULL_ADDRESS_BITS-TAG_BITS];
    endfunction

    function bit [BYTE_OFFSET_BITS-1:0] ByteOffset();
      return addr[BYTE_OFFSET_BITS-1:0];
    endfunction

    function bit [FULL_ADDRESS_BITS-1:0] LineAddr();
      return {addr[FULL_ADDRESS_BITS-1:BYTE_OFFSET_BITS], {BYTE_OFFSET_BITS{1'b0}}};
    endfunction
  endclass


  class SnoopResponse;
    bit [5-1:0] CRRESP;
    line_arr_t CDDATA;

    int dummy_delay;

    function new(bit [5-1:0] CRRESP = '0, line_arr_t CDDATA = '{default: 0});
      this.CRRESP = CRRESP;
      this.CDDATA = CDDATA;
      if (  /*isSetDataTransfer() &*/ `DUMMY_DELAY_ON) begin
        dummy_delay = DIR_MANAGE_INFO_DELAY; //LINE_SIZE/BUS_WIDTH_BYTE + $urandom_range(0, MAX_DELAY_REQUEST);
      end else begin
        dummy_delay = 0;
      end
    endfunction

    function bit isSetDataTransfer();
      return CRRESP[0];
    endfunction

    function bit isSetPassDirty();
      return CRRESP[2];
    endfunction

    function bit isSetIsShared();
      return CRRESP[3];
    endfunction

  endclass

  class SnoopRequest;
    bit [4-1:0] ACSNOOP;
    Address addr;

    function new(bit [4-1:0] ACSNOOP = '0, Address addr = null);
      if (addr == null) begin
        addr = new();
      end
      this.ACSNOOP = ACSNOOP;
      this.addr = addr;
    endfunction

    function string transaction_to_string();
      case (ACSNOOP)
        4'b0010: return "ReadClean";
        4'b0111: return "ReadUnique";
        default: return "Unknown";
      endcase
    endfunction
  endclass

  class AR_request;
    bit [ARID_BITS-1:0] ARID;
    Address addr;
    bit [4-1:0] ARSNOOP;
    function new(bit [4-1:0] ARSNOOP = '0, Address addr = null, bit [ARID_BITS-1:0] ARID = '0);
      if (addr == null) begin
        addr = new();
      end
      this.addr = addr;
      this.ARSNOOP = ARSNOOP;
      this.ARID = ARID;
    endfunction

    function string transaction_to_string();
      case (ARSNOOP)
        4'b0010: return "ReadClean";
        4'b0111: return "ReadUnique";
        default: return "Unknown";
      endcase
    endfunction
  endclass

  class R_response #(
      int N_CPU = 4,
      int MSHR_SIZE = 4
  );
    bit [RID_BITS-1:0] RID;
    bit [2-1:0] RRESP;
    line_arr_t RDATA;

    int dummy_delay;

    function new(bit [2-1:0] RRESP = '0, line_arr_t RDATA = '{default: 0},
                 bit [RID_BITS-1:0] RID = '0);
      this.RRESP = RRESP;
      this.RDATA = RDATA;
      this.RID   = RID;
      if (`DUMMY_DELAY_ON)
        dummy_delay = 0;  //LINE_SIZE/BUS_WIDTH_BYTE + $urandom_range(0, MAX_DELAY_REQUEST);
      else dummy_delay = 0;
    endfunction

    function string response_to_string();
      case (RRESP)
        2'b00:   return "OKAY";
        2'b01:   return "EXOKAY";
        2'b10:   return "SLVERR";
        2'b11:   return "DECERR";
        default: return "Unknown";
      endcase
    endfunction
  endclass

  class AW_request;
    bit [AWID_BITS-1:0] AWID;
    Address addr;
    bit [3-1:0] AWSNOOP;
    line_arr_t WDATA;

    int dummy_delay;

    function new(bit [3-1:0] AWSNOOP = '0, Address addr = null, line_arr_t WDATA = '{default: 0},
                 bit [AWID_BITS-1:0] AWID = '0);
      if (addr == null) begin
        addr = new();
      end
      this.addr = addr;
      this.AWSNOOP = AWSNOOP;
      this.WDATA = WDATA;
      this.AWID = AWID;
      case (AWSNOOP)
        `EVICT: dummy_delay = 0;
        `WRITE_BACK: begin
          if (`DUMMY_DELAY_ON)
            dummy_delay = 0;  //LINE_SIZE/BUS_WIDTH_BYTE + $urandom_range(0, MAX_DELAY_REQUEST);
          else dummy_delay = 0;
        end
        default: begin
          $fatal(1, "Unknown AWSNOOP %0d", AWSNOOP);
        end
      endcase
    endfunction

    function string transaction_to_string();
      case (AWSNOOP)
        3'b100:  return "Evict";
        3'b011:  return "WriteBack";
        default: return "Unknown";
      endcase
    endfunction
  endclass

  class B_response;
    bit [BID_BITS-1:0] BID;
    bit [2-1:0] BRESP;

    function new(bit [2-1:0] BRESP = '0, bit [BID_BITS-1:0] BID = '0);
      this.BRESP = BRESP;
      this.BID   = BID;
    endfunction

    function string response_to_string();
      case (BRESP)
        2'b00:   return "OKAY";
        2'b01:   return "EXOKAY";
        2'b10:   return "SLVERR";
        2'b11:   return "DECERR";
        default: return "Unknown";
      endcase
    endfunction
  endclass

  class CPU_request;
    Address addr;
    cpu_request_type_t req_type;
    bit [DBUS_DW-1:0] value;
    bit [DBUS_ISEL-1:0] sel;
    function new(cpu_request_type_t req_type, Address addr = null, bit [DBUS_DW-1:0] value = '0,
                 bit [DBUS_ISEL-1:0] sel = '0);
      this.req_type = req_type;
      this.addr = addr;
      this.value = value;
      this.sel = sel;
    endfunction
  endclass

  class CPU_request_ext;
    Address addr;
    cpu_request_type_t req_type;
    bit [DBUS_DW-1:0] value;
    bit [DBUS_ISEL-1:0] sel;
    longint unsigned issue_tick;
    function new(cpu_request_type_t req_type, Address addr = null, bit [DBUS_DW-1:0] value = '0,
                 bit [DBUS_ISEL-1:0] sel = '0, longint unsigned issue_tick = 0);
      this.req_type = req_type;
      this.addr = addr;
      this.value = value;
      this.sel = sel;
      this.issue_tick = issue_tick;
    endfunction
  endclass
endpackage
