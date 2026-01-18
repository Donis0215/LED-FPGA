module lab2Q3(clk, reset, seg7_sel, enable, seg7_out, dpt_out, carry, led_com);
    input clk, reset, enable;
    output [2:0] seg7_sel;
    output [6:0] seg7_out;
    output dpt_out, led_com, carry;
    
    wire clk_count, clk_sel;
    wire [3:0] count_out, count1, count0;//count1(十位), count0(各位)


    assign dpt_out = 1'b0;
    assign led_com = 1'b1;
    
    // MUX 選擇個位或十位
    assign count_out = (seg7_sel == 3'b101) ? count0 : count1; 

    freq_div #(21) M1 (clk, reset, clk_count); 
    freq_div #(17) M2 (clk, reset, clk_sel);   
    count_00_99 M3 (clk_count, reset, enable, count1, count0, carry);
    
    // 呼叫解碼器，輸出到暫存 wire
    bcd_to_seg7 M4 (count_out, seg7_out);

    // 【關鍵修正】如果硬體不亮，通常是因為要給 0 才會亮
    // 將輸出取反後再送往硬體腳位


    seg7_select #(2) M5 (clk_sel, reset, seg7_sel);
endmodule

module seg7_select(clk, reset, seg7_sel);
    parameter num_use = 6;
    input clk, reset;
    output reg [2:0] seg7_sel;//seg7_sel 的白話定義：燈光選取開關(現在輪到哪一個顯示器亮起來)

    always @(posedge clk or posedge reset) begin
        if(reset)
            seg7_sel <= 3'b101; // 從最右邊開始亮
        else begin
            // 簡化邏輯：在 3'b101 (右) 和 3'b100 (左) 之間切換
            if(seg7_sel == 3'b100) 
                seg7_sel <= 3'b101;
            else
                seg7_sel <= seg7_sel - 3'b001; 
        end
    end
endmodule

module count_00_99(clk, reset, enable, count1_out, count0_out, carry);
input	clk, reset, enable;
output[3:0] count1_out, count0_out;
output	carry ;
wire	carry0, carry1;
count_0_9 C1(clk, reset, enable, count0_out, carry0);
count_0_9 C2(clk, reset, carry0, count1_out, carry1);
assign carry = carry1 & carry0;
endmodule

module bcd_to_seg7(bcd_in, seg7); // decoder
    input [3:0] bcd_in;
    output reg[6:0] seg7;
     

    always @(bcd_in) begin
        case(bcd_in)
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

module count_0_9(clk, reset, enable, count_out, carry);
input clk, reset, enable;
output[3:0] count_out;
output carry;
reg[3:0] count_out;
assign carry = (count_out== 4'b1001) ? 1 : 0;
always@ (posedge clk or posedge reset)begin
if(reset)
count_out= 4'b0;
else if(enable == 1) begin
if(count_out== 4'b1001)
 count_out <= 4'b0000;
else
 count_out <= count_out + 4'b0001;
end
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





//assign count_out= (seg7_sel == 3'b101 )? count0 : 
						//(seg7_sel == 3'b100 )? count1 : count2; //MUX
