module timer(
    input clk,rst,ena,
    output reg[6:0]show_number_led,
    output reg[2:0]sel_num,
    output decimal_out,led_ena_signal
);
wire clk_scan_to_light;
wire carry_sec0,carry_sec1,carry_min0,carry_min1,carry_hr0,carry_hr1,rst_hr;
wire [6:0]light0,light1,light2,light3,light4,light5;
wire [3:0]count0,count1,count2,count3,count4,count5;
assign decimal_out=1'b0;
assign led_ena_signal=1'b1;
assign rst_hr=rst|(count5 == 2 && count4 == 3 && carry_min1 == 1);
freq_div #21 slow_clk(clk,rst,clk_out);
freq_div #15 scan_clk(clk, rst, clk_scan_to_light);
// 所有人共用 clk_out
counter     sec0(clk_out, rst, ena, carry_sec0, light0, count0);
counter #5 sec1(clk_out, rst, carry_sec0, carry_sec1, light1, count1); // ena 接前一級的 carry
counter     min0(clk_out, rst, carry_sec1, carry_min0, light2, count2);
counter #5 min1(clk_out, rst, carry_min0, carry_min1, light3, count3);
counter     hr0(carry_min1,rst_hr,ena,carry_hr0,light4,count4);
counter     hr1(carry_hr0,rst_hr,ena,carry_hr1,light5,count5);
always@(posedge clk_scan_to_light,posedge rst)begin
    if(rst)sel_num<=0;
    else if(sel_num==5)  sel_num<=0;
    else sel_num<=sel_num+1'b1;
end
always @(*) begin
    case(sel_num)
        3'd0: show_number_led = light5; // 最左邊：小時十位 (Lh1)
        3'd1: show_number_led = light4; // 時個位 (Lh0)
        3'd2: show_number_led = light3; // 分十位 (Lm1)
        3'd3: show_number_led = light2; // 分個位 (Lm0)
        3'd4: show_number_led = light1; // 秒十位 (Ls1)
        3'd5: show_number_led = light0; // 最右邊：秒個位 (Ls0)
        default: show_number_led = 7'b0000000;
    endcase
end
endmodule

module counter(
input clk,rst,ena,
output  carry,
output reg [6:0]light,
output reg [3:0]count

);
parameter carry_base_minus_one=9;
assign carry = (count == carry_base_minus_one) && (ena == 1);
always@(posedge clk,posedge rst)begin
    if(rst)begin count<=0;end
    else if(ena==1)begin
	 if(count<carry_base_minus_one)count<=count+1;
    else begin count<=0;end end end
    always@(*)begin
case(count)
4'b0000: light = 7'b1111110; // 0
4'b0001: light = 7'b0110000; // 1
4'b0010: light = 7'b1101101; // 2
4'b0011: light = 7'b1111001; // 3
4'b0100: light = 7'b0110011; // 4
4'b0101: light = 7'b1011011; // 5
4'b0110: light = 7'b1011111; // 6
4'b0111: light = 7'b1110000; // 7
4'b1000: light = 7'b1111111; // 8
4'b1001: light = 7'b1111011; // 9
default: light = 7'b0000000; 
endcase
end
endmodule

module freq_div(clk_in, reset, clk_out);
parameter exp = 20;   
input clk_in, reset;
output clk_out;
reg[exp-1:0] divider;
integer i;
assign clk_out= divider[exp-1];
always@ (posedge clk_in or posedge reset)	//正緣觸發
begin
if(reset)
for(i=0; i < exp; i=i+1)
divider[i] = 1'b0;
else
divider = divider+ 1'b1;
end
endmodule
