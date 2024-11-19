module fetch_stage(
    input clk, sync_rst, jmp, clk_en,
    input [9:0] jmp_in,
    output [9:0] inst_address, to_pipe
);

    reg init_state = 0;
    reg [9:0] pc = 0;
    assign inst_address = (!init_state || sync_rst) ? 10'h0 : (jmp ? jmp_in : pc+1);
    assign to_pipe = pc;

    always_ff @(posedge clk) begin
        if(clk_en) begin
            init_state <= !sync_rst;
            if(sync_rst || !init_state) pc <= 0;
            else if(jmp) pc <= jmp_in;
            else pc <= pc + 1;
        end
    end


endmodule : fetch_stage
