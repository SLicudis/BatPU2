module writeback_stage(
    input clk, clk_en, sync_rst,
    input [7:0] from_alu, from_memory,
    input [15:0] inst_bus,
    input [4:0] ctr_word_in,
    output logic [3:0] rd_addr,
    output [7:0] to_reg,
    output reg_we, clk_hlt
);
    reg [7:0] alu_buffer = 0;
    reg [15:0] inst_reg = 0;
    reg [4:0] ctr_word = 0;

    assign reg_we = ctr_word[0];
    assign clk_hlt = ctr_word[4];

    always_ff @(posedge clk) begin : BufferInputs
        if(clk_en) begin
            alu_buffer <= sync_rst ? 8'h0 : from_alu;
            inst_reg <= sync_rst ? 16'h0 : inst_bus;
            ctr_word <= sync_rst ? 5'h0 : ctr_word_in;
        end
    end

    always_comb begin : SelectDest
        case(ctr_word[2:1])
        2'h0: rd_addr = inst_reg[11:8]; //A
        2'h1: rd_addr = inst_reg[7:4]; //B
        2'h2: rd_addr = inst_reg[3:0]; //C
        default: rd_addr = 0;
        endcase
    end

    assign to_reg = ctr_word[3] ? from_memory : alu_buffer;

endmodule : writeback_stage
