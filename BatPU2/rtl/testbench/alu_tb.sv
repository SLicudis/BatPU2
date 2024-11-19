module alu_tb(
    input clk, clk_en, sync_rst
);
    reg [2:0] timer = 0;
    logic [7:0] a;
    logic [7:0] b;
    logic [2:0] op;
    wire [7:0] res;
    wire carry;
    wire zero;

    always_ff @(posedge clk) begin
        if(clk_en) timer <= timer + 1;
    end

    always_comb begin
        if(timer == 0) begin
            op = 0;
            a = 2;
            b = 5;
        end else if(timer == 1) begin
            op = 1;
            a = 10;
            b = 5;
        end else if(timer == 2) begin
            op = 2;
            a = 8'hff;
            b = 8'hf0;
        end else if(timer == 3) begin
            op = 3;
            a = 8'hff;
            b = 8'hf0;
        end else if(timer == 4) begin
            op = 4;
            a = 8'hff;
            b = 8'hf0;
        end else if(timer == 5) begin
            op = 5;
            a = 8'h80;
            b = 0;
        end else if(timer == 6) begin
            op = 6;
            a = 0;
            b = 7;
        end else begin
            op = 0;
            a = 0;
            b = 0;
        end
    end

    alu alu_inst(
        .a(a), .b(b), .op(op), .res(res), .carry(carry), .zero(zero)
    );


endmodule : alu_tb