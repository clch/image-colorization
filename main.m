% variables
image_num = 4;
num_swatches = 3;

patch_size = 5;
grid_size = 5; % odd number
mean_weight = 0.5;

% loading / preprocessing
source_name = ['images/source' int2str(image_num) '.jpg'];
target_name = ['images/target' int2str(image_num) '.jpg'];
source_img = im2double(imread(source_name));
target_img = im2double(imread(target_name));

if size(target_img,3) == 1
    target_img = repmat(target_img(:,:,1), [1 1 3]);
end

source = rgb2ycbcr(source_img);
target = rgb2ycbcr(target_img);

box_s = zeros(num_swatches, 4);
box_t = zeros(num_swatches, 4);
for i = 1:num_swatches
    % getting swatches
    imshow(source_img);
    rect = getrect; % x, y, width, height
    box_s(i, 1) = uint16(rect(1));
    box_s(i, 2) = uint16(rect(2));
    box_s(i, 3) = uint16(rect(1) + rect(3));
    box_s(i, 4) = uint16(rect(2) + rect(4));
    imshow(target_img);
    rect = getrect;
    box_t(i, 1) = uint16(rect(1));
    box_t(i, 2) = uint16(rect(2));
    box_t(i, 3) = uint16(rect(1) + rect(3));
    box_t(i, 4) = uint16(rect(2) + rect(4));
    
    % linear remapping
    swatch_s = source(box_s(i,2):box_s(i,4),box_s(i,1):box_s(i,3),:);
    swatch_t = target(box_t(i,2):box_t(i,4),box_t(i,1):box_t(i,3),:);
    luminance_s = swatch_s(:,:,1);
    luminance_t = swatch_t(:,:,1);
    mean_s = mean(luminance_s(:));
    mean_t = mean(luminance_t(:));
    sigma_s = std(luminance_s(:));
    sigma_t = std(luminance_t(:));
    swatch_t(:,:,1) = (swatch_t(:,:,1)-mean_t).*sigma_t./sigma_s+mean_s;
    luminance_t = target(:,:,1);
    
    % jittered grid
    height = box_s(i,4) - box_s(i,2);
    width = box_s(i,3) - box_s(i,1);
    height_grid_num = floor(height / grid_size)-1;
    width_grid_num = floor(width / grid_size)-1;
    grid = zeros(height_grid_num, width_grid_num, 4);
    patch_margin = (patch_size - 1) / 2;
    for r = 1:height_grid_num
        for c = 1:width_grid_num
            x_patch = uint16(rand() * grid_size);
            y_patch = uint16(rand() * grid_size);
            x = c * grid_size + x_patch;
            y = r * grid_size + y_patch;
            x_min = max(1, x - patch_margin);
            y_min = max(1, y - patch_margin);
            x_max = min(width, x + patch_margin);
            y_max = min(height, y + patch_margin);
            source_patch = luminance_s(y_min:y_max, x_min:x_max);
            cmean = mean(source_patch(:));
            cstd = std(source_patch(:));
            grid(r, c, 1) = cmean;
            grid(r, c, 2) = cstd;
            grid(r, c, 3) = swatch_s(y, x, 2);
            grid(r, c, 4) = swatch_s(y, x, 3);
        end
    end
    
    % coloring swatches
    height = box_t(i,4) - box_t(i,2);
    width = box_t(i,3) - box_t(i,1);
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
            for r = 1:height_grid_num
                for c = 1:width_grid_num
                    cmin = mean_weight * (grid(r,c,1)-cmean)^2;
                    cmin = cmin + (1 - mean_weight) * (grid(r,c,2)-cstd)^2;
                    if cmin < all_min || all_min < 0
                        all_min = cmin;
                        swatch_t(y, x, 2) = grid(r, c, 3);
                        swatch_t(y, x, 3) = grid(r, c, 4);
                    end
                end
            end
        end
    end
    target(box_t(i,2):box_t(i,4),box_t(i,1):box_t(i,3),2)=swatch_t(:,:,2);
    target(box_t(i,2):box_t(i,4),box_t(i,1):box_t(i,3),3)=swatch_t(:,:,3);
end

% matching whole image
tic;
width = size(target,2);
height = size(target, 1);
margin = (patch_size-1)/2;
for y = 1:height
    for x = 1:width
        x_min = max(1, x - margin);
        y_min = max(1, y - margin);
        x_max = min(width, x + margin);
        y_max = min(height, y + margin);
        min_error = -1;
        min_r = 0;
        min_c = 0;
        target_n = luminance_t(y_min:y_max, x_min:x_max);
        for i = 1:num_swatches
            for r = box_t(i,2):patch_size:box_t(i,4)
                for c = box_t(i,1):patch_size:box_t(i,3)
                    swatch_n = luminance_t(y_min+r-y:y_max+r-y,x_min+c-x:x_max+c-x);
                    error = sum((target_n(:) - swatch_n(:)).^2);
                    if error < min_error || min_error < 0
                        min_error = error;
                        min_r = r;
                        min_c = c;
                    end
                end
            end
        end
        target(y,x,2) = target(min_r,min_c,2);
        target(y,x,3) = target(min_r,min_c,3);
    end
end
toc;
            
% postprocessing
target = ycbcr2rgb(target);
imshow(target);
imwrite(target, ['images/result' int2str(image_num) '.jpg']);




