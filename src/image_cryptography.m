%% MatrixCrypt - Secure Image Cryptography using Chaotic Maps
% MATLAB implementation for image encryption and decryption.
%
% Encryption:
%   1. Pixel permutation (confusion)
%   2. Logistic Map key generation
%   3. XOR diffusion
%
% Decryption reverses these operations to reconstruct the original image.
%
% NOTE:
% Encrypted images must be stored in a lossless format such as PNG.

function image_cryptography()

    clc;

    fprintf('=============================================\n');
    fprintf(' MatrixCrypt - Secure Image Cryptography\n');
    fprintf('=============================================\n\n');

    fprintf('Select Operation Mode:\n');
    fprintf(' [E] Encrypt Image\n');
    fprintf(' [D] Decrypt Image\n');

    modeChoice = upper(input('Choice (E/D): ', 's'));

    if ~strcmp(modeChoice, 'E') && ~strcmp(modeChoice, 'D')
        error('Invalid selection. Use E for encryption or D for decryption.');
    end


    %% Load Image

    inputFile = input('Enter the full path to the image: ', 's');

    % Remove quotation marks if included in the path
    inputFile = strrep(inputFile, '"', '');
    inputFile = strrep(inputFile, '''', '');

    if isempty(inputFile) || ~exist(inputFile, 'file')
        error('The specified image file does not exist.');
    end

    [pathstr, name, ext] = fileparts(inputFile);

    % Chaotic seed used for encryption/decryption
    seed = 0.654321;

    img = imread(inputFile);

    [h, w, c] = size(img);

    fprintf('\nLoaded: %s\n', [name ext]);
    fprintf('Resolution: %d x %d\n', w, h);
    fprintf('Channels: %d\n', c);


    %% Encryption

    if strcmp(modeChoice, 'E')

        fprintf('\nEncrypting image...\n');

        outputFile = fullfile(pathstr, ...
            [name '_encrypted.png']);

        tic;

        % Step 1: Pixel permutation (Confusion)
        permutedImage = scramble_pixels(img, seed, 'forward');

        % Step 2: Logistic Map XOR diffusion
        encryptedImage = chaotic_diffusion(permutedImage, seed);

        encryptionTime = toc;

        % PNG is used because encryption requires lossless storage
        imwrite(encryptedImage, outputFile);

        fprintf('Encryption completed successfully.\n');
        fprintf('Encryption Time: %.4f seconds\n', encryptionTime);
        fprintf('Saved: %s\n', outputFile);

        figure('Name', 'MatrixCrypt - Encryption');

        subplot(1,2,1);
        imshow(img);
        title('Original Image');

        subplot(1,2,2);
        imshow(encryptedImage);
        title('Encrypted Image');


    %% Decryption

    else

        fprintf('\nDecrypting image...\n');

        outputFile = fullfile(pathstr, ...
            [name '_restored.png']);

        tic;

        % Step 1: Reverse XOR diffusion
        diffusedBack = chaotic_diffusion(img, seed);

        % Step 2: Reverse pixel permutation
        decryptedImage = scramble_pixels( ...
            diffusedBack, seed, 'inverse');

        decryptionTime = toc;

        imwrite(decryptedImage, outputFile);

        fprintf('Decryption completed successfully.\n');
        fprintf('Decryption Time: %.4f seconds\n', decryptionTime);
        fprintf('Saved: %s\n', outputFile);

        figure('Name', 'MatrixCrypt - Decryption');

        subplot(1,2,1);
        imshow(img);
        title('Encrypted Image');

        subplot(1,2,2);
        imshow(decryptedImage);
        title('Decrypted Image');

    end

    fprintf('\nIMPORTANT: Keep encrypted images in PNG format.\n');
    fprintf('JPEG compression changes pixel values and prevents exact decryption.\n');

end


%% ============================================================
%  PIXEL PERMUTATION
% =============================================================

function output = scramble_pixels(img, seed, direction)

    [h, w, c] = size(img);

    numPixels = h * w;

    % Save current random-number-generator state
    previousState = rng;

    % Generate deterministic permutation from the seed
    rng(round(seed * 1e7));

    permutation = randperm(numPixels);

    % Restore previous RNG state
    rng(previousState);

    output = img;


    if strcmp(direction, 'forward')

        % Shuffle pixel positions
        for channel = 1:c

            layer = img(:,:,channel);

            shuffledLayer = layer(permutation);

            output(:,:,channel) = ...
                reshape(shuffledLayer, h, w);

        end

    else

        % Generate inverse permutation
        [~, inversePermutation] = sort(permutation);

        for channel = 1:c

            layer = img(:,:,channel);

            restoredLayer = layer(inversePermutation);

            output(:,:,channel) = ...
                reshape(restoredLayer, h, w);

        end

    end

end


%% ============================================================
%  CHAOTIC DIFFUSION
% =============================================================

function output = chaotic_diffusion(img, seed)

    [h, w, c] = size(img);

    numberOfValues = numel(img);

    % Logistic Map parameter
    r = 3.999;

    x = seed;


    % Warm-up iterations
    % Helps move the Logistic Map into its chaotic region
    for i = 1:200
        x = r * x * (1 - x);
    end


    % Generate 8-bit chaotic key stream
    keyStream = zeros(numberOfValues, 1, 'uint8');

    for i = 1:numberOfValues

        x = r * x * (1 - x);

        keyStream(i) = ...
            uint8(mod(floor(x * 1e14), 256));

    end


    % Convert image into a one-dimensional sequence
    imageData = img(:);

    % XOR diffusion
    encryptedData = bitxor(imageData, keyStream);

    % Restore original image dimensions
    output = reshape(encryptedData, h, w, c);

end
