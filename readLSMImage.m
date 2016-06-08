function img = readLSMImage( filename, lsm, idxStack, idxChannel)
% read LSM image

    % set image dimensions
    iH = lsm.height;
    iW = lsm.width;
    iC = size(idxChannel, 1);
    iZ = size(idxStack, 1);
    
    % allocate image
    imgSize = [iH, iW, iZ, iC];
    img = zeros(prod(imgSize), 1, lsm.readType);
    
    % read raw pixels
    fid = fopen(filename, 'r', lsm.byteOrder);
    index = 0;
    for c = 1 : iC
        for z = 1 : iZ
            fseek(fid, lsm.stripOffset(idxStack(z),idxChannel(c)), 'bof');
            pixels = fread(fid, lsm.readSize, lsm.readType, lsm.byteOrder);
            img((index+1):(index+lsm.readSize)) = pixels;
            index = index + lsm.readSize;
        end
    end
    fclose(fid);
    
    % rearrange to Matlab image
    img = reshape(img, imgSize);
    img = permute(img, [2, 1, 3, 4]);
    
end
