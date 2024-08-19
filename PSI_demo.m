% �����ļ���·��
folder_path = 'F:\Deraining\our_try\results\Rain100L\'; % �滻Ϊͼ���ļ��е�ʵ��·��
image_files = dir(fullfile(folder_path, '*.png')); % ��ȡ����PNGͼ���ļ�����չ�����Ը�����Ҫ����

% ��ʼ���洢PSIֵ������
psi_values = zeros(length(image_files), 1);

% ѭ������ÿ��ͼ��
for i = 1:length(image_files)
    % ��ȡͼ��
    image_path = fullfile(folder_path, image_files(i).name);
    I = imread(image_path);
    
    % ����PSIֵ
    psi_values(i) = PSI(I);
    
    % ��ʾ�������
    fprintf('Processed %d/%d: %s\n', i, length(image_files), image_files(i).name);
end

% ����PSIֵ��ƽ��ֵ
average_psi = mean(psi_values);

% ��ʾ���
fprintf('Average PSI: %.4f\n', average_psi);
