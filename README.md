# CDC Diabetes Health Indicators Analysis Project

## I. Overview
Dự án này tập trung vào việc phân tích bộ dữ liệu **CDC Diabetes Health Indicators** (năm 2015) nhằm xác định các yếu tố nguy cơ chính dẫn đến bệnh tiểu đường và xây dựng mô hình Máy học (Machine Learning) để dự đoán khả năng mắc bệnh.

*   **Nguồn dữ liệu:** Khảo sát BRFSS 2015 của CDC Hoa Kỳ.
*   **Quy mô:** 253,680 bản ghi với 22 biến số sức khỏe.
*   **Mục tiêu:** Xây dựng mô hình phân loại để hỗ trợ sàng lọc sớm bệnh tiểu đường.

---

## II. Methodology

### 1. Khám phá & Tiền xử lý dữ liệu (Data Preprocessing & EDA)
**Mục tiêu:** Hiểu rõ dữ liệu, làm sạch và xác định các đặc điểm quan trọng.

a.  **Làm sạch dữ liệu (Data Cleaning):**
    *   Hợp nhất nhóm "Tiền tiểu đường" (Pre-diabetes) và "Tiểu đường" (Diabetes) thành một nhóm chung để chuyển bài toán về phân loại nhị phân.
    *   Kiểm tra dữ liệu khuyết (Missing values): Dữ liệu sạch, không có giá trị Null.
b.  **Trực quan hóa (Exploratory Data Analysis - EDA):**
    *   Phát hiện **Mất cân bằng dữ liệu (Imbalanced Data):** Nhóm không bệnh chiếm ~85%, nhóm bệnh chiếm ~15%.
    *   **Chân dung người bệnh:** Người mắc bệnh thường có độ tuổi cao (60-74), chỉ số BMI cao (béo phì), đi kèm Cao huyết áp và Mỡ máu cao.
    *   **Tương quan:** Xác định các biến có mối liên hệ mạnh thông qua biểu đồ nhiệt (Heatmap) và ma trận tương quan.

### 2. Kiểm định Thống kê (Hypothesis Testing)
**Mục tiêu:** Kiểm chứng ý nghĩa thống kê của các quan sát từ bước EDA.

a.  **Kiểm định chỉ số BMI (Biến liên tục):**
    *   Sử dụng **Permutation Test** (Kiểm định hoán vị).
    *   *Kết quả:* p-value < 0.05 -> BMI là yếu tố phân biệt rõ rệt giữa hai nhóm.
b.  **Kiểm định Cholesterol & Huyết áp (Biến phân loại):**
    *   Sử dụng **Chi-squared Test** (Kiểm định Chi bình phương).
    *   *Kết quả:* p-value < 0.05 -> Tỷ lệ mắc bệnh nền này ở nhóm tiểu đường cao hơn có ý nghĩa thống kê so với nhóm khỏe mạnh.

### 3. Modeling
**Mục tiêu:** Xây dựng mô hình dự đoán (Predictive Model).

a.  **Chuẩn bị dữ liệu:**
    *   **Feature Selection:** Lựa chọn các biến quan trọng nhất (HighBP, HighChol, BMI, Age, GenHlth, v.v.).
    *   **Data Splitting:** Chia tập dữ liệu Train/Test (80/20).
    *   **SMOTE (Synthetic Minority Over-sampling Technique):** Áp dụng kỹ thuật cân bằng dữ liệu trên tập Train để giải quyết vấn đề mất cân bằng mẫu.

b.  **Mô hình hóa (Training):**
    *   **Logistic Regression:** Mô hình cơ bản, dễ giải thích, yêu cầu chuẩn hóa dữ liệu.
    *   **Random Forest:** Mô hình mạnh mẽ, dựa trên tập hợp cây quyết định.

cc.  **Đánh giá & Kết luận (Evaluation & Conclusion):**

| Mô hình | Accuracy (Độ chính xác) | Sensitivity (Độ nhạy - Phát hiện bệnh) | Nhận xét |
| :--- | :--- | :--- | :--- |
| **Random Forest** | ~78.64% | ~50.03% | Bỏ sót nhiều người bệnh (False Negatives cao). |
| **Logistic Regression** | ~70.42% | **~73.12%** | **Phát hiện bệnh tốt hơn.** |

**➔ Kết luận:** Trong bối cảnh y tế, việc bỏ sót bệnh nhân nguy hiểm hơn báo nhầm. Do đó, **Logistic Regression** được đánh giá là mô hình phù hợp hơn nhờ chỉ số Sensitivity (Độ nhạy) cao hơn, giúp tối ưu hóa khả năng sàng lọc bệnh.

---

## III. Công nghệ sử dụng (Tech Stack)
*   **Ngôn ngữ:** R
*   **Thư viện chính:**
    *   `tidyverse`, `ggplot2` (Xử lý & Vẽ biểu đồ)
    *   `caret` (Huấn luyện mô hình & Đánh giá)
    *   `randomForest`, `e1071` (Thuật toán ML)
    *   `themis` (Xử lý mất cân bằng - SMOTE)
    *   `corrplot`, `cowplot` (Trực quan hóa nâng cao)

## IV. Hướng dẫn chạy (How to run)
1.  Clone repository này về máy.
2.  Đảm bảo đã cài đặt R và RStudio.
3.  Cài đặt các thư viện cần thiết:
    ```r
    install.packages(c("tidyverse", "caret", "randomForest", "e1071", "themis", "janitor", "corrplot"))
    ```
4.  Mở file `.Rmd` và chạy từng chunk hoặc Knit ra file HTML/PDF để xem báo cáo đầy đủ.

---
