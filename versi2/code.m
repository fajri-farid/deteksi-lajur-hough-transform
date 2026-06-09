clc; clear; close all;

%% =============================================================
%% FILE
%% =============================================================
inputVideo  = '../input/video2.mp4';
outputVideo = 'video_lane_output_v2_lane_color_mask2.mp4';

% Pilih frame ke berapa yang mau dijadikan contoh alur proses
frameNumber = 30;

% Output gambar panel proses 1 frame
outputImage = 'proses_1_frame_lane_detection_v2_lane_color_mask2.png';

%% =============================================================
%% OPSI TAMPILAN
%% =============================================================
% true = video tetap tampil berjalan di window sendiri
showVideoPreview = true;

% true = panel proses 1 frame tampil di window sendiri
showProcessFigure = true;

% true = buat video debug panel 2x3 untuk melihat proses tiap frame
makeDebugVideo = true;
debugVideo = 'video_debug_panel_v2_lane_color_mask2.mp4';

% true = tampilkan video debug panel 2x3 di window MATLAB saat program berjalan
showDebugVideoPreview = true;

%% =============================================================
%% PARAMETER DETEKSI
%% =============================================================
param.minAngle = 25; % seberapa curam sebuah garis agar dianggap sebagai kandidat lane (dalam derajat)
param.maxAngle = 80; % seberapa curam sebuah garis agar dianggap sebagai kandidat lane (dalam derajat)
param.numPeaks = 20; % berapa banyak kandidat garis yang dipertimbangkan
param.houghThresh = 0.30; % seberapa kuat sebuah garis agar dianggap valid
param.fillGap = 500; % menyambungkan garis terputus
param.minLength = 25; % panjang minimum garis valid
param.roiTopRatio = 0.75; % seberapa tinggi area jalan yang akan di masking

%% =============================================================
%% PARAMETER CURVE FALLBACK UNTUK PEMBELOKAN
%% dipakai hanya jika Hough linear gagal mendeteksi salah satu sisi
%% =============================================================
param.enableCurveFallback = true;
param.curveOrder = 2;
param.curveMinPoints = 80;
param.curveMinBins = 6;
param.curveBinCount = 12;
param.curveMaxRMSE = 45;
param.curveStep = 8;
param.curveLeftMaxXRatio = 0.50;
param.curveRightMinXRatio = 0.50;
param.curveLeftPercentile = 25;
param.curveRightPercentile = 75;
param.curveWindowMarginRatio = 0.08;
param.curveMinWindowPoints = 6;
param.curveMinWindowHits = 4;
param.curveBottomSearchRatio = 0.65;
param.curveMinPairDistanceRatio = 0.10;

%% =============================================================
%% PARAMETER VALIDASI GARIS
%% memastikan hasil fitting kiri/kanan masih masuk akal secara posisi
%% =============================================================
param.enableLineValidation = true;
param.leftMaxBottomRatio = 0.70; % garis kiri tidak boleh terlalu jauh ke kanan frame
param.rightMinBottomRatio = 0.30; % garis kanan tidak boleh terlalu jauh ke kiri frame
param.minLaneWidthRatio = 0.12; % jarak minimum garis kiri-kanan terhadap lebar frame
param.maxLaneWidthRatio = 0.90; % jarak maksimum garis kiri-kanan terhadap lebar frame

%% =============================================================
%% PARAMETER MASK WARNA MARKA JALAN
%% =============================================================
param.whiteMinValue = 145; % minimum kecerahan piksel agar dianggap kandidat marka putih
param.whiteMaxSaturation = 90; % maksimum saturasi agar warna dianggap putih/abu terang, bukan warna lain
param.yellowHueMin = 0.10; % batas bawah hue HSV untuk kandidat marka kuning
param.yellowHueMax = 0.18; % batas atas hue HSV untuk kandidat marka kuning
param.yellowMinSaturation = 70; % minimum saturasi agar warna dianggap kuning
param.yellowMinValue = 100; % minimum kecerahan kandidat marka kuning
param.laneColorDilateRadius = 2; % mempertebal mask warna marka agar edge tidak mudah putus
param.enableMaskFallback = true; % gunakan edge ROI biasa jika mask warna terlalu sedikit
param.minColorEdgeRatio = 0.08; % rasio minimum edge warna terhadap edge ROI agar mask dianggap cukup

%% =============================================================
%% PARAMETER ROI
%% mengatur bentuk ROI pada area jalan
%% =============================================================
param.roiMode = 'wide'; % pilihan: 'normal' atau 'wide'
param.bottomLeftRatio  = 0.22; % seberapa lebar area jalan di bagian bawah kiri
param.bottomRightRatio = 0.95; % seberapa lebar area jalan di bagian bawah kanan
param.topLeftRatio     = 0.45; % seberapa lebar area jalan di bagian atas kiri
param.topRightRatio    = 0.62; % seberapa lebar area jalan di bagian atas kanan
param.wideBottomLeftRatio  = 0.08; % ROI lebar untuk jalan belok atau marka bergeser
param.wideBottomRightRatio = 0.98;
param.wideTopLeftRatio     = 0.30;
param.wideTopRightRatio    = 0.75;

%% =============================================================
%% STABILIZER
%% Menstabilkan garis lane antar-frame, supaya garis tidak berkedip, hilang-muncul, atau lompat-lompat.
%% =============================================================
prevL = []; % simpan posisi garis sebelumnya
prevR = [];
missL = 0; % hitung berapa kali garis tidak terdeteksi
missR = 0;
maxMissL = 8;
maxMissR = 15; % kanan lebih sering putus-putus, jadi ditahan lebih lama
alphaL = 0.25;
alphaR = 0.18; % kanan dibuat lebih halus agar tidak mudah lompat
maxJumpRatioL = 0.25; % tolak garis baru jika lompat terlalu jauh dari posisi sebelumnya
maxJumpRatioR = 0.18;

%% =============================================================
%% VIDEO READER DAN WRITER
%% =============================================================
vReader = VideoReader(inputVideo);

totalFrames = floor(vReader.Duration * vReader.FrameRate);
frameNumber = min(max(frameNumber, 1), totalFrames);

vWriter = VideoWriter(outputVideo, 'MPEG-4');
vWriter.FrameRate = vReader.FrameRate;
open(vWriter);

if makeDebugVideo
    debugWriter = VideoWriter(debugVideo, 'MPEG-4');
    debugWriter.FrameRate = vReader.FrameRate;
    open(debugWriter);
end

%% =============================================================
%% WINDOW 1: PREVIEW VIDEO BERJALAN
%% =============================================================
if showVideoPreview
    figPreview = figure('Name', 'Window 1 - Preview Video Lane Detection V2 Lane Color Mask', ...
                        'Color', 'white', ...
                        'Position', [100 100 800 500]);

    axPreview = axes('Parent', figPreview);
    imgPreview = [];
end

if showDebugVideoPreview
    figDebug = figure('Name', 'Window 2 - Debug Panel Video V2', ...
                      'Color', 'white', ...
                      'Position', [950 100 1100 700]);

    axDebug = axes('Parent', figDebug);
    imgDebug = [];
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
    makeDebugFrame = makeDebug || makeDebugVideo || showDebugVideoPreview;

    %% =========================================================
    %% PROSES LANE DETECTION PER FRAME
    %% =========================================================
    result = processLaneFrame(frame, param, makeDebugFrame);

    %% =========================================================
    %% VALIDASI GARIS SEBELUM STABILIZER
    %% =========================================================
    [result.rawL, result.rawR] = validateLaneLines(result.rawL, result.rawR, size(frame, 2), param);

    %% =========================================================
    %% STABILIZER UNTUK VIDEO
    %% =========================================================
    [L, prevL, missL] = smoothLine(result.rawL, prevL, missL, maxMissL, alphaL, maxJumpRatioL, size(frame, 2));
    [R, prevR, missR] = smoothLine(result.rawR, prevR, missR, maxMissR, alphaR, maxJumpRatioR, size(frame, 2));

    displayL = L;
    displayR = R;

    useCurveL = isempty(result.rawL) && isempty(L) && ~isempty(result.curveL);
    useCurveR = isempty(result.rawR) && isempty(R) && ~isempty(result.curveR);

    if useCurveL
        displayL = [];
    end

    if useCurveR
        displayR = [];
    end

    [displayL, displayR, useCurveL, useCurveR] = validateDisplayLaneGeometry( ...
        displayL, displayR, result.curveL, result.curveR, useCurveL, useCurveR, size(frame, 2), param);

    %% =========================================================
    %% FINAL OUTPUT FRAME VIDEO
    %% =========================================================
    out = drawLane(frame, displayL, displayR);

    if useCurveL || useCurveR
        out = drawCurveFallback(out, result.curveL, result.curveR, useCurveL, useCurveR);
    end

    result.finalView = out;
    result.useCurveFallback = useCurveL || useCurveR;

    %% =========================================================
    %% SIMPAN KE VIDEO OUTPUT
    %% =========================================================
    writeVideo(vWriter, out);

    if makeDebugVideo || showDebugVideoPreview
        debugFrame = makeDebugPanelFrame(result, currentFrame);
    end

    if makeDebugVideo
        writeVideo(debugWriter, debugFrame);
    end

    if showDebugVideoPreview && ishandle(figDebug)
        if isempty(imgDebug) || ~isgraphics(imgDebug)
            imgDebug = imshow(debugFrame, 'Parent', axDebug);
        else
            set(imgDebug, 'CData', debugFrame);
        end

        title(axDebug, sprintf('Window 2 - Debug Panel V2 | Frame %d', currentFrame));
        drawnow limitrate;
    end

    %% =========================================================
    %% WINDOW 3: PANEL ALUR PROSES 1 FRAME DIAM / STATIC
    %% =========================================================
    if makeDebug

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

        title(axPreview, sprintf('Window 1 - Video Berjalan V2 | Frame %d', currentFrame));
        drawnow limitrate;
    end
end

close(vWriter);

if makeDebugVideo
    close(debugWriter);
end

fprintf('\nSelesai!\n');
fprintf('Video output disimpan sebagai: %s\n', outputVideo);
fprintf('Panel proses 1 frame disimpan sebagai: %s\n', outputImage);
if makeDebugVideo
    fprintf('Video debug panel disimpan sebagai: %s\n', debugVideo);
end

%% =============================================================
%% FUNGSI: PROSES LANE DETECTION PER FRAME
%% =============================================================
function result = processLaneFrame(frame, param, makeDebug)

    [h, w, ~] = size(frame);
    topY = round(h * param.roiTopRatio);

    %% 1. RGB ASLI
    rgbFrame = frame;

    %% 2. DETEKSI WARNA MARKA JALAN PUTIH DAN KUNING
    laneColorMask = createLaneColorMask(rgbFrame, param);

    %% 3. RGB -> GRAYSCALE
    grayFrame = rgb2gray(rgbFrame);

    %% 4. GRAYSCALE -> GAUSSIAN BLUR
    blurFrame = imgaussfilt(grayFrame, 1.5);

    %% 5. GAUSSIAN BLUR -> CANNY EDGE
    edgeImg = edge(blurFrame, 'Canny', [0.05 0.15]);

    %% 6. GABUNGKAN EDGE DENGAN MASK WARNA MARKA
    edgeLaneColor = edgeImg & laneColorMask;

    %% 7. REGION OF INTEREST / ROI
    [roi, roiPolygon] = createLaneROI(h, w, topY, param);

    edgeOnlyROI = edgeImg & roi;
    edgeColorROI = edgeLaneColor & roi;

    [edgeROI, useFallback] = selectEdgeROI(edgeOnlyROI, edgeColorROI, param);

    %% =========================================================
    %% BUAT VISUALISASI ROI HANYA UNTUK FRAME PILIHAN
    %% =========================================================
    if makeDebug

        laneColorMaskView = uint8(laneColorMask) * 255;

        roiView = rgbFrame;

        for c = 1:3
            channel = roiView(:,:,c);
            channel(~roi) = uint8(double(channel(~roi)) * 0.25);
            roiView(:,:,c) = channel;
        end

        roiView = insertShape(roiView, 'Polygon', roiPolygon, ...
            'Color', 'yellow', ...
            'LineWidth', 4);

        houghView = rgbFrame;
    end

    %% 8. HOUGH TRANSFORM
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

    %% 9. FILTER GARIS DAN PISAHKAN KIRI/KANAN
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

    %% 10. FITTING GARIS KIRI DAN KANAN
    rawL = fitLine(leftPts, h, topY, w);
    rawR = fitLine(rightPts, h, topY, w);

    %% 11. CURVE FALLBACK UNTUK PEMBELOKAN
    [curveL, curveR] = fitCurveFallback(edgeColorROI, h, w, topY, param);

    %% 12. OUTPUT UTAMA
    result.rawL = rawL;
    result.rawR = rawR;
    result.curveL = curveL;
    result.curveR = curveR;
    result.useFallback = useFallback;

    %% 13. OUTPUT DEBUG HANYA UNTUK PANEL 1 FRAME
    if makeDebug
        result.rgbFrame      = rgbFrame;
        result.laneColorMaskView = laneColorMaskView;
        result.grayFrame     = grayFrame;
        result.blurFrame     = blurFrame;
        result.edgeImg       = edgeImg;
        result.edgeLaneColor = edgeLaneColor;
        result.roiView       = roiView;
        result.edgeROI       = edgeROI;
        result.houghView     = houghView;
    end
end

%% =============================================================
%% FUNGSI: MASK WARNA MARKA JALAN PUTIH DAN KUNING
%% =============================================================
function laneColorMask = createLaneColorMask(rgbFrame, param)

    hsvFrame = rgb2hsv(rgbFrame);

    hue = hsvFrame(:,:,1);
    saturation = hsvFrame(:,:,2) * 255;
    value = hsvFrame(:,:,3) * 255;

    whiteMask = value >= param.whiteMinValue & ...
                saturation <= param.whiteMaxSaturation;

    yellowMask = hue >= param.yellowHueMin & ...
                 hue <= param.yellowHueMax & ...
                 saturation >= param.yellowMinSaturation & ...
                 value >= param.yellowMinValue;

    laneColorMask = whiteMask | yellowMask;
    laneColorMask = bwareaopen(laneColorMask, 20);

    if param.laneColorDilateRadius > 0
        laneColorMask = imdilate(laneColorMask, strel('disk', param.laneColorDilateRadius));
    end
end

%% =============================================================
%% FUNGSI: BUAT ROI BERDASARKAN MODE
%% =============================================================
function [roi, roiPolygon] = createLaneROI(h, w, topY, param)

    if strcmpi(param.roiMode, 'wide')
        bottomLeftRatio = param.wideBottomLeftRatio;
        bottomRightRatio = param.wideBottomRightRatio;
        topLeftRatio = param.wideTopLeftRatio;
        topRightRatio = param.wideTopRightRatio;
    else
        bottomLeftRatio = param.bottomLeftRatio;
        bottomRightRatio = param.bottomRightRatio;
        topLeftRatio = param.topLeftRatio;
        topRightRatio = param.topRightRatio;
    end

    bottomLeft  = bottomLeftRatio  * w;
    bottomRight = bottomRightRatio * w;
    topLeft     = topLeftRatio     * w;
    topRight    = topRightRatio    * w;

    roi = poly2mask( ...
        [bottomLeft bottomRight topRight topLeft], ...
        [h h topY topY], ...
        h, w);

    roiPolygon = [bottomLeft h bottomRight h topRight topY topLeft topY];
end

%% =============================================================
%% FUNGSI: FALLBACK EDGE JIKA MASK WARNA TERLALU SEDIKIT
%% =============================================================
function [edgeROI, useFallback] = selectEdgeROI(edgeOnlyROI, edgeColorROI, param)

    useFallback = false;
    edgeROI = edgeColorROI;

    if ~param.enableMaskFallback
        return;
    end

    totalEdgeCount = nnz(edgeOnlyROI);
    colorEdgeCount = nnz(edgeColorROI);

    if totalEdgeCount == 0
        return;
    end

    colorEdgeRatio = colorEdgeCount / totalEdgeCount;

    if colorEdgeRatio < param.minColorEdgeRatio
        edgeROI = edgeOnlyROI;
        useFallback = true;
    end
end

%% =============================================================
%% FUNGSI: CURVE FALLBACK UNTUK MARKA PADA PEMBELOKAN
%% =============================================================
function [curveL, curveR] = fitCurveFallback(edgeROI, h, w, topY, param)

    curveL = [];
    curveR = [];

    if ~param.enableCurveFallback
        return;
    end

    curveL = fitSingleCurve(edgeROI, h, w, topY, param, 'left');
    curveR = fitSingleCurve(edgeROI, h, w, topY, param, 'right');
end

function curvePts = fitSingleCurve(edgeROI, h, w, topY, param, side)

    curvePts = [];
    [yAll, xAll] = find(edgeROI);

    if strcmp(side, 'left')
        keep = xAll <= param.curveLeftMaxXRatio * w;
    else
        keep = xAll >= param.curveRightMinXRatio * w;
    end

    xAll = xAll(keep);
    yAll = yAll(keep);

    if numel(xAll) < param.curveMinPoints
        return;
    end

    bottomSearchY = round(topY + param.curveBottomSearchRatio * (h - topY));
    bottomKeep = yAll >= bottomSearchY;

    if nnz(bottomKeep) < param.curveMinWindowPoints
        return;
    end

    if strcmp(side, 'left')
        currentX = prctile(double(xAll(bottomKeep)), param.curveLeftPercentile);
    else
        currentX = prctile(double(xAll(bottomKeep)), param.curveRightPercentile);
    end

    margin = max(20, round(param.curveWindowMarginRatio * w));
    binEdges = round(linspace(h, topY, param.curveBinCount + 1));
    sampleX = [];
    sampleY = [];
    windowHits = 0;

    for b = 1:param.curveBinCount
        yLow = binEdges(b + 1);
        yHigh = binEdges(b);

        inBin = yAll >= yLow & ...
                yAll <= yHigh & ...
                abs(double(xAll) - currentX) <= margin;

        if nnz(inBin) < param.curveMinWindowPoints
            continue;
        end

        xBin = xAll(inBin);
        yBin = yAll(inBin);

        if strcmp(side, 'left')
            sampleX(end + 1, 1) = prctile(double(xBin), param.curveLeftPercentile); %#ok<AGROW>
        else
            sampleX(end + 1, 1) = prctile(double(xBin), param.curveRightPercentile); %#ok<AGROW>
        end

        sampleY(end + 1, 1) = median(double(yBin)); %#ok<AGROW>
        currentX = sampleX(end);
        windowHits = windowHits + 1;
    end

    if numel(sampleX) < param.curveMinBins || windowHits < param.curveMinWindowHits
        return;
    end

    p = polyfit(sampleY, sampleX, param.curveOrder);
    fittedX = polyval(p, sampleY);
    rmse = sqrt(mean((fittedX - sampleX).^2));

    if rmse > param.curveMaxRMSE
        return;
    end

    yCurve = (topY:param.curveStep:h)';
    xCurve = round(polyval(p, yCurve));

    valid = xCurve >= 1 & xCurve <= w;
    xCurve = xCurve(valid);
    yCurve = yCurve(valid);

    if numel(xCurve) < 2
        return;
    end

    if strcmp(side, 'left') && median(xCurve) > param.curveLeftMaxXRatio * w
        return;
    end

    if strcmp(side, 'right') && median(xCurve) < param.curveRightMinXRatio * w
        return;
    end

    if strcmp(side, 'left') && any(xCurve > param.curveLeftMaxXRatio * w)
        return;
    end

    if strcmp(side, 'right') && any(xCurve < param.curveRightMinXRatio * w)
        return;
    end

    curvePts = [xCurve yCurve];
end

%% =============================================================
%% FUNGSI: VALIDASI GEOMETRI OUTPUT GARIS/KURVA
%% =============================================================
function [L, R, useCurveL, useCurveR] = validateDisplayLaneGeometry(L, R, curveL, curveR, useCurveL, useCurveR, w, param)

    minPairDistance = param.curveMinPairDistanceRatio * w;

    if ~isempty(L) && L(1) > param.curveLeftMaxXRatio * w
        L = [];
    end

    if ~isempty(R) && R(1) < param.curveRightMinXRatio * w
        R = [];
    end

    if useCurveL && ~isCurveOnSide(curveL, 'left', w, param)
        useCurveL = false;
    end

    if useCurveR && ~isCurveOnSide(curveR, 'right', w, param)
        useCurveR = false;
    end

    if useCurveL && ~isempty(R) && ~curveLeftOfLine(curveL, R, minPairDistance)
        useCurveL = false;
    end

    if useCurveR && ~isempty(L) && ~lineLeftOfCurve(L, curveR, minPairDistance)
        useCurveR = false;
    end

    if useCurveL && useCurveR && ~curveLeftOfCurve(curveL, curveR, minPairDistance)
        useCurveL = false;
        useCurveR = false;
    end
end

function ok = isCurveOnSide(curvePts, side, w, param)

    ok = false;

    if size(curvePts, 1) < 2
        return;
    end

    if strcmp(side, 'left')
        ok = all(curvePts(:,1) <= param.curveLeftMaxXRatio * w);
    else
        ok = all(curvePts(:,1) >= param.curveRightMinXRatio * w);
    end
end

function ok = curveLeftOfLine(curvePts, linePts, minDistance)

    curveBottomX = curvePts(end, 1);
    curveTopX = curvePts(1, 1);

    ok = curveBottomX + minDistance < linePts(1) && ...
         curveTopX + minDistance < linePts(3);
end

function ok = lineLeftOfCurve(linePts, curvePts, minDistance)

    curveBottomX = curvePts(end, 1);
    curveTopX = curvePts(1, 1);

    ok = linePts(1) + minDistance < curveBottomX && ...
         linePts(3) + minDistance < curveTopX;
end

function ok = curveLeftOfCurve(curveL, curveR, minDistance)

    yCommon = intersect(curveL(:,2), curveR(:,2));

    if numel(yCommon) < 2
        ok = false;
        return;
    end

    xL = interp1(curveL(:,2), curveL(:,1), yCommon, 'linear');
    xR = interp1(curveR(:,2), curveR(:,1), yCommon, 'linear');

    ok = all(xL + minDistance < xR);
end

%% =============================================================
%% FUNGSI: SIMPAN PANEL ALUR PROSES
%% =============================================================
function saveProcessPanel(result, frameNumber, outputImage, showProcessFigure)

    if showProcessFigure
        figProcess = figure('Name', 'Window 3 - Proses Lane Detection V2 Lane Color Mask', ...
                            'Color', 'white', ...
                            'Position', [950 100 1500 850]);
    else
        figProcess = figure('Name', 'Window 3 - Proses Lane Detection V2 Lane Color Mask', ...
                            'Color', 'white', ...
                            'Position', [950 100 1500 850], ...
                            'Visible', 'off');
    end

    tl = tiledlayout(figProcess, 3, 3, ...
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
    imshow(result.laneColorMaskView);
    title('5. Mask Putih + Kuning');

    nexttile(tl);
    imshow(result.edgeLaneColor);
    title('6. Canny + Mask Warna Marka');

    nexttile(tl);
    imshow(result.roiView);
    title('7. ROI Area Jalan');

    nexttile(tl);
    imshow(result.houghView);
    title('8. Kandidat Garis Hough');

    nexttile(tl);
    imshow(result.finalView);
    title(sprintf('9. Final Deteksi Jalur Frame #%d', frameNumber));

    exportgraphics(figProcess, outputImage, 'Resolution', 200);
end

%% =============================================================
%% FUNGSI: BUAT FRAME VIDEO DEBUG PANEL 2x3
%% =============================================================
function panelFrame = makeDebugPanelFrame(result, currentFrame)

    [h, w, ~] = size(result.rgbFrame);

    tileH = max(120, round(h / 2));
    tileW = max(160, round(w / 2));

    originalTile = makeDebugTile(result.rgbFrame, 'Original Frame', tileH, tileW);
    colorMaskTile = makeDebugTile(result.laneColorMaskView, 'Mask Putih + Kuning', tileH, tileW);
    edgeColorTile = makeDebugTile(result.edgeLaneColor, 'Canny + Mask Warna', tileH, tileW);
    roiTile = makeDebugTile(result.roiView, 'ROI Area Jalan', tileH, tileW);
    houghTile = makeDebugTile(result.houghView, 'Hough Lines', tileH, tileW);
    finalTile = makeDebugTile(result.finalView, 'Final Output', tileH, tileW);

    topRow = cat(2, originalTile, colorMaskTile, edgeColorTile);
    bottomRow = cat(2, roiTile, houghTile, finalTile);
    panelFrame = cat(1, topRow, bottomRow);

    panelFrame = insertText(panelFrame, [12 12], ...
        sprintf('Debug Panel V2 | Frame %d', currentFrame), ...
        'FontSize', 20, ...
        'BoxColor', 'black', ...
        'TextColor', 'white', ...
        'BoxOpacity', 0.65);

    if result.useFallback
        panelFrame = insertText(panelFrame, [12 48], ...
            'Fallback aktif: Hough memakai Canny Edge dalam ROI', ...
            'FontSize', 16, ...
            'BoxColor', 'yellow', ...
            'TextColor', 'black', ...
            'BoxOpacity', 0.75);
    end

    if result.useCurveFallback
        panelFrame = insertText(panelFrame, [12 82], ...
            'Curve fallback aktif: sisi linear hilang digambar dengan polynomial', ...
            'FontSize', 16, ...
            'BoxColor', 'blue', ...
            'TextColor', 'white', ...
            'BoxOpacity', 0.75);
    end
end

%% =============================================================
%% FUNGSI: FORMAT 1 TILE UNTUK VIDEO DEBUG
%% =============================================================
function tile = makeDebugTile(img, label, tileH, tileW)

    if islogical(img)
        img = uint8(img) * 255;
    end

    if size(img, 3) == 1
        img = repmat(img, [1 1 3]);
    end

    tile = imresize(img, [tileH tileW]);

    tile = insertText(tile, [10 10], label, ...
        'FontSize', 18, ...
        'BoxColor', 'black', ...
        'TextColor', 'white', ...
        'BoxOpacity', 0.65);
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
%% FUNGSI: VALIDASI GARIS KIRI DAN KANAN
%% =============================================================
function [L, R] = validateLaneLines(L, R, w, param)

    if ~param.enableLineValidation
        return;
    end

    if ~isempty(L) && L(1) > param.leftMaxBottomRatio * w
        L = [];
    end

    if ~isempty(R) && R(1) < param.rightMinBottomRatio * w
        R = [];
    end

    if isempty(L) || isempty(R)
        return;
    end

    bottomDistance = R(1) - L(1);
    topDistance = R(3) - L(3);

    minLaneWidth = param.minLaneWidthRatio * w;
    maxLaneWidth = param.maxLaneWidthRatio * w;

    laneOrderInvalid = bottomDistance <= 0 || topDistance <= 0;
    laneWidthInvalid = bottomDistance < minLaneWidth || ...
                       bottomDistance > maxLaneWidth;

    if laneOrderInvalid || laneWidthInvalid
        L = [];
        R = [];
    end
end

%% =============================================================
%% FUNGSI: ANTI FLICKER / ANTI MUNCUL-HILANG
%% =============================================================
function [lineOut, prevLine, missCount] = smoothLine(newLine, prevLine, missCount, maxMiss, alpha, maxJumpRatio, frameWidth)

    if ~isempty(newLine)

        if ~isempty(prevLine)
            jump = max(abs(double(newLine([1 3])) - double(prevLine([1 3]))));

            if jump > maxJumpRatio * frameWidth
                missCount = missCount + 1;

                if missCount <= maxMiss
                    lineOut = prevLine;
                    return;
                end

                lineOut = [];
                prevLine = [];
                return;
            end
        end

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

%% =============================================================
%% FUNGSI: GAMBAR CURVE FALLBACK
%% =============================================================
function out = drawCurveFallback(frame, curveL, curveR, useCurveL, useCurveR)

    out = frame;

    if useCurveL && size(curveL, 1) >= 2
        out = insertShape(out, 'Line', curveToSegments(curveL), ...
            'Color', 'blue', ...
            'LineWidth', 5);
    end

    if useCurveR && size(curveR, 1) >= 2
        out = insertShape(out, 'Line', curveToSegments(curveR), ...
            'Color', 'red', ...
            'LineWidth', 5);
    end
end

function segments = curveToSegments(curvePts)

    segments = [curvePts(1:end-1,1) curvePts(1:end-1,2) ...
                curvePts(2:end,1)   curvePts(2:end,2)];
end
