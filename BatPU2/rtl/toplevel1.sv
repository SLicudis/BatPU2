module toplevel1(
    input clk, clk_en, sync_rst
    input [7:0] switches,
    output [7:0] disp
);

    reg [7:0] ram [254:0];
    reg [7:0] ram_buffer = 0;
    reg [7:0] dispreg = 0;
    assign disp = dispreg;

    wire [7:0] d_addr;
    wire [7:0] cpu_data_out;
    wire mem_we;
    wire mem_req;

    reg [15:0] rom [1023:0];
    reg [15:0] rom_buffer = 0;

    wire [9:0] inst_addr;
    wire inst_mem_req;

    initial $readmemh("/mnt/e/Pogramacion/SystemVerilog/BPU2/BatPU2/rtl/ROM/test1.hex", rom); //Change the directory. I was using WSL

    always_ff @(posedge clk) begin
        if(clk_en) begin
            if(mem_req) ram_buffer <= (d_addr == 255) ? switches : ram[d_addr];
            if(inst_mem_req) rom_buffer <= rom[inst_addr];
            if(mem_we) begin
                if(d_addr == 255) dispreg <= cpu_data_out;
                else ram[d_addr] <= cpu_data_out;
            end
        end
    end

    CPU CPU(
        .clk(clk), .clk_en(clk_en), .sync_rst(sync_rst),
        .data_in(ram_buffer), .data_out(cpu_data_out), .inst_in(rom_buffer),
        .data_address(d_addr), .inst_address(inst_addr),
        .mem_we(mem_we), .mem_req(mem_req), .inst_mem_req
    );

endmodule : toplevel1
