`timescale 1ns/10ps

module CONV(
    input           clk,
    input           reset,
    output reg      busy,   
    input           ready,  
            
    output reg [11:0] iaddr,
    input      [19:0] idata,  
    
    output reg        cwr,
    output reg [11:0] caddr_wr,
    output reg [19:0] cdata_wr,
    
    output reg        crd,
    output reg [11:0] caddr_rd,
    input      [19:0] cdata_rd,
    
    output reg [2:0]  csel
    );

    //=============================================================
    // 參數與變數定義
    //=============================================================
    localparam IDLE       = 3'd0;
    localparam L0_CALC    = 3'd1;
    localparam L0_WRITE   = 3'd2;
    localparam L1_ENABLE  = 3'd3; 
    localparam L1_CALC    = 3'd4;
    localparam L1_WRITE   = 3'd5;
    localparam FINISH     = 3'd6;

    localparam signed [19:0] BIAS = 20'h01310; 

    // --- 硬體化 KERNEL (可合成寫法) ---
    wire signed [19:0] KERNEL [0:8];
    assign KERNEL[0] = 20'h0A89E; assign KERNEL[1] = 20'h092D5; assign KERNEL[2] = 20'h06D43;
    assign KERNEL[3] = 20'h01004; assign KERNEL[4] = 20'hF8F71; assign KERNEL[5] = 20'hF6E54;
    assign KERNEL[6] = 20'hFA6D7; assign KERNEL[7] = 20'hFC834; assign KERNEL[8] = 20'hFAC19;

    reg [2:0]  current_state;
    reg [3:0]  cnt;
    reg [5:0]  x, y;   
    reg signed [44:0] acc;      
    reg signed [19:0] max_val;  
    
    reg signed [7:0] target_x, target_y;
    reg signed [19:0] pixel_val;

    //=============================================================
    // 主控制邏輯 (FSM)
    //=============================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            busy <= 0;
            cnt <= 0; x <= 0; y <= 0;
            acc <= 0; max_val <= 0;
            cwr <= 0; crd <= 0; csel <= 0;
            iaddr <= 0; caddr_wr <= 0; caddr_rd <= 0; cdata_wr <= 0;
        end else begin
            case (current_state)
            
                IDLE: begin
                    if (ready) begin
                        busy <= 1;
                        x <= 0; y <= 0; cnt <= 0; acc <= 0;
                        current_state <= L0_CALC;
                    end
                end

                // --- LAYER 0: Convolution ---
                L0_CALC: begin
                    cwr <= 0;
                    if (cnt < 9) begin
                        target_x = {2'b0, x} + (cnt % 3) - 1; 
                        target_y = {2'b0, y} + (cnt / 3) - 1;
                        if (target_x < 0 || target_x > 63 || target_y < 0 || target_y > 63)
                            iaddr <= 0; 
                        else
                            iaddr <= {target_y[5:0], target_x[5:0]};
                    end
                    
                    if (cnt > 0) begin
                        target_x = {2'b0, x} + ((cnt-1) % 3) - 1; 
                        target_y = {2'b0, y} + ((cnt-1) / 3) - 1;
                        if (target_x < 0 || target_x > 63 || target_y < 0 || target_y > 63)
                            pixel_val = 20'd0;
                        else
                            pixel_val = idata;
                        acc <= acc + (pixel_val * KERNEL[cnt-1]);
                    end

                    if (cnt == 9) begin
                        current_state <= L0_WRITE;
                    end else begin
                        cnt <= cnt + 1;
                    end
                end

                L0_WRITE: begin
                    csel <= 3'b001; 
                    cwr  <= 1;
                    caddr_wr <= {y[5:0], x[5:0]};
                    
                    if ( ($signed(acc) + $signed({BIAS, 16'b0})) < 0 )
                        cdata_wr <= 20'd0;
                    else
                        cdata_wr <= ($signed(acc) + $signed({BIAS, 16'b0}) + 45'h00000008000) >>> 16;
                    
                    cnt <= 0; acc <= 0;
                    
                    if (x == 63) begin
                        x <= 0;
                        if (y == 63) begin
                            y <= 0;
                            current_state <= L1_ENABLE; 
                        end else begin
                            y <= y + 1;
                            current_state <= L0_CALC;
                        end
                    end else begin
                        x <= x + 1;
                        current_state <= L0_CALC;
                    end
                end

                // --- LAYER 1: Max-pooling ---
                L1_ENABLE: begin
                    cwr <= 0; crd <= 0;
                    csel <= 3'b001; 
                    cnt <= 0;
                    current_state <= L1_CALC;
                end

                L1_CALC: begin
                    crd <= 1;
                    csel <= 3'b001; 
                    
                    if (cnt < 4) begin
                        target_x = {2'b0, x, 1'b0} + (cnt[0]); 
                        target_y = {2'b0, y, 1'b0} + (cnt[1]); 
                        caddr_rd <= {target_y[5:0], target_x[5:0]};
                    end
                    
                    if (cnt > 0) begin
                        if (cnt == 1) max_val <= cdata_rd;
                        else if ($signed(cdata_rd) > $signed(max_val)) max_val <= cdata_rd;
                    end
                    
                    if (cnt == 4) begin
                        current_state <= L1_WRITE;
                    end else begin
                        cnt <= cnt + 1;
                    end
                end

                L1_WRITE: begin
                    crd <= 0;
                    csel <= 3'b011; 
                    cwr <= 1;
                    caddr_wr <= {y[4:0], x[4:0]};
                    cdata_wr <= max_val;
                    
                    if (x == 31) begin
                        x <= 0;
                        if (y == 31) begin 
                            current_state <= FINISH; 
                            cnt <= 0; // 重置 cnt 用於 FINISH 緩衝
                        end else begin 
                            y <= y + 1; 
                            current_state <= L1_ENABLE;
                        end
                    end else begin
                        x <= x + 1;
                        current_state <= L1_ENABLE;
                    end
                end
                
                // --- FINISH: 額外緩衝一拍確保 GLS 寫入正確 ---
                FINISH: begin
                    cwr  <= 0; // 關閉寫入
                    if (cnt == 0) begin
                        cnt <= cnt + 1; // 多等一拍時鐘
                    end else begin
                        busy <= 0;     // 最後才放掉 busy
                        current_state <= IDLE;
                    end
                end

                default: current_state <= IDLE;
            endcase
        end
    end
endmodule
