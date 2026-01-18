module lab5(clk, reset, column, sel, led, led_com);
input clk, reset;      //pinW16,C16
input[2:0]column;    // pin AA13, AB12, Y16
output[2:0]sel;       // pin AB10, AB11, AA12
output[9:0]led;       // pin E2, D3, C2, C1 ,L2, L1, G2, G1, U2, N1
output led_com;      // pin N20
assign led_com= 1'b1;
wire clk_sel;
wire[3:0] key_code;
freq_div#(13) M1 (
        .clk_in(clk), 
        .reset(reset), 
        .clk_out(clk_sel)
    );

    // 2. 鍵盤控制核心：處理掃描、解碼與緩衝
    key_led M2 (
        .clk_sel(clk_sel), 
        .reset(reset), 
        .column(column), 
        .sel(sel), 
        .key_code(key_code)
    );

    // 3. LED 顯示：將 key_code 轉換成 10 顆 LED 的訊號
    bcd_led M3 (
        .key_code(key_code), 
        .led(led)
    );
endmodule


module key_decode(sel, column, press, scan_code);
input[2:0]sel;//當 sel = 3'b000：FPGA 點名第一列（數字 1, 2, 3）。這時只有第一列是有電的，其他列都沒電。當 sel = 3'b001：FPGA 點名第二列（數字 4, 5, 6）。
input[2:0] column;
output press;
output[3:0] scan_code;
reg[3:0] scan_code;
reg press;
always@(sel or column) begin
case(sel)
3'b000:
case(column)
3'b011: begin scan_code= 4'b0001; press = 1'b1; end // 1
3'b101: begin scan_code= 4'b0010; press = 1'b1; end // 2
3'b110: begin scan_code= 4'b0011; press = 1'b1; end // 3
default: begin scan_code= 4'b1111; press = 1'b0; end
endcase
3'b001:
case(column)
3'b011: begin scan_code= 4'b0100; press = 1'b1; end // 4
    3'b101: begin scan_code= 4'b0101; press = 1'b1; end // 5
    3'b110: begin scan_code= 4'b0110; press = 1'b1; end // 6
default: begin scan_code= 4'b1111; press = 1'b0; end
endcase
3'b010:
case(column)
3'b011: begin scan_code = 4'b0111; press = 1'b1; end // 7
3'b101: begin scan_code = 4'b1000; press = 1'b1; end // 8
3'b110: begin scan_code = 4'b1001; press = 1'b1; end // 9
default: begin scan_code = 4'b1111; press = 1'b0; end
endcase
3'b011:
case(column)
3'b101: begin scan_code = 4'b0000; press = 1'b1; end // 0
default: begin scan_code = 4'b1111; press = 1'b0; end

endcase
default:
begin scan_code= 4'b1111; press = 1'b0; end
endcase
end
endmodule



module key_buf(clk, rst, press, scan_code, key_code);//如果沒有 key_buf：當 FPGA 點名到第一排（1, 2, 3）時，如果你按了「2」，LED 會亮一下；但萬分之一秒後，FPGA 點名到第二排（4, 5, 6），這時你沒按第二排的按鈕，scan_code 就會變回 1111（無效碼），燈就滅了。
input clk, rst, press;
input[3:0] scan_code;
output[3:0]key_code;
reg[3:0]key_code;
always@(posedge clk or posedge rst) begin
if(rst)
key_code= 4'b1111;// initial value
else
key_code<= press ? scan_code:key_code;
end
endmodule
module bcd_led(key_code, led);//BCD碼轉LED輸出電路
input[3:0]key_code;
output[9:0]led;
reg[9:0]led;
always@(key_code) begin
case(key_code)
            4'b0000: led = 10'b0000000001; // 數字 0，點亮第 1 顆燈
            4'b0001: led = 10'b0000000010; // 數字 1
            4'b0010: led = 10'b0000000100; // 數字 2
            4'b0011: led = 10'b0000001000; // 數字 3
            4'b0100: led = 10'b0000010000; // 數字 4
            4'b0101: led = 10'b0000100000; // 數字 5
            4'b0110: led = 10'b0001000000; // 數字 6
            4'b0111: led = 10'b0010000000; // 數字 7
            4'b1000: led = 10'b0100000000; // 數字 8
            4'b1001: led = 10'b1000000000; // 數字 9
            default: led = 10'b0000000000; // 初始值 1111 或其他狀況時全滅
        endcase
end
endmodule

module key_led(clk_sel, reset, column, sel, key_code);
input clk_sel, reset;
input[2:0]column;
output[2:0]sel;
output[3:0] key_code;
wire press;
wire[3:0] scan_code, key_code;
count4 M1 (
        .clk(clk_sel), 
        .rst(reset), 
        .sel(sel)
    );

    // 實體化 2: 鍵盤解碼 (實驗一)
    // 把目前的 sel 與讀到的 column 轉成數字 scan_code
    key_decode M2 (
        .sel(sel), 
        .column(column), 
        .press(press), 
        .scan_code(scan_code)
    );

    // 實體化 3: 鍵盤緩衝 (實驗二)
    // 當 press 為 1 時，把 scan_code 存進 key_code
    key_buf M3 (
        .clk(clk_sel), 
        .rst(reset), 
        .press(press), 
        .scan_code(scan_code), 
        .key_code(key_code)
    );
endmodule

module count4(clk, rst, sel);//它的工作只有一個：不停地數 0, 1, 2, 3，然後再回到 0。
    input clk, rst;
    output reg [2:0] sel;

    always @(posedge clk or posedge rst) begin
        if (rst)
            sel <= 3'b000;
        else if (sel >= 3'b011) // 當掃描到第 4 列時回到第 1 列
            sel <= 3'b000;
        else
            sel <= sel + 1'b1;
    end
endmodule

module freq_div(clk_in, reset, clk_out);
parameter exp = 20;   
input clk_in, reset;
output clk_out;
reg[exp-1:0] divider;
integer i;
assign clk_out= divider[exp-1];
always@ (posedge clk_in or posedge reset) //正緣觸發
begin
if(reset)
for(i=0; i < exp; i=i+1)
divider[i] = 1'b0;
else
divider = divider+ 1'b1;
end
endmodule