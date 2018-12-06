sourceImgName = 'source1.jpg';
targetImgName = 'target1.jpg';

sourceImg = imread(sourceImgName);
targetImg = imread(targetImgName);

if size(sourceImg,3) ~= 3
    disp ('Source input must be color image');
end

if size(targetImg,3) == 1
    target = repmat(target(:,:,1), [1 1 3]);
end

source = rgb2ycbcr(sourceImg)
target = rgb2ycbcr(targetImg)


