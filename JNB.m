function [results, avg_blur_distortion, avg_sharp_distortion] = JNB(folder_path)
    % 初始化变量
    results = struct([]);
    total_blur_distortion = 0;
    total_sharp_distortion = 0;
    image_count = 0;

    % 获取文件夹中的所有图像文件
    image_files = dir(fullfile(folder_path, '*.*'));
    valid_extensions = {'.png', '.jpg', '.jpeg', '.bmp', '.tiff'};

    for i = 1:length(image_files)
        [~, ~, ext] = fileparts(image_files(i).name);
        if ismember(lower(ext), valid_extensions)
            image_path = fullfile(folder_path, image_files(i).name);
            try
                [total_distortion, blur_distortion, sharp_distortion] = JNBM(image_path);
                image_count = image_count + 1;

                % 保存结果
                results(image_count).image = image_files(i).name;
                results(image_count).total_distortion = total_distortion;
                results(image_count).blur_distortion = blur_distortion;
                results(image_count).sharp_distortion = sharp_distortion;

                total_blur_distortion = total_blur_distortion + blur_distortion;
                total_sharp_distortion = total_sharp_distortion + sharp_distortion;

                fprintf('Processed %s: Sharpness=%f, Blur=%f\n', image_files(i).name, sharp_distortion, blur_distortion);
            catch ME
                fprintf('Error processing %s: %s\n', image_files(i).name, ME.message);
            end
        end
    end

    % 计算平均值
    if image_count > 0
        avg_blur_distortion = total_blur_distortion / image_count;
        avg_sharp_distortion = total_sharp_distortion / image_count;
        fprintf('\nAverage Blur Distortion: %f\n', avg_blur_distortion);
        fprintf('Average Sharp Distortion: %f\n', avg_sharp_distortion);
    else
        avg_blur_distortion = NaN;
        avg_sharp_distortion = NaN;
        fprintf('No images were processed.\n');
    end
end

function [total_distortion, blur_distortion, sharp_distortion] = JNBM(image_path)
    T = 0.002;
    CHUNK_SIZE = 64;
    BETA = 3.6;

    % 读取图像并转换为灰度图
    src_img = imread(image_path);
    if size(src_img, 3) == 3
        src_img = rgb2gray(src_img);
    end

    % 计算Sobel边缘
    sobel_abs = abs(imfilter(double(src_img), fspecial('sobel')));

    % 初始化变量
    processed_blocks = 0;
    threshold = T * CHUNK_SIZE * CHUNK_SIZE;
    [height, width] = size(sobel_abs);
    x_chunks = ceil(width / CHUNK_SIZE);
    y_chunks = ceil(height / CHUNK_SIZE);
    block_distortions = [];

    for x = 1:x_chunks
        cx = (x-1) * CHUNK_SIZE + 1;
        for y = 1:y_chunks
            cy = (y-1) * CHUNK_SIZE + 1;
            edge_chunk = sobel_abs(cy:min(cy + CHUNK_SIZE - 1, height), cx:min(cx + CHUNK_SIZE - 1, width));
            edge_ct = sum(edge_chunk(:) > 0);

            if edge_ct > threshold
                processed_blocks = processed_blocks + 1;
                lum_chunk = src_img(cy:min(cy + CHUNK_SIZE - 1, height), cx:min(cx + CHUNK_SIZE - 1, width));
                contrast = max(lum_chunk(:)) - min(lum_chunk(:));
                jnb_width = 5;
                if contrast > 50
                    jnb_width = 3;
                end
                edge_widths = [];

                for i = 1:size(edge_chunk, 1)
                    row = edge_chunk(i, :);
                    for j = 1:size(row, 2)
                        if row(j) > 0
                            edge_width = local_extrema(row, j);
                            edge_widths = [edge_widths edge_width]; %#ok<AGROW>
                        end
                    end
                end

                block_dist = get_block_distortion(edge_widths, jnb_width, BETA);
                block_distortions = [block_distortions block_dist]; %#ok<AGROW>
            end
        end
    end

    total_distortion = get_image_distortion(block_distortions, BETA);
    

    sharp_distortion = total_distortion / processed_blocks; 
    blur_distortion = processed_blocks / total_distortion;   
end



function dist = get_block_distortion(edges, w_jnb, beta)
    distortion = sum((edges / w_jnb) .^ beta);
    dist = distortion ^ (1 / beta);
end

function dist = get_image_distortion(block_distortions, beta)
    distortion = sum(abs(block_distortions) .^ beta);
    dist = distortion ^ (1 / beta);
end

function width = local_extrema(row, x_pos)
    x_value = row(x_pos);
    last_x_value = x_value;

    right_inc_width = 0;
    for x = x_pos:length(row)
        if x ~= x_pos
            current_value = row(x);
            if current_value > last_x_value
                right_inc_width = right_inc_width + 1;
                last_x_value = current_value;
            else
                break;
            end
        end
    end

    last_x_value = x_value;
    right_dec_width = 0;
    for x = x_pos:length(row)
        if x ~= x_pos
            current_value = row(x);
            if current_value < last_x_value
                right_dec_width = right_dec_width + 1;
                last_x_value = current_value;
            else
                break;
            end
        end
    end

    last_x_value = x_value;
    left_inc_width = 0;
    for x = x_pos:-1:1
        if x ~= x_pos
            current_value = row(x);
            if current_value > last_x_value
                left_inc_width = left_inc_width + 1;
                last_x_value = current_value;
            else
                break;
            end
        end
    end

    last_x_value = x_value;
    left_dec_width = 0;
    for x = x_pos:-1:1
        if x ~= x_pos
            current_value = row(x);
            if current_value < last_x_value
                left_dec_width = left_dec_width + 1;
                last_x_value = current_value;
            else
                break;
            end
        end
    end

    right_width = max(right_inc_width, right_dec_width);
    left_width = max(left_inc_width, left_dec_width);

    width = right_width + left_width;
end
