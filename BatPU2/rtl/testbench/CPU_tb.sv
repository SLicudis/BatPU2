module CPU_tb(
    input clk, clk_en, sync_rst
);
    reg [15:0] irom [1023:0];
    reg [15:0] irom_buffer;
    wire [9:0] irom_addr;

    wire cpu_mem_we;
    wire cpu_mem_req;
    wire cpu_imem_req;
    wire [7:0] cpu_daddr;
    wire [7:0] cpu_data_out;

    always_ff @(posedge clk) begin
        irom_buffer <= irom[irom_addr];
    end

    initial begin
        $readmemh("/mnt/e/Pogramacion/SystemVerilog/BPU2/BatPU2/rtl/ROM/test1.hex", irom);
    end

    CPU CPU(
        .clk(clk), .clk_en(clk_en), .sync_rst(sync_rst), .data_in(5), .inst_in(irom_buffer),
        .mem_we(cpu_mem_we), .mem_req(cpu_mem_req), .inst_mem_req(cpu_imem_req),
        .data_address(cpu_daddr), .data_out(cpu_data_out), .inst_address(irom_addr)
    );

endmodule : CPU_tb
