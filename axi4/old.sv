    interface axi4_if #(
        parameter ADDR_WIDTH = 32,
        parameter DATA_WIDTH = 64,
        parameter ID_WIDTH   = 4,
        parameter USER_WIDTH = 1
    ) (
        input logic clk,
        input logic rstn
    );

    // Write Address Channel signals
    logic [ID_WIDTH-1:0]   awid;
    logic [ADDR_WIDTH-1:0] awaddr;
    logic [7:0]            awlen;
    axi_size_e             awsize;
    axi_burst_e            awburst;
    logic                  awlock;
    logic [3:0]            awcache;
    logic [2:0]            awprot;
    logic [3:0]            awqos;
    logic [3:0]            awregion;
    logic [USER_WIDTH-1:0] awuser;
    logic                  awvalid;
    logic                  awready;

    // Write Data Channel signals
    logic [ID_WIDTH-1:0]   wid; // AXI4-Lite does not have WID
    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH/8-1:0] wstrb;
    logic                  wlast;
    logic [USER_WIDTH-1:0] wuser;
    logic                  wvalid;
    logic                  wready;

    // Write Response Channel signals
    logic [ID_WIDTH-1:0]   bid;
    axi_resp_e             bresp;
    logic [USER_WIDTH-1:0] buser;
    logic                  bvalid;
    logic                  bready;

    // Read Address Channel signals
    logic [ID_WIDTH-1:0]   arid;
    logic [ADDR_WIDTH-1:0] araddr;
    logic [7:0]            arlen;
    axi_size_e             arsize;
    axi_burst_e            arburst;
    logic                  arlock;
    logic [3:0]            arcache;
    logic [2:0]            arprot;
    logic [3:0]            arqos;
    logic [3:0]            arregion;
    logic [USER_WIDTH-1:0] aruser;
    logic                  arvalid;
    logic                  arready;

    // Read Data Channel signals
    logic [ID_WIDTH-1:0]   rid;
    logic [DATA_WIDTH-1:0] rdata;
    axi_resp_e             rresp;
    logic                  rlast;
    logic [USER_WIDTH-1:0] ruser;
    logic                  rvalid;
    logic                  rready;

    // Modports for master and slave
    modport master (
        output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awregion, awuser, awvalid,
        input  awready,

        output wid, wdata, wstrb, wlast, wuser, wvalid,
        input  wready,

        input  bid, bresp, buser, bvalid,
        output bready,

        output arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arregion, aruser, arvalid,
        input  arready,

        input  rid, rdata, rresp, rlast, ruser, rvalid,
        output rready
    );

    modport slave (
        input  awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awregion, awuser, awvalid,
        output awready,

        input  wid, wdata, wstrb, wlast, wuser, wvalid,
        output wready,

        output bid, bresp, buser, bvalid,
        input  bready,

        input  arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arregion, aruser, arvalid,
        output arready,

        output rid, rdata, rresp, rlast, ruser, rvalid,
        input  rready
    );

    endinterface
