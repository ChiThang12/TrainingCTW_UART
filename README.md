# TrainingCTW_UART
UART Implementation
📌 Giới thiệu

UART (Universal Asynchronous Receiver–Transmitter) là giao thức truyền thông nối tiếp không đồng bộ, được sử dụng phổ biến để truyền dữ liệu giữa các thiết bị điện tử.
Implementation này bao gồm đầy đủ bộ truyền (TX) và bộ nhận (RX) cùng FIFO buffer cho khả năng truyền nhận liên tục, ổn định.

🚀 Tính năng chính
UART Transmitter (TX)

Tự động quản lý dữ liệu thông qua FIFO.

Hỗ trợ truyền liên tục nhiều byte.

Đóng gói dữ liệu theo chuẩn UART frame.

Báo trạng thái FIFO đầy/rỗng, TX bận/rảnh.

UART Receiver (RX)

Tự động phát hiện và lấy mẫu dữ liệu từ đường truyền.

Đồng bộ hóa tín hiệu để tránh metastability.

Lấy mẫu chính xác ở giữa bit (16× oversampling).

Phát hiện lỗi stop bit.

Cảnh báo tràn FIFO khi nhận quá nhanh.

🏗️ Kiến trúc hệ thống

Hệ thống gồm 4 thành phần chính:

1. Bộ sinh Baud Rate

Tạo tick chính xác cho cả TX/RX.

Oversampling ×16 để tối ưu độ chính xác.

Tự động tính toán từ clock hệ thống.

Ví dụ: Clock 100 MHz → Baud 115200 → Tick mỗi 54 cycles.

2. TX Core

Tạo frame UART: Start bit → Data bits → Stop bit.

Truyền dữ liệu dạng LSB first.

State machine điều khiển chính xác thời điểm truyền từng bit.

3. RX Core

Phát hiện cạnh xuống của start bit.

Xác nhận start bit ở giữa bit để tránh nhiễu.

Lấy mẫu data bits tại vị trí 15/16 chu kỳ.

Kiểm tra stop bit trước khi ghi vào FIFO.

Tích hợp bộ đồng bộ 2 tầng.

4. FIFO Buffer

Lưu trữ tạm dữ liệu để truyền/nhận liên tục.

Độ sâu mặc định: 16 bytes (configurable).

Tránh mất dữ liệu khi tốc độ xử lý không đều.

🔄 Luồng hoạt động
TX Flow

Người dùng ghi byte vào FIFO-TX.

TX core tự động lấy dữ liệu khi rảnh.

TX truyền từng bit theo frame UART.

Lặp lại cho đến khi FIFO trống.

RX Flow

RX giám sát đường truyền liên tục.

Phát hiện và xác thực start bit.

Lấy mẫu 8 data bits chính xác theo baud tick.

Kiểm tra stop bit.

Ghi dữ liệu vào FIFO-RX cho người dùng đọc.

⚙️ Đặc điểm kỹ thuật
Thông số	Giá trị
Baud rate	Configurable (default 115200)
Data bits	Configurable (default 8 bits)
Stop bits	Configurable (default 1 bit)
Parity	❌ Không hỗ trợ
Flow control	❌ Không hỗ trợ (no RTS/CTS)
Oversampling	16×
FIFO size	16 bytes (configurable)
📡 UART Frame Format

Mỗi byte gồm:

Start bit: 1 (mức 0)

Data bits: 8 (LSB → MSB)

Stop bit: 1 (mức 1)

➡️ Tổng cộng 10 bits/byte

Với 115200 baud → thời gian truyền 1 byte ≈ 86.8 µs.

🎯 Ứng dụng

Giao tiếp PC ↔ FPGA / MCU

Truyền dữ liệu cho module GPS, Bluetooth, WiFi

Debug UART cho FPGA

Giao tiếp sensor/actuator

Linh kiện trao đổi dữ liệu giữa các board điện tử

⚠️ Lưu ý quan trọng

Clock hệ thống phải đủ cao để tạo baud rate chính xác.

Cả TX và RX phải cấu hình cùng baud rate.

Phải kiểm tra trạng thái FIFO trước khi đọc/ghi.

Reset active-low (rst_n = 0 để reset).

Đường truyền UART ở trạng thái idle = mức logic 1.
