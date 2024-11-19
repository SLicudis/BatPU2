module alu(
    input [7:0] a, b,
    input [2:0] op,
    output logic [7:0] res,
    output zero,
    output logic carry
);

    always_comb begin : CombinationalLogic
        case(op)
        3'h0: {carry, res} = {1'b0, a} + {1'b0, b}; //ADD
        3'h1: {carry, res} = {1'b0, a} - {1'b0, b}; //SUB
        3'h2: {carry, res} = {1'b0, (~(a | b))}; //NOR
        3'h3: {carry, res} = {1'b0, (a & b)}; //AND
        3'h4: {carry, res} = {1'b0, (a ^ b)}; //XOR
        3'h5: {carry, res} = {2'b0, a[7:1]}; //RSH
        3'h6: {carry, res} = {1'b0, b}; //RES = B
        default: {carry, res} = 0;
        endcase
    end
    
    assign zero = (res == 0); //Check for Zero

endmodule : alu
