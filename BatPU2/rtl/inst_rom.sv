module inst_rom(
    input [3:0] opcode,
    output logic [17:0] ctr_word
);
    always_comb begin : ROMLogic
        case(opcode)
        4'h0: ctr_word = 0; //NOP
        4'h1: ctr_word = 18'b1_0_00_0_0_0_0_0_0_0_0_0_0_0_000; //HLT
        4'h2: ctr_word = 18'b0_0_10_1_0_0_0_0_0_0_0_1_0_0_000; //ADD
        4'h3: ctr_word = 18'b0_0_10_1_0_0_0_0_0_0_0_1_0_0_001; //SUB
        4'h4: ctr_word = 18'b0_0_10_1_0_0_0_0_0_0_0_1_0_0_010; //NOR
        4'h5: ctr_word = 18'b0_0_10_1_0_0_0_0_0_0_0_1_0_0_011; //AND
        4'h6: ctr_word = 18'b0_0_10_1_0_0_0_0_0_0_0_1_0_0_100; //XOR
        4'h7: ctr_word = 18'b0_0_10_1_0_0_0_0_0_0_0_0_0_0_101; //RSH
        4'h8: ctr_word = 18'b0_0_00_1_0_0_0_0_0_0_0_0_0_1_110; //LDI
        4'h9: ctr_word = 18'b0_0_00_1_0_0_0_0_0_0_0_1_0_1_000; //ADI
        4'ha: ctr_word = 18'b0_0_00_0_0_0_0_0_0_0_1_0_0_0_000; //JMP
        4'hb: ctr_word = 18'b0_0_00_0_0_0_0_0_0_1_0_0_0_0_000; //BRH
        4'hc: ctr_word = 18'b0_0_00_0_0_0_0_0_1_0_1_0_0_0_000; //CAL
        4'hd: ctr_word = 18'b0_0_00_0_0_0_1_1_1_0_1_0_0_0_000; //RET
        4'he: ctr_word = 18'b0_1_01_1_0_1_0_0_0_0_0_0_1_1_000; //LOD
        4'hf: ctr_word = 18'b0_0_00_0_1_0_0_0_0_0_0_0_1_1_000; //STR
        endcase
    end

endmodule : inst_rom

/*
0-2. ALU_OP: ADD, SUB, NOR, AND, XOR, RSH, B_IN
3. ALU_BSEL: RS2, IMM
4. IMM_SEL: IMM8, IMM4
5. FLAGS_UPDT
6. JMP
7. BRH
8. CSTACK_EXE
9. CSTACK_TYPE: PSH, POP
10. PC_IN: ADDR10, CSTACK
11. MEM_REQ
12. MEM_WE
13. REG_WE
14-15. RD_SEL: A, B, C
16. REG_IN: ALU, MEM
17. CLK_HLT
*/

