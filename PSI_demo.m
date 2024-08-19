% 设置文件夹路径
folder_path = 'F:\Deraining\our_try\results\Rain100L\'; % 替换为图像文件夹的实际路径
image_files = dir(fullfile(folder_path, '*.png')); % 获取所有PNG图像文件，扩展名可以根据需要调整

% 初始化存储PSI值的数组
psi_values = zeros(length(image_files), 1);

% 循环处理每张图像
for i = 1:length(image_files)
    % 读取图像
    image_path = fullfile(folder_path, image_files(i).name);
    I = imread(image_path);
    
    % 计算PSI值
    psi_values(i) = PSI(I);
    
    % 显示处理进度
    fprintf('Processed %d/%d: %s\n', i, length(image_files), image_files(i).name);
end

% 计算PSI值的平均值
average_psi = mean(psi_values);

% 显示结果
fprintf('Average PSI: %.4f\n', average_psi);
