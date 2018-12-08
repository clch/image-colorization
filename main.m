% variables
image_num = 2;

patch_size = 5;
grid_size = 7;
mean_weight = 0.5;

% loading / preprocessing
source_name = ['source' int2str(image_num) '.jpg'];
target_name = ['target' int2str(image_num) '.jpg'];
source_img = im2double(imread(source_name));
target_img = im2double(imread(target_name));

if size(target_img,3) == 1
    target_img = repmat(target_img(:,:,1), [1 1 3]);
end

source = rgb2ycbcr(source_img);
target = rgb2ycbcr(target_img);

% remapping
luminance_s = source(:,:,1);
luminance_t = target(:,:,1);
mean_s = mean(luminance_s(:));
mean_t = mean(luminance_t(:));
sigma_s = std(luminance_s(:));
sigma_t = std(luminance_t(:));
target(:,:,1) = (target(:,:,1) - mean_t) .* sigma_t ./ sigma_s + mean_s;
luminance_t = target(:,:,1);

% jittered grid
height = size(source, 1);
width = size(source, 2);
height_grid_num = floor(height / grid_size)-1;
width_grid_num = floor(width / grid_size)-1;
grid = zeros(height_grid_num, width_grid_num, 4);
patch_margin = (patch_size - 1) / 2;
for j = 1:height_grid_num
    for i = 1:width_grid_num
        x_patch = uint16(rand() * grid_size);
        y_patch = uint16(rand() * grid_size);
        x = i * grid_size + x_patch;
        y = j * grid_size + y_patch;
        x_min = max(1, x - patch_margin);
        y_min = max(1, y - patch_margin);
        x_max = min(width, x + patch_margin);
        y_max = min(height, y + patch_margin);
        source_patch = luminance_s(y_min:y_max, x_min:x_max);
        cmean = mean(source_patch(:));
        cstd = std(source_patch(:));
        grid(j, i, 1) = cmean;
        grid(j, i, 2) = cstd;
        grid(j, i, 3) = source(y, x, 2);
        grid(j, i, 4) = source(y, x, 3);
    end
end

% matching
height = size(target, 1);
width = size(target, 2);
for y = 1:height
    for x = 1:width
        all_min = double(-1);
        x_min = max(1, x - patch_margin);
        y_min = max(1, y - patch_margin);
        x_max = min(width, x + patch_margin);
        y_max = min(height, y + patch_margin);
        target_patch = luminance_t(y_min:y_max, x_min:x_max);
        cmean = mean(target_patch(:));
        cstd = std(target_patch(:));
        for j = 1:height_grid_num
            for i = 1:width_grid_num
                cmin = mean_weight * (grid(j,i,1)-cmean)^2;
                cmin = cmin + (1 - mean_weight) * (grid(j,i,2)-cstd)^2;
                if cmin < all_min || all_min < 0
                    all_min = cmin;
                    target(y, x, 2) = grid(j, i, 3);
                    target(y, x, 3) = grid(j, i, 4);
                end
            end
        end
    end
end

% postprocessing
target = ycbcr2rgb(target);
imshow(target);
imwrite(target, ['result' int2str(image_num) '.jpg']);

%% rgb2gray for testing

img = imread('3.jpg');
img = rgb2gray(img);
imwrite(img, 'target4.jpg');



