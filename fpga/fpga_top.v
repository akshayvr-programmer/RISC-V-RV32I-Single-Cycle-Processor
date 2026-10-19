`ifndef HEX_PATH
    `define HEX_PATH "programs/bench_loop.hex"
`endif

module fpga_top (
    input  wire        clk,
    input  wire        rst,
    output wire [15:0] debug_out
);
    cpu_pipeline cpu_i (.clk(clk), .rst(rst), .debug_out(debug_out));
    defparam cpu_i.IM.HEXFILE = `HEX_PATH;
endmodule
