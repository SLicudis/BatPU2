module CPU(
    input clk, clk_en, sync_rst,
    input [7:0] data_in,
    input [15:0] inst_in,
    output mem_we, mem_req, inst_mem_req,
    output [7:0] data_address, data_out,
    output [9:0] inst_address
);

    wire core_clk_en = ~icache_busy && clk_en;
    wire [15:0] inst_bus;
    wire [9:0] int_inst_address;

    core core(
        .clk(clk), .clk_en(core_clk_en), .sync_rst(sync_rst),
        .inst_in(inst_bus), .data_in(data_in), .data_out(data_out), .data_address(data_address),
        .inst_address(int_inst_address), .mem_we(mem_we), .mem_req(mem_req)
    );

    wire icache_busy;

    icache icache(
        .clk(clk), .clk_en(clk_en), .req(1'b1), .address_in(int_inst_address), .from_mem(inst_in),
        .inst_out(inst_bus), .address_out(inst_address), .busy(icache_busy), .mreq(inst_mem_req)
    );

endmodule : CPU
