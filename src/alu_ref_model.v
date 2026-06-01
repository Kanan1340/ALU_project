module alu_reference_model #(
    parameter WIDTH = 8,
    parameter CMD_WIDTH = 4)
(
    input wire [WIDTH-1:0] opa, opb,
    input wire cin,
    input wire mode,
    input wire [CMD_WIDTH-1:0] cmd,
    input wire [1:0] inp_valid,
    output reg [2*WIDTH-1:0] res,
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

    reg signed [WIDTH-1:0] sopa, sopb;
    reg signed [2*WIDTH-1:0] s_res;

	reg [WIDTH:0] temp;

    always @(*) begin

        res = {2*WIDTH{1'b0}};
        cout = 1'b0;
        oflow = 1'b0;
        g = 1'b0;
        l = 1'b0;
        e = 1'b0;
        err = 1'b0;
		temp = {WIDTH+1{1'b0}};
		sopa = $signed(opa);
        sopb = $signed(opb);

        if (mode) begin  
            case(cmd)
                ADD: begin
                    if(inp_valid == 2'b11) begin
						temp = opa + opb;
						res = temp;
						cout = temp[WIDTH];
                    end else err = 1'b1;
                end

                SUB: begin
                    if(inp_valid == 2'b11) begin
                        temp = opa - opb;
						res = temp;
                        oflow = (opa < opb);
                    end else err = 1'b1;
                end

                ADD_CIN: begin
                    if(inp_valid == 2'b11) begin
						temp = opa + opb + cin;
						res = temp;
						cout = temp[WIDTH];
                    end else err = 1'b1;
					end

                SUB_CIN: begin
                    if(inp_valid == 2'b11) begin
                        temp = opa - opb - cin;
						res = temp;
                        oflow = (opa < (opb + cin));
                    end else err = 1'b1;
                end

                INC_A: begin
                    if(inp_valid == 2'b11 || inp_valid == 2'b01) begin
						temp = opa + 1;
						res = temp[WIDTH-1:0];
						oflow = temp[WIDTH];
                    end else err = 1'b1;
                end

                DEC_A: begin
                    if(inp_valid == 2'b11 || inp_valid == 2'b01) begin				
						temp = opa - 1;
						res = temp[WIDTH-1:0];
						oflow = temp[WIDTH];
                    end else err = 1'b1;
                end

                INC_B: begin
                    if(inp_valid == 2'b11 || inp_valid == 2'b10) begin
						temp = opb + 1;
						res = temp[WIDTH-1:0];
						oflow = temp[WIDTH];
                    end else err = 1'b1;
                end

                DEC_B: begin
                    if(inp_valid == 2'b11 || inp_valid == 2'b10) begin
						temp = opb - 1;
						res = temp[WIDTH-1:0];
						oflow = temp[WIDTH];
                    end else err = 1'b1;
                end

                CMP: begin
                    if(inp_valid == 2'b11) begin
                        g = (opa > opb);
                        l = (opa < opb);
                        e = (opa == opb);
                    end else err = 1'b1;
                end

                MUL_INC: begin
                    if(inp_valid == 2'b11) begin
                        res = (opa + 1'b1) * (opb + 1'b1);
                    end else err = 1'b1;
					end

                MUL_SHIFT: begin
                    if(inp_valid == 2'b11) begin
                        res = (opa << 1) * opb;
                    end else err = 1'b1;
                end

                S_ADD: begin
                    if(inp_valid == 2'b11) begin
                        s_res = sopa + sopb;
                        res = s_res;
                        cout = (~sopa[WIDTH-1] & ~sopb[WIDTH-1] & s_res[WIDTH]);
						oflow = s_res[WIDTH-1] & (sopa[WIDTH-1] | sopb[WIDTH-1]);
                        g = (sopa > sopb);
                        l = (sopa < sopb);
                        e = (sopa == sopb);
                    end else err = 1'b1;
                end

                S_SUB: begin
                    if(inp_valid == 2'b11) begin
                        s_res = sopa - sopb;
                        res = s_res;
                        cout = (~sopa[WIDTH-1] & sopb[WIDTH-1] & s_res[WIDTH]);
                        oflow = s_res[WIDTH-1] & (sopa[WIDTH-1] | ~sopb[WIDTH-1]);
                        g = (sopa > sopb);
                        l = (sopa < sopb);
                        e = (sopa == sopb);
                    end else err = 1'b1;
                end

                default: res = {2*WIDTH{1'b0}};         
			endcase

        end else begin  
            case(cmd)
                AND_OP: begin
                    if(inp_valid == 2'b11) begin
                        res = opa & opb;
                    end else err = 1'b1;
                end

                NAND_OP: begin
                    if(inp_valid == 2'b11) begin
                        res = ~(opa & opb);
                    end else err = 1'b1;
                end

                OR_OP: begin
                    if(inp_valid == 2'b11) begin
                        res = opa | opb;
                    end else err = 1'b1;
                end

                NOR_OP: begin
                    if(inp_valid == 2'b11) begin
                        res = ~(opa | opb);
                    end else err = 1'b1;
                end

                XOR_OP: begin
                    if(inp_valid == 2'b11) begin
                        res = opa ^ opb;
                    end else err = 1'b1;
                end

                XNOR_OP: begin
                    if(inp_valid == 2'b11) begin
                        res = ~(opa ^ opb);
                    end else err = 1'b1;
                end

                NOT_A: begin
                    if(inp_valid == 2'b11 || inp_valid == 2'b01) begin
                        res = ~opa;
                    end else err = 1'b1;
                end

                NOT_B: begin
                    if(inp_valid == 2'b11 || inp_valid == 2'b10) begin
                        res = ~opb;
                    end else err = 1'b1;
                end

                SHR_A: begin
                    if(inp_valid == 2'b11 || inp_valid == 2'b01) begin
                        res = opa >> 1;
                    end else err = 1'b1;
                end

                SHL_A: begin
                    if(inp_valid == 2'b11 || inp_valid == 2'b01) begin
                        res = opa << 1;
                    end else err = 1'b1;
                end

                SHR_B: begin
                    if(inp_valid == 2'b11 || inp_valid == 2'b10) begin
                        res = opb >> 1;
                    end else err = 1'b1;
                end

                SHL_B: begin
                    if(inp_valid == 2'b11 || inp_valid == 2'b10) begin
                        res = opb << 1;
                    end else err = 1'b1;
                end

                ROL_A_B: begin
                    if(inp_valid == 2'b11 && opb < WIDTH) begin
                        res = (opa << opb) | (opa >> (WIDTH - opb));
						err = 1'bz;
                    end else err = 1'b1;
                end

                ROR_A_B: begin
                    if(inp_valid == 2'b11 && opb < WIDTH) begin
                        res = (opa >> opb) | (opa << (WIDTH - opb));
						err = 1'bz;
                    end else err = 1'b1;
                end

                default: res = {2*WIDTH{1'b0}};
            endcase
        end
    end

endmodule
