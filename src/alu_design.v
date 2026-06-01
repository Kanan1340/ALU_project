`default_nettype none

module alu_design #(
    parameter WIDTH = 8,
    parameter CMD_WIDTH = 4)
	
(
    input wire clk, rst, ce,
    input wire mode,
    input wire[1:0] inp_valid,
    input wire[CMD_WIDTH-1:0] cmd,

    input wire[WIDTH-1:0] opa,
    input wire[WIDTH-1:0] opb,
    input wire cin,

    output reg[2*WIDTH-1:0] res,
    output reg cout, oflow,
    output reg g, l, e,

    output reg err
);

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

reg mode_r;
reg [1:0] inp_valid_r;
reg [CMD_WIDTH-1:0] cmd_r;
reg [WIDTH-1:0] opa_r, opb_r;
reg cin_r;
reg [2*WIDTH-1:0]res_next;
reg cout_next, oflow_next;
reg g_next, l_next, e_next;
reg err_next;
reg [WIDTH:0] temp;
reg signed [WIDTH-1:0]sopa, sopb;
reg signed [2*WIDTH-1:0]s_res;
reg [2*WIDTH-1:0] res_mul;
reg oflow_mul;
reg is_mul_r;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        mode_r      <= 0;
        inp_valid_r <= 0;
        cmd_r       <= 0;
        opa_r       <= 0;
        opb_r       <= 0;
        cin_r       <= 0;
    end
    else if(ce) begin     
        mode_r      <= mode;
        inp_valid_r <= inp_valid;
        cmd_r       <= cmd;
        opa_r       <= opa;
        opb_r       <= opb;
        cin_r       <= cin;
    end
end

always @(*) begin
		res_next = {2*WIDTH{1'b0}};
        cout_next = 1'b0;
        oflow_next = 1'b0;
        g_next = 1'b0;
        l_next = 1'b0;
        e_next = 1'b0;
        err_next = 1'b0;
        temp = {WIDTH+1{1'b0}};
		sopa = $signed(opa_r);
		sopb = $signed(opb_r);
		
        if(mode_r) begin
            case(cmd_r)
            ADD: begin
                if(inp_valid_r == 2'b11) begin
                    temp = opa_r + opb_r;
                    res_next = temp;
                    cout_next = temp[WIDTH];
                end else begin
					err_next = 1'b1;
				end
            end

            SUB: begin
                if(inp_valid_r == 2'b11) begin
                    temp = opa_r - opb_r;
                    res_next = temp;
					oflow_next = (opa_r < opb_r)? 1 : 0;
                end else begin
					err_next = 1'b1;
				end
            end

            ADD_CIN: begin
                if(inp_valid_r == 2'b11) begin
                    temp = opa_r + opb_r + cin_r;
                    res_next = temp;
                    cout_next = temp[WIDTH];
                end else begin
					err_next = 1'b1;
				end
            end

            SUB_CIN: begin
                if(inp_valid_r == 2'b11) begin
                    temp = opa_r - opb_r - cin_r;
                    res_next = temp;
					oflow_next = (opa_r < (opb_r + cin_r));
                end else begin
					err_next = 1'b1;
				end
            end

            INC_A: begin
                if(inp_valid_r == 2'b11 || inp_valid_r == 2'b01) begin
					temp = opa_r + 1'b1;
					res_next = temp[WIDTH-1:0];
					oflow_next = temp[WIDTH];
				end else begin
					err_next = 1'b1;
				end		
            end

            DEC_A: begin
                if(inp_valid_r == 2'b11 || inp_valid_r == 2'b01) begin
					temp = opa_r - 1'b1;
					res_next = temp[WIDTH-1:0];
					oflow_next = temp[WIDTH];
				end else begin
					err_next = 1'b1;
				end	
            end

            INC_B: begin
                if(inp_valid_r == 2'b11 || inp_valid_r == 2'b10)begin           
					temp = opb_r + 1'b1;
					res_next = temp[WIDTH-1:0];
					oflow_next = temp[WIDTH];
				end else begin
					err_next = 1'b1;
				end
            end

            DEC_B: begin
                if(inp_valid_r == 2'b11 || inp_valid_r == 2'b10)begin					
					temp = opb_r - 1'b1;
					res_next = temp[WIDTH-1:0];
					oflow_next = temp[WIDTH];
				end else begin
					err_next = 1'b1;
				end
            end

            CMP: begin
                if(inp_valid_r == 2'b11) begin
                    g_next = (opa_r > opb_r);
                    l_next = (opa_r < opb_r);
                    e_next = (opa_r == opb_r);
                end else err_next = 1'b1;
            end
 
            MUL_INC: begin
                if(inp_valid_r == 2'b11) begin
                    res_next = (opa_r + 1'b1) * (opb_r + 1'b1);
				end else err_next = 1'b1;
            end

            MUL_SHIFT: begin
                if(inp_valid_r == 2'b11)
                    res_next = (opa_r << 1) * opb_r;
				else err_next = 1'b1;
            end

            S_ADD: begin
                if(inp_valid_r == 2'b11) begin
                    s_res = sopa + sopb;
                    res_next = s_res;
                    oflow_next = ~(sopa[WIDTH-1] ^ sopb[WIDTH-1]) & (sopa[WIDTH-1] ^ res_next[WIDTH-1]);
					cout_next = res_next[WIDTH];
                    g_next = (sopa > sopb);
                    l_next = (sopa < sopb);
                    e_next = (sopa == sopb); 
                end else err_next = 1'b1;
            end

            S_SUB: begin
                if(inp_valid_r == 2'b11) begin
                    s_res = sopa - sopb;
                    res_next = s_res;
                    cout_next  = res_next[WIDTH];
                    oflow_next = (sopa[WIDTH-1] ^ sopb[WIDTH-1]) & (sopa[WIDTH-1] ^ res_next[WIDTH-1]);
                    g_next = (sopa > sopb);
                    l_next = (sopa < sopb);
                    e_next = (sopa == sopb);
                end else err_next = 1'b1;
            end
            default: begin
                res_next = 'd0;
            end
            endcase
        end
		
		else begin 
            case(cmd_r)
            AND_OP: if (inp_valid_r == 2'b11) 
						res_next = opa_r & opb_r;
					else err_next = 1'b1;				
            NAND_OP: if (inp_valid_r == 2'b11)
						res_next = ~(opa_r & opb_r);
					else err_next = 1'b1;
            OR_OP: if (inp_valid_r == 2'b11)
						res_next = opa_r | opb_r;
					else err_next = 1'b1;  
            NOR_OP: if (inp_valid_r == 2'b11)
						res_next = ~(opa_r | opb_r);
					else err_next = 1'b1;
            XOR_OP: if (inp_valid_r == 2'b11)
						res_next = opa_r ^ opb_r;
					else err_next = 1'b1;
            XNOR_OP: if (inp_valid_r == 2'b11)
						res_next = ~(opa_r ^ opb_r);
					else err_next = 1'b1;
            NOT_A: if (inp_valid_r == 2'b11 || inp_valid_r == 2'b01)
						res_next = ~opa_r;
					else err_next = 1'b1;
            NOT_B: if (inp_valid_r == 2'b11 || inp_valid_r == 2'b10)
						res_next = ~opb_r;
					else err_next = 1'b1;
            SHR_A: if (inp_valid_r == 2'b11 || inp_valid_r == 2'b01)
						res_next = opa_r >> 1;
					else err_next = 1'b1;
            SHL_A: if (inp_valid_r == 2'b11 || inp_valid_r == 2'b01)
						res_next = opa_r << 1;
					else err_next = 1'b1;
            SHR_B: if (inp_valid_r == 2'b11 || inp_valid_r == 2'b10)
						res_next = opb_r >> 1;
					else err_next = 1'b1;
            SHL_B: if (inp_valid_r == 2'b11 || inp_valid_r == 2'b10)
						res_next = opb_r << 1;
					else err_next = 1'b1;
			ROL_A_B: begin
				if (inp_valid_r == 2'b11 && opb_r < WIDTH) begin
					res_next =(opa_r << opb_r) | (opa_r >> (WIDTH-opb_r));
					err_next = 1'bz;
				end else err_next = 1'b1;
            end
			ROR_A_B: begin
				if (inp_valid_r == 2'b11 && opb_r < WIDTH) begin
					res_next =(opa_r >> opb_r) | (opa_r << (WIDTH-opb_r));
					err_next = 1'bz;
				end else err_next = 1'b1;
            end
            default: begin
                res_next = 'd0;
            end
            endcase
        end
    end
		
	always @(posedge clk or posedge rst) begin

    if(rst) begin
        res <= 0;
        cout <= 0;
        oflow <= 0;
        g <= 0;
        l <= 0;
        e <= 0;
        err <= 0;
        res_mul <= 0;        
        oflow_mul <= 0;
        is_mul_r <= 0;
    end
    else if(ce) begin
        res_mul <= res_next;        
        oflow_mul <= oflow_next;
        is_mul_r <= (mode_r && ((cmd_r == MUL_INC) || (cmd_r == MUL_SHIFT)));
		cout <= cout_next;
		g <= g_next;
        l <= l_next;
        e <= e_next;
        err <= err_next;
        if(!is_mul_r) begin
            res <= res_next;
            oflow <= oflow_next;  
        end else begin
            res <= res_mul;
            oflow <= oflow_mul;
        end
    end
end
endmodule
