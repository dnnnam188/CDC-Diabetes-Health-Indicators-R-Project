# ==============================================================================
# ĐỒ ÁN PHÂN TÍCH DỮ LIỆU TIỂU ĐƯỜNG
# ==============================================================================

# 1. KHAI BÁO THƯ VIỆN
library(ggplot2)
library(tidyverse)
library(janitor)
library(dplyr)
library(boot)
library(leaps)
library(VIM)
library(reshape2)
library(gridExtra)
library(car)
library(cowplot)
library(corrplot)
library(RColorBrewer)
library(caret)
library(themis)
library(e1071)
library(randomForest)

# 2. NHẬP VÀ LÀM SẠCH DỮ LIỆU
# Lưu ý: Đảm bảo file csv nằm đúng đường dẫn của file csv 
data_diabetes <- read.csv("diabetes_012_health_indicators_BRFSS2015.csv")
data_diabetes <- data_diabetes |> janitor::clean_names()

# Kiểm tra tổng quan
glimpse(data_diabetes)
summary_data <- summary(data_diabetes)
print(summary_data)

# Chia tập dữ liệu thành nhóm bệnh và không bệnh
diabetes_no <- data_diabetes |> filter(diabetes_012 == 0) 
diabetes_yes <- data_diabetes |> filter(diabetes_012 != 0)
new_diabetes <- data_diabetes |> 
  mutate(group = ifelse(diabetes_012 == 0, "No diabetes", "Diabetes"))

# 3. KIỂM TRA DỮ LIỆU TRỐNG (MISSING VALUES)
print(paste("Tổng số giá trị NA:", sum(is.na(data_diabetes))))
aggr(data_diabetes, col = c("blue", "red"), numbers = TRUE, sortVars = TRUE, 
     labels = names(data_diabetes), cex.axis = 0.5, gap = 3, 
     ylab = c("Missing data", "Pattern"))

# 4. KHÁM PHÁ DỮ LIỆU (EDA)

# Hàm vẽ biểu đồ biến mục tiêu
target_count <- function(data) {
  outcome_counts <- table(data$group)
  outcomes <- names(outcome_counts)
  counts <- as.numeric(outcome_counts)
  ggplot(aes(x = counts, y = outcomes), data = data.frame(counts, outcomes)) +
    geom_bar(stat = "identity", fill = c("lightskyblue", "gold"), color = "black") +
    labs(title = "Count of Outcome Variable", x = "Number of Individuals", y = "Outcome") +
    coord_flip() +
    theme_bw() +
    theme(text = element_text(size = 15))
}
target_count(new_diabetes)

# Phân bố Giới tính
plot1_sex <- ggplot(diabetes_no, aes(x = as.factor(sex), fill = as.factor(sex))) +
  geom_bar() +
  scale_fill_manual(values = c("#1f77b4", "#ff7f0e")) +
  labs(title = "Gender distribution for no-diabetes", x = "Sex", y = "Count", fill = "Gender") +
  scale_x_discrete(labels = c("Female", "Male")) +
  theme_minimal()

plot2_sex <- ggplot(diabetes_yes, aes(x = as.factor(sex), fill = as.factor(sex))) +
  geom_bar() +
  scale_fill_manual(values = c("#1f77b4", "#ff7f0e")) +
  labs(title = "Gender distribution for diabetics", x = "Sex", y = "Count", fill = "Gender") +
  scale_x_discrete(labels = c("Female", "Male")) +
  ylim(0, max(table(diabetes_no$sex), table(diabetes_yes$sex))) + 
  theme_minimal()

plot_grid(plot1_sex, plot2_sex, ncol = 2, align = "hv")

# Phân bố Tuổi của người mắc bệnh
ggplot(diabetes_yes, aes(x = as.factor(age))) +
  geom_bar(fill = "steelblue") +
  labs(title = "Age distribution for Diabetics", x = "Age Group") +
  scale_x_discrete(labels = c("18-24", "25-29", "30-34", "35-39", "40-44", "45-49", 
                              "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", ">80")) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Phân bố BMI (Lọc outliers 15-60)
diabetes_yes_filtered <- subset(diabetes_yes, bmi >= 15 & bmi <= 60)
diabetes_no_filtered <- subset(diabetes_no, bmi >= 15 & bmi <= 60)

plot1_bmi <- ggplot(diabetes_yes_filtered, aes(x = bmi)) +
  geom_histogram(fill = "steelblue", color = "black", binwidth = 2) + 
  labs(title = "BMI for Diabetics") + xlim(15, 60) + theme_bw() 

plot2_bmi <- ggplot(diabetes_no_filtered, aes(x = bmi)) +
  geom_histogram(fill = "steelblue", color = "black", binwidth = 2) + 
  labs(title = "BMI for No diabetics") + xlim(15, 60) + theme_bw() 

plot_grid(plot1_bmi, plot2_bmi, ncol = 2)

# Các yếu tố sức khỏe khác
# Cholesterol & Huyết áp
plot_chol <- ggplot(new_diabetes, aes(x = group, fill = as.factor(high_chol))) +
  geom_bar(position = "dodge") +  
  scale_fill_manual(values = c("lightblue", "gold")) +  
  labs(title = "Diabetes vs High Chol", fill = "High Chol") + theme_minimal()

plot_bp <- ggplot(new_diabetes, aes(x = group, fill = as.factor(high_bp))) +
  geom_bar(position = "dodge") +  
  scale_fill_manual(values = c("lightblue", "gold")) +  
  labs(title = "Diabetes vs High BP", fill = "High BP") + theme_minimal()

plot_grid(plot_chol, plot_bp, ncol = 2)

# Ma trận tương quan
cor_diabetes <- cor(data_diabetes, method = "pearson")
corrplot(cor_diabetes, method = "circle")

# 5. KIỂM ĐỊNH THỐNG KÊ

# --- Kiểm định 1: Chỉ số BMI trung bình ---
print(new_diabetes |> group_by(group) |> summarise(n = n(), mean = mean(bmi), sd = sd(bmi)))

# Permutation Test cho BMI
nA <- sum(new_diabetes$group == 'Diabetes')
nB <- sum(new_diabetes$group == 'No diabetes')

perm_fun <- function(x, nA, nB, R) {
  n <- nA + nB
  mean_diff <- numeric(R)
  for (i in 1:R){
    idx_a <- sample(x = 1:n, size = nA)
    idx_b <- setdiff(x = 1:n, y = idx_a)
    mean_diff[i] <- mean(x[idx_a]) - mean(x[idx_b])
  }
  return(mean_diff)
}

set.seed(21)
R <- 100
diff_mean_perm <- perm_fun(new_diabetes$bmi, nA, nB, R)
mean_a <- mean(new_diabetes$bmi[new_diabetes$group == 'Diabetes'])
mean_b <- mean(new_diabetes$bmi[new_diabetes$group == 'No diabetes'])
p_value_bmi <- mean(abs(diff_mean_perm) >= abs(mean_a - mean_b))
cat("P-value cho kiểm định BMI:", p_value_bmi, "\n")

# --- Kiểm định 2: Tỷ lệ Cholesterol cao (Chi-squared) ---
contingency_chol <- table(new_diabetes$diabetes_012, new_diabetes$high_chol)
chi2_chol <- chisq.test(contingency_chol)
print(chi2_chol)

# --- Kiểm định 3: Tỷ lệ Huyết áp cao (Chi-squared) ---
contingency_bp <- table(new_diabetes$diabetes_012, new_diabetes$high_bp)
chi2_bp <- chisq.test(contingency_bp)
print(chi2_bp)

# 6. XÂY DỰNG MÔ HÌNH

# Chuẩn bị dữ liệu
new_diabetes$group <- as.factor(new_diabetes$group)
X <- new_diabetes %>% select(-diabetes_012, -group)
y <- new_diabetes$group

# Lựa chọn đặc trưng (Chi-square)
chi_square_results <- sapply(X, function(col) {
  chisq.test(table(col, y))$statistic
})
important_features <- names(sort(chi_square_results, decreasing = TRUE))[2:7]
important_features <- gsub("\\.X-squared$", "", important_features)
print(paste("Các đặc trưng quan trọng:", paste(important_features, collapse = ", ")))

# Chia dữ liệu Train/Test
set.seed(123)
index <- createDataPartition(new_diabetes$group, p = 0.8, list = FALSE)
train_data <- new_diabetes[index, ]
test_data <- new_diabetes[-index, ]

# Xử lý mất cân bằng bằng SMOTE
train_data_smote <- smote(df = train_data, var = "group", k = 5, over_ratio = 1)
print("Phân bố lớp sau khi SMOTE:")
print(table(train_data_smote$group))

# Chuẩn bị X, y cho training
y_train <- as.factor(train_data_smote$group)
X_train <- train_data_smote %>% select(all_of(important_features))
y_test <- as.factor(test_data$group)
X_test <- test_data %>% select(all_of(important_features))

# Chuẩn hóa dữ liệu
preprocessor <- preProcess(X_train, method = c("center", "scale"))
X_train_scaled <- predict(preprocessor, X_train)
X_test_scaled <- predict(preprocessor, X_test)

# --- MÔ HÌNH 1: LOGISTIC REGRESSION ---
train_data_final <- data.frame(X_train_scaled, group = y_train)

set.seed(123)
model_logistic <- train(
  group ~ ., 
  data = train_data_final,
  method = "glmnet",
  family = "binomial",
  metric = "Accuracy",
  trControl = trainControl(method = "cv", number = 10)
)

# Dự đoán Logistic
y_pred_probs <- predict(model_logistic, newdata = X_test_scaled, type = "prob")
y_pred_logistic <- ifelse(y_pred_probs[, "Diabetes"] > 0.5, "Diabetes", "No diabetes")
y_pred_logistic <- factor(y_pred_logistic, levels = levels(y_test))

# Đánh giá Logistic
conf_matrix_log <- confusionMatrix(y_pred_logistic, y_test)
print(conf_matrix_log)

# --- MÔ HÌNH 2: RANDOM FOREST ---
set.seed(123)
model_rf <- randomForest(x = X_train, y = y_train, 
                         ntree = 500, 
                         mtry = sqrt(ncol(X_train)), 
                         importance = TRUE)

# Dự đoán Random Forest
y_pred_rf <- predict(model_rf, newdata = X_test)

# Đánh giá Random Forest
conf_matrix_rf <- confusionMatrix(y_pred_rf, y_test)
print(conf_matrix_rf)