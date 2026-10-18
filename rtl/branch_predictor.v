module branch_predictor (
    input wire clk,
    input wire rst,

    input wire [31:0] pc_IF,
    output wire predict_taken,
    output wire [31:0] predict_target,
        // update (EX stage, when a branch resolves)
    input  wire        update_en,
    input  wire [31:0] update_pc,
    input  wire        update_taken,
    input  wire [31:0] update_target


);

reg         valid   [0:15];
reg [25:0]  tag     [0:15];
reg [31:0]  target  [0:15];
reg [1:0]   counter [0:15];

wire [3:0]  index  = pc_IF[5:2];
wire [25:0] tag_IF = pc_IF[31:6];

wire hit = valid[index] && (tag[index] == tag_IF);

assign predict_taken  = hit && counter[index][1];
assign predict_target = target[index];


wire [3:0]  u_index = update_pc[5:2];
wire [25:0] u_tag   = update_pc[31:6];
wire        u_hit   = valid[u_index] && (tag[u_index] == u_tag);

integer i;
always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < 16; i = i + 1) begin
            valid[i]   <= 1'b0;
            tag[i]     <= 26'b0;
            target[i]  <= 32'b0;
            counter[i] <= 2'b01;
        end
    end
    else if (update_en) begin
        if (u_hit) begin
            if (update_taken && counter[u_index] != 2'b11)
                counter[u_index] <= counter[u_index] + 2'b01;
            else if (!update_taken && counter[u_index] != 2'b00)
                counter[u_index] <= counter[u_index] - 2'b01;

            if (update_taken)
                target[u_index] <= update_target;
        end
        else begin
            valid[u_index]   <= 1'b1;
            tag[u_index]     <= u_tag;
            target[u_index]  <= update_target;
            counter[u_index] <= update_taken ? 2'b10 : 2'b01;
        end
    end
end

    
endmodule