Dưới đây là phiên bản **được làm đẹp, rõ ràng, chuyên nghiệp**, giữ nguyên nội dung kỹ thuật nhưng trình bày gọn hơn, hiện đại hơn — phù hợp làm README cho GitHub.

---

# UART Implementation

## 📌 Giới thiệu

**UART (Universal Asynchronous Receiver–Transmitter)** là giao thức truyền thông nối tiếp **không đồng bộ**, được sử dụng phổ biến để truyền dữ liệu giữa các thiết bị điện tử.
Implementation này bao gồm **đầy đủ bộ truyền (TX)** và **bộ nhận (RX)** cùng **FIFO buffer** cho khả năng truyền nhận liên tục, ổn định.
<img width="929" height="864" alt="image" src="https://github.com/user-attachments/assets/581f7281-7d05-4729-b143-5db42ccadd46" />

## 🚀 Tính năng chính

### **UART Transmitter (TX)**
<img width="781" height="602" alt="image" src="https://github.com/user-attachments/assets/05b06ee6-d15c-4590-8440-e23c92681ca2" />

* Tự động quản lý dữ liệu thông qua FIFO.
* Hỗ trợ truyền liên tục nhiều byte.
* Đóng gói dữ liệu theo chuẩn UART frame.
* Báo trạng thái FIFO đầy/rỗng, TX bận/rảnh.

### **UART Receiver (RX)**
<img width="723" height="540" alt="image" src="https://github.com/user-attachments/assets/8e6ffc9b-1c49-4e7c-b74d-baf2bb469d51" />

* Tự động phát hiện và lấy mẫu dữ liệu từ đường truyền.
* Đồng bộ hóa tín hiệu để tránh metastability.
* Lấy mẫu chính xác ở giữa bit (16× oversampling).
* Phát hiện lỗi stop bit.
* Cảnh báo tràn FIFO khi nhận quá nhanh.


## 🏗️ Kiến trúc hệ thống

Hệ thống gồm 4 thành phần chính:

### **1. Bộ sinh Baud Rate**
<img width="551" height="554" alt="image" src="https://github.com/user-attachments/assets/6f76ff55-6eaa-4f8f-9aac-8ab9ce85f22e" />

* Tạo tick chính xác cho cả TX/RX.
* Oversampling ×16 để tối ưu độ chính xác.
* Tự động tính toán từ clock hệ thống.
* *Ví dụ:* Clock 100 MHz → Baud 115200 → Tick mỗi 54 cycles.

### **2. TX Core**
<img width="746" height="544" alt="image" src="https://github.com/user-attachments/assets/1d26183d-7ef4-4bc4-9136-c12a48026f2b" />

* Tạo frame UART: Start bit → Data bits → Stop bit.
* Truyền dữ liệu dạng **LSB first**.
* State machine điều khiển chính xác thời điểm truyền từng bit.

### **3. RX Core**
<img width="893" height="574" alt="image" src="https://github.com/user-attachments/assets/2c0ee6bc-777c-44b9-829c-a88cdb74fb35" />
* Phát hiện cạnh xuống của start bit.
* Xác nhận start bit ở giữa bit để tránh nhiễu.
* Lấy mẫu data bits tại vị trí 15/16 chu kỳ.
* Kiểm tra stop bit trước khi ghi vào FIFO.
* Tích hợp bộ đồng bộ 2 tầng.

### **4. FIFO Buffer**

* Lưu trữ tạm dữ liệu để truyền/nhận liên tục.
* Độ sâu mặc định: **16 bytes** (configurable).
* Tránh mất dữ liệu khi tốc độ xử lý không đều.

## 🔄 FSM

### **TX Flow**
<img width="1078" height="336" alt="image" src="https://github.com/user-attachments/assets/d6f99804-7f89-49dc-802f-b7dd1f62814d" />


### **RX Flow**
<img width="1216" height="304" alt="image" src="https://github.com/user-attachments/assets/41c566f2-d825-4a92-af59-bab5e7fac2b0" />

## 🔄 Luồng hoạt động

### **TX Flow**

1. Người dùng ghi byte vào FIFO-TX.
2. TX core tự động lấy dữ liệu khi rảnh.
3. TX truyền từng bit theo frame UART.
4. Lặp lại cho đến khi FIFO trống.

### **RX Flow**

1. RX giám sát đường truyền liên tục.
2. Phát hiện và xác thực start bit.
3. Lấy mẫu 8 data bits chính xác theo baud tick.
4. Kiểm tra stop bit.
5. Ghi dữ liệu vào FIFO-RX cho người dùng đọc.

## ⚙️ Đặc điểm kỹ thuật

| Thông số     | Giá trị                           |
| ------------ | --------------------------------- |
| Baud rate    | Configurable (default **115200**) |
| Data bits    | Configurable (default **8 bits**) |
| Stop bits    | Configurable (default **1 bit**)  |
| Oversampling | **16×**                           |
| FIFO size    | **16 bytes** (configurable)       |


## 📡 UART Frame Format

Mỗi byte gồm:

* **Start bit**: 1 (mức 0)
* **Data bits**: 8 (LSB → MSB)
* **Stop bit**: 1 (mức 1)

➡️ Tổng cộng **10 bits/byte**

Với 115200 baud → thời gian truyền 1 byte ≈ **86.8 µs**.

## 🎯 Ứng dụng
* Giao tiếp PC ↔ FPGA / MCU
* Truyền dữ liệu cho module GPS, Bluetooth, WiFi
* Debug UART cho FPGA
* Giao tiếp sensor/actuator
* Linh kiện trao đổi dữ liệu giữa các board điện tử

