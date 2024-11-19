module decode_stage(
    input clk, clk_en, invalidate, reg_we, sync_rst,
    input [3:0] rd_addr,
    input [7:0] rd_in,
    input [15:0] inst_bus,
    output [7:0] rs1, rs2,
    output [17:0] ctr_word,
    output [15:0] inst_bus_out
);

wire [17:0] intermediate_ctr_word;
assign ctr_word = (invalidate || sync_rst) ? 18'h0 : intermediate_ctr_word;
assign inst_bus_out = inst_bus;

inst_rom inst_rom(
    .opcode(inst_bus[15:12]), .ctr_word(intermediate_ctr_word)
);

regfile regfile(
    .clk(clk), .clk_en(clk_en), .we(reg_we),
    .din(rd_in), .rs1_addr(inst_bus[11:8]), .rs2_addr(inst_bus[7:4]),
    .rd_addr(rd_addr), .rs1(rs1), .rs2(rs2)
);

endmodule : decode_stage
