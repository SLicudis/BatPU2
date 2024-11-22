module core(
    input clk, clk_en, sync_rst, stall_proc,
    input [15:0] inst_in,
    input [7:0] data_in,
    output [7:0] data_out, data_address,
    output [9:0] inst_address,
    output mem_we, mem_req
);
    reg clk_state = 1; //Enable the clock to the internal components (used by HLT)
    reg initial_state = 0;
    wire int_clk_en = clk_state && clk_en; //Internal clock enable
    wire clk_hlt;
    wire int_sync_rst = clk_hlt || sync_rst;

    always_ff @(posedge clk) begin : ClockStateUpdate
        if(clk_en) begin
            if(sync_rst) begin
                clk_state <= 0;
                initial_state <= 0;
            end else begin
                initial_state <= 1;
                if(clk_hlt) clk_state <= 0;
            end
        end
    end
    
    wire fetch_jmp;
    wire [9:0] fetch_jmp_in;
    wire [9:0] fetch_pc_to_pipe;

    fetch_stage fetch_stage(
        .clk(clk), .sync_rst(int_sync_rst), .clk_en(int_clk_en), .jmp(fetch_jmp),
        .jmp_in(fetch_jmp_in), .inst_address(inst_address), .to_pipe(fetch_pc_to_pipe)
    );

    wire decode_reg_we;
    wire [3:0] decode_rd_addr;
    wire [7:0] decode_data_to_reg;
    wire [7:0] decode_rs1_out;
    wire [7:0] decode_rs2_out;
    wire [17:0] decode_ctr_word;
    wire [15:0] decode_inst_bus_out;
    wire [15:0] int_inst_in = initial_state ? inst_in : 16'h0;
    wire invalid_decode = fetch_jmp || stall_proc;

    decode_stage decode_stage(
        .clk(clk), .clk_en(int_clk_en), .sync_rst(int_sync_rst),
        .invalidate(invalid_decode), .reg_we(decode_reg_we), .rd_addr(decode_rd_addr),
        .rd_in(decode_data_to_reg), .inst_bus(int_inst_in), .rs1(decode_rs1_out), .rs2(decode_rs2_out),
        .ctr_word(decode_ctr_word), .inst_bus_out(decode_inst_bus_out)
    );

    wire [4:0] exe_ctr_to_writeback;
    wire [15:0] exe_inst_bus_out;
    wire [7:0] exe_alu_res;

    assign data_address = exe_alu_res;

    exe_stage exe_stage(
        .clk(clk), .clk_en(int_clk_en), .sync_rst(int_sync_rst), .reg_we(decode_reg_we),
        .rs1(decode_rs1_out), .rs2(decode_rs2_out), .write_in(decode_data_to_reg), .rd_addr(decode_rd_addr),
        .ctr_word_in(decode_ctr_word), .inst_bus(decode_inst_bus_out), .pc_in(fetch_pc_to_pipe), .ctr_word_to_writeback(exe_ctr_to_writeback),
        .inst_bus_out(exe_inst_bus_out), .alu_res(exe_alu_res), .to_memory(data_out), .memory_req(mem_req), .memory_we(mem_we),
        .jmp(fetch_jmp), .to_pc(fetch_jmp_in)
    );

    writeback_stage writeback_stage(
        .clk(clk), .clk_en(int_clk_en), .sync_rst(int_sync_rst), .from_alu(exe_alu_res), .from_memory(data_in),
        .inst_bus(exe_inst_bus_out), .ctr_word_in(exe_ctr_to_writeback), .rd_addr(decode_rd_addr), .to_reg(decode_data_to_reg),
        .reg_we(decode_reg_we), .clk_hlt(clk_hlt)
    );

endmodule : core
