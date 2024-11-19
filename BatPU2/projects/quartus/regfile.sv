module regfile(
    input clk, we, clk_en,
    input [7:0] din,
    input [3:0] rs1_addr, rs2_addr, rd_addr,
    output [7:0] rs1, rs2
);
    reg [7:0] memory [15:0];

    always_ff @(posedge clk) if(we && clk_en) memory[rd_addr] <= din;
    assign rs1 = (rs1_addr != 0) ? ((we && (rd_addr == rs1_addr)) ? din : memory[rs1_addr]) : 8'h0;
    assign rs2 = (rs2_addr != 0) ? ((we && (rd_addr == rs2_addr)) ? din : memory[rs2_addr]) : 8'h0;

endmodule : regfile
