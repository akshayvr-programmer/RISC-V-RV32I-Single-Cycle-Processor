module csr_file(
    input  wire        clk,
    input  wire        rst,

    input  wire [11:0] csr_addr,
    output reg  [31:0] csr_rdata,

    input  wire        csr_we,
    input  wire [31:0] csr_wdata,
    input  wire        trap_we,
    input  wire [31:0] trap_pc,
    input  wire [31:0] trap_cause,
    output wire [31:0] mtvec_out,
    output wire [31:0] mepc_out
);

reg [31:0] mstatus, mtvec, mepc, mcause;
assign mtvec_out = mtvec;
assign mepc_out  = mepc;


// Read: pick a register by its CSR address
always @(*) begin
    case (csr_addr)
        12'h300: csr_rdata = mstatus;
        12'h305: csr_rdata = mtvec;
        12'h341: csr_rdata = mepc;
        12'h342: csr_rdata = mcause;
        default: csr_rdata = 32'b0;
    endcase
end

// Write: on the clock edge, update the chosen register
always @(posedge clk) begin
    if (rst) begin
        mstatus <= 32'b0;
        mtvec   <= 32'b0;
        mepc    <= 32'b0;
        mcause  <= 32'b0;
    end else if (csr_we) begin
        case (csr_addr)
            12'h300: mstatus <= csr_wdata;
            12'h305: mtvec   <= csr_wdata;
            12'h341: mepc    <= csr_wdata;
            12'h342: mcause  <= csr_wdata;
        endcase
    end

    else if (trap_we) begin
        mepc   <= trap_pc;
        mcause <= trap_cause;
    end
    
end

endmodule