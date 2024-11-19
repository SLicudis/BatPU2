module exe_stage(
    input clk, clk_en, reg_we, sync_rst,
    input [7:0] rs1, rs2, write_in,
    input [3:0] rd_addr,
    input [17:0] ctr_word_in,
    input [15:0] inst_bus,
    input [9:0] pc_in,
    output [4:0] ctr_word_to_writeback,
    output [15:0] inst_bus_out,
    output [7:0] alu_res, to_memory,
    output memory_req, memory_we, jmp,
    output [9:0] to_pc
);
    reg [7:0] rs1_buffer = 0;
    reg [7:0] rs2_buffer = 0;
    reg [17:0] ctr_word = 0;
    reg [15:0] inst_reg = 0;
    reg [9:0] pc_buffer = 0;

    wire [2:0] ctr_alu_op = ctr_word[2:0]; //ADD, SUB, NOR, AND, XOR, RSH, B_IN
    wire ctr_alu_bsel = ctr_word[3]; //RS2, IMM
    wire ctr_immsel = ctr_word[4]; //IMM8, IMM4
    wire ctr_flags_updt = ctr_word[5];
    wire ctr_jmp = ctr_word[6];
    wire ctr_brh = ctr_word[7];
    wire ctr_cstack_exe = ctr_word[8];
    wire ctr_cstack_type = ctr_word[9]; //PSH, POP
    wire ctr_pc_insel = ctr_word[10]; //ADDR10, CSTACK
    wire ctr_memreq = ctr_word[11];
    wire ctr_memwe = ctr_word[12];

    assign memory_req = ctr_memreq && clk_en && !sync_rst;
    assign memory_we = ctr_memwe && clk_en && !sync_rst;
    assign ctr_word_to_writeback = ctr_word[17:13];
    assign inst_bus_out = inst_reg;

    always_ff @(posedge clk) begin : Buffer
        if(clk_en) begin
            rs1_buffer <= sync_rst ? 8'h0 : rs1;
            rs2_buffer <= sync_rst ? 8'h0 : rs2;
            ctr_word <= sync_rst ? 18'h0 : ctr_word_in;
            inst_reg <= sync_rst ? 16'h0 : inst_bus;
            pc_buffer <= sync_rst ? 10'h0 : pc_in;
        end
    end

    logic [7:0] intermediate_rs1;
    always_comb begin : RS1_Forwarding
        if((rd_addr == inst_reg[11:8]) && reg_we) begin
            if(rd_addr == 0) intermediate_rs1 = 8'h0;
            else intermediate_rs1 = write_in;
        end else intermediate_rs1 = rs1_buffer;
    end

    logic [7:0] intermediate_rs2;
    always_comb begin : RS2_Forwarding
        if((rd_addr == inst_reg[7:4]) && reg_we) begin
            if(rd_addr == 0) intermediate_rs2 = 8'h0;
            else intermediate_rs2 = write_in;
        end else intermediate_rs2 = rs2_buffer;
    end

    assign to_memory = intermediate_rs2;

    wire [7:0] alu_b = ctr_alu_bsel ? immediate : intermediate_rs2;
    wire [7:0] immediate = ctr_immsel ? {{4{inst_reg[3]}}, inst_reg[3:0]} : inst_reg[7:0];

    wire alu_zero;
    wire alu_carry;
    reg [1:0] flags = 0;

    always_ff @(posedge clk) begin : UpdateFlags
        if(clk_en && ctr_flags_updt) flags <= {alu_carry, alu_zero};
    end

    alu alu(
        .a(intermediate_rs1), .b(alu_b), .op(ctr_alu_op),
        .res(alu_res), .zero(alu_zero), .carry(alu_carry)
    );

    wire branch = (inst_reg[11] ? flags[1] : flags[0]) ^ inst_reg[10];
    wire [9:0] cstack_top;
    assign to_pc = ctr_pc_insel ? cstack_top : inst_reg[9:0];
    assign jmp = ctr_jmp || (ctr_brh && branch);

    call_stack call_stack(
        .clk(clk), .clk_en(clk_en), .execute(ctr_cstack_exe),
        .mode(ctr_cstack_type),
        .data_in(pc_buffer), .data_out(cstack_top)
    );

endmodule : exe_stage
