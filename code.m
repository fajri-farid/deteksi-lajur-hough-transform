clc; clear; close all;

%% =============================================================
%% FILE
%% =============================================================
inputVideo  = 'video.mp4';
outputVideo = 'video_lane_output.mp4';

% Pilih frame ke berapa yang mau dijadikan contoh alur proses
frameNumber = 30;

% Output gambar panel proses 1 frame
outputImage = 'proses_1_frame_lane_detection.png';

%% =============================================================
%% OPSI TAMPILAN
%% =============================================================
% true = video tetap tampil berjalan di window sendiri
showVideoPreview = true;

% true = panel proses 1 frame tampil di window sendiri
showProcessFigure = true;

%% =============================================================
%% PARAMETER DETEKSI
%% =============================================================
param.minAngle = 25;
param.maxAngle = 80;
param.numPeaks = 20;
param.houghThresh = 0.30;
param.fillGap = 500;
param.minLength = 25;
param.roiTopRatio = 0.75;

%% =============================================================
%% PARAMETER ROI
%% =============================================================
param.bottomLeftRatio  = 0.22;
param.bottomRightRatio = 0.95;
param.topLeftRatio     = 0.45;
param.topRightRatio    = 0.62;

%% =============================================================
%% STABILIZER
%% =============================================================
prevL = [];
prevR = [];
missL = 0;
missR = 0;
maxMiss = 8;
alpha = 0.25;

%% =============================================================
%% VIDEO READER DAN WRITER
%% =============================================================
vReader = VideoReader(inputVideo);

totalFrames = floor(vReader.Duration * vReader.FrameRate);
frameNumber = min(max(frameNumber, 1), totalFrames);

vWriter = VideoWriter(outputVideo, 'MPEG-4');
vWriter.FrameRate = vReader.FrameRate;
open(vWriter);

%% =============================================================
%% WINDOW 1: PREVIEW VIDEO BERJALAN
%% =============================================================
if showVideoPreview
    figPreview = figure('Name', 'Window 1 - Preview Video Lane Detection', ...
                        'Color', 'white', ...
                        'Position', [100 100 800 500]);

    axPreview = axes('Parent', figPreview);
    imgPreview = [];
end

%% =============================================================
%% LOOP VIDEO
%% =============================================================
currentFrame = 0;
processFrameSaved = false;

while hasFrame(vReader)

    currentFrame = currentFrame + 1;
    frame = readFrame(vReader);

    %% =========================================================
    %% DEBUG HANYA UNTUK FRAME PILIHAN
    %% =========================================================
    makeDebug = currentFrame == frameNumber && ~processFrameSaved;

    %% =========================================================
    %% PROSES LANE DETECTION PER FRAME
    %% =========================================================
    result = processLaneFrame(frame, param, makeDebug);

    %% =========================================================
    %% STABILIZER UNTUK VIDEO
    %% =========================================================
    [L, prevL, missL] = smoothLine(result.rawL, prevL, missL, maxMiss, alpha);
    [R, prevR, missR] = smoothLine(result.rawR, prevR, missR, maxMiss, alpha);

    %% =========================================================
    %% FINAL OUTPUT FRAME VIDEO
    %% =========================================================
    out = drawLane(frame, L, R);

    %% =========================================================
    %% SIMPAN KE VIDEO OUTPUT
    %% =========================================================
    writeVideo(vWriter, out);

    %% =========================================================
    %% WINDOW 2: PANEL ALUR PROSES 1 FRAME DIAM / STATIC
    %% =========================================================
    if makeDebug

        % Nomor 8 pada panel memakai hasil final dari frame ini
        result.finalView = out;

        % Simpan dan tampilkan panel proses 1 frame
        saveProcessPanel(result, frameNumber, outputImage, showProcessFigure);

        processFrameSaved = true;
    end

    %% =========================================================
    %% UPDATE WINDOW 1: VIDEO BERJALAN
    %% =========================================================
    if showVideoPreview && ishandle(figPreview)

        if isempty(imgPreview) || ~isgraphics(imgPreview)
            imgPreview = imshow(out, 'Parent', axPreview);
        else
            set(imgPreview, 'CData', out);
        end

        title(axPreview, sprintf('Window 1 - Video Berjalan | Frame %d', currentFrame));
        drawnow limitrate;
    end
end

close(vWriter);

fprintf('\nSelesai!\n');
fprintf('Video output disimpan sebagai: %s\n', outputVideo);
fprintf('Panel proses 1 frame disimpan sebagai: %s\n', outputImage);

%% =============================================================
%% FUNGSI: PROSES LANE DETECTION PER FRAME
%% =============================================================
function result = processLaneFrame(frame, param, makeDebug)

    [h, w, ~] = size(frame);
    topY = round(h * param.roiTopRatio);

    %% 1. RGB ASLI
    rgbFrame = frame;

    %% 2. RGB -> GRAYSCALE
    grayFrame = rgb2gray(rgbFrame);

    %% 3. GRAYSCALE -> GAUSSIAN BLUR
    blurFrame = imgaussfilt(grayFrame, 1.5);

    %% 4. GAUSSIAN BLUR -> CANNY EDGE
    edgeImg = edge(blurFrame, 'Canny', [0.05 0.15]);

    %% 5. REGION OF INTEREST / ROI
    bottomLeft  = param.bottomLeftRatio  * w;
    bottomRight = param.bottomRightRatio * w;
    topLeft     = param.topLeftRatio     * w;
    topRight    = param.topRightRatio    * w;

    roi = poly2mask( ...
        [bottomLeft bottomRight topRight topLeft], ...
        [h h topY topY], ...
        h, w);

    edgeROI = edgeImg & roi;

    %% =========================================================
    %% BUAT VISUALISASI ROI HANYA UNTUK FRAME PILIHAN
    %% =========================================================
    if makeDebug

        roiView = rgbFrame;

        for c = 1:3
            channel = roiView(:,:,c);
            channel(~roi) = uint8(double(channel(~roi)) * 0.25);
            roiView(:,:,c) = channel;
        end

        roiPolygon = [bottomLeft h bottomRight h topRight topY topLeft topY];

        roiView = insertShape(roiView, 'Polygon', roiPolygon, ...
            'Color', 'yellow', ...
            'LineWidth', 4);

        houghView = rgbFrame;
    end

    %% 6. HOUGH TRANSFORM
    [H, T, Rho] = hough(edgeROI);

    hMax = max(H(:));

    if hMax > 0
        P = houghpeaks(H, param.numPeaks, ...
            'Threshold', param.houghThresh * hMax);
    else
        P = [];
    end

    if isempty(P)
        lines = struct('point1', {}, 'point2', {});
    else
        lines = houghlines(edgeROI, T, Rho, P, ...
            'FillGap', param.fillGap, ...
            'MinLength', param.minLength);
    end

    %% 7. FILTER GARIS DAN PISAHKAN KIRI/KANAN
    maxPts = 2 * max(numel(lines), 1);

    leftPts  = zeros(maxPts, 2);
    rightPts = zeros(maxPts, 2);

    nLeft = 0;
    nRight = 0;

    for k = 1:numel(lines)

        pts = [lines(k).point1; lines(k).point2];

        dx = pts(2,1) - pts(1,1);
        dy = pts(2,2) - pts(1,2);

        angle = abs(atan2d(dy, dx));

        if angle < param.minAngle || angle > param.maxAngle
            continue;
        end

        slope = dy / (dx + eps);

        if slope < 0

            leftPts(nLeft + 1:nLeft + 2, :) = pts;
            nLeft = nLeft + 2;

            if makeDebug
                houghView = insertShape(houghView, 'Line', ...
                    [pts(1,1) pts(1,2) pts(2,1) pts(2,2)], ...
                    'Color', 'blue', ...
                    'LineWidth', 4);
            end

        else

            rightPts(nRight + 1:nRight + 2, :) = pts;
            nRight = nRight + 2;

            if makeDebug
                houghView = insertShape(houghView, 'Line', ...
                    [pts(1,1) pts(1,2) pts(2,1) pts(2,2)], ...
                    'Color', 'red', ...
                    'LineWidth', 4);
            end
        end
    end

    leftPts  = leftPts(1:nLeft, :);
    rightPts = rightPts(1:nRight, :);

    %% 8. FITTING GARIS KIRI DAN KANAN
    rawL = fitLine(leftPts, h, topY, w);
    rawR = fitLine(rightPts, h, topY, w);

    %% 9. OUTPUT UTAMA
    result.rawL = rawL;
    result.rawR = rawR;

    %% 10. OUTPUT DEBUG HANYA UNTUK PANEL 1 FRAME
    if makeDebug
        result.rgbFrame  = rgbFrame;
        result.grayFrame = grayFrame;
        result.blurFrame = blurFrame;
        result.edgeImg   = edgeImg;
        result.roiView   = roiView;
        result.edgeROI   = edgeROI;
        result.houghView = houghView;
    end
end

%% =============================================================
%% FUNGSI: SIMPAN PANEL ALUR PROSES 1 FRAME
%% =============================================================
function saveProcessPanel(result, frameNumber, outputImage, showProcessFigure)

    if showProcessFigure
        figProcess = figure('Name', 'Window 2 - Proses Lane Detection 1 Frame', ...
                            'Color', 'white', ...
                            'Position', [950 100 1500 850]);
    else
        figProcess = figure('Name', 'Window 2 - Proses Lane Detection 1 Frame', ...
                            'Color', 'white', ...
                            'Position', [950 100 1500 850], ...
                            'Visible', 'off');
    end

    tl = tiledlayout(figProcess, 2, 4, ...
        'Padding', 'compact', ...
        'TileSpacing', 'compact');

    nexttile(tl);
    imshow(result.rgbFrame);
    title(sprintf('1. Frame RGB Asli (#%d)', frameNumber));

    nexttile(tl);
    imshow(result.grayFrame);
    title('2. Grayscale');

    nexttile(tl);
    imshow(result.blurFrame);
    title('3. Gaussian Blur');

    nexttile(tl);
    imshow(result.edgeImg);
    title('4. Canny Edge');

    nexttile(tl);
    imshow(result.roiView);
    title('5. ROI Area Jalan');

    nexttile(tl);
    imshow(result.edgeROI);
    title('6. Edge di Dalam ROI');

    nexttile(tl);
    imshow(result.houghView);
    title('7. Kandidat Garis Hough');

    nexttile(tl);
    imshow(result.finalView);
    title(sprintf('8. Final Deteksi Jalur Frame #%d', frameNumber));

    exportgraphics(figProcess, outputImage, 'Resolution', 200);
end

%% =============================================================
%% FUNGSI: FITTING GARIS
%% =============================================================
function lineOut = fitLine(pts, h, topY, w)

    if size(pts, 1) < 2
        lineOut = [];
        return;
    end

    p = polyfit(pts(:,2), pts(:,1), 1);

    xBottom = round(polyval(p, h));
    xTop    = round(polyval(p, topY));

    xBottom = min(max(xBottom, 1), w);
    xTop    = min(max(xTop, 1), w);

    lineOut = [xBottom h xTop topY];
end

%% =============================================================
%% FUNGSI: ANTI FLICKER / ANTI MUNCUL-HILANG
%% =============================================================
function [lineOut, prevLine, missCount] = smoothLine(newLine, prevLine, missCount, maxMiss, alpha)

    if ~isempty(newLine)

        if isempty(prevLine)
            lineOut = newLine;
        else
            lineOut = round(alpha * double(newLine) + ...
                            (1 - alpha) * double(prevLine));
        end

        prevLine = lineOut;
        missCount = 0;

    else

        missCount = missCount + 1;

        if ~isempty(prevLine) && missCount <= maxMiss
            lineOut = prevLine;
        else
            lineOut = [];
            prevLine = [];
        end
    end
end

%% =============================================================
%% FUNGSI: GAMBAR GARIS DAN AREA JALUR
%% =============================================================
function out = drawLane(frame, L, R)

    out = frame;
    [h, w, ~] = size(frame);

    if ~isempty(L) && ~isempty(R)

        mask = poly2mask( ...
            [L(1) L(3) R(3) R(1)], ...
            [L(2) L(4) R(4) R(2)], ...
            h, w);

        green = out(:,:,2);
        green(mask) = uint8(double(green(mask)) * 0.75 + 150 * 0.25);
        out(:,:,2) = green;

        out = insertShape(out, 'Line', L, ...
            'Color', 'blue', ...
            'LineWidth', 6);

        out = insertShape(out, 'Line', R, ...
            'Color', 'red', ...
            'LineWidth', 6);

    elseif ~isempty(L)

        out = insertShape(out, 'Line', L, ...
            'Color', 'blue', ...
            'LineWidth', 6);

    elseif ~isempty(R)

        out = insertShape(out, 'Line', R, ...
            'Color', 'red', ...
            'LineWidth', 6);
    end
end