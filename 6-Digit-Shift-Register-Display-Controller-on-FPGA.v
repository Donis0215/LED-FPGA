module lab6 (clk, rst, column, sel, seg7);
input clk, rst;  //pin W16,C16
input[2:0]column;  // pin AA13, AB12, Y16
output[2:0]sel;  // pin AB10, AB11, AA12
output[6:0]seg7;  // pin AB7,AA7,AB6,AB5,AA9,Y9,AB8 
wire clk_sel;
wire[3:0] key_code;
freq_div #(13) u_div (
        .clk_in(clk), 
        .rst(rst), 
        .clk_out(clk_sel)
    );

    key_seg7_6dig u_key (
        .clk_sel(clk_sel), 
        .rst(rst), 
        .column(column), 
        .sel(sel), 
        .key_code(key_code)
    );

    // 修正點 3: bcd_in 必須連接到 key_code 訊號
    bcd_to_seg7 u_seg7 (
        .bcd_in(key_code), 
        .seg7(seg7)
    );
endmodule

module key_code_mux(display_code, sel, key_code);
input[23:0] display_code;
input[2:0]sel;
output[3:0] key_code;
assign key_code= (sel== 3'b101) ? display_code[3:0] :
 (sel== 3'b100) ? display_code[7:4] :
 (sel== 3'b011) ? display_code[11:8] :
 (sel== 3'b010) ? display_code[15:12] :
 (sel== 3'b001) ? display_code[19:16] :
 (sel== 3'b000) ? display_code[23:20] :  4'b1111;//如果 sel 指向第 1 位（3'b101），key_code 就拿 display_code 最右邊那格 [3:0];(sel == 3'b101)：這部分確實是 True 或 False。後面的結果：如果 True，它會把 display_code[3:0] 這 4 個位元的內容（比如是 4'b0101，也就是數字 5）交給 key_code。
endmodule

module key_seg7_6dig(clk_sel, rst, column, sel, key_code);//它就像是一個簡易計算機的輸入介面：你每按一個數字，原本的數字就會往左移一位，並騰出最右邊的位置顯示你剛按下的新數字，且同時管理 6 個七段顯示器的點亮工作
input clk_sel, rst;
input[2:0]column;
output[2:0]sel;
output[3:0]key_code;
wire press, press_valid;
wire[3:0] scan_code;
wire[23:0]display_code;
count6 u1(clk_sel, rst, sel);
key_decode u2(sel, column, press, scan_code);
debounce_ctl u3(clk_sel, rst, press, press_valid);
key_buf6 u4(clk_sel, rst, press_valid, scan_code, display_code);
key_code_mux u5(display_code, sel, key_code);
endmodule

module count6(clk, rst, sel);
input clk, rst;
output reg [2:0] sel;
always @(posedge clk or posedge rst) begin
if (rst)
sel <= 3'b000;
else if (sel >= 3'b101)
sel <= 3'b000;
else
sel <= sel + 1'b1;
end
endmodule

module key_decode(sel, column, press, scan_code);//decode the number you press
input[2:0]sel;//當 sel = 3'b000：FPGA 點名第一列（數字 1, 2, 3）。這時只有第一列是有電的，其他列都沒電。當 sel = 3'b001：FPGA 點名第二列（數字 4, 5, 6）。
input[2:0] column;
output press;
output[3:0] scan_code;
reg[3:0] scan_code;
reg press;
always@(*) begin
press = 1'b0;
scan_code = 4'b1111;
case(sel)
3'b000: begin
case(column)
3'b011: begin scan_code= 4'b0001; press = 1'b1; end // 1
3'b101: begin scan_code= 4'b0010; press = 1'b1; end // 2
3'b110: begin scan_code= 4'b0011; press = 1'b1; end // 3
default: begin scan_code= 4'b1111; press = 1'b0; end
endcase
end
3'b001: begin
case(column)
3'b011: begin scan_code= 4'b0100; press = 1'b1; end // 4
3'b101: begin scan_code= 4'b0101; press = 1'b1; end // 5
3'b110: begin scan_code= 4'b0110; press = 1'b1; end // 6
default: begin scan_code= 4'b1111; press = 1'b0; end
endcase
end
3'b010: begin
case(column)
3'b011: begin scan_code = 4'b0111; press = 1'b1; end // 7
3'b101: begin scan_code = 4'b1000; press = 1'b1; end // 8
3'b110: begin scan_code = 4'b1001; press = 1'b1; end // 9
default: begin scan_code = 4'b1111; press = 1'b0; end
endcase
end
3'b011: begin
case(column)
3'b101: begin scan_code = 4'b0000; press = 1'b1; end // 0
default: begin scan_code = 4'b1111; press = 1'b0; end
endcase
end
default:
begin scan_code= 4'b1111; press = 1'b0; end
endcase
end
endmodule

module debounce_ctl (clk, rst, press, press_valid);//確保你按一下按鈕，系統只會產生一個極短的訊號（1 個 clock 週期），並且過濾掉按鈕接觸時的雜訊
    input   press, clk, rst;
    output  press_valid;
    reg     [5:0] gg;

    assign press_valid =(~gg[5]) && press;//現在（press）是 1 (按下)，而且 6 個週期前（gg[5]）是 0 (沒按)

    always @(posedge clk or posedge rst) begin
        if (rst)
            gg <= 6'b0;
        else
            gg <= {gg[4:0], press};
    end
endmodule

module key_buf6(clk, rst, press_valid, scan_code, display_code);//left shift number
input clk, rst, press_valid;
input[3:0] scan_code;
output[23:0]display_code;
reg[23:0]display_code;
always@(posedge clk or posedge rst) begin
if(rst)
display_code= 24'hffffff;// initial value
else
display_code= press_valid ? {display_code[19:0], scan_code} : display_code;//{Left_shift_value} :Previous_ value;
end
endmodule



module bcd_to_seg7(bcd_in, seg7);
input[3:0] bcd_in;
output reg [6:0] seg7;
always@ (*)begin
case(bcd_in) // abcdefg
4'b0000: seg7 = 7'b1111110; // 0
4'b0001: seg7 = 7'b0110000; // 1
4'b0010: seg7 = 7'b1101101; // 2 
4'b0011: seg7 = 7'b1111001; // 3 
4'b0100: seg7 = 7'b0110011; // 4
4'b0101: seg7 = 7'b1011011; // 5
4'b0110: seg7 = 7'b1011111; // 6
4'b0111: seg7 = 7'b1110000; // 7
4'b1000: seg7 = 7'b1111111; // 8
4'b1001: seg7 = 7'b1111011; // 9
default: seg7 = 7'b0000000; 
endcase
end
endmodule

module freq_div(clk_in, rst, clk_out);
parameter exp = 20;   
input clk_in, rst;
output clk_out;
reg[exp-1:0] divider;
integer i;
assign clk_out= divider[exp-1];
always@ (posedge clk_in or posedge rst) //正緣觸發
begin
if(rst)
for(i=0; i < exp; i=i+1)
divider[i] = 1'b0;
else
divider = divider+ 1'b1;
end
endmodule