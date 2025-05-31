package ace_pkg;

interface ace_aw_if();

    logic [2:0] snoop;
    logic [1:0] domain;
    logic [1:0] bar;
    logic       uniq;

    modport Master (
        output snoop, domain, bar, uniq
    );

    modport Slave (
        input snoop, domain, bar, uniq
    );

endinterface: ace_aw_if

endpackage : ace_pkg
