sourceImgName = 'source1.jpg';
targetImgName = 'target1.jpg';

sourceImg = im2double(imread(sourceImgName));
targetImg = im2double(imread(targetImgName));

if size(targetImg,3) == 1
    targetImg = repmat(targetImg(:,:,1), [1 1 3]);
end

source = rgb2ycbcr(sourceImg);
target = rgb2ycbcr(targetImg);
size(source);

% remapping
luminance_s = source(:,:,1);
luminance_t = target(:,:,1);
mean_s = mean(luminance_s(:));
mean_t = mean(luminance_t(:));
size(mean_t)
sigma_s = std(luminance_s(:));
sigma_t = std(luminance_t(:));
target(:,:,1) = (target(:,:,1) - mean_t) .* sigma_t ./ sigma_s + mean_s;


