package params_pkg;
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter ID_WIDTH = 4;
    parameter USER_WIDTH = 0;
    parameter SNOOP_DATA_BUS_WIDTH = 1;
    parameter SNOOP_ADD_BUS_WIDTH = 1;

    // # of bits for each cache line
    parameter LINE_SIZE = 1;
endpackage : params_pkg
