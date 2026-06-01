`timescale 1ns/1ps
module alu_testbench;
	parameter WIDTH = 8;
    parameter CMD_WIDTH = 4;
    reg clk, rst, ce, mode;
    reg [1:0] inp_valid;
    reg [CMD_WIDTH-1:0] cmd;
    reg [WIDTH-1:0] opa;
    reg [WIDTH-1:0] opb;
    reg cin;
    wire [2*WIDTH-1:0] res_dut;
    wire cout_dut, oflow_dut;
    wire g_dut, l_dut, e_dut;
    wire err_dut;
	wire [2*WIDTH-1:0] res_ref;
    wire cout_ref, oflow_ref;
    wire g_ref, l_ref, e_ref;
    wire err_ref;
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;
	localparam ADD = 4'd0,
               SUB = 4'd1,
               ADD_CIN = 4'd2,
               SUB_CIN = 4'd3,
               INC_A = 4'd4,
               DEC_A = 4'd5,
               INC_B = 4'd6,
               DEC_B = 4'd7,
               CMP = 4'd8,
               MUL_INC = 4'd9,
               MUL_SHIFT = 4'd10,
               S_ADD = 4'd11,
               S_SUB = 4'd12;
    localparam AND_OP = 4'd0,
               NAND_OP = 4'd1,
               OR_OP = 4'd2,
               NOR_OP = 4'd3,
               XOR_OP = 4'd4,
               XNOR_OP = 4'd5,
               NOT_A = 4'd6,
               NOT_B = 4'd7,
               SHR_A = 4'd8,
               SHL_A = 4'd9,
               SHR_B = 4'd10,
               SHL_B = 4'd11,
               ROL_A_B = 4'd12,
               ROR_A_B = 4'd13;
    alu_design dut (
        .opa(opa), .opb(opb), .cin(cin),
        .clk(clk), .rst(rst), .ce(ce),
        .cmd(cmd), .mode(mode), .inp_valid(inp_valid),
        .cout(cout_dut), .oflow(oflow_dut), .res(res_dut),
        .g(g_dut), .e(e_dut), .l(l_dut),
        .err(err_dut)
    );
    alu_reference_model refr (
        .opa(opa), .opb(opb), .cin(cin),
        .mode(mode), .cmd(cmd), .inp_valid(inp_valid),
        .res(res_ref), .cout(cout_ref), .oflow(oflow_ref),
        .g(g_ref), .e(e_ref), .l(l_ref),
        .err(err_ref)
    );
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    initial begin
        rst = 1; ce = 1; cin = 0; inp_valid = 0;
        opa = 0; opb = 0; mode = 0; cmd = 0;
        repeat(3)@(posedge clk);
        rst = 0;
		@(negedge clk);
        mode = 1;
        test_arithmetic();
        mode = 0;
        test_logical();
        $display("-------TEST SUMMARY-------");
        $display("Total Tests: %0d", test_count);
        $display("PASS: %0d", pass_count);
        $display("FAIL: %0d", fail_count);
        if (fail_count == 0)
            $display("--------ALL TESTS PASSED--------");
        else
            $display("--------SOME TESTS FAILED---------");
        #5000;
        $finish;
    end
    task test_arithmetic();
        begin
		$display("SECTION 1 :  ARITHMETIC OPERATIONS  (mode = 1)");
			test_add();
            test_sub();
			test_add_cin();
			test_sub_cin();
            test_INC_A();
            test_DEC_A();
			test_INC_B();
			test_DEC_B();
			test_CMP();
			test_MUL_INC();
			test_MUL_SHIFT();
            test_S_ADD();
			test_S_SUB();
        end
    endtask
    task test_logical();
        begin
		$display("SECTION 2 :  LOGICAL OPERATIONS  (mode = 0)");
			test_AND_OP();
			test_NAND_OP();
			test_OR_OP();
			test_NOR_OP();
			test_XOR_OP();
			test_XNOR_OP();
			test_NOT_A();
			test_NOT_B();
			test_SHR_A();
			test_SHL_A();
			test_SHR_B();
			test_SHL_B();
			test_ROL_A_B();
            test_ROR_A_B();
        end
    endtask
	task test_add();
		begin
			apply_test(1, 2'b11, ADD, 8'h00, 8'h00, 0, "ADD  0+0 = 0");
			apply_test(1, 2'b11, ADD, 8'h0F, 8'h11, 0, "ADD  normal");
			apply_test(1, 2'b11, ADD, 8'hAA, 8'h55, 0, "ADD  alternating bits");
			apply_test(1, 2'b11, ADD, 8'h7F, 8'h01, 0, "ADD  7F+01 no carry");
			apply_test(1, 2'b11, ADD, 8'hFF, 8'h00, 0, "ADD  FF+00 = FF");
			apply_test(1, 2'b11, ADD, 8'hFF, 8'h01, 0, "ADD  FF+01 cout");
			apply_test(1, 2'b11, ADD, 8'hFF, 8'hFF, 0, "ADD  max+max cout");
			apply_test(1, 2'b00, ADD, 8'hAA, 8'hBB, 0, "ADD  ERR valid=00");
			apply_test(1, 2'b01, ADD, 8'hAA, 8'hBB, 0, "ADD  ERR valid=01");
			apply_test(1, 2'b10, ADD, 8'hAA, 8'hBB, 0, "ADD  ERR valid=10");
		end
	endtask
	task test_sub();
		begin
			apply_test(1, 2'b11, SUB, 8'h00, 8'h00, 0, "SUB  0-0 = 0");
			apply_test(1, 2'b11, SUB, 8'h20, 8'h10, 0, "SUB  normal a>b");
			apply_test(1, 2'b11, SUB, 8'hFF, 8'hFF, 0, "SUB  max-max = 0");
			apply_test(1, 2'b11, SUB, 8'h10, 8'h20, 0, "SUB  oflow a<b");
			apply_test(1, 2'b11, SUB, 8'h00, 8'h01, 0, "SUB  0-1 oflow");
			apply_test(1, 2'b11, SUB, 8'h00, 8'hFF, 0, "SUB  0-FF oflow");
			apply_test(1, 2'b11, SUB, 8'h7F, 8'h80, 0, "SUB  7F-80 oflow");
			apply_test(1, 2'b00, SUB, 8'hAA, 8'hBB, 0, "SUB  ERR valid=00");
			apply_test(1, 2'b01, SUB, 8'hAA, 8'hBB, 0, "SUB  ERR valid=01");
		end
	endtask
	task test_add_cin();
		begin
			apply_test(1, 2'b11, ADD_CIN, 8'h00, 8'h00, 0, "ADD_CIN  0+0+0");
			apply_test(1, 2'b11, ADD_CIN, 8'h00, 8'h00, 1, "ADD_CIN  0+0+1");
			apply_test(1, 2'b11, ADD_CIN, 8'h10, 8'h20, 1, "ADD_CIN  normal cin=1");
			apply_test(1, 2'b11, ADD_CIN, 8'hFE, 8'h01, 1, "ADD_CIN  FE+01+1 cout");
			apply_test(1, 2'b11, ADD_CIN, 8'hFF, 8'h00, 1, "ADD_CIN  FF+0+1 cout");
			apply_test(1, 2'b11, ADD_CIN, 8'hFF, 8'hFF, 1, "ADD_CIN  max+max+1");
			apply_test(1, 2'b11, ADD_CIN, 8'hFF, 8'hFF, 0, "ADD_CIN  max+max+0");
			apply_test(1, 2'b01, ADD_CIN, 8'hAA, 8'hBB, 1, "ADD_CIN  ERR valid=01");
			apply_test(1, 2'b10, ADD_CIN, 8'hAA, 8'hBB, 1, "ADD_CIN  ERR valid=10");
		end
	endtask
	task test_sub_cin();
		begin
			apply_test(1, 2'b11, SUB_CIN, 8'h20, 8'h10, 0, "SUB_CIN  normal cin=0");
			apply_test(1, 2'b11, SUB_CIN, 8'h20, 8'h10, 1, "SUB_CIN  borrow cin=1");
			apply_test(1, 2'b11, SUB_CIN, 8'h01, 8'h00, 1, "SUB_CIN  1-0-1=0");
			apply_test(1, 2'b11, SUB_CIN, 8'h00, 8'h00, 0, "SUB_CIN  0-0-0");
			apply_test(1, 2'b11, SUB_CIN, 8'h00, 8'h00, 1, "SUB_CIN  0-0-1 oflow");
			apply_test(1, 2'b11, SUB_CIN, 8'hFF, 8'hFF, 1, "SUB_CIN  max-max-1 oflow");
			apply_test(1, 2'b11, SUB_CIN, 8'h00, 8'hFF, 1, "SUB_CIN  oflow");
			apply_test(1, 2'b00, SUB_CIN, 8'hAA, 8'hBB, 1, "SUB_CIN  ERR valid=00");
		end
	endtask
	task test_INC_A();
		begin
			apply_test(1, 2'b01, INC_A, 8'h00, 8'h00, 0, "INC_A  0+0=1");
			apply_test(1, 2'b01, INC_A, 8'h0A, 8'h00, 0, "INC_A  normal");
			apply_test(1, 2'b01, INC_A, 8'h7F, 8'h00, 0, "INC_A  7F+1=80");
			apply_test(1, 2'b01, INC_A, 8'hFE, 8'h00, 0, "INC_A  FE+1=FF");
			apply_test(1, 2'b01, INC_A, 8'hFF, 8'h00, 0, "INC_A  FF+1=00  cout=1");
			apply_test(1, 2'b11, INC_A, 8'hAA, 8'hBB, 0, "INC_A  AA+1=AB valid=11");
			apply_test(1, 2'b10, INC_A, 8'hAA, 8'hBB, 0, "INC_A  ERR valid=10");
			apply_test(1, 2'b00, INC_A, 8'hAA, 8'hBB, 0, "INC_A  ERR valid=00");
		end
	endtask
	task test_DEC_A();
		begin
			apply_test(1, 2'b01, DEC_A, 8'h01, 8'h00, 0, "DEC_A  1-1=0");
			apply_test(1, 2'b01, DEC_A, 8'h0A, 8'h00, 0, "DEC_A  normal");
			apply_test(1, 2'b01, DEC_A, 8'hFF, 8'h00, 0, "DEC_A  FF-1=FE");
			apply_test(1, 2'b01, DEC_A, 8'h80, 8'h00, 0, "DEC_A  80-1=7F");
			apply_test(1, 2'b01, DEC_A, 8'h00, 8'h00, 0, "DEC_A  0-1=FF  oflow=1");
			apply_test(1, 2'b11, DEC_A, 8'hAA, 8'hBB, 0, "DEC_A  AA-1=A9 valid=11");
			apply_test(1, 2'b10, DEC_A, 8'hAA, 8'hBB, 0, "DEC_A  ERR valid=10");
		end
	endtask
	task test_INC_B();
		begin
			apply_test(1, 2'b10, INC_B, 8'h00, 8'h00, 0, "INC_B  0+1=1");
			apply_test(1, 2'b10, INC_B, 8'h00, 8'h7F, 0, "INC_B  7F+1=80");
			apply_test(1, 2'b10, INC_B, 8'h00, 8'hFE, 0, "INC_B  FE+1=FF");
			apply_test(1, 2'b10, INC_B, 8'h00, 8'hFF, 0, "INC_B  FF+1=00  cout=1");
			apply_test(1, 2'b11, INC_B, 8'hAA, 8'hBB, 0, "INC_B  BB+1=BC valid=11");
			apply_test(1, 2'b01, INC_B, 8'hAA, 8'hBB, 0, "INC_B  ERR valid=01");
			apply_test(1, 2'b00, INC_B, 8'hAA, 8'hBB, 0, "INC_B  ERR valid=00");
		end
	endtask
	task test_DEC_B();
		begin
			apply_test(1, 2'b10, DEC_B, 8'h00, 8'h01, 0, "DEC_B  1-1=0");
			apply_test(1, 2'b10, DEC_B, 8'h00, 8'hFF, 0, "DEC_B  FF-1=FE");
			apply_test(1, 2'b10, DEC_B, 8'h00, 8'h80, 0, "DEC_B  80-1=7F");
			apply_test(1, 2'b10, DEC_B, 8'h00, 8'h00, 0, "DEC_B  0-1=FF  oflow=1");
			apply_test(1, 2'b11, DEC_B, 8'hAA, 8'hBB, 0, "DEC_B  BB-1=BA valid=11");
			apply_test(1, 2'b01, DEC_B, 8'hAA, 8'hBB, 0, "DEC_B  ERR valid=01");
		end
	endtask
	task test_CMP();
		begin
			apply_test(1, 2'b11, CMP, 8'h10, 8'h10, 0, "CMP  equal");
			apply_test(1, 2'b11, CMP, 8'h00, 8'h00, 0, "CMP  equal zero");
			apply_test(1, 2'b11, CMP, 8'hFF, 8'hFF, 0, "CMP  equal max");
			apply_test(1, 2'b11, CMP, 8'h20, 8'h10, 0, "CMP  20 > 10");
			apply_test(1, 2'b11, CMP, 8'hFF, 8'h00, 0, "CMP  FF > 00");
			apply_test(1, 2'b11, CMP, 8'h00, 8'hFF, 0, "CMP  00 < FF");
			apply_test(1, 2'b11, CMP, 8'h7F, 8'h80, 0, "CMP  7F < 80");
			apply_test(1, 2'b01, CMP, 8'hAA, 8'hBB, 0, "CMP  ERR valid=01");
			apply_test(1, 2'b10, CMP, 8'hAA, 8'hBB, 0, "CMP  ERR valid=10");
		end
	endtask
	task test_MUL_INC();
		begin
			apply_test(1, 2'b11, MUL_INC, 8'h00, 8'h00, 0, "MUL_INC  (0+1)*(0+1)=1");
			apply_test(1, 2'b11, MUL_INC, 8'h01, 8'h01, 0, "MUL_INC  (2)*(2)=4");
			apply_test(1, 2'b11, MUL_INC, 8'h0F, 8'h0F, 0, "MUL_INC  16*16=256");
			apply_test(1, 2'b11, MUL_INC, 8'h0F, 8'h00, 0, "MUL_INC  16*1=16");
			apply_test(1, 2'b11, MUL_INC, 8'h07, 8'h07, 0, "MUL_INC  8*8=64");
			apply_test(1, 2'b11, MUL_INC, 8'hFF, 8'hFF, 0, "MUL_INC  256*256 wide result");
			apply_test(1, 2'b11, MUL_INC, 8'hFE, 8'h01, 0, "MUL_INC  255*2=510");
			apply_test(1, 2'b10, MUL_INC, 8'hAA, 8'hBB, 0, "MUL_INC  ERR valid=10");
			apply_test(1, 2'b00, MUL_INC, 8'hAA, 8'hBB, 0, "MUL_INC  ERR valid=00");
		end
	endtask
	task test_MUL_SHIFT();
		begin
			apply_test(1, 2'b11, MUL_SHIFT, 8'h00, 8'h00, 0, "MUL_SHIFT  0<<1 *0=0");
			apply_test(1, 2'b11, MUL_SHIFT, 8'h01, 8'h01, 0, "MUL_SHIFT  2*1=2");
			apply_test(1, 2'b11, MUL_SHIFT, 8'h01, 8'h00, 0, "MUL_SHIFT  2*0=0");
			apply_test(1, 2'b11, MUL_SHIFT, 8'h04, 8'h04, 0, "MUL_SHIFT  8*4=32");
			apply_test(1, 2'b11, MUL_SHIFT, 8'h80, 8'h01, 0, "MUL_SHIFT  MSB shift*1");
			apply_test(1, 2'b11, MUL_SHIFT, 8'hFF, 8'hFF, 0, "MUL_SHIFT  max wide result");
			apply_test(1, 2'b11, MUL_SHIFT, 8'h0F, 8'h10, 0, "MUL_SHIFT  30*16=480");
			apply_test(1, 2'b01, MUL_SHIFT, 8'hAA, 8'hBB, 0, "MUL_SHIFT  ERR valid=01");
		end
	endtask
	task test_S_ADD();
		begin
			apply_test(1, 2'b11, S_ADD, 8'h00, 8'h00, 0, "S_ADD  0+0=0");
			apply_test(1, 2'b11, S_ADD, 8'h05, 8'h03, 0, "S_ADD  +5+(+3)=+8");
			apply_test(1, 2'b11, S_ADD, 8'hFB, 8'hFD, 0, "S_ADD  -5+(-3)=-8");
			apply_test(1, 2'b11, S_ADD, 8'h05, 8'hFB, 0, "S_ADD  +5+(-5)=0");
			apply_test(1, 2'b11, S_ADD, 8'h7F, 8'h01, 0, "S_ADD  +127+(+1) signed oflow");
			apply_test(1, 2'b11, S_ADD, 8'h7F, 8'h7F, 0, "S_ADD  max+max signed oflow");
			apply_test(1, 2'b11, S_ADD, 8'h80, 8'hFF, 0, "S_ADD  -128+(-1) signed oflow");
			apply_test(1, 2'b10, S_ADD, 8'hAA, 8'hBB, 0, "S_ADD  ERR valid=10");
		end
	endtask
	task test_S_SUB();
		begin
			apply_test(1, 2'b11, S_SUB, 8'h00, 8'h00, 0, "S_SUB  0-0=0  equal");
			apply_test(1, 2'b11, S_SUB, 8'h05, 8'h03, 0, "S_SUB  +5-(+3)=+2");
			apply_test(1, 2'b11, S_SUB, 8'h03, 8'h05, 0, "S_SUB  +3-(+5)=-2");
			apply_test(1, 2'b11, S_SUB, 8'hFB, 8'hFD, 0, "S_SUB  -5-(-3)=-2");
			apply_test(1, 2'b11, S_SUB, 8'h7F, 8'h7F, 0, "S_SUB  +127-(+127)=0  equal");
			apply_test(1, 2'b11, S_SUB, 8'h80, 8'h01, 0, "S_SUB  -128-(+1) oflow");
			apply_test(1, 2'b11, S_SUB, 8'h7F, 8'hFF, 0, "S_SUB  +127-(-1) oflow");
			apply_test(1, 2'b11, S_SUB, 8'h80, 8'h80, 0, "S_SUB  -128-(-128)=0  equal");
			apply_test(1, 2'b11, S_SUB, 8'h7F, 8'h80, 0, "S_SUB  +127-(-128) largest diff");
			apply_test(1, 2'b11, S_SUB, 8'h00, 8'h80, 0, "S_SUB  0-(-128)");
			apply_test(1, 2'b00, S_SUB, 8'hAA, 8'hBB, 0, "S_SUB  ERR valid=00");
			apply_test(1, 2'b01, S_SUB, 8'hAA, 8'hBB, 0, "S_SUB  ERR valid=01");
		end
	endtask
	task test_AND_OP();
		begin
			apply_test(0, 2'b11, AND_OP, 8'h00, 8'h00, 0, "AND  00 & 00 = 00");
			apply_test(0, 2'b11, AND_OP, 8'hFF, 8'hFF, 0, "AND  FF & FF = FF");
			apply_test(0, 2'b11, AND_OP, 8'hFF, 8'h00, 0, "AND  FF & 00 = 00");
			apply_test(0, 2'b11, AND_OP, 8'hF0, 8'h0F, 0, "AND  F0 & 0F = 00");
			apply_test(0, 2'b11, AND_OP, 8'hAA, 8'h55, 0, "AND  AA & 55 = 00");
			apply_test(0, 2'b11, AND_OP, 8'hAA, 8'hFF, 0, "AND  AA & FF = AA");
			apply_test(0, 2'b01, AND_OP, 8'hAA, 8'hBB, 0, "AND  ERR valid=01");
			apply_test(0, 2'b10, AND_OP, 8'hAA, 8'hBB, 0, "AND  ERR valid=10");
			apply_test(0, 2'b00, AND_OP, 8'hAA, 8'hBB, 0, "AND  ERR valid=00");
		end
	endtask
	task test_NAND_OP();
		begin
			apply_test(0, 2'b11, NAND_OP, 8'hFF, 8'hFF, 0, "NAND  FF & FF = 00");
			apply_test(0, 2'b11, NAND_OP, 8'h00, 8'h00, 0, "NAND  00 & 00 = FF");
			apply_test(0, 2'b11, NAND_OP, 8'hF0, 8'h0F, 0, "NAND  F0 & 0F = FF");
			apply_test(0, 2'b11, NAND_OP, 8'hAA, 8'h55, 0, "NAND  AA & 55 = FF");
			apply_test(0, 2'b11, NAND_OP, 8'hAA, 8'hAA, 0, "NAND  AA & AA = 55");
			apply_test(0, 2'b00, NAND_OP, 8'hAA, 8'hBB, 0, "NAND  ERR valid=00");
		end
	endtask
	task test_OR_OP();
		begin
			apply_test(0, 2'b11, OR_OP, 8'h00, 8'h00, 0, "OR  00 | 00 = 00");
			apply_test(0, 2'b11, OR_OP, 8'hFF, 8'h00, 0, "OR  FF | 00 = FF");
			apply_test(0, 2'b11, OR_OP, 8'hF0, 8'h0F, 0, "OR  F0 | 0F = FF");
			apply_test(0, 2'b11, OR_OP, 8'hAA, 8'h55, 0, "OR  AA | 55 = FF");
			apply_test(0, 2'b01, OR_OP, 8'hAA, 8'hBB, 0, "OR  ERR valid=01");
		end
	endtask
	task test_NOR_OP();
		begin
			apply_test(0, 2'b11, NOR_OP, 8'h00, 8'h00, 0, "NOR  00 | 00 = FF");
			apply_test(0, 2'b11, NOR_OP, 8'hFF, 8'hFF, 0, "NOR  FF | FF = 00");
			apply_test(0, 2'b11, NOR_OP, 8'hF0, 8'h0F, 0, "NOR  F0 | 0F = 00");
			apply_test(0, 2'b11, NOR_OP, 8'hAA, 8'h55, 0, "NOR  AA | 55 = 00");
			apply_test(0, 2'b10, NOR_OP, 8'hAA, 8'hBB, 0, "NOR  ERR valid=10");
		end
	endtask
	task test_XOR_OP();
		begin
			apply_test(0, 2'b11, XOR_OP, 8'hF0, 8'h0F, 0, "XOR  F0^0F = FF");
			apply_test(0, 2'b11, XOR_OP, 8'h00, 8'h00, 0, "XOR  00^00 = 00");
			apply_test(0, 2'b11, XOR_OP, 8'h00, 8'hFF, 0, "XOR  00^FF = FF");
			apply_test(0, 2'b11, XOR_OP, 8'hFF, 8'hFF, 0, "XOR  FF^FF = 00");
			apply_test(0, 2'b11, XOR_OP, 8'hAA, 8'h55, 0, "XOR  AA^55 = FF");
			apply_test(0, 2'b00, XOR_OP, 8'hAA, 8'hBB, 0, "XOR  ERR valid=00");
		end
	endtask
	task test_XNOR_OP();
		begin
			apply_test(0, 2'b11, XNOR_OP, 8'h00, 8'h00, 0, "XNOR  00~^00 = FF");
			apply_test(0, 2'b11, XNOR_OP, 8'hAA, 8'h55, 0, "XNOR  AA~^55 = 00");
			apply_test(0, 2'b11, XNOR_OP, 8'hFF, 8'hFF, 0, "XNOR  FF~^FF = FF");
			apply_test(0, 2'b11, XNOR_OP, 8'hF0, 8'h0F, 0, "XNOR  F0~^0F = 00");
			apply_test(0, 2'b11, XNOR_OP, 8'hAA, 8'hFF, 0, "XNOR  AA~^FF = AA");
			apply_test(0, 2'b01, XNOR_OP, 8'hAA, 8'hBB, 0, "XNOR  ERR valid=01");
		end
	endtask
	task test_NOT_A();
		begin
			apply_test(0, 2'b01, NOT_A, 8'h00, 8'h00, 0, "NOT_A  ~00=FF  valid=01");
			apply_test(0, 2'b01, NOT_A, 8'hFF, 8'h00, 0, "NOT_A  ~FF=00  valid=01");
			apply_test(0, 2'b01, NOT_A, 8'hAA, 8'h00, 0, "NOT_A  ~AA=55  valid=01");
			apply_test(0, 2'b01, NOT_A, 8'h55, 8'h00, 0, "NOT_A  ~55=AA  valid=01");
			apply_test(0, 2'b11, NOT_A, 8'hF0, 8'hBB, 0, "NOT_A  valid=11");
			apply_test(0, 2'b10, NOT_A, 8'hAA, 8'hBB, 0, "NOT_A  ERR valid=10");
			apply_test(0, 2'b00, NOT_A, 8'hAA, 8'hBB, 0, "NOT_A  ERR valid=00");
		end
	endtask
	task test_NOT_B();
		begin
			apply_test(0, 2'b10, NOT_B, 8'h00, 8'h00, 0, "NOT_B  ~00=FF  valid=10");
			apply_test(0, 2'b10, NOT_B, 8'h00, 8'hFF, 0, "NOT_B  ~FF=00  valid=10");
			apply_test(0, 2'b10, NOT_B, 8'h00, 8'hAA, 0, "NOT_B  ~AA=55  valid=10");
			apply_test(0, 2'b10, NOT_B, 8'h00, 8'h55, 0, "NOT_B  ~55=AA  valid=10");
			apply_test(0, 2'b11, NOT_B, 8'h55, 8'hAA, 0, "NOT_B  valid=11        ");
			apply_test(0, 2'b01, NOT_B, 8'hAA, 8'hBB, 0, "NOT_B  ERR valid=01");
			apply_test(0, 2'b00, NOT_B, 8'hAA, 8'hBB, 0, "NOT_B  ERR valid=00");
		end
	endtask
	task test_SHR_A();
		begin
			apply_test(0, 2'b01, SHR_A, 8'hAA, 8'h00, 0, "SHR_A  AA>>1 = 55");
			apply_test(0, 2'b01, SHR_A, 8'hFF, 8'h00, 0, "SHR_A  FF>>1 = 7F");
			apply_test(0, 2'b01, SHR_A, 8'h01, 8'h00, 0, "SHR_A  01>>1 = 00");
			apply_test(0, 2'b01, SHR_A, 8'h80, 8'h00, 0, "SHR_A  80>>1 = 40");
			apply_test(0, 2'b01, SHR_A, 8'h00, 8'h00, 0, "SHR_A  00>>1 = 00");
			apply_test(0, 2'b11, SHR_A, 8'hCC, 8'hBB, 0, "SHR_A  valid=11  ");
			apply_test(0, 2'b10, SHR_A, 8'hAA, 8'hBB, 0, "SHR_A  ERR valid=10");
			apply_test(0, 2'b00, SHR_A, 8'hAA, 8'hBB, 0, "SHR_A  ERR valid=00");
		end
	endtask
	task test_SHL_A();
		begin
			apply_test(0, 2'b01, SHL_A, 8'h55, 8'h00, 0, "SHL_A  55<<1 = AA");
			apply_test(0, 2'b01, SHL_A, 8'hFF, 8'h00, 0, "SHL_A  FF<<1 = FE");
			apply_test(0, 2'b01, SHL_A, 8'h80, 8'h00, 0, "SHL_A  80<<1 = 00");
			apply_test(0, 2'b01, SHL_A, 8'h01, 8'h00, 0, "SHL_A  01<<1 = 02");
			apply_test(0, 2'b01, SHL_A, 8'h00, 8'h00, 0, "SHL_A  00<<1 = 00");
			apply_test(0, 2'b11, SHL_A, 8'h3C, 8'hBB, 0, "SHL_A  valid=11  ");
			apply_test(0, 2'b10, SHL_A, 8'hAA, 8'hBB, 0, "SHL_A  ERR valid=10");
		end
	endtask
	task test_SHR_B();
		begin
			apply_test(0, 2'b10, SHR_B, 8'h00, 8'hAA, 0, "SHR_B  AA>>1 = 55");
			apply_test(0, 2'b10, SHR_B, 8'h00, 8'hFF, 0, "SHR_B  FF>>1 = 7F");
			apply_test(0, 2'b10, SHR_B, 8'h00, 8'h01, 0, "SHR_B  01>>1 = 00");
			apply_test(0, 2'b10, SHR_B, 8'h00, 8'h80, 0, "SHR_B  80>>1 = 40");
			apply_test(0, 2'b11, SHR_B, 8'hAA, 8'hCC, 0, "SHR_B  valid=11  ");
			apply_test(0, 2'b01, SHR_B, 8'hAA, 8'hBB, 0, "SHR_B  ERR valid=01");
		end
	endtask
	task test_SHL_B();
		begin
			apply_test(0, 2'b10, SHL_B, 8'h00, 8'h55, 0, "SHL_B  55<<1 = AA");
			apply_test(0, 2'b10, SHL_B, 8'h00, 8'hFF, 0, "SHL_B  FF<<1 = FE");
			apply_test(0, 2'b10, SHL_B, 8'h00, 8'h80, 0, "SHL_B  80<<1 = 00");
			apply_test(0, 2'b10, SHL_B, 8'h00, 8'h01, 0, "SHL_B  01<<1 = 02");
			apply_test(0, 2'b11, SHL_B, 8'hAA, 8'h3C, 0, "SHL_B  valid=11  ");
			apply_test(0, 2'b01, SHL_B, 8'hAA, 8'hBB, 0, "SHL_B  ERR valid=01");
		end
	endtask
	task test_ROL_A_B();
		begin
			apply_test(0, 2'b11, ROL_A_B, 8'hAA, 8'd0, 0, "ROL_A_B  AA rol 0  = AA");
			apply_test(0, 2'b11, ROL_A_B, 8'h01, 8'd1, 0, "ROL_A_B  01 rol 1  = 02");
			apply_test(0, 2'b11, ROL_A_B, 8'h80, 8'd1, 0, "ROL_A_B  80 rol 1  = 01");
			apply_test(0, 2'b11, ROL_A_B, 8'hAA, 8'd1, 0, "ROL_A_B  AA rol 1  = 55");
			apply_test(0, 2'b11, ROL_A_B, 8'hAA, 8'd3, 0, "ROL_A_B  AA rol 3");
			apply_test(0, 2'b11, ROL_A_B, 8'hAA, 8'd4, 0, "ROL_A_B  AA rol 4");
			apply_test(0, 2'b11, ROL_A_B, 8'hFF, 8'd4, 0, "ROL_A_B  FF rol 4  = FF");
			apply_test(0, 2'b11, ROL_A_B, 8'hAA, 8'd7, 0, "ROL_A_B  AA rol 7");
			apply_test(0, 2'b11, ROL_A_B, 8'hAA, 8'd8, 0, "ROL_A_B  AA rol 8  = AA");
			apply_test(0, 2'b11, ROL_A_B, 8'h00, 8'd5, 0, "ROL_A_B  00 rol 5  = 00");
			apply_test(0, 2'b11, ROL_A_B, 8'hAA, 8'd9, 0, "ROL_A_B  ERR rol   9>WIDTH");
			apply_test(0, 2'b11, ROL_A_B, 8'hAA, 8'hFF,0, "ROL_A_B  ERR rol  FF>WIDTH");
		end
	endtask
	task test_ROR_A_B();
		begin
			apply_test(0, 2'b11, ROR_A_B, 8'hAA, 8'd0, 0, "ROR_A_B  AA ror 0  = AA");
			apply_test(0, 2'b11, ROR_A_B, 8'h01, 8'd1, 0, "ROR_A_B  01 ror 1  = 80");
			apply_test(0, 2'b11, ROR_A_B, 8'h80, 8'd1, 0, "ROR_A_B  80 ror 1  = 40");
			apply_test(0, 2'b11, ROR_A_B, 8'hAA, 8'd1, 0, "ROR_A_B  AA ror 1  = 55");
			apply_test(0, 2'b11, ROR_A_B, 8'hAA, 8'd3, 0, "ROR_A_B  AA ror 3");
			apply_test(0, 2'b11, ROR_A_B, 8'hAA, 8'd4, 0, "ROR_A_B  AA ror 4");
			apply_test(0, 2'b11, ROR_A_B, 8'hFF, 8'd4, 0, "ROR_A_B  FF ror 4  = FF");
			apply_test(0, 2'b11, ROR_A_B, 8'hAA, 8'd7, 0, "ROR_A_B  AA ror 7");
			apply_test(0, 2'b11, ROR_A_B, 8'hAA, 8'd8, 0, "ROR_A_B  AA ror 8  = AA");
			apply_test(0, 2'b11, ROR_A_B, 8'h00, 8'd5, 0, "ROR_A_B  00 ror 5  = 00");
			apply_test(0, 2'b11, ROR_A_B, 8'hAA, 8'd9, 0, "ROR_A_B  ERR ror  9>WIDTH");
			apply_test(0, 2'b11, ROR_A_B, 8'hAA, 8'hFF,0, "ROR_A_B  ERR ror FF>WIDTH");
		end
	endtask
	task apply_test(
		input t_mode,
		input [1:0] t_inp_valid,
		input [CMD_WIDTH-1:0] t_cmd,
		input [WIDTH-1:0] t_opa,
		input [WIDTH-1:0] t_opb,
		input t_cin,
		input [80*8:1] test_name
		);
		begin
			@(negedge clk);
			mode = t_mode;
			inp_valid = t_inp_valid;
			cmd = t_cmd;
			opa = t_opa;
			opb = t_opb;
			cin = t_cin;
			@(posedge clk);
			@(posedge clk);
			#0.5;
			test_count = test_count + 1;
			$display("TEST = %0d | TEST CASE : %0s", test_count, test_name);
			$display("MODE=%0b | CMD=%0d | INP_VALID: %0b | CIN: %0b", mode, cmd, inp_valid, cin);
			$display("OPA=%0h (%0d)  | OPB=%0h (%0d) | CIN=%0b", opa, opa, opb, opb, cin);
			compare_outputs();
		end
	endtask
	reg match;
	task compare_outputs;
		begin
			match = (res_dut == res_ref) && (cout_dut == cout_ref) && (oflow_dut == oflow_ref) && (g_dut == g_ref) && (l_dut == l_ref) &&
				(e_dut == e_ref) && (err_dut == err_ref);
			if(match) begin
				pass_count = pass_count + 1;
				$display("PASS");
				$display("---------------------------------------------");
			end
			else begin
				fail_count = fail_count + 1;
				$display("FAIL");
				display_mismatch();
				$display("---------------------------------------------");
			end
		end
	endtask
    task display_mismatch();
        begin
            $display("-----DUT: RES=0x%h | COUT=%b | OFLOW=%b | G=%b | E=%b | L=%b | ERR=%b-----",
                     res_dut, cout_dut, oflow_dut, g_dut, e_dut, l_dut, err_dut);
            $display("-----REF: RES=0x%h | COUT=%b | OFLOW=%b | G=%b | E=%b | L=%b | ERR=%b-----",
                     res_ref, cout_ref, oflow_ref, g_ref, e_ref, l_ref, err_ref);
        end
    endtask
endmodule
