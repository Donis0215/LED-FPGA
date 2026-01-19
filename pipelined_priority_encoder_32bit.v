module encoder(
    input clk,
    input reset,
    input [31:0] ml,
    output reg [4:0] match_label,
    output reg match_hit
);


    // 延遲 ml 訊號，確保每一級看的是正確的時間點
    reg [31:0] ml_d1, ml_d2, ml_d3;

    // 第一級 8-bit 的結果
    reg [4:0] stg1_label;
    reg       stg1_hit;

    // 第二級 8-bit 的結果
    reg [4:0] stg2_label;
    reg       stg2_hit;

    // 第三級 8-bit 的結果
    reg [4:0] stg3_label;
    reg       stg3_hit;

    // --- 第一級：處理 ml[7:0] ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stg1_hit <= 0;
            stg1_label <= 5'd0;
            ml_d1 <= 32'd0;
        end else begin
            ml_d1 <= ml; // 將 ml 傳給下一拍使用
            casez(ml[7:0])
                8'bzzzzzzz1: begin stg1_hit <= 1; stg1_label <= 5'd0; end
                8'bzzzzzz10: begin stg1_hit <= 1; stg1_label <= 5'd1; end
                8'bzzzzz100: begin stg1_hit <= 1; stg1_label <= 5'd2; end
                8'bzzzz1000: begin stg1_hit <= 1; stg1_label <= 5'd3; end
                8'bzzz10000: begin stg1_hit <= 1; stg1_label <= 5'd4; end
                8'bzz100000: begin stg1_hit <= 1; stg1_label <= 5'd5; end
                8'bz1000000: begin stg1_hit <= 1; stg1_label <= 5'd6; end
                8'b10000000: begin stg1_hit <= 1; stg1_label <= 5'd7; end
                default:     begin stg1_hit <= 0; stg1_label <= 5'd0; end
            endcase
        end
    end

    // --- 第二級：看第一級結果，若沒中才處理 ml_d1[15:8] ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stg2_hit <= 0;
            stg2_label <= 5'd0;
            ml_d2 <= 32'd0;
        end else begin
            ml_d2 <= ml_d1; // 繼續傳遞資料
            if (stg1_hit) begin 
                stg2_hit <= stg1_hit;
                stg2_label <= stg1_label;
            end else begin
                casez(ml_d1[15:8]) // 使用延遲一拍的 ml
                    8'bzzzzzzz1: begin stg2_hit <= 1; stg2_label <= 5'd8;  end
                    8'bzzzzzz10: begin stg2_hit <= 1; stg2_label <= 5'd9;  end
                    8'bzzzzz100: begin stg2_hit <= 1; stg2_label <= 5'd10; end
                    8'bzzzz1000: begin stg2_hit <= 1; stg2_label <= 5'd11; end
                    8'bzzz10000: begin stg2_hit <= 1; stg2_label <= 5'd12; end
                    8'bzz100000: begin stg2_hit <= 1; stg2_label <= 5'd13; end
                    8'bz1000000: begin stg2_hit <= 1; stg2_label <= 5'd14; end
                    8'b10000000: begin stg2_hit <= 1; stg2_label <= 5'd15; end
                    default:     begin stg2_hit <= 0; stg2_label <= 5'd0;  end
                endcase
            end
        end
    end

    // --- 第三級：看第二級結果，若沒中才處理 ml_d2[23:16] ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stg3_hit <= 0;
            stg3_label <= 5'd0;
            ml_d3 <= 32'd0;
        end else begin
            ml_d3 <= ml_d2;
            if (stg2_hit) begin
                stg3_hit <= stg2_hit;
                stg3_label <= stg2_label;
            end else begin
                casez(ml_d2[23:16]) // 使用延遲兩拍的 ml
                    8'bzzzzzzz1: begin stg3_hit <= 1; stg3_label <= 5'd16; end
                    8'bzzzzzz10: begin stg3_hit <= 1; stg3_label <= 5'd17; end
                    8'bzzzzz100: begin stg3_hit <= 1; stg3_label <= 5'd18; end
                    8'bzzzz1000: begin stg3_hit <= 1; stg3_label <= 5'd19; end
                    8'bzzz10000: begin stg3_hit <= 1; stg3_label <= 5'd20; end
                    8'bzz100000: begin stg3_hit <= 1; stg3_label <= 5'd21; end
                    8'bz1000000: begin stg3_hit <= 1; stg3_label <= 5'd22; end
                    8'b10000000: begin stg3_hit <= 1; stg3_label <= 5'd23; end
                    default:     begin stg3_hit <= 0; stg3_label <= 5'd0;  end
                endcase
            end
        end
    end

    // --- 最終級：看第三級結果，若沒中才處理 ml_d3[31:24] ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            match_hit <= 0;
            match_label <= 5'd0;
        end else begin
            if (stg3_hit) begin
                match_hit <= stg3_hit;
                match_label <= stg3_label;
            end else begin
                casez(ml_d3[31:24]) // 使用延遲三拍的 ml
                    8'bzzzzzzz1: begin match_hit <= 1; match_label <= 5'd24; end
                    8'bzzzzzz10: begin match_hit <= 1; match_label <= 5'd25; end
                    8'bzzzzz100: begin match_hit <= 1; match_label <= 5'd26; end
                    8'bzzzz1000: begin match_hit <= 1; match_label <= 5'd27; end
                    8'bzzz10000: begin match_hit <= 1; match_label <= 5'd28; end
                    8'bzz100000: begin match_hit <= 1; match_label <= 5'd29; end
                    8'bz1000000: begin match_hit <= 1; match_label <= 5'd30; end
                    8'b10000000: begin match_hit <= 1; match_label <= 5'd31; end
                    default:     begin match_hit <= 0; match_label <= 5'd0;  end
                endcase
            end
        end
    end

endmodule